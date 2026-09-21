import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:doubler/domain/providers/translation_provider.dart';
import 'package:doubler/infrastructure/gemini/gemini_socket.dart';
import 'package:doubler/infrastructure/gemini/gemini_translation_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a real socket handshake with setupComplete {} leaves connecting', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    final seen = Completer<Map<String, dynamic>>();
    server.listen((request) async {
      if (!WebSocketTransformer.isUpgradeRequest(request)) {
        request.response.statusCode = 400;
        await request.response.close();
        return;
      }
      final socket = await WebSocketTransformer.upgrade(request);
      socket.listen((dynamic data) {
        final text = data is String ? data : utf8.decode(data as List<int>);
        final msg = jsonDecode(text);
        if (msg is Map && msg['setup'] is Map && !seen.isCompleted) {
          seen.complete(Map<String, dynamic>.from(msg['setup'] as Map));
          // Binary frame, empty object — the shape that used to be ignored.
          socket.add(utf8.encode(jsonEncode({'setupComplete': <String, dynamic>{}})));
        }
      });
    });

    final provider = GeminiTranslationProvider(
      socketFactory: (_) => IoGeminiSocket.connect(
        GeminiLiveEndpoint(
          uri: Uri.parse('ws://127.0.0.1:${server.port}/live'),
        ),
      ),
      maxReconnects: 0,
      handshakeTimeout: const Duration(seconds: 3),
    );
    final events = <ProviderEvent>[];
    final sub = provider
        .connect(
          const SessionConfig(
            sourceLanguage: 'en-US',
            targetLanguage: 'fa-IR',
            apiKey: 'test-key-value-1234567890',
          ),
        )
        .listen(events.add);
    addTearDown(() async {
      await sub.cancel();
      await provider.disconnect();
    });

    final setup = await seen.future.timeout(const Duration(seconds: 3));
    expect(setup['model'], 'models/gemini-3.5-live-translate-preview');
    expect(setup.containsKey('systemInstruction'), isFalse);
    final generation = Map<String, dynamic>.from(setup['generationConfig'] as Map);
    final translation = Map<String, dynamic>.from(generation['translationConfig'] as Map);
    expect(translation['targetLanguageCode'], 'fa');
    expect(generation['responseModalities'], ['AUDIO']);

    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(events.whereType<ProviderConnected>(), isNotEmpty);
    expect(events.whereType<ProviderError>(), isEmpty);
  });
}
