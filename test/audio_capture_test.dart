import 'dart:typed_data';

import 'package:doubler/domain/providers/translation_provider.dart';
import 'package:doubler/features/api_key/application/api_key_controller.dart';
import 'package:doubler/features/dubbing/application/dubbing_controller.dart';
import 'package:doubler/infrastructure/audio/audio_capture.dart';
import 'package:doubler/infrastructure/gemini/gemini_socket.dart';
import 'package:doubler/infrastructure/storage/secure_key_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _SinkProvider implements TranslationProvider {
  final received = <Uint8List>[];

  @override
  Stream<ProviderEvent> connect(SessionConfig config) async* {
    yield const ProviderConnected();
  }

  @override
  void sendAudio(Uint8List pcm16k) => received.add(pcm16k);

  @override
  void updateConfig(SessionConfig patch) {}

  @override
  Future<void> disconnect() async {}
}

void main() {
  test('frame size is 20ms of 16kHz PCM16 mono', () {
    expect(AudioCapture.frameBytes, 640);
  });

  test('denied permission does not start capture', () async {
    final mic = FakeAudioCapture(permission: MicPermission.denied);
    expect(
      () => mic.start(),
      throwsA(isA<StateError>()),
    );
  });

  test('interruption pauses capture', () {
    final mic = FakeAudioCapture();
    mic.start();
    mic.handleInterruption(AudioInterruption.phoneCall);
    expect(mic.paused, isTrue);
    mic.handleInterruption(AudioInterruption.none);
    expect(mic.paused, isFalse);
  });

  test('controller surfaces micDenied', () async {
    final store = MemoryKeyStore();
    await store.writeApiKey('AIzaSyDummyKeyValue123456');
    final mic = FakeAudioCapture(permission: MicPermission.denied);
    final container = ProviderContainer(
      overrides: [
        secureKeyStoreProvider.overrideWithValue(store),
        audioCaptureProvider.overrideWithValue(mic),
        translationProviderFactory.overrideWithValue(_SinkProvider()),
      ],
    );
    addTearDown(container.dispose);
    await container.read(dubbingControllerProvider.notifier).start();
    expect(container.read(dubbingControllerProvider).errorCode, 'micDenied');
  });

  test('live session pipes mic PCM into the engine', () async {
    final store = MemoryKeyStore();
    await store.writeApiKey('AIzaSyDummyKeyValue123456');
    final mic = FakeAudioCapture();
    final engine = _SinkProvider();
    final container = ProviderContainer(
      overrides: [
        secureKeyStoreProvider.overrideWithValue(store),
        audioCaptureProvider.overrideWithValue(mic),
        translationProviderFactory.overrideWithValue(engine),
      ],
    );
    addTearDown(container.dispose);

    await container.read(dubbingControllerProvider.notifier).start();
    await Future<void>.delayed(Duration.zero);
    final frame = Uint8List(AudioCapture.frameBytes);
    mic.emit(frame);
    await Future<void>.delayed(Duration.zero);
    expect(engine.received, isNotEmpty);
    expect(engine.received.first.length, AudioCapture.frameBytes);
  });

  test('socket factory unused placeholder compiles', () {
    expect(FakeGeminiSocket().closed, isFalse);
  });
}
