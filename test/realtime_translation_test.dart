import 'dart:async';

import 'package:doubler/domain/models/translation_tone.dart';
import 'package:doubler/domain/providers/translation_provider.dart';
import 'package:doubler/features/api_key/application/api_key_controller.dart';
import 'package:doubler/features/dubbing/application/dubbing_controller.dart';
import 'package:doubler/infrastructure/audio/audio_capture.dart';
import 'package:doubler/infrastructure/gemini/gemini_system_instruction.dart';
import 'package:doubler/infrastructure/storage/secure_key_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _ScriptedEngine implements TranslationProvider {
  final controller = StreamController<ProviderEvent>.broadcast();
  SessionConfig? lastConfig;

  @override
  Stream<ProviderEvent> connect(SessionConfig config) {
    lastConfig = config;
    return controller.stream;
  }

  @override
  void sendAudio(pcm) {}

  @override
  void updateConfig(SessionConfig patch) {}

  @override
  Future<void> disconnect() async {}
}

void main() {
  test('tone changes the translator instruction', () {
    const casual = SessionConfig(
      sourceLanguage: 'en-US',
      targetLanguage: 'fa-IR',
      tone: 'casual',
    );
    const formal = SessionConfig(
      sourceLanguage: 'en-US',
      targetLanguage: 'fa-IR',
      tone: 'formal',
    );
    expect(GeminiSystemInstruction.build(casual), contains('everyday'));
    expect(GeminiSystemInstruction.build(formal), contains('polite'));
    expect(GeminiSystemInstruction.build(formal), contains('fa-IR'));
  });

  test('transcripts update live source and target lines', () async {
    final store = MemoryKeyStore();
    await store.writeApiKey('AIzaSyDummyKeyValue123456');
    final engine = _ScriptedEngine();
    final container = ProviderContainer(
      overrides: [
        secureKeyStoreProvider.overrideWithValue(store),
        audioCaptureProvider.overrideWithValue(FakeAudioCapture()),
        translationProviderFactory.overrideWithValue(engine),
        translationToneProvider.overrideWith((ref) => TranslationTone.formal),
      ],
    );
    addTearDown(container.dispose);

    await container.read(dubbingControllerProvider.notifier).start();
    engine.controller.add(const ProviderConnected());
    engine.controller.add(
      const ProviderTranscript(text: 'Hello', isInput: true),
    );
    engine.controller.add(
      const ProviderTranscript(text: 'سلام', isInput: false),
    );
    await Future<void>.delayed(Duration.zero);

    final ui = container.read(dubbingControllerProvider);
    expect(ui.line.source, 'Hello');
    expect(ui.line.target, 'سلام');
    expect(engine.lastConfig?.tone, 'formal');
    expect(engine.lastConfig?.targetLanguage, 'fa-IR');
  });
}
