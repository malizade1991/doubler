import 'dart:async';
import 'dart:typed_data';

enum MicPermission { granted, denied, permanentlyDenied }

enum AudioInterruption {
  none,
  phoneCall,
  audioFocusLoss,
  routeChange,
  background,
}

/// PCM16 little-endian mono @ 16 kHz, ~20–40 ms frames.
abstract class AudioCapture {
  static const sampleRate = 16000;
  static const bytesPerSample = 2;
  static const frameMs = 20;
  static int get frameBytes =>
      (sampleRate * bytesPerSample * frameMs) ~/ 1000;

  Future<MicPermission> requestPermission();

  Stream<Uint8List> start();

  Future<void> pause();

  Future<void> resume();

  Future<void> stop();

  void handleInterruption(AudioInterruption event);
}

class FakeAudioCapture implements AudioCapture {
  FakeAudioCapture({
    this.permission = MicPermission.granted,
    StreamController<Uint8List>? controller,
  }) : _controller = controller ?? StreamController<Uint8List>.broadcast();

  MicPermission permission;
  bool started = false;
  bool paused = false;
  AudioInterruption lastInterruption = AudioInterruption.none;
  final StreamController<Uint8List> _controller;

  @override
  Future<MicPermission> requestPermission() async => permission;

  @override
  Stream<Uint8List> start() {
    if (permission != MicPermission.granted) {
      throw StateError('micDenied');
    }
    started = true;
    paused = false;
    return _controller.stream;
  }

  void emit(Uint8List pcm) {
    if (started && !paused) {
      _controller.add(pcm);
    }
  }

  @override
  Future<void> pause() async => paused = true;

  @override
  Future<void> resume() async => paused = false;

  @override
  Future<void> stop() async {
    started = false;
    paused = false;
  }

  @override
  void handleInterruption(AudioInterruption event) {
    lastInterruption = event;
    if (event == AudioInterruption.phoneCall ||
        event == AudioInterruption.audioFocusLoss ||
        event == AudioInterruption.background) {
      paused = true;
    } else if (event == AudioInterruption.none) {
      paused = false;
    }
  }
}

/// Production capture. Plug in `record` (or a platform channel) via [engine].
class PlatformAudioCapture implements AudioCapture {
  PlatformAudioCapture({AudioCapture? engine}) : _engine = engine ?? FakeAudioCapture();

  final AudioCapture _engine;

  @override
  Future<MicPermission> requestPermission() => _engine.requestPermission();

  @override
  Stream<Uint8List> start() => _engine.start();

  @override
  Future<void> pause() => _engine.pause();

  @override
  Future<void> resume() => _engine.resume();

  @override
  Future<void> stop() => _engine.stop();

  @override
  void handleInterruption(AudioInterruption event) =>
      _engine.handleInterruption(event);
}
