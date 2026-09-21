# LOCALIZATION.md

Runtime strings currently live in `lib/core/l10n/l10n_tables.dart` (consumed by the hand-written `AppLocalizations`). ARB templates are in the same folder for a future `flutter gen-l10n` switch.

> **Do not put an `l10n.yaml` at the repo root.** With no `flutter: generate: true` in `pubspec.yaml`, its presence makes `flutter analyze` fail with `Attempted to generate localizations code without having the flutter: generate flag turned on`. The inactive sample lives at `docs/l10n.yaml.example`.

To add a **UI** language: add a code to `LanguageCatalog.uiLanguageCodes` and a full key map in `kL10nTables` (must match `fa` keys).

To add a **translation** language: add a `Language` to `LanguageCatalog.all`.

- Tooling: `flutter gen-l10n` is **disabled and must stay disabled** — `lib/core/l10n/app_localizations.dart`
  is hand-written and would be overwritten; CI fails if a root `l10n.yaml` or `generate: true` appears
  (see `docs/CI.md`). `docs/l10n.yaml.example` is documentation only.
- Template: `app_fa.arb` (source) + `app_en.arb` etc.
- Access: `AppLocalizations.of(context).startLiveDubbing`
- Never `Text("Settings")` in product UI
- RTL: `fa`, `ar` (and `he` if added) via `MaterialApp.locale` + widgets `textDirection` where mixed
- Mixed strings: wrap Latin/URL in LTR isolates (`\u202A` / `Directionality`) in transcript widgets
- Adding a UI language: new arb + `supportedLocales` + font fallback
- Adding a *translation* language: entry in `LanguageCatalog` with Gemini support flags
