# AI Context — Alzheimer Assistant

> Codebase analysis for AI agents. Keep this file up-to-date after significant changes.

---

## System Overview

Voice assistant for Alzheimer's patients. The user speaks a request, the app transcribes it, sends it to an AI agent, and reads the response aloud. The app can also initiate phone calls to contacts on behalf of the user.

The user can also tell their life as conversations go ("life stories"): the agent keeps these memories, tells them back on request, and relatives read and listen to them in the caregiver back-office.

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

**Phone calls (prototype, no app involved)**
```
Cloud Scheduler ──→ POST /phone/calls/run ──→ Agent ──→ Telnyx Call Control (dial) ──→ landline of the user
Telnyx ──→ WebSocket /phone_stream (media stream) ──→ same live session as /run_live
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
  - Handles `call_phone` tool calls: resolves contacts, initiates phone calls; on ambiguity, shows the candidates as tappable cards
  - Schedules agenda reminders as local notifications; tapping one opens a session where the agent announces the event
  - Settings screen: lets the user turn the keeping of their life stories, and of their voice, on and off
  - Walking guidance: sends the position of the phone while the agent guides the user on foot to a familiar place, and shows the current step
- See [`front/AGENTS.md`](front/AGENTS.md) and [`front/AI_CONTEXT.md`](front/AI_CONTEXT.md) for full details

### `agent/` — Conversational AI Agent
- **Platform:** Google Cloud Run
- **Framework:** Google ADK (Agent Development Kit)
- **Status:** Implemented in a separate repository; will be migrated into `agent/`

### `infra/` — Infrastructure as Code
- **Stack:** Terraform / GCP
- **Status:** Not yet implemented

---

## API Contract: `front/` ↔ `agent/`

See [`front/AI_CONTEXT.md`](front/AI_CONTEXT.md) for the full message format specification.

**WebSocket transport:** `ws(s)://<ADK_BASE_URL>/run_live`. The connection stays open across turns; it closes when the user stops the session or after `end_conversation`.

**LiveKit transport:** Flutter fetches a token via `GET <ADK_BASE_URL>/livekit-token`, joins the LiveKit Cloud room, exchanges audio via WebRTC tracks, and non-audio events via Data Messages (same JSON format as the WebSocket protocol).

