# Android CI/CD — setup & operations

The pipeline lives at [`.github/workflows/android-ci.yml`](../.github/workflows/android-ci.yml).
It is a single workflow with three jobs:

| Job       | Runs on                                   | Purpose |
|-----------|-------------------------------------------|---------|
| `validate`| PR, push `main`, tag, dispatch            | `flutter analyze` + `flutter test` |
| `build`   | after `validate`                          | signed (tag) / debug-signed (dev) APKs (split-per-ABI) + AAB, uploaded as artifacts |
| `release` | tag `v*` only                             | publish a GitHub Release with the artifacts attached |

Nothing is published on ordinary commits — `release` only runs for `refs/tags/v*`.

## Toolchain pins (why these values)

- **Flutter `3.29.3`** — newest stable whose bundled `flutter_localizations` still pins
  `intl: 0.19.0` (pubspec requires `intl: ^0.19.0`). Flutter ≥ 3.32 pins `intl: 0.20.2` and
  would make `flutter pub get` fail.
- **Java 17** — required by AGP 8.7.0 (`android/app/build.gradle`).
- **Gradle 8.10.2** — AGP 8.7.0 requires ≥ 8.9; Flutter 3.29.x validates against [8.0, 8.10.2]
  and uses 8.10.2 as its template default. Pinned in `android/gradle/wrapper/gradle-wrapper.properties`.
- **AGP 8.7.0 / Kotlin 2.0.21** — already in `android/settings.gradle`; unchanged.

The repo intentionally does not commit `gradlew`/`gradle-wrapper.jar`. When absent, the
Flutter tool injects them from its cache and preserves the committed `gradle-wrapper.properties`.

## ⚠️ Localization landmine — do not do these

`lib/core/l10n/app_localizations.dart` is **hand-written** (97 getters). The ARB files in
`lib/core/l10n/` define only 26 keys and are just source data for `l10n_tables.dart`.

- **Do NOT add `generate: true` to `pubspec.yaml`.** With it, the tool runs `gen-l10n` on every
  build and would overwrite `app_localizations.dart` with a generated class that is missing 71+
  getters → the app stops compiling.
- **Do NOT run `flutter gen-l10n` in CI or locally.**
- **Do NOT add an `l10n.yaml` to the repo root.** Its mere presence makes `flutter analyze`
  and `flutter pub get` attempt synthetic-package generation, which aborts with
  `Attempted to generate localizations code without having the flutter: generate flag turned on`
  and exit code 1 — even though nothing in the app needs generation. The sample config now
  lives, inactive, at `docs/l10n.yaml.example`.

On Flutter 3.29.x `synthetic-package` still defaults to `true`, and the pubspec has no
`generate: true`, so today nothing is clobbered — keep it that way.

## Release tags must start with `v`

The workflow triggers on `tags: ["v*"]` and every release step is gated on
`startsWith(github.ref, 'refs/tags/v')`. A tag like `1.0.0` (no `v`) does **not** trigger
a build and does **not** publish — an earlier `1.0.0` tag produced a release with zero
assets for exactly this reason. Always tag `vX.Y.Z`, matching `pubspec.yaml`.

## Signing: signed releases vs. unsigned pre-releases

A `v*` tag always builds APKs + an AAB. Whether the published release is *signed* depends on
the four secrets below:

| Secrets | Build job | Published as |
|---------|-----------|--------------|
| all four set | signed with the release keystore | normal release, becomes **Latest** |
| any missing | debug keystore, `signed=false` | **pre-release**, titled `… (unsigned QA build)`, with a warning annotation and a step-summary block |

An unsigned pre-release is for testing and sideloading only: it cannot be uploaded to Google
Play and must not be handed out as a production build. To restore the old fail-loudly
behaviour (no release at all when signing is missing), set the workflow env
`REQUIRE_SIGNED_RELEASE: "true"` at the top of `.github/workflows/android-ci.yml`.

### Turning an unsigned pre-release into a signed one

