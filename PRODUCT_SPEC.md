# DOUBLER — Product Specification

**Product names:** DOUBLER / دوبلر  
**Default locale:** `fa-IR` (Persian)  
**Platform:** Flutter (Android + iOS), 100% client-side  
**Business model:** Free, BYOK (user Gemini API key)  
**Status:** Planning only — implementation starts only after `START IMPLEMENTATION`

---

## 1. Executive product analysis

Dubingo is a **browser extension** that captures tab audio, streams it to **Google Gemini Live API** over WebSockets, and plays translated speech plus subtitles with ~1.5s target latency. It is free, has no accounts, stores the API key locally, and does not proxy audio through its own servers.

**DOUBLER** is a **native mobile app** with equivalent *capabilities*, not a clone of Dubingo’s UI, assets, or copy:

| Dubingo (inspiration) | DOUBLER (this product) |
|---|---|
| Chrome/Firefox extension | Flutter Android + iOS |
| Tab audio capture | Microphone (and later system-audio where OS allows) |
| Gemini Live, BYOK | Same: Flutter → Gemini, no backend |
| 80–100+ languages | Same language catalog; UI default Persian |
| Mixer + ducking | Same UX; native audio mixing constraints documented |
| Transcript TXT/SRT | Same, local history |

**Tagline (Persian):** هر چیزی را به زبان خودت بشنو  
**English equivalent:** Hear anything in your own language.

Primary UX: *Open → languages → start → hear the world in Persian.* Complex streaming is hidden behind a simple live screen.

---

## 2. Dubingo public feature breakdown (from public materials only)

Public sources: [dubingo.com](https://dubingo.com/), Chrome Web Store, Firefox Add-ons, third-party listings.

- Real-time sentence-by-sentence dubbing (not wait-for-full-video)
- Target latency &lt; 1.5s (marketing benchmark)
- Dual-stream mixer: original vs dubbed volume; smart ducking
- Live subtitles (short lines, styling)
- Live transcripts with timestamps; bilingual export TXT/SRT
- Same-language mode → transcript-only, original at full volume
- Modes: Instant / Balanced / Studio (speed vs quality)
- 80–100+ languages
- Works on YouTube, Meet, Zoom, courses, podcasts, livestreams **in a browser tab**
- BYOK Gemini; key in `chrome.storage.local`
- No Dubingo servers for audio; no subscription; no account
- Direct WebSocket to Gemini Live

**Not copied:** logos, screenshots, proprietary copy, private source, exact layout.

**Mobile gap:** Tab capture does not exist on iOS/Android the same way. DOUBLER v1 uses the **device microphone** as the primary source (speakerphone / meeting / nearby audio). Loopback of other apps’ audio is OS-limited (see TECHNICAL_RISKS.md).

---

## 3. Product goals

1. Real-time speech translation and AI dubbing on-device UI, cloud AI at Google only.
2. Privacy-first: no accounts, ads, analytics backend, or our servers.
3. Production-quality Persian-first UI with full i18n and proper RTL.
4. Streaming pipeline — never record → upload → wait → download.

---

## 4. Non-goals (v1)

- Custom backend, Laravel/Node API, proxy, database server
- User accounts, email, subscriptions, ads
- Cloning Dubingo branding
- Implementing extra AI providers (architecture only)
- Capturing arbitrary other-app audio on iOS (not generally possible without entitlement)

---

## 5. Core user journeys

1. **First launch:** Splash → onboarding (what / why key / how to get key / privacy) → paste key → test connection → home.
2. **Live dubbing:** Home CTA «شروع دوبله زنده» → live session (mic → Gemini → dubbed audio + subtitles).
3. **Conversation (two-way):** Alternating or simultaneous translation for two speakers (best-effort with one mic; see limitations).
4. **History:** Browse local sessions, export, delete.
5. **Settings:** Languages, voice, tone, audio, subtitles, theme, key, clear data.

---

## 6. Translation modes

| Mode | Behavior | Gemini mapping |
|---|---|---|
| **1 Live Dubbing** | Stream mic → translated speech + optional subtitles | Live API native audio + I/O transcription |
| **2 Live translation + subtitles** | Same but emphasis on captions; voice optional | Same session; mute playback |
| **3 Translation only** | Text translation of recognized speech, no TTS | Live text / transcription + system instruction |
| **4 Transcript** | STT + optional translation, original volume 100% | Input transcription; skip audio out |
| **5 Conversation / two-way** | A↔B languages, turn-taking UI | One Live session with language-switch instruction, or two sequential sessions |

If Live Translation API (dedicated) is available and more accurate, prefer it for modes 1–2; otherwise native-audio Live with a strict translator system prompt.

---

## 7. Functional requirements (summary)

- Speech recognition, translation, AI voice, live subtitles
- Original / dubbed volume; smart ducking
- Language pair + Auto Detect (if API supports)
- Voice / personality (Gemini prebuilt voices)
- Tone: casual, natural, formal, professional
- Transcript + TXT/SRT/JSON export
- Pause/resume, start/stop, connection + latency, reconnect
- Offline: settings/history/UI; AI blocked with clear status
- Lifecycle: background, lock, calls, BT/headphones, audio focus

---

## 8. Languages (domain model)

Do **not** hardcode language logic in widgets.

```
Language {
  code,          // BCP-47 e.g. fa-IR
  displayName,   // localized via AppLocalizations
  nativeName,    // فارسی
  flagEmoji or asset,
  supportedAsInput,
  supportedAsOutput,
  textDirection, // rtl | ltr
}
```

Minimum UI locales: fa, en, ru, ar, zh, tr, fr, de, es, it, pt, ja, ko.  
Translation catalog: Gemini Live ~70 languages — map `supportedAsInput/Output` from a data file, not widgets.

Default: source Auto (or en), target fa-IR.

---

## 9. Privacy & legal product distinction

- Audio goes **only** to Google Gemini when a session is active.
- Key stored in platform secure storage; never logged.
- In-app Privacy screen explains Google’s processing; we do not operate servers.
- Inspired by Dubingo **functionality**, original brand **DOUBLER / دوبلر**.
