import 'dart:async';
import 'dart:typed_data';

import 'package:doubler/domain/providers/translation_provider.dart';
import 'package:doubler/features/api_key/application/api_key_controller.dart';
import 'package:doubler/features/dubbing/application/dubbing_controller.dart';
import 'package:doubler/features/history/application/history_controller.dart';
import 'package:doubler/features/transcript/application/transcript_controller.dart';
import 'package:doubler/infrastructure/audio/audio_capture.dart';
import 'package:doubler/infrastructure/audio/audio_output.dart';
import 'package:doubler/infrastructure/storage/history_store.dart';
import 'package:doubler/infrastructure/storage/secure_key_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Engine implements TranslationProvider {
  final events = StreamController<ProviderEvent>.broadcast();

  @override
  Stream<ProviderEvent> connect(SessionConfig config) => events.stream;

  @override
  void sendAudio(Uint8List pcm16k) {}

  @override
  void updateConfig(SessionConfig patch) {}

  @override
  Future<void> disconnect() async {}
}

void main() {
  test('full fake session writes transcript then history on stop', () async {
    final keys = MemoryKeyStore();
    await keys.writeApiKey('AIzaSyDummyKeyValue123456');
    final history = MemoryHistoryStore();
    final engine = _Engine();
    final container = ProviderContainer(
      overrides: [
        secureKeyStoreProvider.overrideWithValue(keys),
        historyStoreProvider.overrideWithValue(history),
        audioCaptureProvider.overrideWithValue(FakeAudioCapture()),
        audioOutputProvider.overrideWithValue(FakeAudioOutput()),
        translationProviderFactory.overrideWithValue(engine),
      ],
    );
    addTearDown(container.dispose);

    await container.read(historyControllerProvider.future);
    await container.read(dubbingControllerProvider.notifier).start();
    engine.events.add(const ProviderConnected());
    engine.events.add(
      const ProviderTranscript(text: 'One', isInput: true, isFinal: true),
    );
    engine.events.add(
      const ProviderTranscript(text: 'یک', isInput: false, isFinal: true),
    );
    await Future<void>.delayed(Duration.zero);

    expect(
      container.read(transcriptControllerProvider).segments,
      isNotEmpty,
    );

    await container.read(dubbingControllerProvider.notifier).stop();
    final saved = await history.list();
    expect(saved, hasLength(1));
    expect(saved.first.targetLanguage, 'fa-IR');
  });

  test('start without key fails closed', () async {
    final container = ProviderContainer(
      overrides: [
        secureKeyStoreProvider.overrideWithValue(MemoryKeyStore()),
        audioCaptureProvider.overrideWithValue(FakeAudioCapture()),
      ],
    );
    addTearDown(container.dispose);
    await container.read(dubbingControllerProvider.notifier).start();
    expect(container.read(dubbingControllerProvider).errorCode, 'keyMissing');
  });
}
