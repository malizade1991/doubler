import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'platform_audio_bridge.dart';

final youtubeLauncherProvider = Provider<YouTubeLauncher>(
  (ref) => const YouTubeLauncher(),
);

/// Opens the YouTube app (or youtube.com) after a live session is up.
///
/// Inject [openOverride] in tests. The default path talks to the platform
/// bridge and never throws — a missing channel means "could not open", not a
/// crashed session.
class YouTubeLauncher {
  const YouTubeLauncher({this.openOverride});

  final Future<bool> Function()? openOverride;

  Future<bool> open() async {
    final override = openOverride;
    if (override != null) {
      return override();
    }
    try {
      final ok = await PlatformAudioBridge.channel.invokeMethod<bool>(
        'openYouTube',
      );
      return ok ?? false;
    } on Object {
      return false;
    }
  }
}
