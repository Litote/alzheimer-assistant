import 'dart:async';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:alzheimer_assistant/features/assistant/domain/entities/live_event.dart';
import 'package:alzheimer_assistant/features/assistant/domain/repositories/audio_repository.dart';
import 'package:alzheimer_assistant/features/assistant/domain/repositories/text_repository.dart';
import 'package:alzheimer_assistant/features/assistant/domain/repositories/webrtc_repository.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_bloc.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_event.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_state.dart';
import 'package:alzheimer_assistant/shared/services/client_tts_service.dart';
import 'package:alzheimer_assistant/shared/services/microphone_stream_service.dart';
import 'package:alzheimer_assistant/shared/services/phone_call_service.dart';
import 'package:alzheimer_assistant/shared/services/settings_service.dart';
import 'package:alzheimer_assistant/shared/services/speech_recognition_service.dart';
import 'package:alzheimer_assistant/shared/services/streaming_audio_player_service.dart';

// ── Mocks ──────────────────────────────────────────────────────────────────

class MockAudioRepository extends Mock implements AudioRepository {}

class MockMicrophoneStreamService extends Mock
    implements MicrophoneStreamService {}

class MockStreamingAudioPlayerService extends Mock
    implements StreamingAudioPlayerService {}

class MockPhoneCallService extends Mock implements PhoneCallService {}

class MockWebRtcRepository extends Mock implements WebRtcRepository {}

class MockSettingsService extends Mock implements SettingsService {}

class MockSpeechRecognitionService extends Mock
    implements SpeechRecognitionService {}

class MockClientTtsService extends Mock implements ClientTtsService {}

// ── Controllable repository (implements both interfaces for testing) ────────

/// In-memory repository that can act as either an [AudioRepository] or a
/// [TextRepository]. Tests control exactly which events the stream emits.
class _ControllableRepository implements AudioRepository, TextRepository {
  final _controller = StreamController<LiveEvent>.broadcast();

  int sendInterruptionCount = 0;
  int sendAudioCount = 0;
  String? lastConnectedSessionId;
  final List<String> sentTexts = [];

  void emit(LiveEvent event) => _controller.add(event);
  void done() => _controller.close();

  @override
  Stream<LiveEvent> connect({
    bool useElevenLabs = false,
    String? sessionId,
  }) {
    lastConnectedSessionId = sessionId;
    return _controller.stream;
  }

  @override
  void sendAudio(Uint8List pcmBytes) => sendAudioCount++;

  @override
  void sendText(String text) => sentTexts.add(text);

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

/// No-op repository that implements both interfaces — never emits, never closes.
class _EmptyRepository implements AudioRepository, TextRepository {
  final _controller = StreamController<LiveEvent>();

  @override
  Stream<LiveEvent> connect({
    bool useElevenLabs = false,
    String? sessionId,
  }) =>
      _controller.stream;

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

/// Repository backed by an externally-owned broadcast controller.
/// disconnect() is a no-op so the stream stays open between exchanges,
/// allowing the BLoC to re-subscribe for a second turn.
class _PersistentRepository implements AudioRepository, TextRepository {
  _PersistentRepository(this._controller);

  final StreamController<LiveEvent> _controller;

  @override
  Stream<LiveEvent> connect({bool useElevenLabs = false, String? sessionId}) =>
      _controller.stream;

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

// ── Mic service helpers ────────────────────────────────────────────────────

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

class _ThrowingMicService implements MicrophoneStreamService {
  @override
  Future<Stream<Uint8List>> startStreaming() async =>
      throw Exception('mic hardware error');

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

class _FakeMicService implements MicrophoneStreamService {
  @override
  Future<Stream<Uint8List>> startStreaming() async =>
      Stream.value(Uint8List(16));

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

// ── Settings service helpers ───────────────────────────────────────────────

class _FakeSettingsService implements SettingsService {
  _FakeSettingsService({this.textMode = false});
  final bool textMode;

  @override
  Future<bool> getUseElevenLabs() async => false;

  @override
  Future<void> setUseElevenLabs(bool value) async {}

  @override
  Future<bool> getUseTextMode() async => textMode;

  @override
  Future<void> setUseTextMode(bool value) async {}

  @override
  Future<bool> getUseLiveKit() async => false;

  @override
  Future<void> setUseLiveKit(bool value) async {}
}

class _MutableFakeSettingsService implements SettingsService {
  _MutableFakeSettingsService({
    bool textMode = false,
    bool useElevenLabs = false,
  })  : _textMode = textMode,
        _useElevenLabs = useElevenLabs;

  bool _textMode;
  bool _useElevenLabs;

  // ignore: avoid_setters_without_getters
  set textMode(bool v) => _textMode = v;
  // ignore: avoid_setters_without_getters
  set useElevenLabs(bool v) => _useElevenLabs = v;

  @override
  Future<bool> getUseElevenLabs() async => _useElevenLabs;

  @override
  Future<void> setUseElevenLabs(bool value) async {}

  @override
  Future<bool> getUseTextMode() async => _textMode;

  @override
  Future<void> setUseTextMode(bool value) async {}

  @override
  Future<bool> getUseLiveKit() async => false;

  @override
  Future<void> setUseLiveKit(bool value) async {}
}

/// Settings: useElevenLabs=true, textMode=true.
class _ElevenLabsTextSettingsService implements SettingsService {
  @override
  Future<bool> getUseElevenLabs() async => true;

  @override
  Future<void> setUseElevenLabs(bool value) async {}

  @override
  Future<bool> getUseTextMode() async => true;

  @override
  Future<void> setUseTextMode(bool value) async {}

  @override
  Future<bool> getUseLiveKit() async => false;

  @override
  Future<void> setUseLiveKit(bool value) async {}
}

// ── Speech recognition service helper ─────────────────────────────────────

class _ControllableSpeechService implements SpeechRecognitionService {
  void Function(String)? onInterim;
  void Function(String)? onFinal;
  void Function()? onTimeout;

  bool stopCalled = false;
  int startListeningCount = 0;

  void emitInterim(String text) => onInterim?.call(text);
  void emitFinal(String text) => onFinal?.call(text);
  void emitTimeout() => onTimeout?.call();

  @override
  Future<bool> initialize() async => true;

  @override
  Future<void> startListening({
    required void Function(String text) onInterim,
    required void Function(String text) onFinal,
    void Function()? onTimeout,
  }) async {
    startListeningCount++;
    this.onInterim = onInterim;
    this.onFinal = onFinal;
    this.onTimeout = onTimeout;
  }

  @override
  Future<void> stopListening() async {
    stopCalled = true;
  }

  @override
  bool get isListening => false;
}

// ── TTS helper ─────────────────────────────────────────────────────────────

class _NoOpClientTtsService implements ClientTtsService {
  @override
  Future<void> speak(String text, {required void Function() onComplete}) async =>
      onComplete();

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

/// Settings with LiveKit enabled (textMode=false).
class _FakeLiveKitSettingsService implements SettingsService {
  @override
  Future<bool> getUseElevenLabs() async => false;

  @override
  Future<void> setUseElevenLabs(bool value) async {}

  @override
  Future<bool> getUseTextMode() async => false;

  @override
  Future<void> setUseTextMode(bool value) async {}

  @override
  Future<bool> getUseLiveKit() async => true;

