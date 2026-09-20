import 'dart:collection';
import 'dart:typed_data';

/// PCM16 LE mono @ 24 kHz (Gemini Live output).
abstract class AudioOutput {
  static const sampleRate = 24000;
  static const bytesPerSample = 2;

  /// Target jitter buffer ~120 ms.
  static const targetBufferMs = 120;

  static int get targetBufferBytes =>
      (sampleRate * bytesPerSample * targetBufferMs) ~/ 1000;

  void enqueue(Uint8List pcm24k);

  Future<void> start();

  Future<void> pause();

  Future<void> stop();

  void setGain(double gain);

  int get bufferedBytes;
}

class JitterBuffer {
  JitterBuffer({this.maxBytes = 24000 * 2}); // 1s cap

  final int maxBytes;
  final Queue<int> _bytes = Queue<int>();

  int get length => _bytes.length;

  void add(Uint8List chunk) {
    for (final b in chunk) {
      if (_bytes.length >= maxBytes) {
        _bytes.removeFirst();
      }
      _bytes.add(b);
    }
  }

  Uint8List take(int count) {
    final n = count.clamp(0, _bytes.length);
    final out = Uint8List(n);
    for (var i = 0; i < n; i++) {
      out[i] = _bytes.removeFirst();
    }
    return out;
  }

  void clear() => _bytes.clear();
}

class FakeAudioOutput implements AudioOutput {
  final played = <Uint8List>[];
  bool started = false;
  bool paused = false;
  double gain = 1;
  final buffer = JitterBuffer();

  @override
  int get bufferedBytes => buffer.length;

  @override
  void enqueue(Uint8List pcm24k) {
    buffer.add(pcm24k);
    if (started && !paused) {
      played.add(buffer.take(pcm24k.length));
    }
  }

  @override
  Future<void> start() async {
    started = true;
    paused = false;
  }

  @override
  Future<void> pause() async => paused = true;

  @override
  Future<void> stop() async {
    started = false;
    paused = false;
    buffer.clear();
    played.clear();
  }

  @override
  void setGain(double gain) => this.gain = gain.clamp(0, 1);
}

class PlatformAudioOutput implements AudioOutput {
  PlatformAudioOutput({AudioOutput? engine})
      : _engine = engine ?? FakeAudioOutput();

  final AudioOutput _engine;

  @override
  void enqueue(Uint8List pcm24k) => _engine.enqueue(pcm24k);

  @override
  Future<void> start() => _engine.start();

  @override
  Future<void> pause() => _engine.pause();

  @override
  Future<void> stop() => _engine.stop();

  @override
  void setGain(double gain) => _engine.setGain(gain);

  @override
  int get bufferedBytes => _engine.bufferedBytes;
}

enum LatencyBand { good, fair, poor }

LatencyBand latencyBand(int? milliseconds) {
  if (milliseconds == null) {
    return LatencyBand.fair;
  }
  if (milliseconds < 1500) {
    return LatencyBand.good;
  }
  if (milliseconds < 3000) {
    return LatencyBand.fair;
  }
  return LatencyBand.poor;
}
