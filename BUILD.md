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
flutter analyze
flutter build apk --release
flutter build appbundle --release
flutter build ios --release   # macOS
```

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

- [ ] `flutter test` / `flutter analyze` clean
- [ ] No real keys in git
- [ ] Privacy copy matches PRIVACY.md
- [ ] Mic permission strings localized
- [ ] Store listing from `docs/STORE.md`
- [ ] Manual: real Gemini key, headphones, Persian↔English
