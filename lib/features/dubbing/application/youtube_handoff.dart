/// When a session becomes live, leave for YouTube exactly once.
///
/// The handoff is a pure decision so tests can lock the product rule without
/// pumping a widget or touching a platform channel: start dubbing → connection
/// completes → the app opens YouTube and keeps translating in the background.
bool shouldOpenYouTube({
  required bool wasLive,
  required bool isLive,
  required bool enabled,
  required bool alreadyOpened,
}) {
  return enabled && !alreadyOpened && !wasLive && isLive;
}

/// Long enough for the foreground notification to post before the activity
/// pauses, short enough that the user is not left staring at a spinner.
const Duration youtubeHandoffDelay = Duration(milliseconds: 450);
