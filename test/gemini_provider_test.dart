import 'dart:convert';
import 'dart:typed_data';

import 'package:doubler/domain/providers/translation_provider.dart';
import 'package:doubler/infrastructure/gemini/gemini_config.dart';
import 'package:doubler/infrastructure/gemini/gemini_error_mapper.dart';
import 'package:doubler/infrastructure/gemini/gemini_socket.dart';
import 'package:doubler/infrastructure/gemini/gemini_system_instruction.dart';
import 'package:doubler/infrastructure/gemini/gemini_translation_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('redacted URI never contains a key', () {
    expect(GeminiConfig.redactedUri(), isNot(contains('AIza')));
    expect(GeminiConfig.liveUri('SECRETKEY').toString(), contains('SECRETKEY'));
    expect(GeminiConfig.redactedUri(), isNot(contains('SECRETKEY')));
  });

  test('the socket carries the key in the header as well as the query', () {
    final uri = GeminiConfig.liveUri('SECRETKEY');
    expect(uri.queryParameters['key'], 'SECRETKEY');
    expect(GeminiConfig.authHeaders('SECRETKEY')['x-goog-api-key'], 'SECRETKEY');
  });

  test('error mapper', () {
    expect(GeminiErrorMapper.fromCloseCode(403, 'invalid api key'), 'keyInvalid');
    expect(GeminiErrorMapper.fromCloseCode(429, 'quota'), 'quotaExceeded');
    expect(GeminiErrorMapper.fromCloseCode(1011, null), 'geminiUnavailable');
  });

  test('system instruction is a translator not a chatbot', () {
    final text = GeminiSystemInstruction.build(
      const SessionConfig(sourceLanguage: 'en-US', targetLanguage: 'fa-IR'),
    );
    expect(text.toLowerCase(), contains('translate'));
    expect(text, contains('fa-IR'));
  });

  test('provider sends setup and maps audio/transcript events', () async {
    final fake = FakeGeminiSocket();
    final provider = GeminiTranslationProvider(
      socketFactory: (endpoint) async {
        expect(endpoint.uri.queryParameters['key'], 'test-key-value-123456');
        expect(
          endpoint.headers['x-goog-api-key'],
          'test-key-value-123456',
        );
        expect(endpoint.uri.path, contains('BidiGenerateContent'));
        return fake;
      },
      maxReconnects: 0,
    );

    final events = <ProviderEvent>[];
    provider
        .connect(
          const SessionConfig(
            sourceLanguage: 'en-US',
            targetLanguage: 'fa-IR',
            apiKey: 'test-key-value-123456',
          ),
        )
        .listen(events.add);

    await Future<void>.delayed(Duration.zero);
    expect(fake.sent, isNotEmpty);
    expect(fake.sent.first, contains('setup'));
    expect(fake.sent.first, isNot(contains('test-key-value-123456')));
    expect(fake.sent.first, contains('models/gemini-3.5-live-translate-preview'));
    expect(fake.sent.first, contains('translationConfig'));
    expect(fake.sent.first, contains('"targetLanguageCode":"fa"'));
    expect(fake.sent.first, isNot(contains('systemInstruction')));
    // Nothing is "connected" until the server confirms the handshake.
    expect(events.whereType<ProviderConnected>(), isEmpty);

    // Audio produced during the handshake is dropped, never queued forever.
    final sentBefore = fake.sent.length;
    provider.sendAudio(Uint8List.fromList([1, 2, 3, 4]));
    expect(fake.sent, hasLength(sentBefore));

    fake.emit(jsonEncode({'setupComplete': true}));
    await Future<void>.delayed(Duration.zero);
    expect(events.whereType<ProviderConnected>(), isNotEmpty);

    provider.sendAudio(Uint8List.fromList([1, 2, 3, 4]));
    expect(fake.sent.last, contains('realtimeInput'));
    expect(fake.sent.last, contains('audio/pcm;rate=16000'));
    expect(fake.sent.last, isNot(contains('media_chunks')));
    expect(fake.sent.last, isNot(contains('mediaChunks')));

    fake.emit(
      jsonEncode({
        'serverContent': {
          'outputTranscription': {'text': 'سلام', 'finished': true},
          'modelTurn': {
            'parts': [
              {
                'inlineData': {
                  'mimeType': 'audio/pcm',
                  'data': base64Encode([1, 2, 3, 4]),
                },
              },
            ],
          },
        },
      }),
    );
    await Future<void>.delayed(Duration.zero);
    expect(events.whereType<ProviderTranscript>(), isNotEmpty);
    expect(events.whereType<ProviderAudioOut>(), isNotEmpty);

    fake.emit(
      jsonEncode({
        'error': {'code': 403, 'message': 'invalid api key'},
      }),
    );
    await Future<void>.delayed(Duration.zero);
    expect(
      events.whereType<ProviderError>().last.code,
      'keyInvalid',
    );

    await provider.disconnect();
  });

  test('a socket that dies with no key says keyMissing, not unavailable', () async {
    final provider = GeminiTranslationProvider(
      socketFactory: (endpoint) async => FakeGeminiSocket(),
      maxReconnects: 0,
    );
    final events = <ProviderEvent>[];
    provider
        .connect(const SessionConfig(sourceLanguage: 'en-US', targetLanguage: 'fa-IR'))
        .listen(events.add);
    await Future<void>.delayed(Duration.zero);
    expect(events.whereType<ProviderError>().last.code, 'keyMissing');
    await provider.disconnect();
  });

  test('setupComplete as an empty object is the real handshake', () async {
    final fake = FakeGeminiSocket();
    final provider = GeminiTranslationProvider(
      socketFactory: (_) async => fake,
      maxReconnects: 0,
    );
    final events = <ProviderEvent>[];
    provider
        .connect(
          const SessionConfig(
            sourceLanguage: 'en-US',
            targetLanguage: 'fa-IR',
            apiKey: 'test-key-value-123456',
          ),
        )
        .listen(events.add);
    await Future<void>.delayed(Duration.zero);
    // Documented wire shape. `== true` never matches this, which is why the
    // button stayed on «در حال اتصال».
    fake.emit(jsonEncode({'setupComplete': <String, dynamic>{}}));
    await Future<void>.delayed(Duration.zero);
    expect(events.whereType<ProviderConnected>(), isNotEmpty);

    fake.emit(utf8.encode(jsonEncode({'setup_complete': <String, dynamic>{}})));
    provider.sendAudio(Uint8List.fromList([9, 8, 7, 6]));
    expect(fake.sent.last, contains('realtimeInput'));
    await provider.disconnect();
  });

  test('serverContent alone is enough to leave connecting', () async {
    final fake = FakeGeminiSocket();
    final provider = GeminiTranslationProvider(
      socketFactory: (_) async => fake,
      maxReconnects: 0,
    );
    final events = <ProviderEvent>[];
    provider
        .connect(
          const SessionConfig(
            sourceLanguage: 'en-US',
            targetLanguage: 'fa-IR',
            apiKey: 'test-key-value-123456',
          ),
        )
        .listen(events.add);
    await Future<void>.delayed(Duration.zero);
    fake.emit(
      jsonEncode({
        'serverContent': {
          'modelTurn': {
            'parts': [
              {
                'inlineData': {
                  'mimeType': 'audio/pcm',
                  'data': base64Encode([1, 2]),
                },
              },
            ],
          },
        },
      }),
    );
    await Future<void>.delayed(Duration.zero);
    expect(events.whereType<ProviderConnected>(), isNotEmpty);
    expect(events.whereType<ProviderAudioOut>(), isNotEmpty);
    provider.sendAudio(Uint8List.fromList([1, 2, 3, 4]));
    expect(fake.sent.last, contains('realtimeInput'));
    await provider.disconnect();
  });

  test('a silent socket becomes connectionTimeout, not an endless spinner', () async {
    final fake = FakeGeminiSocket();
    final provider = GeminiTranslationProvider(
      socketFactory: (_) async => fake,
      maxReconnects: 0,
      handshakeTimeout: const Duration(milliseconds: 40),
    );
    final events = <ProviderEvent>[];
    provider
        .connect(
          const SessionConfig(
            sourceLanguage: 'en-US',
            targetLanguage: 'fa-IR',
            apiKey: 'test-key-value-123456',
          ),
        )
        .listen(events.add);
    await Future<void>.delayed(const Duration(milliseconds: 180));
    expect(events.whereType<ProviderConnected>(), isEmpty);
    expect(
      events.whereType<ProviderError>().map((e) => e.code),
      contains('connectionTimeout'),
    );
    await provider.disconnect();
  });

  test('error text is redacted before classification', () {
    // A key whose own characters contain "401" / "denied" must not be able to
    // classify itself — or reach a log. (Error text arrives as Object; a bare
    // string is enough to exercise the classifier.)
    const query = 'socket closed for key=AQ.ab8-xy.z401.denied';
    expect(IoGeminiSocket.statusCodeOf(query), isNull);
    expect(IoGeminiSocket.classifyError(query), 'geminiUnavailable');

    const header =
        'handshake rejected for x-goog-api-key: AIzaSyDummyKey401Quota';
    expect(IoGeminiSocket.statusCodeOf(header), isNull);
    expect(IoGeminiSocket.classifyError(header), 'geminiUnavailable');

    const bare = 'dead: AQ.abc.403.def';
    expect(IoGeminiSocket.statusCodeOf(bare), isNull);
    expect(IoGeminiSocket.classifyError(bare), 'geminiUnavailable');

    // Real statuses outside a key still classify.
    expect(IoGeminiSocket.statusCodeOf('HTTP 429 too many'), 429);
    expect(IoGeminiSocket.classifyError('HTTP 429'), 'quotaExceeded');
  });

  test('fake socket exposes close code and reason only after close', () async {
    final fake = FakeGeminiSocket();
    expect(fake.closeCode, isNull);
    expect(fake.closeReason, isNull);
    await fake.close(1006, 'going away');
    expect(fake.closed, isTrue);
    expect(fake.closeCode, 1006);
    expect(fake.closeReason, 'going away');
  });
}
