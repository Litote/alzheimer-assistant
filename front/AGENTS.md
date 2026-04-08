
# Front — Flutter (Alzheimer Assistant)

> Flutter mobile application — voice interface for Alzheimer's patients.
> Global rules: see [`../AGENTS.md`](../AGENTS.md) and [`../AI_CONTEXT.md`](../AI_CONTEXT.md).

---

## Commands

```bash
# Dependencies
flutter pub get

# Code generation (freezed, json_serializable) — run after model changes
dart run build_runner build --delete-conflicting-outputs

# Lint
flutter analyze

# Unit + widget tests (Linux-safe, excludes goldens)
flutter test test/ --exclude-tags golden

# Golden tests — macOS only (text rendering differs on Linux)
flutter test test/golden/ --tags golden

# Regenerate golden screenshots — macOS only
flutter test test/golden/ --update-goldens --tags golden

# E2E tests — requires iOS simulator
flutter test integration_test/app_e2e_test.dart -d <device-id>

# Build (requires secrets.json — see secrets.json.example)
flutter build apk --release --dart-define-from-file=secrets.json
flutter build ios --no-codesign --simulator --debug --dart-define-from-file=secrets.json
```

**Important:** Golden tests are generated on macOS and validated on macOS. Never run `--update-goldens` on Linux — it will produce different pixel output and break CI.

---

## Architecture

```
lib/
├── main.dart                  # Entry point — validates secrets, locks portrait
├── app/
│   ├── app.dart               # Root widget, BlocProvider setup
│   ├── router.dart            # GoRouter (single route: '/' → HomeScreen)
│   └── theme.dart             # Material 3, accessibility-first color palette
├── core/
│   └── constants/             # API URLs, dart-define config (AppConstants)
├── features/assistant/
│   ├── domain/
│   │   ├── entities/          # LiveEvent sealed union (audioChunk, textDelta, callPhone, turnComplete)
│   │   └── repositories/      # Abstract LiveRepository interface
│   ├── data/
│   │   └── repositories/      # LiveRepositoryImpl — WebSocket bidi streaming
│   └── presentation/
│       ├── bloc/              # AssistantBloc, AssistantEvent, AssistantState
│       ├── screens/           # HomeScreen
│       └── widgets/           # MicButton, ResponseBubble
└── shared/services/
    ├── microphone_stream_service.dart         # PCM mic capture (16kHz, record package)
    ├── streaming_audio_player_service.dart    # PCM chunk buffer → WAV → audioplayers
    └── phone_call_service.dart               # Contact lookup + direct call
```

**Layer rules:**
- `domain/` has zero Flutter/external dependencies — pure Dart
- `data/` depends on `domain/` only (no presentation)
- `presentation/` depends on `domain/` only (no data — injected via BlocProvider)
- `shared/services/` are injected into the BLoC constructor (testable)

---

## State Management (BLoC)

**States** (sealed Freezed union):
```
Idle            — waiting for user input
Connecting      — WebSocket being established
Listening       — mic streaming, waiting for agent response
Speaking        — agent responding (text + audio)
AssistantError  — unrecoverable error, shows message
```

**Events → States flow:**
```
StartListening (from Idle)      → Connecting → Listening
StartListening (from Listening) → Idle (cancel, disconnect)
StartListening (from Speaking)  → Idle (interrupt, stop audio)
StartListening (from Error)     → Idle (reset)

liveEventReceived(textDelta)    → Speaking(responseText accumulated)
liveEventReceived(audioChunk)   → Speaking (chunk buffered, state emitted once)
liveEventReceived(callPhone)    → calls PhoneCallService, sends tool response (no state change)
liveEventReceived(turnComplete) → if hasChunks: playAndClear → AudioPlaybackFinished → Idle
                                  else: → Idle immediately

audioPlaybackFinished           → Idle
errorOccurred                   → AssistantError
appResumed (while Speaking)     → Idle (handles Android dialer backgrounding)
```

**Key rule:** All state is immutable (Freezed sealed union types). No mutable fields outside services.

---

## Conventions

**Immutability:**
- Use `final` for all fields
- Use Freezed for all data classes, events, and states
- Use `const` constructors for stateless widgets

**Visibility:**
- Private by convention: `_prefixName` for internal fields and methods
- No explicit `public` keyword (Dart default)

**Imports:** Single imports only — no `show X, Y` patterns

**Code generation:** Every model change requires re-running `build_runner`. Generated files (`.freezed.dart`, `.g.dart`) are committed to the repo.

**Secrets:** Injected via `--dart-define-from-file=secrets.json` at build time. Never hardcode. See `secrets.json.example` for required keys.

**Error messages:** User-facing strings are in French (target users are French-speaking elderly patients).

**Comments:** In English (as per global AGENTS.md rule).

---

## Testing Rules

- **Bug fix flow:** write a failing test first, then fix the bug
- **New logic:** always add a corresponding test
- **Mocking:** use `mocktail` (not `mockito`)
- **BLoC tests:** use `bloc_test` package (`blocTest<>` helper)
- **Repository tests:** mock Dio with in-memory interceptors (see existing tests for pattern)
- **E2E fake services:** `FakeLiveRepository`, `FakeMicrophoneStreamService`, `ManualFakeStreamingAudioPlayerService` — reuse, don't duplicate
- **Repository tests:** use `_FakeChannel` (implements `WebSocketChannel`) — see `live_repository_impl_test.dart`

---

## Key Dependencies

| Package | Purpose |
|---------|---------|
| `flutter_bloc` | BLoC state management |
| `go_router` | Declarative routing |
| `freezed` | Immutable data classes + sealed union types |
| `json_serializable` | JSON serialization |
| `web_socket_channel` | WebSocket bidi transport for Live API |
| `record` | Microphone PCM capture (16kHz 16-bit mono) |
| `audioplayers` | WAV playback of buffered PCM chunks |
| `path_provider` | Temp directory for WAV files |
| `flutter_contacts` | Contact lookup |
| `flutter_phone_direct_caller` | Initiate phone calls |
| `bloc_test` + `mocktail` | Testing utilities |


## SonarCloud Workflow

To check the quality gate from an agent session:

1. Run `./gradlew allSonar` from the repo root (runs all checks with coverage then uploads results).
2. Use the `sonarqube` MCP server (configured in Claude Code) to query the gate status —
3. The gate passes when `new_coverage ≥ 80%`, `new_duplicated_lines_density ≤ 3%`, ratings all A, hotspots reviewed 100%.
---
