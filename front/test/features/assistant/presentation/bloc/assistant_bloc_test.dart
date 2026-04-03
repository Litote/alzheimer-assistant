import 'dart:async';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:alzheimer_assistant/features/assistant/domain/entities/live_event.dart';
import 'package:alzheimer_assistant/features/assistant/domain/repositories/live_repository.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_bloc.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_event.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_state.dart';
import 'package:alzheimer_assistant/shared/services/microphone_stream_service.dart';
import 'package:alzheimer_assistant/shared/services/phone_call_service.dart';
import 'package:alzheimer_assistant/shared/services/settings_service.dart';
import 'package:alzheimer_assistant/shared/services/streaming_audio_player_service.dart';

// ── Mocks ──────────────────────────────────────────────────────────────────

class MockLiveRepository extends Mock implements LiveRepository {}

class MockMicrophoneStreamService extends Mock
    implements MicrophoneStreamService {}

class MockStreamingAudioPlayerService extends Mock
    implements StreamingAudioPlayerService {}

class MockPhoneCallService extends Mock implements PhoneCallService {}

class MockSettingsService extends Mock implements SettingsService {}

// ── Helpers ────────────────────────────────────────────────────────────────

/// A [LiveRepository] backed by an in-memory [StreamController].
/// The test controls exactly which events the stream emits.
class _ControllableLiveRepository implements LiveRepository {
  final _controller = StreamController<LiveEvent>.broadcast();

  int sendInterruptionCount = 0;

  void emit(LiveEvent event) => _controller.add(event);
  void done() => _controller.close();

  @override
  Stream<LiveEvent> connect({bool useElevenLabs = false}) => _controller.stream;

  @override
  void sendAudio(Uint8List pcmBytes) {}

  @override
  void sendText(String text) {}

  @override
  void sendInterruption() => sendInterruptionCount++;

  @override
  void sendToolResponse({
    required String callId,
    required String functionName,
    required String result,
  }) {}

  @override
  Future<void> disconnect() async {
    if (!_controller.isClosed) await _controller.close();
  }
}

/// Mic service whose stream is controlled by the test.
class _ControlledMicService implements MicrophoneStreamService {
  final _controller = StreamController<Uint8List>();

  void push(Uint8List data) => _controller.add(data);

  @override
  Future<Stream<Uint8List>> startStreaming() async => _controller.stream;

  @override
  Future<void> stop() async => _controller.close();

  @override
  Future<void> dispose() async {}
}

/// Mic service whose [startStreaming] always throws.
class _ThrowingMicService implements MicrophoneStreamService {
  @override
  Future<Stream<Uint8List>> startStreaming() async =>
      throw Exception('mic hardware error');

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

/// No-op [LiveRepository] for tests that don't need server interaction.
/// The stream never emits and never closes (no onDone/error triggers).
class _EmptyLiveRepository implements LiveRepository {
  final _controller = StreamController<LiveEvent>();

  @override
  Stream<LiveEvent> connect({bool useElevenLabs = false}) => _controller.stream;
  @override
  void sendAudio(Uint8List pcmBytes) {}
  @override
  void sendText(String text) {}
  @override
  void sendInterruption() {}
  @override
  void sendToolResponse({
    required String callId,
    required String functionName,
    required String result,
  }) {}
  @override
  Future<void> disconnect() async {}
}

/// Settings service that always returns defaults — no SharedPreferences needed.
class _FakeSettingsService implements SettingsService {
  @override
  Future<bool> getUseElevenLabs() async => false;

