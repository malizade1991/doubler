import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'audio_capture.dart';

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

  /// Playback-capture policy: [duck] asks the OS to lower YouTube while the
  /// dub speaks. Ignored by microphone-only engines.
  void setOriginalPolicy({required double originalGain, required bool duck}) {}

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

  bool ducked = false;
  double originalGain = 1;

  @override
  void setOriginalPolicy({required double originalGain, required bool duck}) {
    this.originalGain = originalGain;
    ducked = duck;
  }
}

class PlatformAudioOutput implements AudioOutput {
  PlatformAudioOutput({AudioOutput? engine})
      : _engine = engine ?? ChannelAudioOutput();

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
  void setOriginalPolicy({required double originalGain, required bool duck}) {
    _engine.setOriginalPolicy(originalGain: originalGain, duck: duck);
  }

  @override
  int get bufferedBytes => _engine.bufferedBytes;
}

/// Plays 24 kHz PCM through the platform bridge. Without this, a live session
/// "succeeds" and then drops every translated sample on the floor.
class ChannelAudioOutput implements AudioOutput {
  ChannelAudioOutput({PlatformAudioBridgeHost? host})
      : _host = host ?? const PlatformAudioBridgeHost();

  final PlatformAudioBridgeHost _host;
  int _buffered = 0;

  @override
  int get bufferedBytes => _buffered;

  @override
  Future<void> start() async {
    await _host.invoke('startOutput');
  }

  @override
  void enqueue(Uint8List pcm24k) {
    if (pcm24k.isEmpty) {
      return;
    }
    _buffered += pcm24k.length;
    unawaited(_host.invoke('writeOutput', {'pcm': pcm24k}));
  }

  @override
  Future<void> pause() => _host.invoke('pauseOutput');

  @override
  Future<void> stop() async {
    _buffered = 0;
    await _host.invoke('stopOutput');
  }

  @override
  void setGain(double gain) {
    unawaited(_host.invoke('setGain', {'gain': gain.clamp(0.0, 1.0)}));
  }

  @override
  void setOriginalPolicy({required double originalGain, required bool duck}) {
    unawaited(
      _host.invoke('setDuck', {
        'duck': duck,
        'originalGain': originalGain,
      }),
    );
  }
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