  @override
  Future<void> setUseLiveKit(bool value) async {}
}


// ── BLoC factory helpers ───────────────────────────────────────────────────

AssistantBloc _makeBloc({
  AudioRepository? audioRepository,
  TextRepository? textRepository,
  MicrophoneStreamService? micService,
  StreamingAudioPlayerService? audioPlayer,
  PhoneCallService? phoneCallService,
  SettingsService? settingsService,
  bool showTranscription = false,
}) {
  final repo = _EmptyRepository();
  return AssistantBloc(
    audioRepository: audioRepository ?? repo,
    textRepository: textRepository ?? repo,
    micService: micService ?? _FakeMicService(),
    audioPlayer: audioPlayer ?? MockStreamingAudioPlayerService(),
    showTranscription: showTranscription,
    phoneCallService: phoneCallService,
    settingsService: settingsService ?? _FakeSettingsService(),
    elevenLabsTtsService: _NoOpClientTtsService(),
    nativeTtsService: _NoOpClientTtsService(),
  );
}

AssistantBloc _makeBlocWithTimeout({
  required Duration responseTimeout,
  AudioRepository? audioRepository,
  TextRepository? textRepository,
  MicrophoneStreamService? micService,
  StreamingAudioPlayerService? audioPlayer,
  PhoneCallService? phoneCallService,
  SettingsService? settingsService,
}) {
  final repo = _EmptyRepository();
  return AssistantBloc(
    audioRepository: audioRepository ?? repo,
    textRepository: textRepository ?? repo,
    micService: micService ?? _FakeMicService(),
    audioPlayer: audioPlayer ?? MockStreamingAudioPlayerService(),
    phoneCallService: phoneCallService,
    settingsService: settingsService ?? _FakeSettingsService(),
    responseTimeout: responseTimeout,
  );
}

// ── Test data ──────────────────────────────────────────────────────────────

const _kText = 'Vos médicaments sont sur la table de nuit.';
final _kAudioChunk = Uint8List.fromList([1, 2, 3, 4]);
const _kTwoCandidates = <PhoneCandidate>[
  (displayName: 'Martin Jean', number: '+33611111111'),
  (displayName: 'Martin Paul', number: '+33622222222'),
];

void main() {
  late MockAudioRepository audioRepository;
  late MockStreamingAudioPlayerService audioPlayer;
  late MockPhoneCallService phoneCallService;
  late MockSettingsService settingsService;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(const LiveEvent.turnComplete());
  });

