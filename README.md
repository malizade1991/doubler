# DOUBLER — دوبلر

Client-side Flutter app for **real-time speech translation and dubbing**.  
Inspired by the *product capabilities* of [Dubingo](https://dubingo.com/) — **not** a clone of its UI, assets, or code.

**Status:** Phase 17 (release hygiene) complete. Product is code-complete for v0.1 pending a local Flutter build.

Requires a local [Flutter SDK](https://docs.flutter.dev/get-started/install). In this sandbox, Google Storage was unreachable so the Dart SDK could not be bootstrapped; run `flutter pub get && flutter test && flutter analyze` on your machine.

Requires a local [Flutter SDK](https://docs.flutter.dev/get-started/install). In this sandbox, Google Storage was unreachable so the Dart SDK could not be bootstrapped; run `flutter pub get && flutter test && flutter analyze` on your machine.

## What it is

Open DOUBLER → choose languages → start → hear the world in Persian (or another target language).

- 100% client-side: **Flutter → Google Gemini Live API**
- **BYOK:** your Gemini API key, stored on device
- No accounts, ads, subscriptions, or DOUBLER servers
- Android + iOS

## Why there is no backend

Gemini Live supports **direct client WebSockets**. A proxy would contradict privacy and BYOK. We never hide your key on “our” server because we do not run one.

## Docs

| Doc | Contents |
|---|---|
| [PRODUCT_SPEC.md](PRODUCT_SPEC.md) | Product & feature spec |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Flutter / Riverpod / folders |
| [AUDIO_PIPELINE.md](AUDIO_PIPELINE.md) | Capture → Gemini → playback |
| [GEMINI_INTEGRATION.md](GEMINI_INTEGRATION.md) | Live API, BYOK |
| [LOCALIZATION.md](LOCALIZATION.md) | ARB, RTL, adding languages |
| [PRIVACY.md](PRIVACY.md) | Data flows |
| [BUILD.md](BUILD.md) | Build & permissions |
| [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | User-facing failures |
| [TECHNICAL_RISKS.md](TECHNICAL_RISKS.md) | Risks & limits |
| [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) | Phases 0–17 |
| [TASKLIST.md](TASKLIST.md) | DUB-xxx tasks |
| [TESTING.md](TESTING.md) | Test strategy |
| [CHANGELOG.md](CHANGELOG.md) | Versions |
| [docs/STORE.md](docs/STORE.md) | Store listing draft |

## Adding a UI language

New `app_XX.arb` + `supportedLocales`. See LOCALIZATION.md.

## Adding an AI provider later

Implement `TranslationProvider`. Do not rewrite UI.

## License / brand

Original product **DOUBLER / دوبلر**. Do not use Dubingo trademarks or assets.
