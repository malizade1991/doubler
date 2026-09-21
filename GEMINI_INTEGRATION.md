# GEMINI_INTEGRATION.md

Official docs (verify before coding):
https://ai.google.dev/gemini-api/docs/api-key
https://ai.google.dev/gemini-api/docs/live-api
https://ai.google.dev/gemini-api/docs/live-api/get-started-websocket
https://ai.google.dev/gemini-api/docs/models

## Why client → Gemini

Live API supports **client-to-server** WebSockets. DOUBLER will not proxy.

## Key formats (read this before touching validation)

Google replaced the old *standard* keys with *authorization* (auth) keys:

| Shape | Example | Status at Google | Where DOUBLER accepts it |
|---|---|---|---|
| Auth key | `AQ.Ab8RN…_tKAmP15lyGZA` (`AQ.` + base64url, dots allowed) | current, issued by AI Studio since 2026-05-28 | accepted, `ApiKeyKind.authKey` |
| Standard key | `AIzaSy…` (39 chars) | unrestricted ones are **rejected**; only some restricted legacy keys still work | accepted, saved with the `keyWarningLegacy` hint |
| Anything else long enough | Cloud/organisation keys | varies | accepted with `keyWarningShape` |

`ApiKeyValidator` therefore never asserts a prefix. It only:

1. `sanitize()`s the paste — quotes, backticks, `x-goog-api-key:` labels, `…?key=` prefixes,
   newlines, trailing `,`/`;`/`.`, and invisible Unicode (zero-width and bidi marks pasted
   from chat apps);
2. rejects an empty value (`keyEmpty`), a value shorter than 20 chars (`keyTooShort`), and a
   value containing whitespace or characters outside `[0-9A-Za-z_\-.]` (`keyInvalid`);
3. otherwise **stores it and lets Google decide**.

The rule that matters: *Google's HTTP/WS answer is the only thing allowed to call a key
invalid.* The old validator required `^[A-Za-z0-9_\-]+$`, which rejected every `AQ.` key
because of the dot — that was the "my valid key is invalid" bug.

## Auth (BYOK)

User pastes a key from Google AI Studio (`GeminiConfig.keyConsoleUrl`). Stored in the
app-private platform store (`com.doubler.doubler/store`, SharedPreferences / NSUserDefaults)
with an in-memory mirror; only a masked form (`AQ.A••••GZA`) ever reaches a widget.

**Ephemeral tokens:** Google recommends them for production web clients with a minting
server. We explicitly **do not** mint tokens (no backend). Users accept that the key is
on-device.

REST (`GET /v1beta/models`, the key test) sends `x-goog-api-key: KEY` **only** — `?key=`
returns 404 for auth keys. The Live WebSocket sends the header **and** `?key=`, because the
official socket docs still show the query parameter while several clients now report 404s
with headers-only. One of the two always works; the cost of sending both is zero.

## Connection

1. `GeminiLiveEndpoint` = `wss://generativelanguage.googleapis.com/ws/…BidiGenerateContent`
   + headers.
2. First client frame: `setup` (model, `response_modalities: [AUDIO]`, voice, system
   instruction, input/output transcription, session resumption).
3. **Wait for `setupComplete`** before anything else: `sendAudio` drops frames that arrive
   earlier. `ProviderConnected` is emitted from `setupComplete`, not from the socket opening.
   The server sends `{"setupComplete": {}}` (an empty protobuf message), **not** `true`.
   Treating only `true` as success left the live button on «در حال اتصال» forever.
4. Stream `realtime_input.media_chunks` — raw little-endian PCM16 at 16 kHz
   (`audio/pcm;rate=16000`). Model audio is always 24 kHz PCM16.
5. `gemini-3.8-live` does not accept `proactive_audio: false`, `affective_dialog` or
   `thinking_config`; do not reintroduce them (they are hard errors).
6. Handle `goAway`, `sessionResumptionUpdate.newHandle`, close codes (quota, invalid key).

## System instruction

Strict translator: output **only** the target language speech (and matching transcript).
Tone from settings (`_toneGuide`). Never converse, never explain.

## Test connection

`GeminiConnectionTester` → `GET https://generativelanguage.googleapis.com/v1beta/models`
with the auth header; on an auth rejection it retries once with `?key=` (legacy restricted
keys). Mapping: 200 → ok · 429 → `connectionOkQuota` (valid key, spent quota — reported as
*success with a warning*, never as "invalid") · 400/401/403/404 → `keyInvalid`, or
`keyLegacyRejected` when the key starts with `AIza` · timeout → `connectionTimeout` ·
socket/DNS → `networkUnavailable`. Codes are l10n keys resolved by
`AppLocalizations.message(code)`. Never log the key.

## Models

IDs live in one place (`GeminiConfig.liveModels`); the Settings → Gemini screen can switch
model without an app update if Google renames one. The dubbing default is
`models/gemini-3.5-live-translate-preview` (continuous interpreter, `translationConfig`,
no system instruction — that model rejects instructions). `modelResource()` falls back to
that id. `gemini-3.8-live` remains the conversational fallback if the translate model is
not enabled for the key. `gemini-2.5-flash-native-audio-preview-*` is **shut down** and must
not come back — a dead model id surfaces to users as "invalid key".

Setup and audio frames are camelCase (`generationConfig`, `realtimeInput.audio`). A handshake
that never receives `setupComplete` times out (`connectionTimeout`) instead of spinning.

## Adding another provider later

Implement `TranslationProvider`. UI stays on engine events. No Gemini types in widgets.
