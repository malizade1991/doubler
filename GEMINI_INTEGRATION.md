# GEMINI_INTEGRATION.md

Official docs (verify before coding):  
https://ai.google.dev/gemini-api/docs/live-api  
https://ai.google.dev/gemini-api/docs/live-api/get-started-websocket  
https://ai.google.dev/gemini-api/docs/live-guide

## Why client → Gemini

Live API supports **client-to-server** WebSockets. DOUBLER will not proxy.

## Auth (BYOK)

User pastes Gemini API key from Google AI Studio (`https://aistudio.google.com/apikey`). Stored in secure storage. Connection uses that key only.

**Ephemeral tokens:** Google recommends them for production web clients with a minting server. We explicitly **do not** mint tokens (no backend). Users accept that the key is on-device, equivalent to Dubingo’s extension model.

## Connection

1. Open WSS to `BidiGenerateContent`
2. Send `setup` (model, modalities, voice, system instruction, transcriptions)
3. Stream `realtime_input.audio`
4. Receive audio + transcripts
5. Handle `goAway`, session resumption, close codes (quota, invalid key)

## System instruction (conceptual)

Strict translator: output **only** the target language speech (and matching transcript). Tone from settings. Do not converse unless Conversation mode.

## Test connection

Lightweight: HTTP `GET https://generativelanguage.googleapis.com/v1beta/models?key=` or a tiny generateContent. Map 400/403 to «کلید نامعتبر است». Never log the key.

## Adding another provider later

Implement `TranslationProvider`. UI stays on engine events. No Gemini types in widgets.

## Models

Lock model IDs in a single `GeminiConfig` with a remote-free default list. If Google renames models, change one file.
