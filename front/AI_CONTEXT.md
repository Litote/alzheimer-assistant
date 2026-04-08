# AI Context — Front (Flutter)

> Front-specific context for AI agents. See [`../AI_CONTEXT.md`](../AI_CONTEXT.md) for system-wide context.

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
| `ADK_BASE_URL` | Front → ADK agent WebSocket base URL (`/run_live` is appended) |

Secrets are **never** logged or committed.
