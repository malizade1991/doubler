# TESTING.md

## Strategy

| Layer | Tool | Focus |
|---|---|---|
| Unit | `flutter test` | Language catalog, SRT/TXT, error mapping, ducking, transcript, history, export |
| Widget | `flutter test` | RTL mixed text, l10n, theme, waveform a11y, splash |
| Integration (fake) | `flutter test` | Onboarding key gate, session → transcript → history |
| Audio | fakes | Capture/output PCM; no real mic in CI |
| API | mock WSS / HTTP | Invalid key, quota, close codes |
| Lifecycle | observer + fake | Background pauses capture |

## Test files

- `test/widget_test.dart` — splash → onboarding without key
- `test/theme_test.dart` — light/dark tokens
- `test/l10n_test.dart` — UI locale tables
- `test/rtl_mixed_test.dart` — fa/en + mixed string
- `test/api_key_test.dart` — validate/mask/store/HTTP map
- `test/gemini_provider_test.dart` — setup JSON, events, redaction
- `test/audio_capture_test.dart` — mic denied, PCM pipe
- `test/audio_output_test.dart` — jitter + latency bands
- `test/audio_mixer_test.dart` — ducking / mic mute
- `test/realtime_translation_test.dart` — tone + live lines
- `test/transcript_test.dart` — segments
- `test/history_test.dart` — CRUD
- `test/export_test.dart` — SRT comma timestamps
- `test/subtitle_test.dart` — style
- `test/settings_test.dart` — theme mode
- `test/waveform_test.dart` — semantics
- `test/session_flow_test.dart` — stop persists history

Run (when Flutter SDK is available):

```
flutter test
flutter analyze
```

## Must-test locales

Persian, Arabic (RTL), English (LTR), locale switch mid-app.

## Must-test failures

Network loss, 403 key, 429 quota, mic denied, missing key, WS errors.

## What CI cannot fully test

Real Gemini latency, AEC, Bluetooth, store builds — manual release checklist.

## Fake provider

Scripted `TranslationProvider` in tests only. Never ship fake Gemini success in production.
