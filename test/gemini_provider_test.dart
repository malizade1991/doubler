import 'dart:convert';

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
      socketFactory: (uri) async {
        expect(uri.queryParameters['key'], 'test-key-value-123456');
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
    expect(events.whereType<ProviderConnected>(), isNotEmpty);
    expect(fake.sent, isNotEmpty);
    expect(fake.sent.first, contains('setup'));
    expect(fake.sent.first, isNot(contains('test-key-value-123456')));

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
}
