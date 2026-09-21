import 'dart:convert';
import 'dart:typed_data';

import '../../domain/providers/translation_provider.dart';
import 'gemini_config.dart';
import 'gemini_system_instruction.dart';

/// Wire format for the Gemini Live WebSocket.
///
/// The Developer API speaks proto3 JSON: **camelCase**, and
/// `BidiGenerateContentSetupComplete` has no fields — so the server answers
/// `{"setupComplete": {}}`, never `{"setupComplete": true}`. Treating that
/// object as "not connected" left the live button on «در حال اتصال» forever.
abstract final class GeminiLiveMessages {
  /// `fa-IR` → `fa`, `zh-CN` → `zh-Hans`. Live Translate rejects region tags
  /// it does not list (Persian is `fa`, not `fa-IR`).
  static String translationLanguageCode(String bcp47) {
    switch (bcp47) {
      case 'zh-CN':
      case 'zh':
        return 'zh-Hans';
      case 'zh-TW':
      case 'zh-HK':
        return 'zh-Hant';
      case 'pt-BR':
        return 'pt-BR';
      case 'pt-PT':
        return 'pt-PT';
      case 'auto':
        return 'fa';
      default:
        final primary = bcp47.split('-').first;
        return primary.isEmpty ? 'en' : primary;
    }
  }

  static String setup(SessionConfig config, {String? resumeHandle}) {
    final model = GeminiConfig.modelResource(config.model);
    final translate = GeminiConfig.isTranslateModel(config.model);
    final generation = <String, dynamic>{
      'responseModalities': ['AUDIO'],
    };
    if (translate) {
      // Live Translate rejects system instructions, tools and speech config.
      // Those fields are hard errors and close the socket before setupComplete.
      generation['inputAudioTranscription'] = <String, dynamic>{};
      generation['outputAudioTranscription'] = <String, dynamic>{};
      generation['translationConfig'] = <String, dynamic>{
        'targetLanguageCode': translationLanguageCode(config.targetLanguage),
        'echoTargetLanguage': false,
      };
    } else {
      generation['speechConfig'] = <String, dynamic>{
        'voiceConfig': <String, dynamic>{
          'prebuiltVoiceConfig': <String, dynamic>{
            'voiceName': config.voiceId ?? GeminiConfig.defaultVoice,
          },
        },
      };
    }

    final setup = <String, dynamic>{
      'model': model,
      'generationConfig': generation,
    };
    if (!translate) {
      setup['systemInstruction'] = <String, dynamic>{
        'parts': <Map<String, dynamic>>[
          {'text': GeminiSystemInstruction.build(config)},
        ],
      };
      setup['inputAudioTranscription'] = <String, dynamic>{};
      setup['outputAudioTranscription'] = <String, dynamic>{};
      setup['sessionResumption'] = resumeHandle == null
          ? <String, dynamic>{}
          : <String, dynamic>{'handle': resumeHandle};
    }
    return jsonEncode(<String, dynamic>{'setup': setup});
  }

  /// Current realtime audio frame. `mediaChunks` is deprecated and, on the
  /// translate model, is not what starts a turn.
  static String audioChunk(Uint8List pcm16k) {
    return jsonEncode(<String, dynamic>{
      'realtimeInput': <String, dynamic>{
        'audio': <String, dynamic>{
          'data': base64Encode(pcm16k),
          'mimeType': 'audio/pcm;rate=16000',
        },
      },
    });
  }

  /// True when this server frame is the setup acknowledgement.
  ///
  /// Accepted shapes (all observed or documented):
  /// `{"setupComplete": {}}`, `{"setupComplete": true}`, `{"setup_complete": {}}`.
  /// An explicit `false` is not an acknowledgement.
  static bool isSetupComplete(Map<String, dynamic> map) {
    for (final key in const ['setupComplete', 'setup_complete']) {
      if (!map.containsKey(key)) {
        continue;
      }
      return map[key] != false;
    }
    return false;
  }

  /// Text frames, binary JSON frames, and already-decoded maps.
  ///
  /// The Live WebSocket often delivers `{"setupComplete":{}}` as a binary
  /// frame, not a text frame. A non-JSON frame is ignored — one stray byte
  /// must not tear the session down.
  static Map<String, dynamic>? decode(dynamic raw) {
    try {
      dynamic decoded = raw;
      if (raw is String) {
        decoded = jsonDecode(raw);
      } else if (raw is ByteData) {
        decoded = jsonDecode(
          utf8.decode(raw.buffer.asUint8List(raw.offsetInBytes, raw.lengthInBytes)),
        );
      } else if (raw is List<int>) {
        if (raw.isEmpty) {
          return null;
        }
        decoded = jsonDecode(utf8.decode(raw));
      }
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
      return null;
    } on FormatException {
      return null;
    }
  }
}