  @override
  Future<void> setUseElevenLabs(bool value) async {}
}

/// Mic service that immediately provides a stream of one silent chunk.
class _FakeMicService implements MicrophoneStreamService {
  @override
  Future<Stream<Uint8List>> startStreaming() async =>
      Stream.value(Uint8List(16));

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

AssistantBloc _makeBloc({
  LiveRepository? liveRepository,
  MicrophoneStreamService? micService,
  StreamingAudioPlayerService? audioPlayer,
  PhoneCallService? phoneCallService,
  SettingsService? settingsService,
  bool showTranscription = false,
}) =>
    AssistantBloc(
      liveRepository: liveRepository ?? _EmptyLiveRepository(),
      micService: micService ?? _FakeMicService(),
      audioPlayer: audioPlayer ?? MockStreamingAudioPlayerService(),
      showTranscription: showTranscription,
      phoneCallService: phoneCallService,
      settingsService: settingsService ?? _FakeSettingsService(),
    );

// ── Test data ──────────────────────────────────────────────────────────────

const _kText = 'Vos médicaments sont sur la table de nuit.';
final _kAudioChunk = Uint8List.fromList([1, 2, 3, 4]);
const _kTwoCandidates = <PhoneCandidate>[
  (displayName: 'Martin Jean', number: '+33611111111'),
  (displayName: 'Martin Paul', number: '+33622222222'),
];

AssistantBloc _makeBlocWithTimeout({
  required Duration responseTimeout,
  LiveRepository? liveRepository,
  MicrophoneStreamService? micService,
  StreamingAudioPlayerService? audioPlayer,
  PhoneCallService? phoneCallService,
  SettingsService? settingsService,
}) =>
    AssistantBloc(
      liveRepository: liveRepository ?? _EmptyLiveRepository(),
      micService: micService ?? _FakeMicService(),
      audioPlayer: audioPlayer ?? MockStreamingAudioPlayerService(),
      phoneCallService: phoneCallService,
      settingsService: settingsService ?? _FakeSettingsService(),
      responseTimeout: responseTimeout,
    );

void main() {
  late MockLiveRepository repository;
  late MockStreamingAudioPlayerService audioPlayer;
  late MockPhoneCallService phoneCallService;
  late MockSettingsService settingsService;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(const LiveEvent.turnComplete());
  });

  setUp(() {
    repository = MockLiveRepository();
    audioPlayer = MockStreamingAudioPlayerService();
    phoneCallService = MockPhoneCallService();
    settingsService = MockSettingsService();

    // Safe defaults — never-closing stream avoids triggering the onDone error handler.
    when(() => repository.connect(useElevenLabs: any(named: 'useElevenLabs')))
        .thenAnswer((_) => StreamController<LiveEvent>().stream);
    when(() => settingsService.getUseElevenLabs()).thenAnswer((_) async => false);
    when(() => repository.disconnect()).thenAnswer((_) async {});
    when(() => repository.sendAudio(any())).thenReturn(null);
    when(() => repository.sendText(any())).thenReturn(null);
    when(() => repository.sendToolResponse(
      callId: any(named: 'callId'),
      functionName: any(named: 'functionName'),
      result: any(named: 'result'),
    )).thenReturn(null);
    when(() => audioPlayer.hasChunks).thenReturn(false);
    when(() => audioPlayer.addChunk(any())).thenReturn(null);
    when(() => audioPlayer.stop()).thenAnswer((_) async {});
    when(() => audioPlayer.dispose()).thenAnswer((_) async {});
    when(() => audioPlayer.playAndClear(onComplete: any(named: 'onComplete')))
        .thenAnswer((_) async {});
  });

  // ── Initial state ──────────────────────────────────────────────────────────

  test('initial state is Idle', () {
    // Pass configured mocks so close() can call disconnect() without error.
    final bloc = _makeBloc(liveRepository: repository, audioPlayer: audioPlayer);
    expect(bloc.state, const AssistantState.idle());
    bloc.close();
  });

  // ── StartListening from Idle ───────────────────────────────────────────────

  blocTest<AssistantBloc, AssistantState>(
    'StartListening from Idle → Connecting then Listening',
    build: () => _makeBloc(
      liveRepository: repository,
      audioPlayer: audioPlayer,
    ),
    act: (bloc) => bloc.add(const AssistantEvent.startListening()),
    expect: () => [
      const AssistantState.connecting(),
      const AssistantState.listening(),
    ],
  );

  blocTest<AssistantBloc, AssistantState>(
    'StartListening forwards useElevenLabs=false (default) to connect()',
    build: () => _makeBloc(
      liveRepository: repository,
      audioPlayer: audioPlayer,
      settingsService: settingsService,
    ),
    act: (bloc) => bloc.add(const AssistantEvent.startListening()),
    expect: () => [
      const AssistantState.connecting(),
      const AssistantState.listening(),
    ],
    verify: (_) {
      verify(() => repository.connect(useElevenLabs: false)).called(1);
    },
  );

