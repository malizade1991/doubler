# IMPLEMENTATION_PLAN.md

**Rule:** Do not implement until the product owner says `START IMPLEMENTATION`. Then **one phase at a time**, then wait for approval.

---

## Phase 0 — Discovery *(this phase — complete when these docs land)*

- **Objective:** Public product analysis, Gemini Live facts, Flutter constraints, written specs.
- **Tasks:** Inspect repo; research Dubingo public features; research Live API; write PRODUCT_SPEC, ARCHITECTURE, risks, this plan, TASKLIST.
- **Deps:** none
- **Files:** `*.md` at repo root
- **Acceptance:** Specs exist; no app code; known limitations documented
- **Risks:** API docs drift — re-verify in Phase 5
- **Tests:** n/a

## Phase 1 — Flutter foundation

- **Objective:** Create Flutter app skeleton, lints, routing shell, Riverpod, empty screens.
- **Tasks:** `flutter create`; folder structure; `go_router`; `ProviderScope`; CI-friendly analyze
- **Deps:** Phase 0
- **Files:** `lib/`, `pubspec.yaml`, `analysis_options.yaml`
- **Acceptance:** App launches to splash/home placeholder; `flutter analyze` clean
- **Risks:** none major
- **Tests:** widget smoke test

## Phase 2 — Design system

- **Objective:** Theme, typography (Persian fonts), components
- **Deps:** Phase 1
- **Acceptance:** Light/dark; shared buttons/cards; no magic numbers in features
- **Tests:** golden optional later; theme widget test

## Phase 3 — Localization

- **Objective:** ARB for fa + listed languages; RTL
- **Deps:** Phase 2
- **Acceptance:** Locale switch; no hardcoded English in UI; mixed fa+en+123+URL sample
- **Tests:** l10n load; RTL direction test

## Phase 4 — API key / BYOK

- **Objective:** Onboarding + secure key + test connection + privacy copy
- **Deps:** Phase 3
- **Acceptance:** Save/mask/delete/replace; blocked live without key
- **Tests:** secure storage fake; validation unit tests

## Phase 5 — Gemini connection

- **Objective:** `GeminiTranslationProvider` WSS setup/teardown, errors, reconnect
- **Deps:** Phase 4
- **Acceptance:** Test session connects with valid key; invalid key Persian error; no key in logs
- **Risks:** R1, R4, R16
- **Tests:** mocked websocket

## Phase 6 — Audio capture

- **Objective:** Mic PCM 16 kHz; permissions; lifecycle
- **Deps:** Phase 1 (can parallel 5 after 1)
- **Acceptance:** Permission flows; capture callback with correct format
- **Risks:** R7, R8
- **Tests:** permission denied UI

## Phase 7 — Realtime translation

- **Objective:** Stream mic to Gemini; transcripts in; translator prompt
- **Deps:** 5, 6
- **Acceptance:** Spoken sentence appears as source+target text
- **Risks:** R11, R10

## Phase 8 — Audio playback

- **Objective:** 24 kHz out, buffer, pause/stop
- **Deps:** 5
- **Acceptance:** Hear dubbed audio without UI jank
- **Risks:** R12, underruns

## Phase 9 — Live subtitles

- **Objective:** Subtitle stage, styling from settings
- **Deps:** 7
- **Acceptance:** Readable RTL/LTR captions during session

## Phase 10 — Audio mixing

- **Objective:** Sliders + ducking; mic-mode original mute documented
- **Deps:** 8
- **Acceptance:** Gains apply; ducking on speaking when two buses exist
- **Risks:** R13

## Phase 11 — Transcript

- **Objective:** Segment model, live list, copy/share
- **Deps:** 7
- **Acceptance:** Timestamp + source + target per segment

## Phase 12 — History

- **Objective:** Local DB sessions CRUD
- **Deps:** 11
- **Acceptance:** Offline browse/delete

## Phase 13 — Export

- **Objective:** TXT, SRT, JSON bilingual
- **Deps:** 11
- **Acceptance:** SRT `HH:MM:SS,mmm -->`
- **Tests:** formatter unit tests

## Phase 14 — Settings

- **Objective:** All settings listed in product brief
- **Deps:** 2, 3, 4, 10
- **Acceptance:** Persist; apply to next session

## Phase 15 — Polish

- **Objective:** Waveform, transitions, home CTA, empty/error states, About/Help
- **Deps:** 9–14
- **Acceptance:** Production feel; a11y labels; contrast

## Phase 16 — Testing

- **Objective:** Unit/widget/integration strategy executed
- **Deps:** 15
- **Acceptance:** Critical paths green; RTL cases; failure cases

## Phase 17 — Release

- **Objective:** Store listing copy (original), icons, BUILD.md verification
- **Deps:** 16
- **Acceptance:** Release builds; privacy text; no secrets in repo
