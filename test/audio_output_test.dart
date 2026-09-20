import 'dart:async';
import 'dart:typed_data';

import 'package:doubler/domain/providers/translation_provider.dart';
import 'package:doubler/features/api_key/application/api_key_controller.dart';
import 'package:doubler/features/dubbing/application/dubbing_controller.dart';
import 'package:doubler/infrastructure/audio/audio_capture.dart';
import 'package:doubler/infrastructure/audio/audio_output.dart';
import 'package:doubler/infrastructure/storage/secure_key_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Engine implements TranslationProvider {
  final controller = StreamControllerLike();

  @override
  Stream<ProviderEvent> connect(SessionConfig config) => controller.stream;

  @override
  void sendAudio(Uint8List pcm16k) {}

  @override
  void updateConfig(SessionConfig patch) {}

  @override
  Future<void> disconnect() async {}
}

class StreamControllerLike {
  final _c = StreamController<ProviderEvent>.broadcast();
  Stream<ProviderEvent> get stream => _c.stream;
  void add(ProviderEvent e) => _c.add(e);
}

void main() {
  test('jitter buffer drops oldest when over cap', () {
    final buf = JitterBuffer(maxBytes: 4);
    buf.add(Uint8List.fromList([1, 2, 3]));
    buf.add(Uint8List.fromList([4, 5]));
    expect(buf.length, 4);
    expect(buf.take(4), Uint8List.fromList([2, 3, 4, 5]));
  });

  test('latency bands are honest (no fake sub-1.5s)', () {
    expect(latencyBand(800), LatencyBand.good);
    expect(latencyBand(2000), LatencyBand.fair);
    expect(latencyBand(4000), LatencyBand.poor);
  });

  test('audio out is enqueued to the player', () async {
    final store = MemoryKeyStore();
    await store.writeApiKey('AIzaSyDummyKeyValue123456');
    final engine = _Engine();
    final out = FakeAudioOutput();
    final container = ProviderContainer(
      overrides: [
        secureKeyStoreProvider.overrideWithValue(store),
        audioCaptureProvider.overrideWithValue(FakeAudioCapture()),
        audioOutputProvider.overrideWithValue(out),
        translationProviderFactory.overrideWithValue(engine),
      ],
    );
    addTearDown(container.dispose);

    await container.read(dubbingControllerProvider.notifier).start();
    engine.controller.add(const ProviderConnected());
    await Future<void>.delayed(Duration.zero);
    engine.controller.add(ProviderAudioOut(Uint8List.fromList([1, 2, 3, 4])));
    await Future<void>.delayed(Duration.zero);
    expect(out.played, isNotEmpty);
    expect(container.read(dubbingControllerProvider).speaking, isTrue);
  });
}