  blocTest<AssistantBloc, AssistantState>(
    'StartListening forwards useElevenLabs=true to connect() when setting is enabled',
    build: () {
      when(() => settingsService.getUseElevenLabs()).thenAnswer((_) async => true);
      return _makeBloc(
        liveRepository: repository,
        audioPlayer: audioPlayer,
        settingsService: settingsService,
      );
    },
    act: (bloc) => bloc.add(const AssistantEvent.startListening()),
    expect: () => [
      const AssistantState.connecting(),
      const AssistantState.listening(),
    ],
    verify: (_) {
      verify(() => repository.connect(useElevenLabs: true)).called(1);
    },
  );

  // ── StartListening from Error → Idle ──────────────────────────────────────

  blocTest<AssistantBloc, AssistantState>(
    'StartListening from Error → resets to Idle',
    build: () => _makeBloc(liveRepository: repository, audioPlayer: audioPlayer),
    seed: () => const AssistantState.error(message: 'some error'),
    act: (bloc) => bloc.add(const AssistantEvent.startListening()),
    expect: () => [const AssistantState.idle()],
  );

  // ── StartListening from Listening → Idle (cancel) ─────────────────────────

  blocTest<AssistantBloc, AssistantState>(
    'StartListening from Listening → disconnects and returns to Idle',
    build: () => _makeBloc(liveRepository: repository, audioPlayer: audioPlayer),
    seed: () => const AssistantState.listening(),
    act: (bloc) => bloc.add(const AssistantEvent.startListening()),
    expect: () => [const AssistantState.idle()],
    verify: (_) {
      // disconnect() is called at least once: once in _onStartListening and
      // once more when bloc_test closes the bloc after the test.
      verify(() => repository.disconnect()).called(greaterThan(0));
    },
  );

  // ── StartListening from Speaking → interrupts ─────────────────────────────

  blocTest<AssistantBloc, AssistantState>(
    'StartListening from Speaking → stops audio and returns to Idle',
    build: () => _makeBloc(liveRepository: repository, audioPlayer: audioPlayer),
    seed: () => const AssistantState.speaking(responseText: _kText),
    act: (bloc) => bloc.add(const AssistantEvent.startListening()),
    expect: () => [const AssistantState.idle()],
    verify: (_) {
      verify(() => audioPlayer.stop()).called(greaterThan(0));
    },
  );

  // ── LiveEvent: textDelta (ignored) ────────────────────────────────────────

  blocTest<AssistantBloc, AssistantState>(
    'liveEventReceived(textDelta) → no state change (transcriptions used instead)',
    build: () => _makeBloc(audioPlayer: audioPlayer),
    seed: () => const AssistantState.listening(),
    act: (bloc) async {
      bloc.add(const AssistantEvent.liveEventReceived(
        LiveEvent.textDelta('Bonjour '),
      ));
    },
    expect: () => [],
  );

  // ── LiveEvent: outputTranscription ────────────────────────────────────────

  blocTest<AssistantBloc, AssistantState>(
    'liveEventReceived(outputTranscription) → emits Speaking with accumulated text',
    build: () => _makeBloc(audioPlayer: audioPlayer, showTranscription: true),
    seed: () => const AssistantState.listening(),
    act: (bloc) async {
      bloc.add(const AssistantEvent.liveEventReceived(
        LiveEvent.outputTranscription('Bonjour '),
      ));
      bloc.add(const AssistantEvent.liveEventReceived(
        LiveEvent.outputTranscription('le monde.'),
      ));
    },
    expect: () => [
      const AssistantState.speaking(responseText: 'Bonjour '),
      const AssistantState.speaking(responseText: 'Bonjour le monde.'),
    ],
  );

  // ── LiveEvent: audioChunk ─────────────────────────────────────────────────

  blocTest<AssistantBloc, AssistantState>(
    'liveEventReceived(audioChunk) → buffers chunk and transitions to Speaking',
    build: () => _makeBloc(audioPlayer: audioPlayer),
    seed: () => const AssistantState.listening(),
    act: (bloc) => bloc.add(AssistantEvent.liveEventReceived(
      LiveEvent.audioChunk(_kAudioChunk),
    )),
    expect: () => [
      const AssistantState.speaking(),
    ],
    verify: (_) {
      verify(() => audioPlayer.addChunk(_kAudioChunk)).called(1);
    },
  );

  // ── LiveEvent: audioChunk while already Speaking ──────────────────────────

  blocTest<AssistantBloc, AssistantState>(
    'liveEventReceived(audioChunk) while Speaking → buffers without re-emitting',
    build: () => _makeBloc(audioPlayer: audioPlayer),
    seed: () => const AssistantState.speaking(responseText: _kText),
    act: (bloc) => bloc.add(AssistantEvent.liveEventReceived(
      LiveEvent.audioChunk(_kAudioChunk),
    )),
    expect: () => [],
    verify: (_) {
      verify(() => audioPlayer.addChunk(_kAudioChunk)).called(1);
    },
  );

