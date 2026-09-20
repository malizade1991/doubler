import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../../domain/providers/translation_provider.dart';
import 'gemini_config.dart';
import 'gemini_error_mapper.dart';
import 'gemini_socket.dart';
import 'gemini_system_instruction.dart';

class GeminiTranslationProvider implements TranslationProvider {
  GeminiTranslationProvider({
    GeminiSocketFactory? socketFactory,
    this.maxReconnects = 3,
  }) : _socketFactory = socketFactory ?? IoGeminiSocket.connect;

  final GeminiSocketFactory _socketFactory;
  final int maxReconnects;

  final _events = StreamController<ProviderEvent>.broadcast();
  GeminiSocket? _socket;
  SessionConfig? _config;
  StreamSubscription<dynamic>? _sub;
  int _reconnects = 0;
  bool _intentionalClose = false;
  String? _resumeHandle;

  @override
  Stream<ProviderEvent> connect(SessionConfig config) {
    _config = config;
    _intentionalClose = false;
    _reconnects = 0;
    unawaited(_open());
    return _events.stream;
  }

  Future<void> _open() async {
    final config = _config;
    final key = config?.apiKey;
    if (config == null || key == null || key.isEmpty) {
      _events.add(const ProviderError('keyMissing'));
      return;
    }
    try {
      final socket = await _socketFactory(GeminiConfig.liveUri(key));
      _socket = socket;
      _sub = socket.messages.listen(
        _onMessage,
        onError: (_) {
          _events.add(const ProviderError('geminiUnavailable'));
          unawaited(_maybeReconnect());
        },
        onDone: () {
          if (!_intentionalClose) {
            unawaited(_maybeReconnect());
          } else {
            _events.add(const ProviderDisconnected());
          }
        },
      );
      socket.add(_setupJson(config));
      _events.add(const ProviderConnected());
    } on Object {
      _events.add(const ProviderError('geminiUnavailable'));
      await _maybeReconnect();
    }
  }

  String _setupJson(SessionConfig config) {
    final setup = <String, dynamic>{
      'model': GeminiConfig.liveModel,
      'generation_config': {
        'response_modalities': ['AUDIO'],
        'speech_config': {
          'voice_config': {
            'prebuilt_voice_config': {
              'voice_name': config.voiceId ?? GeminiConfig.defaultVoice,
            },
          },
        },
      },
      'system_instruction': {
        'parts': [
          {'text': GeminiSystemInstruction.build(config)},
        ],
      },
      'input_audio_transcription': <String, dynamic>{},
      'output_audio_transcription': <String, dynamic>{},
    };
    if (_resumeHandle != null) {
      setup['session_resumption'] = {'handle': _resumeHandle};
    }
    return jsonEncode({'setup': setup});
  }

  void _onMessage(dynamic raw) {
    Map<String, dynamic>? map;
    if (raw is String) {
      map = jsonDecode(raw) as Map<String, dynamic>;
    } else if (raw is Map<String, dynamic>) {
      map = raw;
    }
    if (map == null) {
      return;
    }

    if (map['error'] != null) {
      final err = map['error'];
      final code = err is Map ? err['code'] : null;
      final message = err is Map ? err['message']?.toString() : err.toString();
      _events.add(
        ProviderError(
          GeminiErrorMapper.fromCloseCode(
            code is int ? code : null,
            message,
          ),
        ),
      );
      return;
    }

    final goAway = map['goAway'];
    if (goAway != null) {
      unawaited(_maybeReconnect());
      return;
    }

    final resume = map['sessionResumptionUpdate'] ?? map['session_resumption_update'];
    if (resume is Map && resume['newHandle'] != null) {
      _resumeHandle = resume['newHandle'] as String;
      _events.add(ProviderResumed(_resumeHandle!));
    }

    final sc = map['serverContent'] ?? map['server_content'];
    if (sc is Map<String, dynamic>) {
      _handleServerContent(sc);
    }
  }

  void _handleServerContent(Map<String, dynamic> sc) {
    if (sc['interrupted'] == true) {
      _events.add(const ProviderSpeaking(false));
    }
    if (sc['turnComplete'] == true || sc['turn_complete'] == true) {
      _events.add(const ProviderSpeaking(false));
    }

    final inputTx = sc['inputTranscription'] ?? sc['input_transcription'];
    if (inputTx is Map && inputTx['text'] != null) {
      _events.add(
        ProviderTranscript(
          text: inputTx['text'] as String,
          isInput: true,
          isFinal: inputTx['finished'] == true,
        ),
      );
    }
    final outputTx = sc['outputTranscription'] ?? sc['output_transcription'];
    if (outputTx is Map && outputTx['text'] != null) {
      _events.add(
        ProviderTranscript(
          text: outputTx['text'] as String,
          isInput: false,
          isFinal: outputTx['finished'] == true,
        ),
      );
      _events.add(const ProviderSpeaking(true));
    }

    final turn = sc['modelTurn'] ?? sc['model_turn'];
    if (turn is Map) {
      final parts = turn['parts'];
      if (parts is List) {
        for (final part in parts) {
          if (part is! Map) {
            continue;
          }
          final inline = part['inlineData'] ?? part['inline_data'];
          if (inline is Map && inline['data'] is String) {
            final bytes = base64Decode(inline['data'] as String);
            _events.add(ProviderAudioOut(Uint8List.fromList(bytes)));
            _events.add(const ProviderSpeaking(true));
          }
        }
      }
    }
  }

  Future<void> _maybeReconnect() async {
    if (_intentionalClose) {
      return;
    }
    if (_reconnects >= maxReconnects) {
      _events.add(const ProviderError('geminiUnavailable'));
      _events.add(const ProviderDisconnected());
      return;
    }
    _reconnects++;
    await Future<void>.delayed(Duration(milliseconds: 400 * _reconnects));
    await _open();
  }

  @override
  void sendAudio(Uint8List pcm16k) {
    final socket = _socket;
    if (socket == null) {
      return;
    }
    socket.add(
      jsonEncode({
        'realtime_input': {
          'media_chunks': [
            {
              'mime_type': 'audio/pcm;rate=16000',
              'data': base64Encode(pcm16k),
            },
          ],
        },
      }),
    );
  }

  @override
  void updateConfig(SessionConfig patch) {
    _config = (_config ?? patch).merge(patch);
  }

  @override
  Future<void> disconnect() async {
    _intentionalClose = true;
    await _sub?.cancel();
    await _socket?.close(1000, 'client');
    _socket = null;
    _events.add(const ProviderDisconnected());
  }
}
