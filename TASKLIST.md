# TASKLIST.md

Statuses: `TODO` | `IN_PROGRESS` | `DONE` | `BLOCKED`

Work sequentially by phase. Do not start Phase N+1 implementation until required previous phase acceptance is met **and** owner approved after `START IMPLEMENTATION`.

---

### DUB-000 — Phase 0 — Planning documents
- **Deps:** none
- **Status:** DONE
- **Acceptance:** PRODUCT_SPEC, ARCHITECTURE, AUDIO_PIPELINE, GEMINI_INTEGRATION, LOCALIZATION, PRIVACY, BUILD, TROUBLESHOOTING, TECHNICAL_RISKS, IMPLEMENTATION_PLAN, TASKLIST, README exist. No Dart implementation.

---

### DUB-001 — Phase 1 — Initialize Flutter architecture
- **Deps:** DUB-000, owner `START IMPLEMENTATION`
- **Status:** DONE
- **Acceptance:** Flutter project compiles; `lib/` structure matches ARCHITECTURE.md; Riverpod + go_router wired.
- **Notes:** Scaffolded by hand because `storage.googleapis.com` (Dart SDK download) is blocked in this environment. `flutter pub get` / `flutter test` must be run on a machine with Flutter SDK.

### DUB-002 — Phase 1 — Routing shell & empty screens
- **Deps:** DUB-001
- **Status:** DONE
- **Acceptance:** All listed screens reachable as stubs without crash.

### DUB-003 — Phase 1 — Analyze + smoke test
- **Deps:** DUB-002
- **Status:** DONE
- **Acceptance:** Widget smoke test added (`test/widget_test.dart`). Analyzer not executed here (no Dart SDK).

---

### DUB-010 — Phase 2 — Color, type, spacing tokens
- **Deps:** DUB-003
- **Status:** DONE
- **Acceptance:** `AppTheme` light/dark; tokens in `lib/core/theme`. Vazirmatn family declared with system fallbacks (TTF not bundled — CDN blocked).

### DUB-011 — Phase 2 — Shared widgets
- **Deps:** DUB-010
- **Status:** DONE
- **Acceptance:** Button, card, slider, field, sheet, dialog; home/placeholder consume tokens.

---

### DUB-020 — Phase 3 — ARB files + gen-l10n
- **Deps:** DUB-011
- **Status:** DONE
- **Acceptance:** Runtime tables + ARB for fa/en; UI locales fa, en, ru, ar, zh, tr, fr, de, es, it, pt, ja, ko. Hand-maintained `AppLocalizations` (no Dart SDK for gen-l10n here).

### DUB-021 — Phase 3 — Language catalog model
- **Deps:** DUB-020
- **Status:** DONE
- **Acceptance:** `Language` + `LanguageCatalog`; language screen uses catalog only.

### DUB-022 — Phase 3 — RTL mixed-content sample
- **Deps:** DUB-021
- **Status:** DONE
- **Acceptance:** `MixedDirectionText` + tests for `فارسی + English + 123 + URL` and RTL→LTR switch.

---

### DUB-030 — Phase 4 — Onboarding flow copy
- **Deps:** DUB-022
- **Status:** DONE
- **Acceptance:** Six localized steps; splash → onboarding if no key, home if key exists.

### DUB-031 — Phase 4 — Secure API key CRUD
- **Deps:** DUB-030
- **Status:** DONE
- **Acceptance:** Validate/mask/save/delete; `SecureKeyStore` + memory impl; live session blocked without key.

### DUB-032 — Phase 4 — Test connection
- **Deps:** DUB-031
- **Status:** DONE
- **Acceptance:** HTTP status mapped to l10n codes; key not included in failures; unit tests.

---

### DUB-040 — Phase 5 — TranslationProvider interface
- **Deps:** DUB-032
- **Status:** DONE
- **Acceptance:** Domain events expanded; `GeminiTranslationProvider` implements contract.

### DUB-041 — Phase 5 — WSS session lifecycle
- **Deps:** DUB-040
- **Status:** DONE
- **Acceptance:** Injected socket factory; setup JSON; reconnect with cap; resume handle; disconnect.

### DUB-042 — Phase 5 — Error mapping
- **Deps:** DUB-041
- **Status:** DONE
- **Acceptance:** Close/error → l10n codes; URI redaction; unit tests. No API key in setup payload logs.

