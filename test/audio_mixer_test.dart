import 'package:doubler/infrastructure/audio/audio_mixer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mic mode mutes original even when volume is high', () {
    final mixer = AudioMixer(
      originalVolume: 1,
      dubbedVolume: 0.85,
      microphoneMode: true,
      speaking: true,
    );
    expect(mixer.effectiveOriginalGain, 0);
    expect(mixer.effectiveDubbedGain, 0.85);
  });

  test('ducking lowers original when AI speaks if not mic mode', () {
    final mixer = AudioMixer(
      originalVolume: 0.8,
      microphoneMode: false,
      smartDucking: true,
    )..speaking = true;
    expect(mixer.effectiveOriginalGain, closeTo(0.16, 0.001));
    mixer.speaking = false;
    expect(mixer.effectiveOriginalGain, 0.8);
  });

  test('ducking off keeps configured original volume', () {
    final mixer = AudioMixer(
      originalVolume: 0.5,
      microphoneMode: false,
      smartDucking: false,
    )..speaking = true;
    expect(mixer.effectiveOriginalGain, 0.5);
  });
}
