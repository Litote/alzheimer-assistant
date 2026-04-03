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
- See [`front/CLAUDE.md`](front/CLAUDE.md) for full details

### `agent/` — Conversational AI Agent
- **Platform:** Google Cloud Run
- **Framework:** Google ADK (Agent Development Kit)
- **Status:** Not yet implemented

### `infra/` — Infrastructure as Code
- **Stack:** Terraform / GCP
- **Status:** Not yet implemented

---

## API Contract: `front/` ↔ `agent/`

### Transport

WebSocket bidi streaming via `ws(s)://<ADK_BASE_URL>/run_live`.

The Flutter app opens a single WebSocket connection per interaction and closes it when the agent's turn completes (`turn_complete: true`).

### Setup (client → server, first message)

```json
{
  "setup": {
    "app_name": "alzheimerassistant"
  }
}
```

### Audio input (client → server)

```json
{
  "realtime_input": {
    "media_chunks": [
      {
        "mime_type": "audio/pcm;rate=16000",
        "data": "<base64-encoded PCM bytes>"
      }
    ]
  }
}
```

Raw PCM chunks from the microphone (16kHz, 16-bit, mono). Server-side VAD detects speech boundaries — no end-of-speech signal needed from the client.

### Text input (client → server)

```json
{
  "client_content": {
    "turns": [{ "role": "user", "parts": [{ "text": "..." }] }],
    "turn_complete": true
  }
}
```

Used to send text messages instead of audio (e.g., disambiguation confirmations).

### Tool response (client → server)

```json
{
  "tool_response": {
    "function_responses": [
      {
        "id": "<call_id>",
        "name": "call_phone",
        "response": { "status": "<result message>" }
      }
    ]
  }
}
```

Sent after the app processes a `call_phone` tool call.

### Text delta (server → client)

```json
{
  "server_content": {
    "model_turn": {
      "parts": [{ "text": "..." }]
    }
  }
}
```

Partial text responses are accumulated into the `Speaking` state's `responseText`.

### Audio chunk (server → client)

```json
{
  "server_content": {
    "model_turn": {
      "parts": [{ "inline_data": { "mime_type": "audio/pcm;rate=24000", "data": "<base64 PCM>" } }]
    }
  }
}
```

PCM chunks (24kHz, 16-bit, mono) buffered client-side. On `turn_complete`, all chunks are assembled into a WAV file and played via `audioplayers`.

### Turn complete (server → client)

```json
{ "server_content": { "turn_complete": true } }
```

Signals the end of the agent's response. The client disconnects and starts audio playback.

### Tool call (server → client)

```json
{
  "tool_call": {
    "function_calls": [
      { "id": "<call_id>", "name": "call_phone", "args": { "name": "...", "exactMatch": true } }
    ]
  }
}
```

### `call_phone` Flow

When the agent sends a `call_phone` tool call, the front:
1. Looks up contacts matching `name`
2. If `exactMatch: true` and exactly one match → calls immediately
3. If multiple matches → sends ambiguity message back via `sendToolResponse`
4. If no match → sends error message back via `sendToolResponse`
5. On successful call → sends confirmation via `sendToolResponse`

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

---

## Flutter Toolchain

Use `flutter` and `dart` directly:

```bash
flutter pub get
flutter test test/ --exclude-tags golden
dart run build_runner build --delete-conflicting-outputs
```

---

## Configuration (Secrets)

Injected at build time via `--dart-define-from-file=secrets.json`. See `front/secrets.json.example`.

| Key | Used by |
|-----|---------|
| `ADK_BASE_URL` | Front → ADK agent WebSocket base URL (`/run_live` is appended) |

Secrets are **never** logged or committed.
