# TROUBLESHOOTING.md

Every message the app can show is a key in `lib/core/l10n/l10n_tables.dart`; the codes below
are those keys. If a code is missing from `fa`/`en`, add it there (no `gen-l10n` — see
docs/CI.md).

| Symptom | Likely cause | Code shown | What to do |
|---|---|---|---|
| «کلید نامعتبر است» right after pasting | paste kept quotes/labels | `keyInvalid` | nothing to fix — the field strips them; re-paste the bare token |
| Key rejected, `AIza…` key | Google no longer accepts unrestricted standard keys | `keyLegacyRejected` | create an **Auth key** (`AQ.…`) in AI Studio |
| Key rejected, `AQ.…` key | key restricted to another app/IP, or deleted | `keyInvalid` | AI Studio → API keys → check restrictions; test with «آزمایش اتصال» |
| «سهمیه…» but the key works | quota exhausted for that key/project | `connectionOkQuota` | billing or another key; DOUBLER treats this as a working key |
| «اتصال اینترنت…» | offline, DNS, VPN, firewall | `networkUnavailable` | the app talks to Google directly; there is no proxy to blame |
| «پاسخ Google دیر رسید» | captive portal, slow TLS | `connectionTimeout` | retry from Settings → Gemini |
| WS opens then closes | wrong model id | `unsupportedModel` | Settings → Gemini → pick a listed Live model |
| No mic | permission denied | `micDenied` | system settings → microphone |
| Silence / no dub | VAD, mic muted, source language `auto` on silence | — | check the status dot on the live screen |
| Feedback howl | speaker + mic | — | headphones, or lower original voice |
| Background stop | iOS/Android audio policy | — | session pauses by design |
| High latency | network / buffer | — | enable low-latency (performance) mode |

## Self-checks before calling a build broken

```bash
flutter pub get
flutter analyze --fatal-infos --fatal-warnings   # must be silent
flutter test                                      # all green
flutter build apk --debug                         # then: flutter run -d <device>
```

`flutter test --update-goldens` is not used; there are no golden files. A widget test that
pumps a screen must not leave an infinite animation running (`pumpAndSettle` would time out):
`AudioWaveform` repaints only when its data changes, and `SplashScreen`'s intro animation is
one-shot.

## Where the key goes

`PlatformKeyStore` → MethodChannel `com.doubler.doubler/store` (Android: SharedPreferences,
`MainActivity.kt`; iOS: NSUserDefaults, `AppDelegate.swift`). Unit tests override
`secureKeyStoreProvider` with `MemoryKeyStore`; nothing else reads the key. Deleting the key,
«پاک کردن تاریخچه» and «پاک کردن همه داده‌ها» all go through the same store and are confirmed
in a dialog first.
