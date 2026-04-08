# AI Context — Alzheimer Assistant

> Codebase analysis for AI agents. Keep this file up-to-date after significant changes.

---

## System Overview

Voice assistant for Alzheimer's patients. The user speaks a request, the app transcribes it, sends it to an AI agent, and reads the response aloud. The app can also initiate phone calls to contacts on behalf of the user.

**Target users:** French-speaking elderly patients with Alzheimer's disease. UX must prioritize simplicity, large UI elements, and forgiving error handling.

---

## Architecture

```
┌─────────────────────────────────────────┐
│  Flutter App (front/)                   │
│                                         │
│  Mic (PCM 16kHz) ──→ WebSocket ──→ ADK │
│  ADK ──→ WebSocket ──→ PCM 24kHz → DAC │
│                     ↓                   │
│               Phone Call?               │
└────────────────┬────────────────────────┘
                 │ WebSocket (bidi)
                 ▼
┌─────────────────────────────────┐
│  ADK Agent (agent/)             │
│  Google Cloud Run               │
│  Google GenAI Live API          │
│  Server-side VAD + TTS          │
└─────────────────────────────────┘
```

---

## Components

### `front/` — Flutter Mobile App
- **Platform:** iOS, Android (web partial support)
- **Architecture:** Clean Architecture + BLoC
- **Key responsibilities:**
  - Streams raw PCM audio (16kHz 16-bit mono) from microphone to ADK over WebSocket
  - Receives PCM audio chunks (24kHz 16-bit mono) from ADK and plays them back
  - Receives text deltas from ADK and displays them as a response bubble
  - Handles `call_phone` tool calls: resolves contacts, initiates phone calls
  - Server-side VAD: Gemini detects speech boundaries — no client-side STT
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

See [`front/AI_CONTEXT.md`](front/AI_CONTEXT.md) for the full WebSocket message format specification.

**Transport:** WebSocket bidi streaming via `ws(s)://<ADK_BASE_URL>/run_live`. Single connection per interaction, closed on `turn_complete`.

---

## Domain Vocabulary

| Term | Definition |
|------|-----------|
| **Live API** | Google GenAI bidi streaming API. Single WebSocket per turn — mic in, PCM + text out. |
| **VAD** | Voice Activity Detection. Handled server-side by Gemini — no client-side speech detection. |
| **PCM** | Pulse-Code Modulation. Raw uncompressed audio. Input: 16kHz 16-bit mono. Output: 24kHz 16-bit mono. |
| **`turnComplete`** | Server signal that the agent has finished its response turn. Triggers audio playback and disconnect. |
| **`LiveEvent`** | Sealed Dart union emitted by `LiveRepository`: `audioChunk`, `textDelta`, `callPhone`, `turnComplete`. |
| **`call_phone` action** | An ADK function call returned by the agent when the user requests a phone call. |
| **Disambiguation** | Flow triggered when a contact name matches multiple contacts — tool response sent back to agent. |
| **Golden test** | Screenshot regression test. 16 images (2 states × 8 device sizes). macOS only. |

