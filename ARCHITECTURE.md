# ARCHITECTURE.md

## Decision: why no backend

Google Live API **officially supports client-to-server** WebSockets (frontend → Live API, no app backend). That matches BYOK and privacy: DOUBLER never sees the key or audio.

Tradeoff: API key lives on device. Mitigations: Flutter Secure Storage, key masking, no logs, user can delete. Google also documents **ephemeral tokens** (usually minted by a server). We **do not** add a server in v1; we use the user’s Gemini API key directly, with clear user education.

## State management: Riverpod

**Chosen: Riverpod** (code-generation optional later).

Why not Bloc: Live audio is a stream of many independent concerns (connection, levels, transcript, mixer, settings). Riverpod providers compose without a single bloc god-object. Why not GetX: weaker compile-time safety.

UI never talks to Gemini sockets directly.

## Layers

```
presentation (screens, widgets, l10n)
        ↓
application (Riverpod notifiers / use-cases)
        ↓
domain (models, TranslationProvider interface)
        ↓
infrastructure (gemini, audio, storage)
```

### Domain AI abstraction

```
abstract class TranslationProvider {
  Stream<ProviderEvent> connect(SessionConfig config);
  void sendAudio(Uint8List pcm16k);
  void updateConfig(SessionConfig patch);
  Future<void> disconnect();
}

class GeminiTranslationProvider implements TranslationProvider { ... }
// Future: OpenAITranslationProvider, ClaudeTranslationProvider
```

Events: `connected`, `listening`, `partialTranscript`, `finalTranscript`, `audioOut`, `speaking`, `turnComplete`, `latency`, `error`, `disconnected`, `quota`.

## Gemini realtime architecture

**Protocol:** Stateful WSS  
**Endpoint (Gemini API / AI Studio):**  
`wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent`  
Auth: `?key=` or header per current official docs (verify at implement time).

**Audio:**
- In: 16-bit PCM, 16 kHz, LE (`audio/pcm;rate=16000`), base64 in JSON messages
- Out: 16-bit PCM, 24 kHz, LE

**Models (verify at implement time against ai.google.dev):**
- Native audio Live, e.g. `gemini-2.5-flash-native-audio` / preview aliases
- Dedicated Live Translation / Live Transcribe if present in current docs

**Session setup:** `setup` with model, `generation_config.response_modalities` AUDIO or TEXT, `speech_config.voice_config`, `system_instruction` (translator persona + tone + target language), `input_audio_transcription`, `output_audio_transcription`, VAD / activity handling.

**Client messages:** `realtime_input` audio chunks; optional `activity_start/end` if manual VAD.  
**Server messages:** `serverContent.modelTurn.parts.inlineData`, transcriptions, `turnComplete`, `interrupted`, goAway, session resumption handle.

**Flutter:** `web_socket_channel` (or equivalent) — no official first-party Flutter Live SDK as of research. Isolate JSON/base64 off the UI isolate if needed.

**Mobile:** TLS WSS is supported. Keepalive + reconnect. Background: Android foreground service for long sessions; iOS background audio limited — pause or degrade when backgrounded (see risks).

## Audio pipeline

See AUDIO_PIPELINE.md.

Abstractions:

- `AudioCapture` — mic → PCM 16 kHz
- `AudioOutput` — PCM 24 kHz → speaker
- `AudioMixer` — original vs dubbed gains + ducking
- `RealtimeConnection` — WSS lifecycle
- `TranslationEngine` — provider + session config
- `TranscriptManager` — segments, export
- `LocalStorage` / `SettingsManager` / `SecureKeyStore`

Platform code only inside `infrastructure/audio/{android,ios}`.

## Localization architecture

Flutter gen-l10n, `arb` per locale, `AppLocalizations`. Default `fa`. `localeResolutionCallback` + `Directionality`. Language *catalog* for translation pairs is data (`languages.yaml` or dart const list), separate from UI strings.

## Security architecture

- API key: `flutter_secure_storage` (Keychain / EncryptedSharedPreferences)
- Never in SharedPreferences plaintext, git, logs, crash payloads
- Masked TextField; show/hide; delete/replace; `Test Connection` = tiny Live setup or `models.list` / generateContent ping without storing response secrets
- Network: HTTPS/WSS to Google only

## Persistence

| Data | Store |
|---|---|
| API key | Secure storage |
| Settings (theme, langs, volumes) | SharedPreferences or Hive |
| Session history + transcripts | Isar or Drift/SQLite (structured query, export) |

Recommendation: **Secure Storage + Isar** (or Drift if team prefers SQL). Hive alone is weaker for relational session/segment queries.

## UX / UI architecture

Design system in `core/theme` + `shared/widgets`: colors, type, spacing, radius, buttons, cards, sheets. Light + dark. Persian typography: a readable Arabic-script family (e.g. Vazirmatn / Estedad as bundled fonts) + Latin fallback.

Screens (named routes / go_router):

Splash, Onboarding, ApiKeySetup, Home, LiveDubbing, LanguageSelection, AudioControls, LiveTranscript, History, SessionDetail, Settings, About, Privacy, GeminiConfig, Export, Help.

Live screen is the product: language pair, status (Listening / Translating / Speaking), waveform, two sliders, subtitle stage, connection + latency, Start/Pause/Stop.

## Project folder structure

```
lib/
  main.dart
  app.dart
  core/
    config/
    constants/
    errors/
    extensions/
    l10n/          # arb generated
    routing/
    theme/
    utils/
  domain/
    models/
    providers/     # TranslationProvider contract
  features/
    onboarding/
    api_key/
    home/
    dubbing/
    conversation/
    transcript/
    history/
    settings/
    about/
    help/
  infrastructure/
    audio/
    gemini/
    storage/
    network/
  shared/
    widgets/
test/
docs as repo-root markdown
```

Feature folders: `presentation/`, `application/` as needed. No UI import of `infrastructure/gemini`.
