# BUILD.md

## Prerequisites

- Flutter stable (SDK `>=3.5.0 <4.0.0` in pubspec)
- Android SDK; Xcode for iOS
- **No backend to deploy**

This sandbox could not download the Dart SDK (`storage.googleapis.com`). Build on a machine with Flutter installed.

## Commands

```
flutter pub get
flutter test
flutter analyze --fatal-infos --fatal-warnings   # CI runs exactly this
flutter build apk --release
flutter build appbundle --release
flutter build ios --release   # macOS
```

`analysis_options.yaml` enables `prefer_const_constructors`, `prefer_const_declarations`,
`prefer_const_literals_to_create_immutables`, `unawaited_futures` and `avoid_print` on top of
`flutter_lints`; `--fatal-infos` turns every info into a build failure, so: put `const` on
literal-only widget trees, never re-declare `const` inside an existing const context, and
`await` or `unawaited()` every `Future` inside an async body.

## Permissions

Android: `RECORD_AUDIO`, `INTERNET`  
iOS: `NSMicrophoneUsageDescription` (Persian in Info.plist)

Optional later: Android foreground service for long background sessions.

## Fonts

Bundle Vazirmatn under `assets/fonts/` when you can fetch the TTFs.

## Secrets

- No committed API keys
- Users paste keys in-app (secure storage seam)
- Test fixtures use obviously fake `AIzaSyDummy…` strings only

## Icons

Replace default launcher when designing store assets. Brand: DOUBLER / دوبلر — original, not Dubingo.

## CI/CD (GitHub Actions)

Android builds and releases are automated by `.github/workflows/android-ci.yml`:
PR / push to `main` run analyze + test + build; a `vX.Y.Z` tag builds signed split-per-ABI
APKs + an AAB and publishes a GitHub Release. Full setup (signing secrets, triggers, artifact
paths, downloads) is in [docs/CI.md](docs/CI.md).

> ⚠️ Do **not** add `generate: true` to `pubspec.yaml` or run `flutter gen-l10n`: the checked-in
> `lib/core/l10n/app_localizations.dart` is hand-written and would be overwritten. See docs/CI.md.

## Release checklist

- [ ] `flutter test` / `flutter analyze --fatal-infos --fatal-warnings` clean
- [ ] No real keys in git
- [ ] Privacy copy matches PRIVACY.md
- [ ] Mic permission strings localized
- [ ] Store listing from `docs/STORE.md`
- [ ] Manual: real Gemini key (`AQ.…` auth key), headphones, Persian↔English
- [ ] Manual: paste the key with quotes and a `key=` label around it — it must still save
- [ ] Manual: kill the network, press start — the app must say *network*, not *invalid key*