  setUp(() {
    audioRepository = MockAudioRepository();
    audioPlayer = MockStreamingAudioPlayerService();
    phoneCallService = MockPhoneCallService();
    settingsService = MockSettingsService();

    when(() => audioRepository.connect(
          useElevenLabs: any(named: 'useElevenLabs'),
          sessionId: any(named: 'sessionId'),
        )).thenAnswer((_) => StreamController<LiveEvent>().stream);
    when(() => settingsService.getUseElevenLabs()).thenAnswer((_) async => false);
    when(() => settingsService.getUseTextMode()).thenAnswer((_) async => false);
    when(() => settingsService.getUseLiveKit()).thenAnswer((_) async => false);
    when(() => audioRepository.disconnect()).thenAnswer((_) async {});
    when(() => audioRepository.sendAudio(any())).thenReturn(null);
    when(() => audioRepository.sendToolResponse(
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
    final bloc =
        _makeBloc(audioRepository: audioRepository, audioPlayer: audioPlayer);
    expect(bloc.state, const AssistantState.idle());
    bloc.close();
  });

  // ── StartListening from Idle ───────────────────────────────────────────────

  blocTest<AssistantBloc, AssistantState>(
    'StartListening from Idle → Connecting then Listening',
    build: () => _makeBloc(
      audioRepository: audioRepository,
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
      audioRepository: audioRepository,
      audioPlayer: audioPlayer,
      settingsService: settingsService,
    ),
    act: (bloc) => bloc.add(const AssistantEvent.startListening()),
    expect: () => [
      const AssistantState.connecting(),
      const AssistantState.listening(),
    ],
    verify: (_) {
      verify(() => audioRepository.connect(
            useElevenLabs: false,
            sessionId: any(named: 'sessionId'),
          )).called(1);
    },
  );

  blocTest<AssistantBloc, AssistantState>(
    'StartListening forwards useElevenLabs=true to connect() when setting is enabled',
    build: () {
      when(() => settingsService.getUseElevenLabs()).thenAnswer((_) async => true);
      return _makeBloc(
        audioRepository: audioRepository,
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
      verify(() => audioRepository.connect(
            useElevenLabs: true,
            sessionId: any(named: 'sessionId'),
          )).called(1);
    },
  );

  // ── StartListening from Error → Idle ──────────────────────────────────────

  blocTest<AssistantBloc, AssistantState>(
    'StartListening from Error → resets to Idle',
    build: () =>
        _makeBloc(audioRepository: audioRepository, audioPlayer: audioPlayer),
    seed: () => const AssistantState.error(message: 'some error'),
    act: (bloc) => bloc.add(const AssistantEvent.startListening()),
    expect: () => [const AssistantState.idle()],
  );

  // ── StartListening from Listening → Idle (cancel) ─────────────────────────

  blocTest<AssistantBloc, AssistantState>(
    'StartListening from Listening → disconnects and returns to Idle',
    build: () =>
        _makeBloc(audioRepository: audioRepository, audioPlayer: audioPlayer),
    seed: () => const AssistantState.listening(),
    act: (bloc) => bloc.add(const AssistantEvent.startListening()),
    expect: () => [const AssistantState.idle()],
    verify: (_) {
      verify(() => audioRepository.disconnect()).called(greaterThan(0));
    },
  );

  // ── StartListening from Speaking → interrupts ─────────────────────────────

  blocTest<AssistantBloc, AssistantState>(
    'StartListening from Speaking → stops audio and returns to Idle',
    build: () =>
        _makeBloc(audioRepository: audioRepository, audioPlayer: audioPlayer),
    seed: () => const AssistantState.speaking(responseText: _kText),
    act: (bloc) => bloc.add(const AssistantEvent.startListening()),
    expect: () => [const AssistantState.idle()],
    verify: (_) {
      verify(() => audioPlayer.stop()).called(greaterThan(0));
    },
  );

  // ── LiveEvent: textDelta (ignored) ────────────────────────────────────────

  blocTest<AssistantBloc, AssistantState>(
    'liveEventReceived(textDelta) → no state change',
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

  test(
    'liveEventReceived(outputTranscription) in text mode → emits Speaking with accumulated text',
    () async {
      final live = _ControllableRepository();
      final speech = _ControllableSpeechService();
      final player = MockStreamingAudioPlayerService();
      when(() => player.stop()).thenAnswer((_) async {});
      when(() => player.dispose()).thenAnswer((_) async {});

      final bloc = AssistantBloc(
        textRepository: live,
        audioRepository: live,
        micService: _FakeMicService(),
        audioPlayer: player,
        settingsService: _FakeSettingsService(textMode: true),
        speechService: speech,
        showTranscription: false,
      );

      final states = <AssistantState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const AssistantEvent.startListening());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      speech.emitFinal('Bonjour');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      live.emit(const LiveEvent.outputTranscription('Vos médicaments '));
      live.emit(const LiveEvent.outputTranscription('sont prêts.'));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // After emitFinal, the BLoC emits Listening(statusLabel: 'Je réfléchis...')
      // to give user feedback while waiting for the server's first response.
      // The first outputTranscription then transitions to Speaking.
      expect(states, containsAllInOrder([
        isA<Listening>().having((s) => s.statusLabel, 'statusLabel', 'Je réfléchis...'),
        const AssistantState.speaking(responseText: 'Vos médicaments '),
        const AssistantState.speaking(responseText: 'Vos médicaments sont prêts.'),
      ]));

      await sub.cancel();
      await bloc.close();
    },
  );

  // ── LiveEvent: imageUrl ───────────────────────────────────────────────────

  blocTest<AssistantBloc, AssistantState>(
    'liveEventReceived(imageUrl) while Listening → transitions to Speaking with imageUrl',
    build: () => _makeBloc(audioPlayer: audioPlayer),
    seed: () => const AssistantState.listening(),
    act: (bloc) => bloc.add(const AssistantEvent.liveEventReceived(
      LiveEvent.imageUrl('https://example.com/photo.jpg'),
    )),
    expect: () => [
      const AssistantState.speaking(imageUrl: 'https://example.com/photo.jpg'),
    ],
  );

  blocTest<AssistantBloc, AssistantState>(
    'liveEventReceived(outputTranscription) after imageUrl → keeps image visible, no text state update',
    build: () => _makeBloc(audioPlayer: audioPlayer, showTranscription: true),
    seed: () => const AssistantState.speaking(imageUrl: 'https://example.com/photo.jpg'),
    act: (bloc) => bloc.add(const AssistantEvent.liveEventReceived(
      LiveEvent.outputTranscription('Voici votre photo.'),
    )),
    expect: () => [],
  );

  blocTest<AssistantBloc, AssistantState>(
    'liveEventReceived(imageUrl) while Speaking → merges imageUrl into current Speaking state',
    build: () => _makeBloc(audioPlayer: audioPlayer, showTranscription: true),
    seed: () => const AssistantState.speaking(responseText: 'Voici votre photo.'),
    act: (bloc) => bloc.add(const AssistantEvent.liveEventReceived(
      LiveEvent.imageUrl('https://example.com/photo.jpg'),
    )),
    expect: () => [
      const AssistantState.speaking(
        responseText: 'Voici votre photo.',
        imageUrl: 'https://example.com/photo.jpg',
      ),
    ],
  );

  test(
    'audioPlaybackFinished from Speaking with imageUrl → Idle preserves imageUrl',
    () async {
      final live = _ControllableRepository();
      final speech = _ControllableSpeechService();
      final player = MockStreamingAudioPlayerService();
      when(() => player.stop()).thenAnswer((_) async {});
      when(() => player.dispose()).thenAnswer((_) async {});

      final localNativeTts = MockClientTtsService();
      when(() => localNativeTts.dispose()).thenAnswer((_) async {});
      when(() => localNativeTts.stop()).thenAnswer((_) async {});

      void Function()? capturedOnComplete;
      when(() => localNativeTts.speak(any(), onComplete: any(named: 'onComplete')))
          .thenAnswer((inv) async {
        capturedOnComplete =
            inv.namedArguments[#onComplete] as void Function();
      });

      final bloc = AssistantBloc(
        textRepository: live,
        audioRepository: live,
        micService: _FakeMicService(),
        audioPlayer: player,
        settingsService: _FakeSettingsService(textMode: true),
        speechService: speech,
        nativeTtsService: localNativeTts,
      );

      bloc.add(const AssistantEvent.startListening());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      speech.emitFinal('Montre-moi une photo');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Server sends image then text (text is suppressed visually).
      live.emit(const LiveEvent.imageUrl('https://example.com/photo.jpg'));
      live.emit(const LiveEvent.outputTranscription('Voici votre photo.'));
      live.emit(const LiveEvent.turnComplete());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(bloc.state, isA<Speaking>());
      expect((bloc.state as Speaking).imageUrl, 'https://example.com/photo.jpg');

      // TTS finishes.
      capturedOnComplete?.call();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(
        bloc.state,
        const AssistantState.idle(imageUrl: 'https://example.com/photo.jpg'),
      );

      await bloc.close();
    },
  );

  test(
    'imageUrl from exchange 1 is NOT carried over into exchange 2 (audio mode)',
    () async {
      // Use a broadcast controller that stays open across disconnect() calls so
      // the BLoC can subscribe again for the second exchange.
      final liveController = StreamController<LiveEvent>.broadcast();
      final live = _PersistentRepository(liveController);

      final player = MockStreamingAudioPlayerService();
      when(() => player.addChunk(any())).thenReturn(null);
      when(() => player.stop()).thenAnswer((_) async {});
      when(() => player.dispose()).thenAnswer((_) async {});
      when(() => player.playAndClear(onComplete: any(named: 'onComplete')))
          .thenAnswer((_) async {});

      final bloc = AssistantBloc(
        audioRepository: live,
        textRepository: live,
        micService: _FakeMicService(),
        audioPlayer: player,
        settingsService: _FakeSettingsService(),
      );

      // ── Exchange 1 ────────────────────────────────────────────────────────
      bloc.add(const AssistantEvent.startListening());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      liveController.add(const LiveEvent.imageUrl('https://example.com/photo.jpg'));
      liveController.add(const LiveEvent.turnComplete());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // After exchange 1, Listening state must carry the image.
      expect(bloc.state, isA<Listening>());
      expect(
        (bloc.state as Listening).imageUrl,
        'https://example.com/photo.jpg',
      );

      // ── Interrupt → Idle ──────────────────────────────────────────────────
      bloc.add(const AssistantEvent.startListening());
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(bloc.state, const AssistantState.idle());

      // ── Exchange 2: no image sent ─────────────────────────────────────────
      bloc.add(const AssistantEvent.startListening());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // The Listening state for exchange 2 must NOT carry the old image URL.
      expect(bloc.state, isA<Listening>());
      expect(
        (bloc.state as Listening).imageUrl,
        '',
        reason: 'image from exchange 1 must not bleed into exchange 2',
      );

      await liveController.close();
      await bloc.close();
    },
  );

  test(
    'imageUrl NOT carried over into next turn within same session (audio chunks)',
    () async {
      // Turn 1 sends image + audio; turn 2 (same connection) sends audio only.
      // The Speaking state of turn 2 must have imageUrl == ''.
      final liveController = StreamController<LiveEvent>.broadcast();
      final live = _PersistentRepository(liveController);

      final player = MockStreamingAudioPlayerService();
      when(() => player.addChunk(any())).thenReturn(null);
      when(() => player.stop()).thenAnswer((_) async {});
      when(() => player.dispose()).thenAnswer((_) async {});
      when(() => player.playAndClear(onComplete: any(named: 'onComplete')))
          .thenAnswer((_) async {});

      final bloc = AssistantBloc(
        audioRepository: live,
        textRepository: live,
        micService: _FakeMicService(),
        audioPlayer: player,
        settingsService: _FakeSettingsService(),
      );

      bloc.add(const AssistantEvent.startListening());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // ── Turn 1: image + audio ─────────────────────────────────────────────
      liveController.add(const LiveEvent.imageUrl('https://example.com/photo.jpg'));
      liveController.add(LiveEvent.audioChunk(_kAudioChunk));
      liveController.add(const LiveEvent.turnComplete());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(bloc.state, isA<Listening>());
      expect((bloc.state as Listening).imageUrl, 'https://example.com/photo.jpg');

      // ── Turn 2: audio only, no new image ─────────────────────────────────
      liveController.add(LiveEvent.audioChunk(_kAudioChunk));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(bloc.state, isA<Speaking>());
      expect(
        (bloc.state as Speaking).imageUrl,
        '',
        reason: 'image from turn 1 must not bleed into turn 2',
      );

      await liveController.close();
      await bloc.close();
    },
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

  // ── LiveEvent: audioChunk ignored in text mode ────────────────────────────

  test('liveEventReceived(audioChunk) in text mode → ignored', () async {
    final live = _ControllableRepository();
    final speech = _ControllableSpeechService();
    final player = MockStreamingAudioPlayerService();
    when(() => player.stop()).thenAnswer((_) async {});
    when(() => player.dispose()).thenAnswer((_) async {});

    final bloc = AssistantBloc(
      textRepository: live,
      audioRepository: live,
      micService: _FakeMicService(),
      audioPlayer: player,
      settingsService: _FakeSettingsService(textMode: true),
      speechService: speech,
    );

    final states = <AssistantState>[];
    final sub = bloc.stream.listen(states.add);

    bloc.add(const AssistantEvent.startListening());
    await Future<void>.delayed(const Duration(milliseconds: 50));
    states.clear();

    live.emit(LiveEvent.audioChunk(_kAudioChunk));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(states, isEmpty);
    verifyNever(() => player.addChunk(any()));

    await sub.cancel();
    await bloc.close();
  });

  // ── LiveEvent: turnComplete (audio mode) ──────────────────────────────────

  blocTest<AssistantBloc, AssistantState>(
    'liveEventReceived(turnComplete) while Speaking → back to Listening',
    build: () =>
        _makeBloc(audioRepository: audioRepository, audioPlayer: audioPlayer),
    seed: () => const AssistantState.speaking(responseText: _kText),
    act: (bloc) => bloc.add(const AssistantEvent.liveEventReceived(
      LiveEvent.turnComplete(),
    )),
    expect: () => [const AssistantState.listening()],
  );

  test('turnComplete resets responseText so next turn starts with empty bubble',
      () async {
    final live = _ControllableRepository();
    final player = MockStreamingAudioPlayerService();
    when(() => player.addChunk(any())).thenReturn(null);
    when(() => player.stop()).thenAnswer((_) async {});
    when(() => player.dispose()).thenAnswer((_) async {});
    when(() => player.playAndClear(onComplete: any(named: 'onComplete')))
        .thenAnswer((_) async {});

    final bloc = AssistantBloc(
      audioRepository: live,
      textRepository: live,
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
      const AssistantState.speaking(),
      const AssistantState.speaking(responseText: _kText),
      const AssistantState.listening(),
      const AssistantState.speaking(),
      const AssistantState.speaking(responseText: 'Turn 2 text'),
    ]));

    await sub.cancel();
    await bloc.close();
  });

  blocTest<AssistantBloc, AssistantState>(
    'liveEventReceived(turnComplete) while Listening → no state change',
    build: () =>
        _makeBloc(audioRepository: audioRepository, audioPlayer: audioPlayer),
    seed: () => const AssistantState.listening(),
    act: (bloc) => bloc.add(const AssistantEvent.liveEventReceived(
      LiveEvent.turnComplete(),
    )),
    expect: () => [],
  );

  // ── LiveEvent: turnComplete — settings drift detection ────────────────────

  test(
    'turnComplete (audio mode): useElevenLabs changed since connect → Idle',
    () async {
      final settings = _MutableFakeSettingsService();
      final live = _ControllableRepository();
      final player = MockStreamingAudioPlayerService();
      when(() => player.addChunk(any())).thenReturn(null);
      when(() => player.stop()).thenAnswer((_) async {});
      when(() => player.dispose()).thenAnswer((_) async {});
      when(() => player.playAndClear(onComplete: any(named: 'onComplete')))
          .thenAnswer((_) async {});

      final bloc = AssistantBloc(
        audioRepository: live,
        textRepository: live,
        micService: _FakeMicService(),
        audioPlayer: player,
        settingsService: settings,
      );

      final states = <AssistantState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const AssistantEvent.startListening());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      settings.useElevenLabs = true;

      live.emit(LiveEvent.audioChunk(_kAudioChunk));
      live.emit(const LiveEvent.turnComplete());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(states.last, const AssistantState.idle());

      await sub.cancel();
      await bloc.close();
    },
  );

  test(
    'turnComplete (audio mode): useTextMode changed since connect → Idle',
    () async {
      final settings = _MutableFakeSettingsService();
      final live = _ControllableRepository();
      final player = MockStreamingAudioPlayerService();
      when(() => player.addChunk(any())).thenReturn(null);
      when(() => player.stop()).thenAnswer((_) async {});
      when(() => player.dispose()).thenAnswer((_) async {});
      when(() => player.playAndClear(onComplete: any(named: 'onComplete')))
          .thenAnswer((_) async {});

      final bloc = AssistantBloc(
        audioRepository: live,
        textRepository: live,
        micService: _FakeMicService(),
        audioPlayer: player,
        settingsService: settings,
      );

      final states = <AssistantState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const AssistantEvent.startListening());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      settings.textMode = true;

      live.emit(LiveEvent.audioChunk(_kAudioChunk));
      live.emit(const LiveEvent.turnComplete());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(states.last, const AssistantState.idle());

      await sub.cancel();
      await bloc.close();
    },
  );

  test(
    'turnComplete (audio mode): no settings change → stays Listening',
    () async {
      final settings = _MutableFakeSettingsService();
      final live = _ControllableRepository();
      final player = MockStreamingAudioPlayerService();
      when(() => player.addChunk(any())).thenReturn(null);
      when(() => player.stop()).thenAnswer((_) async {});
      when(() => player.dispose()).thenAnswer((_) async {});
      when(() => player.playAndClear(onComplete: any(named: 'onComplete')))
          .thenAnswer((_) async {});

      final bloc = AssistantBloc(
        audioRepository: live,
        textRepository: live,
        micService: _FakeMicService(),
        audioPlayer: player,
        settingsService: settings,
      );

      final states = <AssistantState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const AssistantEvent.startListening());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      live.emit(LiveEvent.audioChunk(_kAudioChunk));
      live.emit(const LiveEvent.turnComplete());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(states.last, const AssistantState.listening());

      await sub.cancel();
      await bloc.close();
    },
  );

