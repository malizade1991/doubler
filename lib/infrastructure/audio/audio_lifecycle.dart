import 'package:flutter/widgets.dart';

import 'audio_capture.dart';

/// Maps app lifecycle and route-style interruptions onto [AudioCapture].
class AudioLifecycleObserver with WidgetsBindingObserver {
  AudioLifecycleObserver(this.capture);

  final AudioCapture capture;

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