  // ── LiveEvent: turnComplete with audio buffer ─────────────────────────────

  blocTest<AssistantBloc, AssistantState>(
    'liveEventReceived(turnComplete) while Speaking → back to Listening',
    build: () => _makeBloc(liveRepository: repository, audioPlayer: audioPlayer),
    seed: () => const AssistantState.speaking(responseText: _kText),
    act: (bloc) => bloc.add(const AssistantEvent.liveEventReceived(
      LiveEvent.turnComplete(),
    )),
    // In bidi streaming, turnComplete always transitions Speaking → Listening
    // so the mic stays active for the next user turn.
    expect: () => [const AssistantState.listening()],
  );

  // ── LiveEvent: turnComplete resets responseText ────────────────────────────

  test('turnComplete resets responseText so next turn starts with empty bubble', () async {
    final live = _ControllableLiveRepository();
    final player = MockStreamingAudioPlayerService();
    when(() => player.addChunk(any())).thenReturn(null);
    when(() => player.stop()).thenAnswer((_) async {});
    when(() => player.dispose()).thenAnswer((_) async {});
    when(() => player.playAndClear(onComplete: any(named: 'onComplete')))
        .thenAnswer((_) async {});

    final bloc = AssistantBloc(
      liveRepository: live,
      micService: _FakeMicService(),
      audioPlayer: player,
      showTranscription: true,
      settingsService: _FakeSettingsService(),
    );

    final states = <AssistantState>[];
    final sub = bloc.stream.listen(states.add);

    bloc.add(const AssistantEvent.startListening());
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // Turn 1
    live.emit(LiveEvent.audioChunk(_kAudioChunk));
    live.emit(const LiveEvent.outputTranscription(_kText));
    live.emit(const LiveEvent.turnComplete());
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // Turn 2 — responseText must start fresh
    live.emit(LiveEvent.audioChunk(_kAudioChunk));
    live.emit(const LiveEvent.outputTranscription('Turn 2 text'));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(states, containsAllInOrder([
      // Turn 1
      const AssistantState.speaking(),
      const AssistantState.speaking(responseText: _kText),
      const AssistantState.listening(), // turnComplete resets _responseText
      // Turn 2 — Speaking emits '' (reset), then accumulates only turn 2 text
      const AssistantState.speaking(),
      const AssistantState.speaking(responseText: 'Turn 2 text'),
    ]));

    await sub.cancel();
    await bloc.close();
  });

  // ── LiveEvent: turnComplete not in Speaking ───────────────────────────────

  blocTest<AssistantBloc, AssistantState>(
    'liveEventReceived(turnComplete) while Listening → no state change',
    build: () => _makeBloc(liveRepository: repository, audioPlayer: audioPlayer),
    seed: () => const AssistantState.listening(),
    act: (bloc) => bloc.add(const AssistantEvent.liveEventReceived(
      LiveEvent.turnComplete(),
    )),
    expect: () => [],
  );

  // ── AudioPlaybackFinished ──────────────────────────────────────────────────

  blocTest<AssistantBloc, AssistantState>(
    'audioPlaybackFinished → Listening (bidi: mic stays active)',
    build: () => _makeBloc(audioPlayer: audioPlayer),
    seed: () => const AssistantState.speaking(responseText: _kText),
    act: (bloc) =>
        bloc.add(const AssistantEvent.audioPlaybackFinished()),
    // In bidi mode, after playback the user can speak again immediately.
    expect: () => [const AssistantState.listening()],
  );

  // ── ErrorOccurred ──────────────────────────────────────────────────────────

  blocTest<AssistantBloc, AssistantState>(
    'errorOccurred → Error state',
    build: () => _makeBloc(audioPlayer: audioPlayer),
    act: (bloc) =>
        bloc.add(const AssistantEvent.errorOccurred('Connexion perdue.')),
    expect: () => [
      const AssistantState.error(message: 'Connexion perdue.'),
    ],
  );

  // ── AppResumed while Speaking ──────────────────────────────────────────────