**Reminders:** `GET <ADK_BASE_URL>/reminders/upcoming` returns the notifications to schedule; a tapped notification opens a session with `reminder: {event_id, date}` (WS `setup` or SSE body) so that the agent speaks first. See [`front/AI_CONTEXT.md`](front/AI_CONTEXT.md#reminders-proactive-notifications).

**End of conversation:** in live modes (WS, LiveKit), when the user says goodbye the agent sends `{"end_conversation": true}` after the goodbye turn, then closes the session; the app returns to Idle. The agent does the same, without a goodbye, when nobody has spoken for 3 minutes. See [`front/AI_CONTEXT.md`](front/AI_CONTEXT.md#end-of-conversation-server--client).

**Life stories:** the app has no dedicated screen or session message; its settings screen reads and changes the consent through `GET` / `PUT <ADK_BASE_URL>/life-stories/settings` (`{capture_enabled, keep_audio}`), the same settings the caregiver changes in the back-office. In live modes (WS, LiveKit) the agent keeps the transcript of the session and, when the session ends, extracts the memories the user told into the Supabase table `life_stories`; with the caregiver's consent the matching microphone audio is stored server-side as well. The transcript is also saved as the session goes (`life_story_drafts`), so that a session that never closes properly is extracted later, without the audio. Capture is opt-in per user (`life_story_settings`) and read when a session opens, so a change applies to the next session; when enabled, the `session_info` welcome text lists "Vos souvenirs". The agent reads memories back through its `recall_life_stories` tool in every mode. In WebSocket mode only, when the user asks to hear their own voice again, its `play_life_story_recording` tool sends the stored recording as ordinary `audio/pcm;rate=24000` chunks, like the assistant voice (the app needs no change), with the mic muted meanwhile; it plays nothing when the voice consent is off. Text SSE mode does not capture.

**Walking guidance:** in WebSocket mode only, the user can ask to be guided on foot to a place the caregiver allowed (`places.guidance_enabled`, set in the back-office). The agent's `start_guidance` tool asks the app for the position of the phone (`tool_call` `get_location`), computes a walking route (Google Routes API) and sends `{"guidance": {active, destination, instruction, maneuver, distance_m}}` (first "Je cherche où vous êtes…" while the position is not accurate enough for a route); while `active`, the app sends `{"location": {lat, lng, accuracy, heading?, heading_accuracy?, speed?}}` as the user walks (heading = GPS direction of the walk). The server alone decides when the next instruction is due and what it says: the model only repeats it, and the app shows the server's text. Positions are never stored. See [`front/AI_CONTEXT.md`](front/AI_CONTEXT.md#walking-guidance).

**Phone calls (prototype):** the agent can call the user on their landline through Telnyx: a morning call (day, date, programme of the day) and reminder calls for the events the caregiver flagged (`events.phone_call`, at the time of the event's reminder), then talk as in the app. The caregiver sets them in the back-office (Events page): consent and number, optional morning call time and days — no time, no morning call (`phone_call_settings`); every call is logged in `phone_call_log`, which also keeps a call from being placed twice. When an answering machine answers (Telnyx answering machine detection, reported to the agent's `POST /phone_events`), the agent hangs up without a message and logs the call as `machine`. A call that reached nobody (no answer, answering machine, dialling refused) is placed again 10 minutes later, up to the number of calls the caregiver chose (`phone_call_settings.max_attempts`, 1–5, default 3; one `phone_call_log` row per attempt); when the last one fails too, the agent sends the caregiver an SMS through Telnyx Messaging (`caregiver_phone_number`, optional, a French mobile), once. The call speaks with the user's ElevenLabs voice, whatever `USE_ELEVENLABS` says. Cloud Scheduler asks the agent every 5 minutes for the calls due (`POST /phone/calls/run`); the back-office can ask for a test call through `alzheimer-assistant-backagent` (`POST /phone/calls/test`), both behind a shared secret. Telnyx streams the call audio to the agent's `WS /phone_stream` (enabled by `ENABLE_PHONE=true`; a signed token in the call's Telnyx `client_state`, never in the URL, names the user and why they are called), which runs the same live session as `/run_live`; `call_phone` and walking guidance are unavailable on a call. No contract with `front/`: the app is not involved. See the agent README, « Appels téléphoniques ».

**Authentication:** every transport sends the Supabase access token of the signed-in user (`Authorization: Bearer` header for HTTP, `access_token` in the WebSocket `setup` message). The agent verifies it and derives the user id from it. See [`front/AI_CONTEXT.md`](front/AI_CONTEXT.md).

---

## Domain Vocabulary

| Term | Definition |
|------|-----------|
| **Live API** | Google GenAI bidi streaming API. One WebSocket per session — mic in, PCM + text out. |
| **VAD** | Voice Activity Detection. Handled server-side (Gemini in WS mode, livekit-agents in WebRTC mode). |
| **PCM** | Pulse-Code Modulation. Raw uncompressed audio. Input: 16kHz 16-bit mono. Output: 24kHz 16-bit mono. |
| **`turnComplete`** | Server signal that the agent has finished its response turn. In WS and LiveKit modes: returns to Listening (connection stays open). In Text SSE mode: triggers TTS of the accumulated text. |
| **Reminder** | Agenda event occurrence notified on the phone. `Reminder` (server payload, with `notifyAt`) and `ReminderRef` (`eventId` + `date`, sent back to the agent) in `features/reminders/domain/entities/reminder.dart`. |
| **Life story** | A memory of their life told by the user ("souvenir"). Extracted by the agent at the end of a live session (title, summary, user's own words, the exchange with the assistant's questions, optional voice recording); a retelling is linked to the original (`duplicate_of`). Stored in Supabase, not in the app. |
| **Guidance** | A walk guided step by step to a familiar place. `Guidance` (`features/assistant/domain/entities/guidance.dart`) is the step shown on screen: destination, exact instruction of the routing service, manoeuvre, distance. Carried by the `Listening` and `Speaking` states. |
| **`LiveEvent`** | Sealed Dart union emitted by any repository: `audioChunk`, `textDelta`, `interrupted`, `outputTranscription`, `inputTranscription`, `callPhone`, `turnComplete`, `toolStatus`, `sessionInfo`, `sessionEstablished`, `imageUrl`, `endConversation`, `locationRequested`, `guidanceChanged`. |
| **`LiveMessageParser`** | Shared JSON parser used by both `WsAudioRepository` and `LiveKitAudioRepository`. Located in `data/repositories/live_message_parser.dart`. |
| **`WebRtcRepository`** | Domain interface for LiveKit transport. Distinct from `AudioRepository`: no `sendAudio()`, no mic streaming in the BLoC. |
| **`call_phone` action** | An ADK function call returned by the agent when the user requests a phone call. |
| **Disambiguation** | Flow triggered when a contact name matches multiple contacts — tool response sent back to agent, and the candidates shown on screen (`contactChoices` state field, `ContactChoiceList`) so the user can tap one or answer by voice. |
| **Golden test** | Screenshot regression test (home screen states and permission onboarding, 8 device sizes each). macOS only. |
| **LiveKit Cloud** | SaaS WebRTC infrastructure (signalling + media relay). Intelligence stays on the ADK server. |
| **livekit-agents** | Python SDK for building LiveKit agent workers. Handles VAD and bridges WebRTC ↔ Gemini Live API. |

