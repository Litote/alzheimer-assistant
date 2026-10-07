# AI Context — Alzheimer Assistant

> Codebase analysis for AI agents. Keep this file up-to-date after significant changes.

---

## System Overview

Voice assistant for Alzheimer's patients. The user speaks a request, the app transcribes it, sends it to an AI agent, and reads the response aloud. The app can also initiate phone calls to contacts on behalf of the user.

**Target users:** French-speaking elderly patients with Alzheimer's disease. UX must prioritize simplicity, large UI elements, and forgiving error handling.

---

## Architecture

Three transport modes coexist, selected at runtime:

**Mode Audio WebSocket (default)**
```
Flutter App
  Mic (PCM 16kHz) ──→ WebSocket /run_live ──→ ADK Agent (Cloud Run)
  ADK Agent ──────────→ WebSocket ──→ PCM 24kHz ──→ local player
                              ↓
                        Phone Call?
```

**Mode LiveKit WebRTC**
```
Flutter App
  LocalAudioTrack ──→ LiveKit Cloud (SaaS) ──→ ADK Agent Worker (Cloud Run)
  ADK Agent Worker ──→ LiveKit Cloud ──→ RemoteAudioTrack (auto-played)
  ADK Agent Worker ──→ LiveKit Data Messages ──→ Flutter (text/tool events)
  Flutter ──────────→ GET /livekit-token ──→ ADK Agent (HTTP)
```

**Mode Text SSE**
```
Flutter App (STT) ──→ POST /run_sse ──→ ADK Agent ──→ SSE ──→ Flutter (TTS)
```

---

## Components

### `front/` — Flutter Mobile App
- **Platform:** iOS, Android (web partial support)
- **Architecture:** Clean Architecture + BLoC
- **Key responsibilities:**
  - Three transport modes: Audio WebSocket, Text SSE, LiveKit WebRTC (runtime setting)
  - Audio WS: streams raw PCM (16kHz 16-bit mono) over WebSocket, receives PCM (24kHz) back
  - LiveKit: mic/speaker via WebRTC tracks (SDK-managed); text/tool events via Data Messages
  - Text SSE: device STT → HTTP SSE → client TTS
  - Handles `call_phone` tool calls: resolves contacts, initiates phone calls
  - Schedules agenda reminders as local notifications; tapping one opens a session where the agent announces the event
- See [`front/CLAUDE.md`](front/CLAUDE.md) and [`front/AI_CONTEXT.md`](front/AI_CONTEXT.md) for full details

### `agent/` — Conversational AI Agent
- **Platform:** Google Cloud Run
- **Framework:** Google ADK (Agent Development Kit)
- **Status:** Not yet implemented

### `infra/` — Infrastructure as Code
- **Stack:** Terraform / GCP
- **Status:** Not yet implemented

---

## API Contract: `front/` ↔ `agent/`

See [`front/AI_CONTEXT.md`](front/AI_CONTEXT.md) for the full message format specification.

**WebSocket transport:** `ws(s)://<ADK_BASE_URL>/run_live`. Single connection per turn, closed on `turn_complete`.

**LiveKit transport:** Flutter fetches a token via `GET <ADK_BASE_URL>/livekit-token`, joins the LiveKit Cloud room, exchanges audio via WebRTC tracks, and non-audio events via Data Messages (same JSON format as the WebSocket protocol).

**Reminders:** `GET <ADK_BASE_URL>/reminders/upcoming` returns the notifications to schedule; a tapped notification opens a session with `reminder: {event_id, date}` (WS `setup` or SSE body) so that the agent speaks first. See [`front/AI_CONTEXT.md`](front/AI_CONTEXT.md#reminders-proactive-notifications).

**End of conversation:** in live modes (WS, LiveKit), when the user says goodbye the agent sends `{"end_conversation": true}` after the goodbye turn, then closes the session; the app returns to Idle. See [`front/AI_CONTEXT.md`](front/AI_CONTEXT.md#end-of-conversation-server--client).

**Authentication:** every transport sends the Supabase access token of the signed-in user (`Authorization: Bearer` header for HTTP, `access_token` in the WebSocket `setup` message). The agent verifies it and derives the user id from it. See [`front/AI_CONTEXT.md`](front/AI_CONTEXT.md).

---

## Domain Vocabulary

| Term | Definition |
|------|-----------|
| **Live API** | Google GenAI bidi streaming API. Single WebSocket per turn — mic in, PCM + text out. |
| **VAD** | Voice Activity Detection. Handled server-side (Gemini in WS mode, livekit-agents in WebRTC mode). |
| **PCM** | Pulse-Code Modulation. Raw uncompressed audio. Input: 16kHz 16-bit mono. Output: 24kHz 16-bit mono. |
| **`turnComplete`** | Server signal that the agent has finished its response turn. In WS mode: triggers playback + disconnect. In LiveKit mode: returns to Listening (connection stays open). |
| **Reminder** | Agenda event occurrence notified on the phone. `Reminder` (server payload, with `notifyAt`) and `ReminderRef` (`eventId` + `date`, sent back to the agent) in `features/reminders/domain/entities/reminder.dart`. |
| **`LiveEvent`** | Sealed Dart union emitted by any repository: `audioChunk`, `outputTranscription`, `inputTranscription`, `callPhone`, `turnComplete`, `toolStatus`, `sessionInfo`, `sessionEstablished`, `imageUrl`, `endConversation`. |
| **`LiveMessageParser`** | Shared JSON parser used by both `WsAudioRepository` and `LiveKitAudioRepository`. Located in `data/repositories/live_message_parser.dart`. |
| **`WebRtcRepository`** | Domain interface for LiveKit transport. Distinct from `AudioRepository`: no `sendAudio()`, no mic streaming in the BLoC. |
| **`call_phone` action** | An ADK function call returned by the agent when the user requests a phone call. |
| **Disambiguation** | Flow triggered when a contact name matches multiple contacts — tool response sent back to agent. |
| **Golden test** | Screenshot regression test. 16 images (2 states × 8 device sizes). macOS only. |
| **LiveKit Cloud** | SaaS WebRTC infrastructure (signalling + media relay). Intelligence stays on the ADK server. |
| **livekit-agents** | Python SDK for building LiveKit agent workers. Handles VAD and bridges WebRTC ↔ Gemini Live API. |

