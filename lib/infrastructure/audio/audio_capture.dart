import 'dart:async';
import 'dart:typed_data';

import 'platform_audio_bridge.dart';

/// Where spoken audio comes from.
///
/// [playback] is other apps (YouTube) via Android playback capture, so the
/// user can leave DOUBLER and keep the dub. [microphone] is the fallback when
/// the OS will not share another app's audio (iOS, or a denied consent).
enum CaptureSource { playback, microphone }

enum MicPermission { granted, denied, permanentlyDenied }

enum AudioInterruption {
  none,
  phoneCall,
  audioFocusLoss,
  routeChange,
  background,
}

/// PCM16 little-endian mono @ 16 kHz, ~20–100 ms frames.
abstract class AudioCapture {
  static const sampleRate = 16000;
  static const bytesPerSample = 2;
  static const frameMs = 20;
  static int get frameBytes =>
      (sampleRate * bytesPerSample * frameMs) ~/ 1000;

  /// When true, switching to YouTube must not pause the session.
  bool continueInBackground = true;

  Future<MicPermission> requestPermission();

  /// Permission / media-projection consent. Null means capture may start.
  /// Returns an l10n code (`micDenied`, `playbackDenied`, …) otherwise.
  Future<String?> arm(
    CaptureSource source, {
    String notificationTitle = 'DOUBLER',
    String notificationBody = 'Translating…',
    String notificationStop = 'Stop',
  }) async {
    return null;
  }

  /// Notification Stop / interruption signals. Empty unless a platform engine
  /// is actually running.
  Stream<String> get sessionEvents => const Stream.empty();

  Stream<Uint8List> start();

  Future<void> pause();

  Future<void> resume();

  Future<void> stop();

  void handleInterruption(AudioInterruption event);
}

class FakeAudioCapture implements AudioCapture {
  FakeAudioCapture({
    this.permission = MicPermission.granted,
    this.playbackAllowed = true,
    StreamController<Uint8List>? controller,
  }) : _controller = controller ?? StreamController<Uint8List>.broadcast();

  MicPermission permission;
  bool playbackAllowed;
  bool started = false;
  bool paused = false;
  CaptureSource? lastSource;
  String? lastNotificationTitle;
  AudioInterruption lastInterruption = AudioInterruption.none;
  final StreamController<Uint8List> _controller;
  final _events = StreamController<String>.broadcast();

  @override
  bool continueInBackground = true;

  @override
  Stream<String> get sessionEvents => _events.stream;

  void emitControl(String event) => _events.add(event);

  @override
  Future<MicPermission> requestPermission() async => permission;

  @override
  Future<String?> arm(
    CaptureSource source, {
    String notificationTitle = 'DOUBLER',
    String notificationBody = 'Translating…',
    String notificationStop = 'Stop',
  }) async {
    lastSource = source;
    lastNotificationTitle = notificationTitle;
    if (source == CaptureSource.playback && !playbackAllowed) {
      return 'playbackDenied';
    }
    if (source == CaptureSource.microphone &&
        permission != MicPermission.granted) {
      return 'micDenied';
    }
    return null;
  }

  @override
  Stream<Uint8List> start() {
    final needsMic = lastSource == null || lastSource == CaptureSource.microphone;
    if (needsMic && permission != MicPermission.granted) {
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
    if (event == AudioInterruption.background && continueInBackground) {
      return;
    }
    if (event == AudioInterruption.phoneCall ||
        event == AudioInterruption.audioFocusLoss ||
        event == AudioInterruption.background) {
      paused = true;
    } else if (event == AudioInterruption.none) {
      paused = false;
    }
  }
}

/// Production capture. The default engine is the platform channel — a fake
/// here is what made «شروع دوبله» look connected while capturing nothing.
class PlatformAudioCapture implements AudioCapture {
  PlatformAudioCapture({AudioCapture? engine})
      : _engine = engine ?? ChannelAudioCapture();

  final AudioCapture _engine;

  @override
  bool get continueInBackground => _engine.continueInBackground;

  @override
  set continueInBackground(bool value) => _engine.continueInBackground = value;

  @override
  Future<MicPermission> requestPermission() => _engine.requestPermission();

  @override
  Future<String?> arm(
    CaptureSource source, {
    String notificationTitle = 'DOUBLER',
    String notificationBody = 'Translating…',
    String notificationStop = 'Stop',
  }) {
    return _engine.arm(
      source,
      notificationTitle: notificationTitle,
      notificationBody: notificationBody,
      notificationStop: notificationStop,
    );
  }

  @override
  Stream<String> get sessionEvents => _engine.sessionEvents;

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

/// Microphone or other-app audio via the platform channel.
class ChannelAudioCapture implements AudioCapture {
  ChannelAudioCapture({PlatformAudioBridgeHost? host})
      : _host = host ?? const PlatformAudioBridgeHost();

  final PlatformAudioBridgeHost _host;

  @override
  bool continueInBackground = true;

  @override
  Future<MicPermission> requestPermission() async {
    final result = await _host.invoke('micPermission');
    if (result['granted'] == true) {
      return MicPermission.granted;
    }
    if (result['permanentlyDenied'] == true) {
      return MicPermission.permanentlyDenied;
    }
    return MicPermission.denied;
  }

  @override
  Future<String?> arm(
    CaptureSource source, {
    String notificationTitle = 'DOUBLER',
    String notificationBody = 'Translating…',
    String notificationStop = 'Stop',
  }) async {
    _host.ensureWired();
    final result = await _host.invoke('startCapture', {
      'source': source.name,
      'title': notificationTitle,
      'body': notificationBody,
      'stop': notificationStop,
    }).timeout(
      const Duration(seconds: 90),
      onTimeout: () => <String, dynamic>{'error': 'connectionTimeout'},
    );
    final error = result['error'];
    if (error is String && error.isNotEmpty) {
      return error;
    }
    return null;
  }

  @override
  Stream<String> get sessionEvents => _host.control;

  @override
  Stream<Uint8List> start() => _host.pcm;

  @override
  Future<void> pause() => _host.invoke('pauseCapture');

  @override
  Future<void> resume() => _host.invoke('resumeCapture');

  @override
  Future<void> stop() async {
    await _host.invoke('stopSession');
  }

  @override
  void handleInterruption(AudioInterruption event) {
    if (event == AudioInterruption.background && continueInBackground) {
      return;
    }
    if (event == AudioInterruption.phoneCall ||
        event == AudioInterruption.audioFocusLoss) {
      unawaited(pause());
    } else if (event == AudioInterruption.none) {
      unawaited(resume());
    }
  }
}

/// Indirection so tests can fake the bridge without a method channel.
class PlatformAudioBridgeHost {
  const PlatformAudioBridgeHost();

  void ensureWired() => PlatformAudioBridge.ensureWired();

  Stream<Uint8List> get pcm => PlatformAudioBridge.pcm;

  Stream<String> get control => PlatformAudioBridge.control;

  Future<Map<String, dynamic>> invoke(
    String method, [
    Map<String, Object?>? args,
  ]) {
    return PlatformAudioBridge.invoke(method, args);
  }
}
