# LOCALIZATION.md

Runtime strings currently live in `lib/core/l10n/l10n_tables.dart` (consumed by `AppLocalizations`). ARB templates are in the same folder for a future `flutter gen-l10n` switch.

To add a **UI** language: add a code to `LanguageCatalog.uiLanguageCodes` and a full key map in `kL10nTables` (must match `fa` keys).

To add a **translation** language: add a `Language` to `LanguageCatalog.all`.

- Tooling: `flutter gen-l10n` (planned), ARB files in `lib/core/l10n`
- Template: `app_fa.arb` (source) + `app_en.arb` etc.
- Access: `AppLocalizations.of(context)!.startLiveDubbing`
- Never `Text("Settings")` in product UI
- RTL: `fa`, `ar` (and `he` if added) via `MaterialApp.locale` + widgets `textDirection` where mixed
- Mixed strings: wrap Latin/URL in LTR isolates (`\u202A` / `Directionality`) in transcript widgets
- Adding a UI language: new arb + `supportedLocales` + font fallback
- Adding a *translation* language: entry in `LanguageCatalog` with Gemini support flags
