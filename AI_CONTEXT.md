# AI Context — Alzheimer Assistant

> Codebase analysis for AI agents. Keep this file up-to-date after significant changes.

---

## System Overview

Voice assistant for Alzheimer's patients. The user speaks a request, the app transcribes it, sends it to an AI agent, and reads the response aloud. The app can also initiate phone calls to contacts on behalf of the user.

**Target users:** French-speaking elderly patients with Alzheimer's disease. UX must prioritize simplicity, large UI elements, and forgiving error handling.

---

## Architecture

```
┌─────────────────────────────────┐
│  Flutter App (front/)           │
│                                 │
│  Mic → STT → ADK Agent → TTS   │
│              ↓                  │
│         Phone Call?             │
└────────────┬────────────────────┘
             │ HTTPS (SSE)
             ▼
┌─────────────────────────────────┐
│  ADK Agent (agent/)             │
│  Google Cloud Run               │
│  Conversational AI              │
└─────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────┐
│  ElevenLabs TTS API             │
│  Text → MP3 audio bytes         │
└─────────────────────────────────┘
```

---

## Components

### `front/` — Flutter Mobile App
- **Platform:** iOS, Android (web partial support)
- **Architecture:** Clean Architecture + BLoC
- **Key responsibilities:**
  - Speech-to-text (French, device-native via `speech_to_text`)
  - Sends user message to ADK agent via SSE
  - Receives text response + optional `call_phone` action
  - Converts text to speech via ElevenLabs (MP3 playback)
  - Resolves and initiates phone calls via device contacts
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

### Session Management

```
POST /apps/alzheimerassistant/users/user/sessions
→ { id: string }
```

Session ID is cached in `SharedPreferences`. If the agent restarts and returns 404 on `/run_sse`, the front clears the session and creates a new one (transparent retry).

### Query (SSE)

```
POST /run_sse
Body: {
  app_name: "alzheimerassistant",
  user_id: "user",
  session_id: string,
  new_message: {
    role: "user",
    parts: [{ text: string }]
  },
  streaming: false
}
```

**Response:** Server-Sent Events stream. Each event is a JSON object. The front extracts:
- `content.parts[].text` — model text fragments (concatenated into final response)
- `actions[].function_call.name == "call_phone"` with `args.contact_name: string`

### `call_phone` Action

When the agent determines the user wants to call someone, it returns a function call action with `contact_name`. The front then:
1. Looks up contacts matching the name
2. If exactly one match → calls immediately
3. If multiple matches → enters disambiguation flow (asks user to confirm)
4. Calls `flutter_phone_direct_caller` with the resolved number

---

## Domain Vocabulary

| Term | Definition |
|------|-----------|
| **Session** | An ADK conversation session scoped to a user. Cached between app launches. |
| **STT** | Speech-to-Text. Device-native recognition, French (`fr_FR`) locale. |
| **TTS** | Text-to-Speech. ElevenLabs API converts agent text response to MP3 bytes. |
| **`call_phone` action** | An ADK function call returned by the agent when the user requests a phone call. |
| **Disambiguation** | Flow triggered when a contact name matches multiple contacts — user must confirm. |
| **Golden test** | Screenshot regression test. 16 images (2 states × 8 device sizes). macOS only. |

---

## Configuration (Secrets)

Injected at build time via `--dart-define-from-file=secrets.json`. See `front/secrets.json.example`.

| Key | Used by |
|-----|---------|
| `ADK_BASE_URL` | Front → ADK agent base URL |
| `ELEVENLABS_API_KEY` | Front → ElevenLabs TTS authentication |
| `ELEVENLABS_VOICE_ID` | Front → ElevenLabs voice selection |

Secrets are **never** logged or committed.

---

## CI/CD

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| `front-ci` | push/PR on `front/**` | Analyze, unit+widget tests, golden tests (macOS), build Android+iOS |
| `front-e2e` | push/PR on `front/**` | E2E tests on iOS simulator |
| `front-update-goldens` | Manual | Regenerates golden screenshots and commits them |