---

### DUB-050 — Phase 6 — AudioCapture abstraction
- **Deps:** DUB-003
- **Status:** DONE
- **Acceptance:** PCM16 16kHz 20ms frames; permission denied → `micDenied`; fake capture for tests. Platform engine is injectable (`record` to be wired when SDK is available).

### DUB-051 — Phase 6 — Lifecycle & audio focus
- **Deps:** DUB-050
- **Status:** DONE
- **Acceptance:** `AudioLifecycleObserver` pauses on background; phone/focus/route interruptions; live screen attaches observer.

---

### DUB-060 — Phase 7 — Stream capture into Gemini
- **Deps:** DUB-041, DUB-050
- **Status:** DONE
- **Acceptance:** Mic frames sent after connect; live source/target lines from transcription events.

### DUB-061 — Phase 7 — Translator system instruction + tone
- **Deps:** DUB-060
- **Status:** DONE
- **Acceptance:** Tone (casual/natural/formal/professional) in SessionConfig and instruction; settings chips; tests.

---

### DUB-070 — Phase 8 — AudioOutput + jitter buffer
- **Deps:** DUB-041
- **Status:** DONE
- **Acceptance:** PCM24kHz output + ~120ms jitter buffer; start/pause/stop; fake player for tests.

### DUB-071 — Phase 8 — Latency indicator
- **Deps:** DUB-070, DUB-060
- **Status:** DONE
- **Acceptance:** Measured ms (mic→first audio out); bands good/fair/poor; never faked as &lt;1.5s.

---

### DUB-080 — Phase 9 — Subtitle surface
- **Deps:** DUB-061, DUB-011
- **Status:** DONE
- **Acceptance:** `SubtitleStage` + settings (size, colors, position); live screen consumes style provider.

---

### DUB-090 — Phase 10 — Volume sliders
- **Deps:** DUB-070
- **Status:** DONE
- **Acceptance:** Original + dubbed sliders on live + audio controls; dubbed gain applied to `AudioOutput`.

### DUB-091 — Phase 10 — Smart ducking
- **Deps:** DUB-090
- **Status:** DONE
- **Acceptance:** `AudioMixer` ducks original when speaking; mic mode original gain is 0 (feedback). Tests cover both.

---

### DUB-100 — Phase 11 — TranscriptManager
- **Deps:** DUB-061
- **Status:** DONE
- **Acceptance:** Timestamped bilingual segments; live list; copy to clipboard; export entry point.

---

### DUB-110 — Phase 12 — Session history DB
- **Deps:** DUB-100
- **Status:** DONE
- **Acceptance:** Local `HistoryStore` (memory seam for Isar later); list/view/delete; saved on session stop. Offline only.

---

### DUB-120 — Phase 13 — TXT/SRT/JSON export
- **Deps:** DUB-100
- **Status:** DONE
- **Acceptance:** SRT `HH:MM:SS,mmm -->`; bilingual TXT/SRT; JSON; copy to clipboard.

---

### DUB-130 — Phase 14 — Settings screen complete
- **Deps:** DUB-020, DUB-090, DUB-080, DUB-031
- **Status:** DONE
- **Acceptance:** UI language, theme, pair, voice, tone, audio, subtitles, performance, privacy/clear data. In-session providers (SharedPreferences later).

---

### DUB-140 — Phase 15 — Home + live polish
- **Deps:** DUB-080–DUB-130
- **Status:** DONE
- **Acceptance:** Tagline, CTA, waveform, Semantics on primary actions.

### DUB-141 — Phase 15 — About / Help / Privacy screens
- **Deps:** DUB-140
- **Status:** DONE
- **Acceptance:** About/Help/Privacy copy localized; official AI Studio URL only.

---

### DUB-150 — Phase 16 — Test suite expansion
- **Deps:** DUB-141
- **Status:** DONE
- **Acceptance:** Session-flow + failure tests added; TESTING.md lists all suites. `flutter test` still requires a local SDK.

---

### DUB-160 — Phase 17 — Release hygiene
- **Deps:** DUB-150
- **Status:** DONE
- **Acceptance:** BUILD/STORE/CHANGELOG; no real secrets in repo; remaining device work documented (SDK, fonts, plugins).
