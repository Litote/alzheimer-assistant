# AI Context — Front (Flutter)

> Front-specific context for AI agents. See [`../AI_CONTEXT.md`](../AI_CONTEXT.md) for system-wide context.

---

## Transport modes

Three transport modes are available, selected at runtime via `SettingsService`:

| Mode | Setting | Repository | Audio path |
|------|---------|-----------|-----------|
| Audio WS | `useLiveKit=false`, `useTextMode=false` | `WsAudioRepository` | PCM mic → WebSocket → ADK → PCM → local player |
| Text SSE | `useLiveKit=false`, `useTextMode=true` | `SseTextRepository` | STT → HTTP SSE → ADK → TTS |
| LiveKit WebRTC | `useLiveKit=true` | `LiveKitAudioRepository` | WebRTC mic track → LiveKit Cloud → ADK agent → WebRTC audio track |

---

## API Contract: `front/` ↔ `agent/`

### Transport — WebSocket (modes Audio WS and Text SSE)

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

## API Contract: `front/` ↔ `agent/` — LiveKit WebRTC mode

### Overview

In LiveKit mode, audio flows via WebRTC tracks managed by the `livekit_client` SDK.
Non-audio events (text, tool calls, turn_complete, etc.) transit as **Data Messages** in the **same JSON format** as the WebSocket transport above. The `LiveMessageParser` class (`data/repositories/live_message_parser.dart`) is shared between both transports.

### Connection setup

1. Flutter calls `GET <ADK_BASE_URL>/livekit-token`
2. ADK server responds with `{ "url": "wss://...", "token": "<JWT>", "room": "<room-name>" }`
3. Flutter joins the LiveKit room via `Room.connect(url, token)`
4. Flutter enables the microphone: `localParticipant.setMicrophoneEnabled(true)`
5. Audio flows automatically via `LocalAudioTrack` (Flutter → LiveKit Cloud → ADK agent)
6. ADK agent publishes its audio response as a `RemoteAudioTrack` (ADK agent → LiveKit Cloud → Flutter, played automatically by the SDK)

The Flutter client does **not** capture raw PCM or manage audio buffers in this mode.

### Client → server (Data Messages)

Interruption signal:
```json
{ "client_content": { "interrupted": true } }
```

Tool response (same format as WebSocket):
```json
{
  "tool_response": {
    "function_responses": [
      { "id": "<call_id>", "name": "call_phone", "response": { "status": "<result>" } }
    ]
  }
}
```

### Server → client (Data Messages)

Same JSON format as the WebSocket transport: `server_content`, `tool_call`, `output_transcription`, `input_transcription`, `tool_status`, `session_info`, `image_url`.

**Audio chunks are NOT sent via Data Messages** — audio flows via `RemoteAudioTrack`.

### Turn lifecycle in LiveKit mode

```
Flutter joins room → Listening state
Agent speaks       → RemoteAudioTrack plays automatically + outputTranscription → Speaking state
turn_complete DM   → back to Listening state (connection stays open)
User re-speaks     → VAD (server-side, livekit-agents) detects speech → new agent turn
```

Unlike WebSocket mode, the connection **stays open** between turns. `turn_complete` returns to `Listening`, not `Idle`.

### VAD

Voice Activity Detection is handled server-side by the `livekit-agents` framework. The Flutter client does not implement VAD — it just streams the mic track continuously.

---

## Expected ADK server behavior for LiveKit mode

The ADK server must expose two new endpoints/processes:

### 1. `GET /livekit-token`

Returns a signed LiveKit JWT for the Flutter client to join the room.

```python
from livekit.api import AccessToken, VideoGrants

@app.get("/livekit-token")
def livekit_token():
    token = (
        AccessToken(LIVEKIT_API_KEY, LIVEKIT_API_SECRET)
        .with_grants(VideoGrants(room_join=True, room="alzheimer-room"))
        .to_jwt()
    )
    return {"url": LIVEKIT_URL, "token": token, "room": "alzheimer-room"}
```

`LIVEKIT_API_KEY`, `LIVEKIT_API_SECRET`, `LIVEKIT_URL` must be set as Cloud Run secrets. They are **never** sent to the Flutter client.

### 2. LiveKit Agent Worker

A `livekit-agents` Python worker that:

1. Connects to LiveKit Cloud using the same API key/secret
2. Waits for a participant to join the room
3. On join: opens a Gemini Live API session
4. Receives audio from the Flutter `LocalAudioTrack` → forwards to Gemini
5. Receives audio response from Gemini → publishes as `RemoteAudioTrack`
6. Receives text/tool events from Gemini → publishes as Data Messages (same JSON format as the existing WebSocket protocol)
7. On `turn_complete`: publishes `{ "server_content": { "turn_complete": true } }` as a Data Message, then stays connected for the next turn

```python
from livekit.agents import WorkerOptions, cli, JobContext
from livekit.agents.voice import VoiceAgent

async def entrypoint(ctx: JobContext):
    await ctx.connect()
    # Bridge: LiveKit audio ↔ Gemini Live API
    agent = VoiceAgent(...)
    agent.start(ctx.room)
    # Forward Gemini tool_call / transcription / turn_complete as Data Messages
    # using the same JSON keys as the existing WebSocket protocol

cli.run_app(WorkerOptions(entrypoint_fnc=entrypoint))
```

### Key differences from WebSocket mode

| Aspect | WebSocket mode | LiveKit WebRTC mode |
|--------|---------------|-------------------|
| Audio client → server | Base64 PCM over JSON | WebRTC LocalAudioTrack |
| Audio server → client | Base64 PCM over JSON | WebRTC RemoteAudioTrack |
| Text/tool events | Same WebSocket | Data Messages (same JSON) |
| Connection lifetime | One connection per turn | Persistent across turns |
| VAD | Gemini server-side | livekit-agents server-side |
| Turn end | Client disconnects | Client stays, returns to Listening |

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

Injected at build time via `--dart-define-from-file=secrets.json`. See `secrets.json.example`.

| Key | Used by |
|-----|---------|
| `ADK_BASE_URL` | Base URL for all ADK endpoints : `/run_live` (WebSocket audio), `/run_sse` (text), `/livekit-token` (LiveKit token fetch) |
| `ELEVENLABS_API_KEY` | ElevenLabs client-side TTS (text mode only) |
| `ELEVENLABS_VOICE_ID` | ElevenLabs voice identifier |

`ELEVENLABS_TTS_MODEL` is optional (defaults to `eleven_flash_v2_5`).

The LiveKit URL and room token are **not** dart-defines — they are returned dynamically by `GET <ADK_BASE_URL>/livekit-token` at runtime, so the LiveKit API keys never reach the Flutter client.

Secrets are **never** logged or committed.