  blocTest<AssistantBloc, AssistantState>(
    'appResumed while Speaking → stops audio and returns to Idle',
    build: () => _makeBloc(liveRepository: repository, audioPlayer: audioPlayer),
    seed: () => const AssistantState.speaking(responseText: _kText),
    act: (bloc) => bloc.add(const AssistantEvent.appResumed()),
    expect: () => [const AssistantState.idle()],
    verify: (_) {
      verify(() => audioPlayer.stop()).called(greaterThan(0));
    },
  );

  // ── AppResumed while not Speaking ─────────────────────────────────────────

  blocTest<AssistantBloc, AssistantState>(
    'appResumed while Idle → no state change but audio player still stopped (restores iOS session)',
    build: () => _makeBloc(audioPlayer: audioPlayer),
    act: (bloc) => bloc.add(const AssistantEvent.appResumed()),
    expect: () => [],
    verify: (_) {
      verify(() => audioPlayer.stop()).called(greaterThan(0));
    },
  );

  blocTest<AssistantBloc, AssistantState>(
    'appResumed while Listening → no state change but audio player stopped (restores iOS session)',
    build: () => _makeBloc(liveRepository: repository, audioPlayer: audioPlayer),
    seed: () => const AssistantState.listening(),
    act: (bloc) => bloc.add(const AssistantEvent.appResumed()),
    expect: () => [],
    verify: (_) {
      verify(() => audioPlayer.stop()).called(greaterThan(0));
    },
  );

  // ── call_phone action ──────────────────────────────────────────────────────

  blocTest<AssistantBloc, AssistantState>(
    'liveEventReceived(callPhone) — PhoneCallSuccess → sends tool response',
    build: () {
      when(() => phoneCallService.callByName(any(), exactMatch: any(named: 'exactMatch')))
          .thenAnswer((_) async => PhoneCallSuccess());
      return _makeBloc(
        liveRepository: repository,
        audioPlayer: audioPlayer,
        phoneCallService: phoneCallService,
      );
    },
    seed: () => const AssistantState.listening(),
    act: (bloc) => bloc.add(const AssistantEvent.liveEventReceived(
      LiveEvent.callPhone(
        callId: 'call-1',
        contactName: 'Jean Martin',
        exactMatch: false,
      ),
    )),
    expect: () => [],
    verify: (_) {
      verify(() => repository.sendToolResponse(
        callId: 'call-1',
        functionName: 'call_phone',
        result: any(named: 'result'),
      )).called(1);
    },
  );

  blocTest<AssistantBloc, AssistantState>(
    'liveEventReceived(callPhone) — PhoneCallAmbiguous → sends ambiguity message',
    build: () {
      when(() => phoneCallService.callByName(any(), exactMatch: any(named: 'exactMatch')))
          .thenAnswer((_) async => PhoneCallAmbiguous(_kTwoCandidates));
      return _makeBloc(
        liveRepository: repository,
        audioPlayer: audioPlayer,
        phoneCallService: phoneCallService,
      );
    },
    seed: () => const AssistantState.listening(),
    act: (bloc) => bloc.add(const AssistantEvent.liveEventReceived(
      LiveEvent.callPhone(
        callId: 'call-2',
        contactName: 'Martin',
        exactMatch: false,
      ),
    )),
    expect: () => [],
    verify: (_) {
      verify(() => repository.sendToolResponse(
        callId: 'call-2',
        functionName: 'call_phone',
        result: any(named: 'result'),
      )).called(1);
    },
  );

  // ── LiveEvent: sessionInfo ────────────────────────────────────────────────

  blocTest<AssistantBloc, AssistantState>(
    'liveEventReceived(sessionInfo) while Listening → emits Listening with welcomeText',
    build: () => _makeBloc(audioPlayer: audioPlayer),
    seed: () => const AssistantState.listening(),
    act: (bloc) => bloc.add(const AssistantEvent.liveEventReceived(
      LiveEvent.sessionInfo('Je peux vous aider avec :\n• Famille & Appels'),
    )),
    expect: () => [
      const AssistantState.listening(
        welcomeText: 'Je peux vous aider avec :\n• Famille & Appels',
      ),
    ],
  );

  blocTest<AssistantBloc, AssistantState>(
    'liveEventReceived(sessionInfo) preserves interimTranscript and statusLabel',
    build: () => _makeBloc(audioPlayer: audioPlayer),
    seed: () => const AssistantState.listening(
      interimTranscript: 'allume',
      statusLabel: 'Maison & Cuisine',
    ),
    act: (bloc) => bloc.add(const AssistantEvent.liveEventReceived(
      LiveEvent.sessionInfo('Je peux vous aider.'),
    )),
    expect: () => [
      const AssistantState.listening(
        interimTranscript: 'allume',
        statusLabel: 'Maison & Cuisine',
        welcomeText: 'Je peux vous aider.',
      ),
    ],
  );

