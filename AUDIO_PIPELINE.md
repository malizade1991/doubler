# AUDIO_PIPELINE.md

```
Microphone / (future: loopback)
        → AudioCapture (native)
        → resample to PCM16 16kHz mono
        → chunk (~20–40 ms)
        → RealtimeConnection (WSS binary/JSON)
        → Gemini Live
        → PCM16 24kHz chunks
        → jitter buffer
        → AudioOutput + Mixer
        → speaker / headphones
```

## Capture (implemented)

- Abstraction: `AudioCapture` (`lib/infrastructure/audio/audio_capture.dart`)
- Format: PCM16 LE mono 16 kHz. YouTube capture emits 100 ms frames after resampling.
- `FakeAudioCapture` for tests. Production `ChannelAudioCapture` uses
  `com.doubler.doubler/audio`: Android playback capture (MediaProjection, own UID excluded)
  or the microphone, plus a foreground service so switching to YouTube does not kill the isolate.
- iOS cannot capture other apps. `playbackUnsupported` falls back to the microphone.
- Permission denied → `micDenied`
- Interruptions: phone, audio focus, background, route change

## Capture

- Permission: `RECORD_AUDIO` / iOS mic usage string
- Preferred package: `record` or platform channels if resampling quality insufficient
- Echo: when playing dubbed audio while capturing, use AEC (Android AcousticEchoCanceler; iOS voice-processing IO). Conversation mode needs this; “listen to speaker across the room” may disable AEC.

## Playback (implemented)

- `AudioOutput` / `JitterBuffer` in `lib/infrastructure/audio/audio_output.dart`
- Format: PCM16 LE mono **24 kHz**
- Target buffer ~120 ms, cap 1 s (drop oldest)
- `FakeAudioOutput` for tests; platform engine injectable
- Latency = time from last mic chunk to first PCM out; UI shows ms + خوب/متوسط/ضعیف

## Playback

- 24 kHz PCM stream, underrun-safe ring buffer
- Target buffer 80–160 ms (latency vs glitch)
- Isolate decode/copy from UI

## Mixing & ducking (implemented)

`AudioMixer` (`lib/infrastructure/audio/audio_mixer.dart`):

- Defaults: original 25% / dubbed 85%
- Smart ducking: original × 0.2 while AI speaks (loopback only)
- **Microphone mode: original gain is always 0** (feedback)

## Mixing & ducking

**Desired:** Original 25% / Dubbed 85%; when AI speaks, duck original; restore after.

**Mobile reality:**

- **Microphone-as-source:** “original” is the same mic signal. Playing original + dubbed from mic causes feedback. For mic mode, **original playback is typically muted**; ducking applies if we later mix a **loopback** or **file/stream** source.
- **Android:** Accessibility / `AudioPlaybackCapture` can capture other apps on some versions with user consent — investigate in Phase 6; not guaranteed.
- **iOS:** No general other-app audio capture.

Document in UI: «در حالت میکروفون، صدای اصلی پخش نمی‌شود تا از فیدبک جلوگیری شود.»

If loopback exists: two players (or one mixer node), duck original gain on `speaking` events with 20–40 ms attack, 200–400 ms release.

## Interruptions

Audio focus (Android), `AVAudioSession` interruptions (call, Siri), route changes (BT). Pause send, fade out, resume or reconnect.

## Sync / latency indicator

`latency_ms = t_first_audio_out - t_vad_end` (or chunk timestamp). Show qualitative: خوب / متوسط / ضعیف.

## Limitations

Cannot match Chrome tab-capture mixing 1:1 on iOS. Closest robust v1: mic → Gemini → dubbed only + subtitles.
