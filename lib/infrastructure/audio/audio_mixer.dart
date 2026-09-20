/// Mix original vs dubbed gains. In microphone mode the original bus is
/// muted to avoid feedback (see AUDIO_PIPELINE.md).
class AudioMixer {
  AudioMixer({
    this.originalVolume = 0.25,
    this.dubbedVolume = 0.85,
    this.smartDucking = true,
    this.microphoneMode = true,
    this.duckFactor = 0.2,
  });

  double originalVolume;
  double dubbedVolume;
  bool smartDucking;
  bool microphoneMode;
  double duckFactor;
  bool speaking = false;

  /// Gain applied to a loopback/original bus.
  double get effectiveOriginalGain {
    if (microphoneMode) {
      return 0;
    }
    if (smartDucking && speaking) {
      return (originalVolume * duckFactor).clamp(0, 1);
    }
    return originalVolume.clamp(0, 1);
  }

  double get effectiveDubbedGain => dubbedVolume.clamp(0, 1);
}
