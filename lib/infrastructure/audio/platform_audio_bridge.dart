import 'dart:async';

import 'package:flutter/services.dart';

/// Platform half of a live session: capture, playback, foreground service,
/// and the jump into YouTube.
///
/// Channels:
/// * `com.doubler.doubler/audio` — commands
/// * `com.doubler.doubler/audio_pcm` — PCM16 frames (bytes) and `control:*` strings
///
/// Nothing here runs until a session starts, so unit tests that never arm
/// capture do not touch an unmocked channel.
abstract final class PlatformAudioBridge {
  static const channel = MethodChannel('com.doubler.doubler/audio');
  static const events = EventChannel('com.doubler.doubler/audio_pcm');

  static const controlStop = 'control:stop';
  static const controlInterrupted = 'control:interrupted';
  static const controlResumed = 'control:resumed';

  static final _pcm = StreamController<Uint8List>.broadcast();
  static final _control = StreamController<String>.broadcast();
  static StreamSubscription<dynamic>? _events;
  static bool _wired = false;

  static Stream<Uint8List> get pcm => _pcm.stream;
  static Stream<String> get control => _control.stream;

  static void ensureWired() {
    if (_wired) {
      return;
    }
    _wired = true;
    _events = events.receiveBroadcastStream().listen(
      (dynamic event) {
        final bytes = _asBytes(event);
        if (bytes != null) {
          if (bytes.isNotEmpty) {
            _pcm.add(bytes);
          }
          return;
        }
        if (event is String && event.isNotEmpty) {
          _control.add(event);
        }
      },
      onError: (Object _) {
        // The native side reports failures as method results, not stream errors.
      },
    );
  }

  static Uint8List? _asBytes(dynamic event) {
    if (event is Uint8List) {
      return event;
    }
    if (event is ByteData) {
      return event.buffer.asUint8List(event.offsetInBytes, event.lengthInBytes);
    }
    if (event is List<int>) {
      return Uint8List.fromList(event);
    }
    return null;
  }

  static Future<Map<String, dynamic>> invoke(
    String method, [
    Map<String, Object?>? args,
  ]) async {
    try {
      final raw = await channel.invokeMethod<dynamic>(method, args);
      if (raw is Map) {
        return raw.map((key, value) => MapEntry(key.toString(), value));
      }
      if (raw is bool) {
        return {'ok': raw};
      }
      return {'ok': true};
    } on MissingPluginException {
      return {'error': 'captureFailed'};
    } on PlatformException catch (error) {
      return {'error': error.code.isEmpty ? 'captureFailed' : error.code};
    } on Object {
      return {'error': 'captureFailed'};
    }
  }

  static Future<void> disposeEvents() async {
    await _events?.cancel();
    _events = null;
    _wired = false;
  }
}