  blocTest<AssistantBloc, AssistantState>(
    'liveEventReceived(sessionInfo) while not Listening → stores text, no state change',
    build: () => _makeBloc(audioPlayer: audioPlayer),
    seed: () => const AssistantState.speaking(),
    act: (bloc) => bloc.add(const AssistantEvent.liveEventReceived(
      LiveEvent.sessionInfo('Je peux vous aider.'),
    )),
    expect: () => [],
  );

  // ── LiveEvent: toolStatus ─────────────────────────────────────────────────

  blocTest<AssistantBloc, AssistantState>(
    'liveEventReceived(toolStatus) while Listening → emits Listening with statusLabel',
    build: () => _makeBloc(audioPlayer: audioPlayer),
    seed: () => const AssistantState.listening(),
    act: (bloc) => bloc.add(const AssistantEvent.liveEventReceived(
      LiveEvent.toolStatus('Maison & Cuisine'),
    )),
    expect: () => [
      const AssistantState.listening(statusLabel: 'Maison & Cuisine'),
    ],
  );

  blocTest<AssistantBloc, AssistantState>(
    'liveEventReceived(toolStatus) preserves interimTranscript',
    build: () => _makeBloc(audioPlayer: audioPlayer),
    seed: () => const AssistantState.listening(interimTranscript: 'allume'),
    act: (bloc) => bloc.add(const AssistantEvent.liveEventReceived(
      LiveEvent.toolStatus('Maison & Cuisine'),
    )),
    expect: () => [
      const AssistantState.listening(
        interimTranscript: 'allume',
        statusLabel: 'Maison & Cuisine',
      ),
    ],
  );

  blocTest<AssistantBloc, AssistantState>(
    'liveEventReceived(toolStatus) while not Listening → no state change',
    build: () => _makeBloc(audioPlayer: audioPlayer),
    seed: () => const AssistantState.speaking(),
    act: (bloc) => bloc.add(const AssistantEvent.liveEventReceived(
      LiveEvent.toolStatus('Maison & Cuisine'),
    )),
    expect: () => [],
  );

  // ── Full round-trip via controllable stream ───────────────────────────────

  test('full round-trip: connect → audio + transcription → turnComplete → Listening', () async {
    final live = _ControllableLiveRepository();

    final player = MockStreamingAudioPlayerService();
    when(() => player.addChunk(any())).thenReturn(null);
    when(() => player.stop()).thenAnswer((_) async {});
    when(() => player.dispose()).thenAnswer((_) async {});
    when(() => player.playAndClear(onComplete: any(named: 'onComplete')))
        .thenAnswer((_) async {});

    final bloc = AssistantBloc(
      liveRepository: live,
      micService: _FakeMicService(),
      audioPlayer: player,
      showTranscription: true,
      settingsService: _FakeSettingsService(),
    );

    final states = <AssistantState>[];
    final sub = bloc.stream.listen(states.add);

    bloc.add(const AssistantEvent.startListening());
    await Future<void>.delayed(const Duration(milliseconds: 50));

    live.emit(LiveEvent.audioChunk(_kAudioChunk));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    live.emit(const LiveEvent.outputTranscription(_kText));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    live.emit(const LiveEvent.turnComplete());
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(states, containsAllInOrder([
      const AssistantState.connecting(),
      const AssistantState.listening(),
      const AssistantState.speaking(), // audioChunk → Speaking (no text yet)
      const AssistantState.speaking(responseText: _kText), // outputTranscription
      // turnComplete: Speaking → Listening (bidi: mic stays active)
      const AssistantState.listening(),
    ]));

    await sub.cancel();
    await bloc.close();
  });

  // ── Server closes connection without responding ───────────────────────────

