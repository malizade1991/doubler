# Changelog

## 0.2.1

### Fixed

- **The published release had no downloadable files.** GitHub rejected the asset upload with
  *"Cannot upload asset … to an immutable release"*: the workflow created the release already
  published, and an immutable release only accepts assets before it is published. The release
  is now created as a **draft**, the APK/AAB files are attached, and only then is it published
  (`gh release edit --draft=false`, keeping `prerelease` when the build is unsigned). A failed
  upload now leaves an invisible draft instead of a public release with zero assets.

## 0.2.0

### Fixed

- **CI analyze gate was red on `main`.** `IoGeminiSocket` now defines the `_redact`
  sanitizer it calls (API keys are stripped from error text before classification — a
  token that happens to contain "401" can neither classify itself nor reach a log, and
  `statusCodeOf` redacts too), `FakeGeminiSocket` implements `closeCode`/`closeReason`,
  the dead `_wentLive` field is gone, and a redundant `dart:typed_data` import was
  dropped. `flutter analyze --fatal-infos --fatal-warnings` is clean.
- **A `v*` tag with no Android signing secrets published nothing.** The old signing gate
  failed the build job and the release job was skipped — that is what happened to the
  `v0.1.0` tag. Signing is now resolved instead of enforced: with all four `ANDROID_*`
  secrets the release is signed as before, and without them the tag is built with the debug
  keystore and published as an explicitly labelled **unsigned pre-release** with
  `doubler-<tag>-<abi>.apk` / `doubler-<tag>.aab` assets, so a tag always produces something
  downloadable. `REQUIRE_SIGNED_RELEASE: "true"` (workflow env) restores the fail-loudly
  behaviour.

- **Start dubbing stayed on «در حال اتصال».** Gemini answers the Live handshake with
  `{"setupComplete": {}}`, not `true`. The client now treats that empty object (and a binary
  JSON frame) as connected, speaks the current camelCase protocol, and uses
  `gemini-3.5-live-translate-preview` so a video is translated continuously instead of waiting
  for a chat turn. If the server never answers, the button times out instead of spinning.
- **Leaving the app stopped the session, and capture/playback were fakes.** Start now arms
  Android playback capture (YouTube and other apps), keeps a foreground service alive, and
  opens YouTube once the socket is live. Dubbed audio plays while YouTube is ducked. iOS has
  no other-app capture; it falls back to the microphone and says so.
- **Valid Gemini keys were rejected as invalid.** `ApiKeyValidator` only allowed
  `[A-Za-z0-9_-]`, so Google's current auth keys (`AQ.…`, which contain a dot) failed the
  format check before anything was sent. Validation is now shape-agnostic (sanitize →
  length → character set) and Google's answer is what decides. Legacy `AIza…` keys are still
  saved but flagged as legacy; malformed pastes (quotes, `x-goog-api-key:` labels, `?key=`
  prefixes, newlines, zero-width marks) are cleaned instead of rejected.
- **Key check and Live socket auth.** REST now uses the `x-goog-api-key` header (a `?key=`
  request 404s for auth keys); the WebSocket sends the header and the documented `?key=`
  parameter, and a 429 is reported as "key works, quota spent" rather than "invalid key".
- **Dead default model.** The Live model id moved from the retired
  `gemini-2.5-flash-native-audio-preview-*` to `gemini-3.8-live`, selectable in
  Settings → Gemini if Google renames it again.
- **Controls behind the system safe area.** Every screen now goes through
  `DoublerScaffold`/`DoublerPage`, which apply `MediaQuery` insets (top notch, bottom
  gesture bar) and keep the pinned action row clear of the keyboard.
- Weak UI/UX across the app: single hero action on Home instead of a wall of identical
  cards, 48dp touch targets everywhere, real empty/busy/error states, inline key-test
  feedback, a live subtitle stage, mute + mic controls reachable in one thumb zone,
  confirmations on destructive actions, sliders with labelled targets, colour/position
  subtitle picker with a preview, and Persian fallback strings that were mojibake-fixed.
- Missing platform launch theme: added `values-night/styles.xml` + `launch_background`
  colors so a cold start no longer flashes white over the dark theme.

### Changed

- Localizable strings: ~100 new keys in `fa` and `en`; partial locales now fall back to
  English before Persian.
- History, transcript and export screens rebuilt on the shared widgets; export renders the
  file immediately (TXT/SRT/JSON, bilingual toggle) and copies it — no server, no share
  plugin dependency.
- Tests cover the new key shapes, header/query auth, quota handling and setup-gated audio.

## 0.1.0

- Client-side Flutter shell (Android + iOS project files)
- BYOK Gemini Live WebSocket provider (injectable)
- Mic capture + 24 kHz playback abstractions, mixer, ducking
- Live subtitles, transcript, SRT/TXT/JSON export, local history
- Persian-first localization + RTL
- No backend, no ads, no accounts