  // ── AudioPlaybackFinished ──────────────────────────────────────────────────

  blocTest<AssistantBloc, AssistantState>(
    'audioPlaybackFinished → Listening (bidi: mic stays active)',
    build: () => _makeBloc(audioPlayer: audioPlayer),
    seed: () => const AssistantState.speaking(responseText: _kText),
    act: (bloc) => bloc.add(const AssistantEvent.audioPlaybackFinished()),
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
    build: () =>
        _makeBloc(audioRepository: audioRepository, audioPlayer: audioPlayer),
    seed: () => const AssistantState.speaking(responseText: _kText),
    act: (bloc) => bloc.add(const AssistantEvent.appResumed()),
    expect: () => [const AssistantState.idle()],
    verify: (_) {
      verify(() => audioPlayer.stop()).called(greaterThan(0));
    },
  );

  blocTest<AssistantBloc, AssistantState>(
    'appResumed while Idle → no state change but audio player stopped',
    build: () => _makeBloc(audioPlayer: audioPlayer),
    act: (bloc) => bloc.add(const AssistantEvent.appResumed()),
    expect: () => [],
    verify: (_) {
      verify(() => audioPlayer.stop()).called(greaterThan(0));
    },
  );

  blocTest<AssistantBloc, AssistantState>(
    'appResumed while Listening → no state change but audio player stopped',
    build: () =>
        _makeBloc(audioRepository: audioRepository, audioPlayer: audioPlayer),
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
      when(() => phoneCallService.callByName(any(),
              exactMatch: any(named: 'exactMatch')))
          .thenAnswer((_) async => PhoneCallSuccess());
      return _makeBloc(
        audioRepository: audioRepository,
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
      verify(() => audioRepository.sendToolResponse(
            callId: 'call-1',
            functionName: 'call_phone',
            result: any(named: 'result'),
          )).called(1);
    },
  );

