# TECHNICAL_RISKS.md

| ID | Risk | Impact | Mitigation |
|---|---|---|---|
| R1 | No official Flutter Live SDK | Custom WSS + JSON | Isolate protocol; follow JS websocket tutorial |
| R2 | API key on device | Theft if device compromised | Secure storage; user education; no logs |
| R3 | Google prefers ephemeral tokens | Policy / key leak on shared devices | Document; no server in v1 |
| R4 | Model IDs change | Broken sessions | Single config; test connection |
| R5 | Session time limits (~10 min connection, resume tokens) | Long dubs fail | Auto-resume with handle |
| R6 | iOS no tab/app loopback | Cannot dub Netflix in another app | Mic + honest UX |
| R7 | Echo / AEC | Conversation quality | Voice processing IO; headphones CTA |
| R8 | Background audio policy | Session killed | Android FGS; iOS pause |
| R9 | Rate/quota | Errors | Persian messages; backoff |
| R10 | 70 langs vs 100+ marketing | Some pairs unsupported | Catalog flags; disable unsupported |
| R11 | Translator prompt drift | Model chats instead of dubs | Strict instruction; Conversation as separate mode |
| R12 | Latency &gt; 1.5s on mobile | Misses Dubingo web claim | Jitter buffer tuning; don’t fake the metric |
| R13 | Mixing original+dub on mic | Feedback | Mute original in mic mode |
| R14 | Isolates + FFI audio | Complexity | Start with plugins; isolate if jank |
| R15 | RTL mixed content | Broken subtitles | Dedicated transcript widgets |
| R16 | WS on cellular NAT | Drops | Ping, reconnect, resume |