  test('server closes stream while Listening → AssistantError', () async {
    final live = _ControllableLiveRepository();
    final player = MockStreamingAudioPlayerService();
    when(() => player.stop()).thenAnswer((_) async {});
    when(() => player.dispose()).thenAnswer((_) async {});
    when(() => player.hasChunks).thenReturn(false);

    final bloc = AssistantBloc(
      liveRepository: live,
      micService: _FakeMicService(),
      audioPlayer: player,
      settingsService: _FakeSettingsService(),
    );

    final states = <AssistantState>[];
    final sub = bloc.stream.listen(states.add);

    bloc.add(const AssistantEvent.startListening());
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // Server closes the connection without ever sending an event.
    live.done();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(states, containsAllInOrder([
      const AssistantState.connecting(),
      const AssistantState.listening(),
      isA<AssistantError>(),
    ]));

    await sub.cancel();
    await bloc.close();
  });

  // ── LiveEvent: inputTranscription ─────────────────────────────────────────

  blocTest<AssistantBloc, AssistantState>(
    'liveEventReceived(inputTranscription) with showTranscription → emits Listening with interimTranscript',
    build: () => _makeBloc(audioPlayer: audioPlayer, showTranscription: true),
    seed: () => const AssistantState.listening(),
    act: (bloc) => bloc.add(const AssistantEvent.liveEventReceived(
      LiveEvent.inputTranscription('allume la lumière'),
    )),
    expect: () => [
      const AssistantState.listening(interimTranscript: 'allume la lumière'),
    ],
  );

  blocTest<AssistantBloc, AssistantState>(
    'liveEventReceived(inputTranscription) without showTranscription → no state change',
    build: () => _makeBloc(audioPlayer: audioPlayer, showTranscription: false),
    seed: () => const AssistantState.listening(),
    act: (bloc) => bloc.add(const AssistantEvent.liveEventReceived(
      LiveEvent.inputTranscription('allume la lumière'),
    )),
    expect: () => [],
  );

  // ── Connection error (mic throws) ─────────────────────────────────────────

  blocTest<AssistantBloc, AssistantState>(
    'mic startStreaming throws → emits AssistantError',
    build: () => _makeBloc(
      liveRepository: repository,
      audioPlayer: audioPlayer,
      micService: _ThrowingMicService(),
    ),
    act: (bloc) => bloc.add(const AssistantEvent.startListening()),
    expect: () => [
      const AssistantState.connecting(),
      isA<AssistantError>(),
    ],
  );

  // ── Interruption detection ─────────────────────────────────────────────────

  test('mic chunk with high RMS while Speaking → calls sendInterruption()', () async {
    final live = _ControllableLiveRepository();
    final mic = _ControlledMicService();
    final player = MockStreamingAudioPlayerService();
    when(() => player.addChunk(any())).thenReturn(null);
    when(() => player.stop()).thenAnswer((_) async {});
    when(() => player.dispose()).thenAnswer((_) async {});
    when(() => player.playAndClear(onComplete: any(named: 'onComplete')))
        .thenAnswer((_) async {});

    final bloc = AssistantBloc(
      liveRepository: live,
      micService: mic,
      audioPlayer: player,
      settingsService: _FakeSettingsService(),
    );

    bloc.add(const AssistantEvent.startListening());
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // Transition to Speaking via audio chunk
    live.emit(LiveEvent.audioChunk(Uint8List(4)));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(bloc.state, isA<Speaking>());

    // Push a full 3200-byte buffer with max-amplitude samples (RMS >> 3500)
    final buffer = Uint8List(3200);
    final samples = Int16List.view(buffer.buffer);
    for (var i = 0; i < samples.length; i++) {
      samples[i] = 32767;
    }
    mic.push(buffer);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(live.sendInterruptionCount, 1);

    await bloc.close();
  });

  // ── No server response within timeout ─────────────────────────────────────

  test('no server response within timeout → AssistantError', () async {
    final live = _ControllableLiveRepository();
    final player = MockStreamingAudioPlayerService();
    when(() => player.stop()).thenAnswer((_) async {});
    when(() => player.dispose()).thenAnswer((_) async {});
    when(() => player.hasChunks).thenReturn(false);

    final bloc = _makeBlocWithTimeout(
      responseTimeout: const Duration(milliseconds: 100),
      liveRepository: live,
      audioPlayer: player,
    );

    final states = <AssistantState>[];
    final sub = bloc.stream.listen(states.add);

    bloc.add(const AssistantEvent.startListening());
    // Wait long enough for the timeout to fire.
    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(states, containsAllInOrder([
      const AssistantState.connecting(),
      const AssistantState.listening(),
      isA<AssistantError>(),
    ]));

    await sub.cancel();
    await bloc.close();
  });
}

