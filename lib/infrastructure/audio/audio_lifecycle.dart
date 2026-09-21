import 'package:flutter/widgets.dart';

import 'audio_capture.dart';

/// Maps app lifecycle and route-style interruptions onto [AudioCapture].
class AudioLifecycleObserver with WidgetsBindingObserver {
  AudioLifecycleObserver(
    this.capture, {
    this.keepAliveInBackground = true,
  });

  final AudioCapture capture;

  /// YouTube dubbing requires the session to survive the activity pause that
  /// happens the moment the user leaves for another app.
  final bool keepAliveInBackground;

  void attach() {
    WidgetsBinding.instance.addObserver(this);
  }

  void detach() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        capture.handleInterruption(AudioInterruption.background);
      case AppLifecycleState.resumed:
        capture.handleInterruption(AudioInterruption.none);
      case AppLifecycleState.detached:
        break;
    }
  }

  void onAudioFocusLoss() {
    capture.handleInterruption(AudioInterruption.audioFocusLoss);
  }

  void onPhoneCall() {
    capture.handleInterruption(AudioInterruption.phoneCall);
  }

  void onRouteChange() {
    capture.handleInterruption(AudioInterruption.routeChange);
  }
}