This repository has **immutable releases**, so an already-published release can never take new
assets. Adding the secrets later therefore needs one of:

```bash
# a) delete the release (the tag stays) and rebuild that tag, now signed:
gh release delete vX.Y.Z --yes
gh workflow run android-ci.yml --ref vX.Y.Z -f run_release=true

# b) or simply cut the next patch version — bump pubspec.yaml, commit, tag, push.
```

## Required GitHub Secrets (release signing only)

PR/branch builds need **no secrets**. A *signed* tag release requires all four:

| Secret | Contents |
|--------|----------|
| `ANDROID_KEYSTORE_BASE64` | `base64 -w0` of the `.jks` keystore |
| `ANDROID_KEYSTORE_PASSWORD` | keystore password |
| `ANDROID_KEY_ALIAS` | key alias |
| `ANDROID_KEY_PASSWORD` | key password |

Create a keystore once (never commit it):

```bash
keytool -genkeypair -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias doubler-release -storetype JKS
base64 -w0 upload-keystore.jks   # macOS: base64 upload-keystore.jks | pbcopy
```

Set them under **Settings → Secrets and variables → Actions → New repository secret**.

If any of the four is missing on a tag run, the assets are built with the debug keystore and
the tag is published as an unsigned **pre-release** instead (see above) — never as a normal
release, so a debug-signed APK can never be mistaken for a production build.

## Triggering

```bash
# CI validation on a pull request (auto)
gh pr create ...

# CI validation on main (auto on push)

# Production release: bump pubspec version first, then tag
git checkout main && git pull
# edit pubspec.yaml version: X.Y.Z+ N
git commit -am "chore: release X.Y.Z" && git push
git tag vX.Y.Z && git push origin vX.Y.Z

# Manual build (debug-signed artifacts for QA)
gh workflow run android-ci.yml --ref main

# Manual release from an existing tag
gh workflow run android-ci.yml --ref vX.Y.Z -f run_release=true
```

## Expected artifact paths

Local / in-repo Gradle output (`android/build.gradle` sets `rootProject.buildDir = ../build`):

```
build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
build/app/outputs/flutter-apk/app-x86_64-release.apk
build/app/outputs/bundle/release/app-release.aab
```

The workflow uploads these (plus the `apk/` mirror) as artifact `android-release-<run_number>`,
and the `Verify produced artifacts` step fails if none are found, so a path mismatch can never
silently upload an empty artifact.

## Downloading

- **Actions artifacts** (any run): repo → *Actions* → the run → *Artifacts* → `android-release-<run_number>`.
  Or via CLI: `gh run download <RUN_ID> -n android-release-<run_number>` — run it from inside a
  git clone of this repo (or add `-R malizade1991/doubler`), otherwise `gh` cannot tell which
  repository the run belongs to.
- **GitHub Releases** (tag runs): repo → *Releases* → `DOUBLER vX.Y.Z` → assets, renamed for
  humans: `doubler-vX.Y.Z-arm64-v8a.apk` (most phones), `…-armeabi-v7a.apk`, `…-x86_64.apk`,
  and `doubler-vX.Y.Z.aab` for Play. Or via CLI: `gh release download vX.Y.Z`.

## Remaining manual steps

1. Add the four signing secrets (above) to get *signed* releases from now on. The artifacts
   published before that are unsigned pre-releases; because releases here are immutable, a tag
   that already has a published release has to be rebuilt after `gh release delete vX.Y.Z
   --yes` (the tag stays), or the next version can simply be tagged.
2. Optionally replace the generated launcher icons with final brand assets.
3. NDK: the runner image ships NDK 27/28/29 but not the `flutter.ndkVersion` (26.1.10909125).
   This app has **no native code**, so nothing resolves the NDK and no install is needed. If a
   future plugin adds native code, add a step: `sdkmanager --install "ndk;26.1.10909125"`.
4. `flutter analyze --fatal-infos --fatal-warnings` and `flutter test` run in CI on every
   push/PR — that is the source of truth, since the authoring sandbox has no Flutter SDK.