  blocTest<AssistantBloc, AssistantState>(
    'liveEventReceived(callPhone) — PhoneCallAmbiguous → sends ambiguity message',
    build: () {
      when(() => phoneCallService.callByName(any(),
              exactMatch: any(named: 'exactMatch')))
          .thenAnswer((_) async => PhoneCallAmbiguous(_kTwoCandidates));
      return _makeBloc(
        audioRepository: audioRepository,
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
      verify(() => audioRepository.sendToolResponse(
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
    'liveEventReceived(sessionInfo) while not Listening → no state change',
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

  // ── Full round-trip ───────────────────────────────────────────────────────

  test('full round-trip: connect → audio + transcription → turnComplete → Listening',
      () async {
    final live = _ControllableRepository();

    final player = MockStreamingAudioPlayerService();
    when(() => player.addChunk(any())).thenReturn(null);
    when(() => player.stop()).thenAnswer((_) async {});
    when(() => player.dispose()).thenAnswer((_) async {});
    when(() => player.playAndClear(onComplete: any(named: 'onComplete')))
        .thenAnswer((_) async {});

    final bloc = AssistantBloc(
      audioRepository: live,
      textRepository: live,
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
      const AssistantState.speaking(),
      const AssistantState.speaking(responseText: _kText),
      const AssistantState.listening(),
    ]));

    await sub.cancel();
    await bloc.close();
  });

  // ── Server closes connection without responding ───────────────────────────

  test('server closes stream while Listening → AssistantError', () async {
    final live = _ControllableRepository();
    final player = MockStreamingAudioPlayerService();
    when(() => player.stop()).thenAnswer((_) async {});
    when(() => player.dispose()).thenAnswer((_) async {});
    when(() => player.hasChunks).thenReturn(false);

    final bloc = AssistantBloc(
      audioRepository: live,
      textRepository: live,
      micService: _FakeMicService(),
      audioPlayer: player,
      settingsService: _FakeSettingsService(),
    );

    final states = <AssistantState>[];
    final sub = bloc.stream.listen(states.add);

    bloc.add(const AssistantEvent.startListening());
    await Future<void>.delayed(const Duration(milliseconds: 50));

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

  test(
    'liveEventReceived(inputTranscription) in text mode → emits Listening with interimTranscript',
    () async {
      final live = _ControllableRepository();
      final speech = _ControllableSpeechService();
      final player = MockStreamingAudioPlayerService();
      when(() => player.stop()).thenAnswer((_) async {});
      when(() => player.dispose()).thenAnswer((_) async {});

      final bloc = AssistantBloc(
        textRepository: live,
        audioRepository: live,
        micService: _FakeMicService(),
        audioPlayer: player,
        settingsService: _FakeSettingsService(textMode: true),
        speechService: speech,
      );

      final states = <AssistantState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const AssistantEvent.startListening());
      await Future<void>.delayed(const Duration(milliseconds: 50));
      states.clear();

      bloc.add(const AssistantEvent.liveEventReceived(
        LiveEvent.inputTranscription('allume la lumière'),
      ));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(states, [
        const AssistantState.listening(interimTranscript: 'allume la lumière'),
      ]);

      await sub.cancel();
      await bloc.close();
    },
  );

  // ── Connection error (mic throws) ─────────────────────────────────────────

  blocTest<AssistantBloc, AssistantState>(
    'mic startStreaming throws → emits AssistantError',
    build: () => _makeBloc(
      audioRepository: audioRepository,
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
    final live = _ControllableRepository();
    final mic = _ControlledMicService();
    final player = MockStreamingAudioPlayerService();
    when(() => player.addChunk(any())).thenReturn(null);
    when(() => player.stop()).thenAnswer((_) async {});
    when(() => player.dispose()).thenAnswer((_) async {});
    when(() => player.playAndClear(onComplete: any(named: 'onComplete')))
        .thenAnswer((_) async {});

    final bloc = AssistantBloc(
      audioRepository: live,
      textRepository: live,
      micService: mic,
      audioPlayer: player,
      settingsService: _FakeSettingsService(),
    );

    bloc.add(const AssistantEvent.startListening());
    await Future<void>.delayed(const Duration(milliseconds: 50));

    live.emit(LiveEvent.audioChunk(Uint8List(4)));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(bloc.state, isA<Speaking>());

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

  test('mic chunk with low RMS while Speaking → audio NOT forwarded to server', () async {
    final live = _ControllableRepository();
    final mic = _ControlledMicService();
    final player = MockStreamingAudioPlayerService();
    when(() => player.addChunk(any())).thenReturn(null);
    when(() => player.stop()).thenAnswer((_) async {});
    when(() => player.dispose()).thenAnswer((_) async {});
    when(() => player.playAndClear(onComplete: any(named: 'onComplete')))
        .thenAnswer((_) async {});

    final bloc = AssistantBloc(
      audioRepository: live,
      textRepository: live,
      micService: mic,
      audioPlayer: player,
      settingsService: _FakeSettingsService(),
    );

    bloc.add(const AssistantEvent.startListening());
    await Future<void>.delayed(const Duration(milliseconds: 50));

    live.emit(LiveEvent.audioChunk(Uint8List(4)));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(bloc.state, isA<Speaking>());

    final countBefore = live.sendAudioCount;
    // Low-RMS buffer (silence) during Speaking — simulates speaker echo captured by mic
    mic.push(Uint8List(3200));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // Echo MUST NOT be forwarded to the server (fixes Android echo loop)
    expect(live.sendAudioCount, equals(countBefore));

    await bloc.close();
  });

  test('interruption threshold adapts to measured background noise', () async {
    // Verifies that after calibration with a quiet environment (RMS ≈ 400),
    // the dynamic threshold is max(3000, 400 * 4) = 3000, so a buffer with
    // RMS ≈ 3200 triggers interruption even though it is below the old
    // hard-coded threshold of 3500.
    final live = _ControllableRepository();
    final mic = _ControlledMicService();
    final player = MockStreamingAudioPlayerService();
    when(() => player.addChunk(any())).thenReturn(null);
    when(() => player.stop()).thenAnswer((_) async {});
    when(() => player.dispose()).thenAnswer((_) async {});
    when(() => player.playAndClear(onComplete: any(named: 'onComplete')))
        .thenAnswer((_) async {});

    final bloc = AssistantBloc(
      audioRepository: live,
      textRepository: live,
      micService: mic,
      audioPlayer: player,
      settingsService: _FakeSettingsService(),
    );

    bloc.add(const AssistantEvent.startListening());
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(bloc.state, isA<Listening>());

    // Calibration: 25 low-noise buffers (all samples = 400, RMS ≈ 400).
    // After 20+ buffers, the baseline locks in at ≈ 400.
    // dynamic threshold = max(3000, 400 * 4) = 3000.
    final quietBuffer = Uint8List(3200);
    final quietSamples = Int16List.view(quietBuffer.buffer);
    for (var i = 0; i < quietSamples.length; i++) {
      quietSamples[i] = 400;
    }
    for (var i = 0; i < 25; i++) {
      mic.push(Uint8List.fromList(quietBuffer));
      await Future<void>.delayed(Duration.zero);
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));

    // Transition to Speaking.
    live.emit(LiveEvent.audioChunk(Uint8List(4)));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(bloc.state, isA<Speaking>());

    // Buffer with RMS ≈ 3200 — above dynamic threshold (3000)
    // but below the old hard-coded threshold (3500).
    final interruptBuffer = Uint8List(3200);
    final interruptSamples = Int16List.view(interruptBuffer.buffer);
    for (var i = 0; i < interruptSamples.length; i++) {
      interruptSamples[i] = 3200;
    }
    mic.push(interruptBuffer);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(
      live.sendInterruptionCount,
      1,
      reason: 'A buffer above the dynamic threshold must trigger interruption',
    );

    await bloc.close();
  });

  // ── TEXT MODE ─────────────────────────────────────────────────────────────

  test('text mode: StartListening → Connecting → Listening, STT started', () async {
    final live = _ControllableRepository();
    final speech = _ControllableSpeechService();
    final player = MockStreamingAudioPlayerService();
    when(() => player.stop()).thenAnswer((_) async {});
    when(() => player.dispose()).thenAnswer((_) async {});

    final bloc = AssistantBloc(
      textRepository: live,
      audioRepository: live,
      micService: _FakeMicService(),
      audioPlayer: player,
      settingsService: _FakeSettingsService(textMode: true),
      speechService: speech,
    );

    final states = <AssistantState>[];
    final sub = bloc.stream.listen(states.add);

    bloc.add(const AssistantEvent.startListening());
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(states, containsAllInOrder([
      const AssistantState.connecting(),
      const AssistantState.listening(),
    ]));
    expect(speech.startListeningCount, 1);

    await sub.cancel();
    await bloc.close();
  });

  test(
    'text mode: STT final result → sendText() called, Listening(statusLabel) emitted',
    () async {
      final live = _ControllableRepository();
      final speech = _ControllableSpeechService();
      final player = MockStreamingAudioPlayerService();
      when(() => player.stop()).thenAnswer((_) async {});
      when(() => player.dispose()).thenAnswer((_) async {});

      final bloc = AssistantBloc(
        textRepository: live,
        audioRepository: live,
        micService: _FakeMicService(),
        audioPlayer: player,
        settingsService: _FakeSettingsService(textMode: true),
        speechService: speech,
      );

      final states = <AssistantState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const AssistantEvent.startListening());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      speech.emitFinal('Appelle maman');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(live.sentTexts, ['Appelle maman']);
      // After emitFinal the BLoC emits a "thinking" Listening state (not
      // Speaking) so the UI gives feedback while waiting for the server.
      expect(states, containsAllInOrder([
        const AssistantState.connecting(),
        const AssistantState.listening(),
        isA<Listening>().having(
          (s) => s.statusLabel,
          'statusLabel',
          'Je réfléchis...',
        ),
      ]));

      await sub.cancel();
      await bloc.close();
    },
  );

  test('text mode: STT interim result → Listening with interimTranscript', () async {
    final live = _ControllableRepository();
    final speech = _ControllableSpeechService();
    final player = MockStreamingAudioPlayerService();
    when(() => player.stop()).thenAnswer((_) async {});
    when(() => player.dispose()).thenAnswer((_) async {});

    final bloc = AssistantBloc(
      textRepository: live,
      audioRepository: live,
      micService: _FakeMicService(),
      audioPlayer: player,
      settingsService: _FakeSettingsService(textMode: true),
      speechService: speech,
      showTranscription: true,
    );

    final states = <AssistantState>[];
    final sub = bloc.stream.listen(states.add);

    bloc.add(const AssistantEvent.startListening());
    await Future<void>.delayed(const Duration(milliseconds: 50));

    speech.emitInterim('Appelle');
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(states, containsAllInOrder([
      const AssistantState.listening(interimTranscript: 'Appelle'),
    ]));

    await sub.cancel();
    await bloc.close();
  });

  test('text mode: empty STT result → Idle, no sendText()', () async {
    final live = _ControllableRepository();
    final speech = _ControllableSpeechService();
    final player = MockStreamingAudioPlayerService();
    when(() => player.stop()).thenAnswer((_) async {});
    when(() => player.dispose()).thenAnswer((_) async {});

    final bloc = AssistantBloc(
      textRepository: live,
      audioRepository: live,
      micService: _FakeMicService(),
      audioPlayer: player,
      settingsService: _FakeSettingsService(textMode: true),
      speechService: speech,
    );

    final states = <AssistantState>[];
    final sub = bloc.stream.listen(states.add);

    bloc.add(const AssistantEvent.startListening());
    await Future<void>.delayed(const Duration(milliseconds: 50));

    speech.emitFinal('');
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(live.sentTexts, isEmpty);
    expect(states.last, const AssistantState.idle());

    await sub.cancel();
    await bloc.close();
  });

  test('text mode: STT timeout → returns to Idle without error', () async {
    final live = _ControllableRepository();
    final speech = _ControllableSpeechService();
    final player = MockStreamingAudioPlayerService();
    when(() => player.stop()).thenAnswer((_) async {});
    when(() => player.dispose()).thenAnswer((_) async {});

    final bloc = AssistantBloc(
      textRepository: live,
      audioRepository: live,
      micService: _FakeMicService(),
      audioPlayer: player,
      settingsService: _FakeSettingsService(textMode: true),
      speechService: speech,
    );

    final states = <AssistantState>[];
    final sub = bloc.stream.listen(states.add);

    bloc.add(const AssistantEvent.startListening());
    await Future<void>.delayed(const Duration(milliseconds: 50));

    speech.emitTimeout();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(states.last, const AssistantState.idle());
    expect(states, isNot(contains(isA<AssistantError>())));

    await sub.cancel();
    await bloc.close();
  });

  test('text mode: turnComplete while Speaking → Idle (not Listening)', () async {
    final live = _ControllableRepository();
    final speech = _ControllableSpeechService();
    final player = MockStreamingAudioPlayerService();
    when(() => player.addChunk(any())).thenReturn(null);
    when(() => player.stop()).thenAnswer((_) async {});
    when(() => player.dispose()).thenAnswer((_) async {});

    // No TTS services → turnComplete disconnects immediately
    final bloc = AssistantBloc(
      textRepository: live,
      audioRepository: live,
      micService: _FakeMicService(),
      audioPlayer: player,
      settingsService: _FakeSettingsService(textMode: true),
      speechService: speech,
    );

    final states = <AssistantState>[];
    final sub = bloc.stream.listen(states.add);

    bloc.add(const AssistantEvent.startListening());
    await Future<void>.delayed(const Duration(milliseconds: 50));

    speech.emitFinal('Appelle maman');
    await Future<void>.delayed(const Duration(milliseconds: 50));

    live.emit(const LiveEvent.outputTranscription('Réponse de l\'agent.'));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    live.emit(const LiveEvent.turnComplete());
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(states.last, const AssistantState.idle());

    await sub.cancel();
    await bloc.close();
  });

  test('text mode: sessionEstablished → session_id forwarded on next connection',
      () async {
    final live = _ControllableRepository();
    final speech = _ControllableSpeechService();
    final player = MockStreamingAudioPlayerService();
    when(() => player.addChunk(any())).thenReturn(null);
    when(() => player.stop()).thenAnswer((_) async {});
    when(() => player.dispose()).thenAnswer((_) async {});
    when(() => player.playAndClear(onComplete: any(named: 'onComplete')))
        .thenAnswer((_) async {});

    final bloc = AssistantBloc(
      textRepository: live,
      audioRepository: live,
      micService: _FakeMicService(),
      audioPlayer: player,
      settingsService: _FakeSettingsService(textMode: true),
      speechService: speech,
    );

    // Turn 1: receive session_id
    bloc.add(const AssistantEvent.startListening());
    await Future<void>.delayed(const Duration(milliseconds: 50));

    live.emit(const LiveEvent.sessionEstablished('sess-42'));
    speech.emitFinal('Bonjour');
    await Future<void>.delayed(const Duration(milliseconds: 50));

    live.emit(LiveEvent.audioChunk(_kAudioChunk));
    live.emit(const LiveEvent.turnComplete());
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // Turn 2: session_id should be forwarded
    bloc.add(const AssistantEvent.startListening());
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(live.lastConnectedSessionId, 'sess-42');

    await bloc.close();
  });

  test(
    'text mode: after speech recognized → emits Listening(statusLabel) while waiting for server',
    () async {
      // Verifies that between the moment the user finishes speaking and the
      // moment the server's first response arrives, the BLoC emits a
      // Listening state with statusLabel = 'Je réfléchis...' so the UI
      // gives visible feedback that the request was sent.
      final live = _ControllableRepository();
      final speech = _ControllableSpeechService();
      final player = MockStreamingAudioPlayerService();
      when(() => player.stop()).thenAnswer((_) async {});
      when(() => player.dispose()).thenAnswer((_) async {});

      final bloc = AssistantBloc(
        textRepository: live,
        audioRepository: live,
        micService: _FakeMicService(),
        audioPlayer: player,
        settingsService: _FakeSettingsService(textMode: true),
        speechService: speech,
        nativeTtsService: _NoOpClientTtsService(),
      );

      final states = <AssistantState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const AssistantEvent.startListening());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      speech.emitFinal('Bonjour');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(
        states,
        contains(
          isA<Listening>().having(
            (s) => s.statusLabel,
            'statusLabel',
            'Je réfléchis...',
          ),
        ),
        reason: 'A "thinking" label must be shown between sendText() and the first server response',
      );

      await sub.cancel();
      await bloc.close();
    },
  );

  // ── No server response within timeout ─────────────────────────────────────

  test('no server response within timeout → AssistantError', () async {
    final live = _ControllableRepository();
    final player = MockStreamingAudioPlayerService();
    when(() => player.stop()).thenAnswer((_) async {});
    when(() => player.dispose()).thenAnswer((_) async {});
    when(() => player.hasChunks).thenReturn(false);

    final bloc = _makeBlocWithTimeout(
      responseTimeout: const Duration(milliseconds: 100),
      audioRepository: live,
      textRepository: live,
      audioPlayer: player,
    );

    final states = <AssistantState>[];
    final sub = bloc.stream.listen(states.add);

    bloc.add(const AssistantEvent.startListening());
    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(states, containsAllInOrder([
      const AssistantState.connecting(),
      const AssistantState.listening(),
      isA<AssistantError>(),
    ]));

    await sub.cancel();
    await bloc.close();
  });

  // ── CLIENT-SIDE TTS (text mode) ───────────────────────────────────────────

  group('text mode + TTS', () {
    late MockClientTtsService elevenLabsTts;
    late MockClientTtsService nativeTts;

    setUp(() {
      elevenLabsTts = MockClientTtsService();
      nativeTts = MockClientTtsService();
      when(() => elevenLabsTts.speak(any(), onComplete: any(named: 'onComplete')))
          .thenAnswer((_) async {});
      when(() => elevenLabsTts.stop()).thenAnswer((_) async {});
      when(() => elevenLabsTts.dispose()).thenAnswer((_) async {});
      when(() => nativeTts.speak(any(), onComplete: any(named: 'onComplete')))
          .thenAnswer((_) async {});
      when(() => nativeTts.stop()).thenAnswer((_) async {});
      when(() => nativeTts.dispose()).thenAnswer((_) async {});
    });

    test(
      'turnComplete with text → ElevenLabs TTS called (useElevenLabs=true)',
      () async {
        final live = _ControllableRepository();
        final speech = _ControllableSpeechService();
        final player = MockStreamingAudioPlayerService();
        when(() => player.stop()).thenAnswer((_) async {});
        when(() => player.dispose()).thenAnswer((_) async {});

        final bloc = AssistantBloc(
          textRepository: live,
          audioRepository: live,
          micService: _FakeMicService(),
          audioPlayer: player,
          settingsService: _ElevenLabsTextSettingsService(),
          speechService: speech,
          elevenLabsTtsService: elevenLabsTts,
          nativeTtsService: nativeTts,
        );

        final states = <AssistantState>[];
        final sub = bloc.stream.listen(states.add);

        bloc.add(const AssistantEvent.startListening());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        speech.emitFinal('Bonjour');
        await Future<void>.delayed(const Duration(milliseconds: 50));

        live.emit(const LiveEvent.outputTranscription(_kText));
        live.emit(const LiveEvent.turnComplete());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        verify(() =>
                elevenLabsTts.speak(_kText, onComplete: any(named: 'onComplete')))
            .called(1);
        verifyNever(
            () => nativeTts.speak(any(), onComplete: any(named: 'onComplete')));

        await sub.cancel();
        await bloc.close();
      },
    );

    test(
      'turnComplete with text → native TTS called (useElevenLabs=false)',
      () async {
        final live = _ControllableRepository();
        final speech = _ControllableSpeechService();
        final player = MockStreamingAudioPlayerService();
        when(() => player.stop()).thenAnswer((_) async {});
        when(() => player.dispose()).thenAnswer((_) async {});

        final bloc = AssistantBloc(
          textRepository: live,
          audioRepository: live,
          micService: _FakeMicService(),
          audioPlayer: player,
          settingsService: _FakeSettingsService(textMode: true),
          speechService: speech,
          elevenLabsTtsService: elevenLabsTts,
          nativeTtsService: nativeTts,
        );

        final states = <AssistantState>[];
        final sub = bloc.stream.listen(states.add);

        bloc.add(const AssistantEvent.startListening());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        speech.emitFinal('Bonjour');
        await Future<void>.delayed(const Duration(milliseconds: 50));

        live.emit(const LiveEvent.outputTranscription(_kText));
        live.emit(const LiveEvent.turnComplete());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        verify(() =>
                nativeTts.speak(_kText, onComplete: any(named: 'onComplete')))
            .called(1);
        verifyNever(() =>
            elevenLabsTts.speak(any(), onComplete: any(named: 'onComplete')));

        await sub.cancel();
        await bloc.close();
      },
    );

    test(
      'TTS onComplete fires audioPlaybackFinished → disconnect → Idle',
      () async {
        final live = _ControllableRepository();
        final speech = _ControllableSpeechService();
        final player = MockStreamingAudioPlayerService();
        when(() => player.stop()).thenAnswer((_) async {});
        when(() => player.dispose()).thenAnswer((_) async {});

        void Function()? capturedOnComplete;
        when(() => nativeTts.speak(any(), onComplete: any(named: 'onComplete')))
            .thenAnswer((inv) async {
          capturedOnComplete =
              inv.namedArguments[#onComplete] as void Function();
        });

        final bloc = AssistantBloc(
          textRepository: live,
          audioRepository: live,
          micService: _FakeMicService(),
          audioPlayer: player,
          settingsService: _FakeSettingsService(textMode: true),
          speechService: speech,
          nativeTtsService: nativeTts,
          elevenLabsTtsService: elevenLabsTts,
        );

        final states = <AssistantState>[];
        final sub = bloc.stream.listen(states.add);

        bloc.add(const AssistantEvent.startListening());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        speech.emitFinal('Bonjour');
        await Future<void>.delayed(const Duration(milliseconds: 50));

        live.emit(const LiveEvent.outputTranscription(_kText));
        live.emit(const LiveEvent.turnComplete());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(bloc.state, isA<Speaking>());

        capturedOnComplete?.call();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(bloc.state, const AssistantState.idle());

        await sub.cancel();
        await bloc.close();
      },
    );

    test(
      'text mode: tool-response turn → second TTS triggered after first turnComplete',
      () async {
        final live = _ControllableRepository();
        final speech = _ControllableSpeechService();
        final player = MockStreamingAudioPlayerService();
        when(() => player.stop()).thenAnswer((_) async {});
        when(() => player.dispose()).thenAnswer((_) async {});

        final List<String> spokenTexts = [];
        when(() => nativeTts.speak(any(), onComplete: any(named: 'onComplete')))
            .thenAnswer((inv) async {
          spokenTexts.add(inv.positionalArguments.first as String);
        });

        final bloc = AssistantBloc(
          textRepository: live,
          audioRepository: live,
          micService: _FakeMicService(),
          audioPlayer: player,
          settingsService: _FakeSettingsService(textMode: true),
          speechService: speech,
          nativeTtsService: nativeTts,
          elevenLabsTtsService: elevenLabsTts,
        );

        bloc.add(const AssistantEvent.startListening());
        await Future<void>.delayed(const Duration(milliseconds: 50));
        speech.emitFinal('Appelle Madeleine');
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // First turn: agent says something and then tool response comes back
        const firstText = "J'appelle Madeleine, ta sœur.";
        const secondText =
            'Plusieurs Madeleine correspondent. Voulez-vous appeler Madeleine Test ou Madeleine Test 2 ?';

        live.emit(const LiveEvent.outputTranscription(firstText));
        live.emit(const LiveEvent.turnComplete());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Simulate tool-response turn arriving while first TTS is playing
        live.emit(const LiveEvent.outputTranscription(secondText));
        live.emit(const LiveEvent.turnComplete());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Both texts must have triggered TTS
        expect(spokenTexts, [firstText, secondText]);

        await bloc.close();
      },
    );
  });

  // ── LiveKit / WebRTC mode ──────────────────────────────────────────────────

  group('WebRTC mode', () {
    late MockWebRtcRepository webRtcRepository;

    setUp(() {
      webRtcRepository = MockWebRtcRepository();
      when(
        () => webRtcRepository.connect(
          useElevenLabs: any(named: 'useElevenLabs'),
          sessionId: any(named: 'sessionId'),
        ),
      ).thenAnswer((_) => StreamController<LiveEvent>().stream);
      when(() => webRtcRepository.disconnect()).thenAnswer((_) async {});
      when(
        () => webRtcRepository.sendToolResponse(
          callId: any(named: 'callId'),
          functionName: any(named: 'functionName'),
          result: any(named: 'result'),
        ),
      ).thenReturn(null);
      when(() => webRtcRepository.sendInterruption()).thenReturn(null);
    });

    test('StartListening routes to WebRTC when useLiveKit=true', () async {
      final bloc = AssistantBloc(
        textRepository: _EmptyRepository(),
        webRtcRepository: webRtcRepository,
        micService: _FakeMicService(),
        settingsService: _FakeSettingsService(),
        enableWakelock: () async {},
        disableWakelock: () async {},
      );
      final settings = _FakeLiveKitSettingsService();
      final liveKitBloc = AssistantBloc(
        textRepository: _EmptyRepository(),
        webRtcRepository: webRtcRepository,
        micService: _FakeMicService(),
        settingsService: settings,
        enableWakelock: () async {},
        disableWakelock: () async {},
      );

      liveKitBloc.add(const AssistantEvent.startListening());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      verify(
        () => webRtcRepository.connect(
          useElevenLabs: any(named: 'useElevenLabs'),
          sessionId: any(named: 'sessionId'),
        ),
      ).called(1);

      await liveKitBloc.close();
      await bloc.close();
    });

    test('StartListening in WebRTC mode does not start mic streaming', () async {
      final mockMic = MockMicrophoneStreamService();
      when(() => mockMic.stop()).thenAnswer((_) async {});
      when(() => mockMic.dispose()).thenAnswer((_) async {});

      final settings = _FakeLiveKitSettingsService();
      final bloc = AssistantBloc(
        textRepository: _EmptyRepository(),
        webRtcRepository: webRtcRepository,
        micService: mockMic,
        settingsService: settings,
        enableWakelock: () async {},
        disableWakelock: () async {},
      );

      bloc.add(const AssistantEvent.startListening());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      verifyNever(() => mockMic.startStreaming());
      await bloc.close();
    });

    test('outputTranscription in WebRTC mode emits Speaking', () async {
      final live = _ControllableRepository();
      when(
        () => webRtcRepository.connect(
          useElevenLabs: any(named: 'useElevenLabs'),
          sessionId: any(named: 'sessionId'),
        ),
      ).thenAnswer((_) => live.connect());

      final settings = _FakeLiveKitSettingsService();
      final bloc = AssistantBloc(
        textRepository: _EmptyRepository(),
        webRtcRepository: webRtcRepository,
        micService: _FakeMicService(),
        settingsService: settings,
        enableWakelock: () async {},
        disableWakelock: () async {},
      );

      final states = <AssistantState>[];
      bloc.stream.listen(states.add);

      bloc.add(const AssistantEvent.startListening());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      live.emit(const LiveEvent.outputTranscription('Bonjour'));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(states.whereType<Speaking>(), isNotEmpty);
      await bloc.close();
    });

    test('turnComplete in WebRTC mode returns to Listening (not Idle)', () async {
      final live = _ControllableRepository();
      when(
        () => webRtcRepository.connect(
          useElevenLabs: any(named: 'useElevenLabs'),
          sessionId: any(named: 'sessionId'),
        ),
      ).thenAnswer((_) => live.connect());

      final settings = _FakeLiveKitSettingsService();
      final bloc = AssistantBloc(
        textRepository: _EmptyRepository(),
        webRtcRepository: webRtcRepository,
        micService: _FakeMicService(),
        settingsService: settings,
        enableWakelock: () async {},
        disableWakelock: () async {},
      );

      bloc.add(const AssistantEvent.startListening());
      await Future<void>.delayed(const Duration(milliseconds: 50));
      live.emit(const LiveEvent.outputTranscription('Réponse'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      live.emit(const LiveEvent.turnComplete());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(bloc.state, isA<Listening>());
      await bloc.close();
    });

    test('errorOccurred while in WebRTC Listening disconnects repository', () async {
      final live = _ControllableRepository();
      when(
        () => webRtcRepository.connect(
          useElevenLabs: any(named: 'useElevenLabs'),
          sessionId: any(named: 'sessionId'),
        ),
      ).thenAnswer((_) => live.connect());

      final settings = _FakeLiveKitSettingsService();
      final bloc = AssistantBloc(
        textRepository: _EmptyRepository(),
        webRtcRepository: webRtcRepository,
        micService: _FakeMicService(),
        settingsService: settings,
        enableWakelock: () async {},
        disableWakelock: () async {},
      );

      bloc.add(const AssistantEvent.startListening());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      bloc.add(const AssistantEvent.errorOccurred('Connexion perdue.'));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      verify(() => webRtcRepository.disconnect()).called(greaterThan(0));
      expect(bloc.state, isA<AssistantError>());
      await bloc.close();
    });
  });

  // ── Wakelock ───────────────────────────────────────────────────────────────

  group('wakelock', () {
    late List<String> wakelockCalls;
    late Future<void> Function() enableWakelock;
    late Future<void> Function() disableWakelock;

    setUp(() {
      wakelockCalls = [];
      enableWakelock = () async => wakelockCalls.add('enable');
      disableWakelock = () async => wakelockCalls.add('disable');
    });

    MockStreamingAudioPlayerService stubbedPlayer() {
      final player = MockStreamingAudioPlayerService();
      when(() => player.stop()).thenAnswer((_) async {});
      when(() => player.dispose()).thenAnswer((_) async {});
      when(() => player.hasChunks).thenReturn(false);
      when(() => player.addChunk(any())).thenReturn(null);
      when(() => player.playAndClear(onComplete: any(named: 'onComplete')))
          .thenAnswer((_) async {});
      return player;
    }

    AssistantBloc makeWakelockBloc(_ControllableRepository live) => AssistantBloc(
          audioRepository: live,
          textRepository: live,
          micService: _FakeMicService(),
          audioPlayer: stubbedPlayer(),
          settingsService: _FakeSettingsService(),
          enableWakelock: enableWakelock,
          disableWakelock: disableWakelock,
        );

    test('enables wakelock when transitioning to Connecting', () async {
      final live = _ControllableRepository();
      final bloc = makeWakelockBloc(live);

      bloc.add(const AssistantEvent.startListening());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(wakelockCalls, contains('enable'));
      await bloc.close();
    });

    test('disables wakelock when transitioning to Idle', () async {
      final live = _ControllableRepository();
      final bloc = makeWakelockBloc(live);

      bloc.add(const AssistantEvent.startListening());
      await Future<void>.delayed(const Duration(milliseconds: 50));
      wakelockCalls.clear();

      // Cancel the session → back to Idle
      bloc.add(const AssistantEvent.startListening());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(wakelockCalls, contains('disable'));
      await bloc.close();
    });

    test('disables wakelock when transitioning to AssistantError', () async {
      final live = _ControllableRepository();
      final bloc = makeWakelockBloc(live);

      bloc.add(const AssistantEvent.startListening());
      await Future<void>.delayed(const Duration(milliseconds: 50));
      wakelockCalls.clear();

      bloc.add(const AssistantEvent.errorOccurred('Erreur réseau'));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(wakelockCalls, contains('disable'));
      await bloc.close();
    });
  });
}
