import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:alzheimer_assistant/features/assistant/domain/entities/assistant_response.dart';
import 'package:alzheimer_assistant/features/assistant/domain/repositories/assistant_repository.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_bloc.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_event.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_state.dart';
import 'package:alzheimer_assistant/shared/services/phone_call_service.dart';
import 'package:alzheimer_assistant/shared/services/speech_recognition_service.dart';
import 'package:alzheimer_assistant/shared/services/tts_service.dart';

// ── Mocks ──────────────────────────────────────────────────────────────────

class MockAssistantRepository extends Mock implements AssistantRepository {}

class MockSpeechRecognitionService extends Mock
    implements SpeechRecognitionService {}

class MockTtsService extends Mock implements TtsService {}

class MockPhoneCallService extends Mock implements PhoneCallService {}

// ── Helpers ────────────────────────────────────────────────────────────────

AssistantBloc _makeBloc({
  required MockAssistantRepository repository,
  required MockSpeechRecognitionService speechService,
  required MockTtsService ttsService,
}) =>
    AssistantBloc(
      repository: repository,
      speechService: speechService,
      ttsService: ttsService,
    );

const _kQuestion = 'Où sont mes médicaments ?';
const _kAnswer = 'Vos médicaments sont sur la table de nuit.';
final _kResponse = AssistantResponse(text: _kAnswer, audioBytes: [1, 2, 3]);

const _kTwoCandidates = <PhoneCandidate>[
  (displayName: 'Martin Jean', number: '+33611111111'),
  (displayName: 'Martin Paul', number: '+33622222222'),
];

void main() {
  late MockAssistantRepository repository;
  late MockSpeechRecognitionService speechService;
  late MockTtsService ttsService;

  setUp(() {
    repository = MockAssistantRepository();
    speechService = MockSpeechRecognitionService();
    ttsService = MockTtsService();

    // Defaults: no error on close
    when(() => speechService.stopListening()).thenAnswer((_) async {});
    when(() => ttsService.stop()).thenAnswer((_) async {});
    when(() => ttsService.dispose()).thenAnswer((_) async {});
  });

  // ── Initial state ─────────────────────────────────────────────────────────

  test('initial state is Idle', () {
    final bloc = _makeBloc(
      repository: repository,
      speechService: speechService,
      ttsService: ttsService,
    );
    expect(bloc.state, const AssistantState.idle());
    bloc.close();
  });

  // ── StartListening ────────────────────────────────────────────────────────

  blocTest<AssistantBloc, AssistantState>(
    'StartListening → switches to Listening and starts STT',
    build: () {
      when(
        () => speechService.startListening(
          onInterim: any(named: 'onInterim'),
          onFinal: any(named: 'onFinal'),
          onTimeout: any(named: 'onTimeout'),
        ),
      ).thenAnswer((_) async {});
      return _makeBloc(
        repository: repository,
        speechService: speechService,
        ttsService: ttsService,
      );
    },
    act: (bloc) => bloc.add(const AssistantEvent.startListening()),
    expect: () => [const AssistantState.listening()],
    verify: (_) {
      verify(
        () => speechService.startListening(
          onInterim: any(named: 'onInterim'),
          onFinal: any(named: 'onFinal'),
          onTimeout: any(named: 'onTimeout'),
        ),
      ).called(1);
    },
  );

  // ── StartListening from Error ─────────────────────────────────────────────

  blocTest<AssistantBloc, AssistantState>(
    'StartListening from Error → resets to Idle without starting STT',
    build: () => _makeBloc(
      repository: repository,
      speechService: speechService,
      ttsService: ttsService,
    ),
    seed: () => const AssistantState.error(message: 'oups'),
    act: (bloc) => bloc.add(const AssistantEvent.startListening()),
    expect: () => [const AssistantState.idle()],
    verify: (_) {
      verifyNever(
        () => speechService.startListening(
          onInterim: any(named: 'onInterim'),
          onFinal: any(named: 'onFinal'),
          onTimeout: any(named: 'onTimeout'),
        ),
      );
    },
  );

  // ── InterimTranscript ─────────────────────────────────────────────────────

  blocTest<AssistantBloc, AssistantState>(
    'InterimTranscript → updates interimTranscript in Listening',
    build: () => _makeBloc(
      repository: repository,
      speechService: speechService,
      ttsService: ttsService,
    ),
    seed: () => const AssistantState.listening(),
    act: (bloc) =>
        bloc.add(const AssistantEvent.interimTranscript(_kQuestion)),
    expect: () => [
      const AssistantState.listening(interimTranscript: _kQuestion),
    ],
  );

  // ── SendMessage (success, no phone call) ──────────────────────────────────

  blocTest<AssistantBloc, AssistantState>(
    'SendMessage success → Processing then SpeakResponse triggers Speaking',
    build: () {
      when(() => repository.ask(_kQuestion))
          .thenAnswer((_) async => _kResponse);
      when(
        () => ttsService.play(
          any(),
          onComplete: any(named: 'onComplete'),
        ),
      ).thenAnswer((invocation) async {
        final onComplete =
            invocation.namedArguments[const Symbol('onComplete')] as Function;
        onComplete();
      });
      return _makeBloc(
        repository: repository,
        speechService: speechService,
        ttsService: ttsService,
      );
    },
    act: (bloc) => bloc.add(const AssistantEvent.sendMessage(_kQuestion)),
    expect: () => [
      const AssistantState.processing(userMessage: _kQuestion),
      const AssistantState.speaking(responseText: _kAnswer),
      const AssistantState.idle(),
    ],
    verify: (_) {
      verify(() => repository.ask(_kQuestion)).called(1);
      verify(
        () => ttsService.play(any(), onComplete: any(named: 'onComplete')),
      ).called(1);
    },
  );

  // ── SendMessage (network error) ───────────────────────────────────────────

  blocTest<AssistantBloc, AssistantState>(
    'SendMessage failure → Processing then Error',
    build: () {
      when(() => repository.ask(any()))
          .thenThrow(Exception('network error'));
      return _makeBloc(
        repository: repository,
        speechService: speechService,
        ttsService: ttsService,
      );
    },
    act: (bloc) => bloc.add(const AssistantEvent.sendMessage(_kQuestion)),
    expect: () => [
      const AssistantState.processing(userMessage: _kQuestion),
      const AssistantState.error(
          message: 'Désolé, une erreur est survenue.'),
    ],
  );

  // ── SendMessage with call_phone → phone called → [phone] feedback → Speaking ──
  //
  // When the agent returns a call_phone action, the BLoC:
  //   1. calls callByName() immediately (no TTS for the agent's initial text)
  //   2. on success/error/ambiguity: sends a [phone] result message back to the
  //      agent so it can respond naturally (confirm the call, explain an error,
  //      or ask for disambiguation).

  blocTest<AssistantBloc, AssistantState>(
    'SendMessage with call_phone (success) → sends [phone] feedback → agent responds → Speaking',
    build: () {
      const kFeedback = '[phone] Maman appelé.';
      final phoneService = MockPhoneCallService();
      when(() => repository.ask('Appelle Maman')).thenAnswer(
        (_) async => AssistantResponse(
          text: 'Je vais appeler Maman.',
          audioBytes: const [],
          callPhoneName: 'Maman',
        ),
      );
      when(() => phoneService.callByName('Maman', exactMatch: any(named: 'exactMatch')))
          .thenAnswer((_) async => PhoneCallSuccess());
      when(() => repository.ask(kFeedback)).thenAnswer((_) async => _kResponse);
      when(() => ttsService.play(any(), onComplete: any(named: 'onComplete')))
          .thenAnswer((_) async {});
      return AssistantBloc(
        repository: repository,
        speechService: speechService,
        ttsService: ttsService,
        phoneCallService: phoneService,
      );
    },
    act: (bloc) => bloc.add(const AssistantEvent.sendMessage('Appelle Maman')),
    expect: () => [
      const AssistantState.processing(userMessage: 'Appelle Maman'),
      const AssistantState.processing(userMessage: '[phone] Maman appelé.'),
      const AssistantState.speaking(responseText: _kAnswer),
    ],
    verify: (_) {
      verify(() => repository.ask('Appelle Maman')).called(1);
      verify(() => repository.ask('[phone] Maman appelé.')).called(1);
      verify(() => ttsService.play(any(), onComplete: any(named: 'onComplete'))).called(1);
    },
  );

  blocTest<AssistantBloc, AssistantState>(
    'SendMessage with call_phone (PhoneCallAmbiguous) → sends [phone] feedback with candidates',
    build: () {
      const kFeedback =
          '[phone] plusieurs contacts correspondent à "Martin" : Martin Jean et Martin Paul.';
      final phoneService = MockPhoneCallService();
      when(() => repository.ask('Appelle Martin')).thenAnswer(
        (_) async => AssistantResponse(
          text: '...',
          audioBytes: const [],
          callPhoneName: 'Martin',
        ),
      );
      when(() => phoneService.callByName('Martin', exactMatch: any(named: 'exactMatch')))
          .thenAnswer((_) async => PhoneCallAmbiguous(_kTwoCandidates));
      when(() => repository.ask(kFeedback))
          .thenAnswer((_) async => _kResponse);
      when(
        () => ttsService.play(any(), onComplete: any(named: 'onComplete')),
      ).thenAnswer((_) async {});
      return AssistantBloc(
        repository: repository,
        speechService: speechService,
        ttsService: ttsService,
        phoneCallService: phoneService,
      );
    },
    act: (bloc) => bloc.add(const AssistantEvent.sendMessage('Appelle Martin')),
    expect: () => [
      const AssistantState.processing(userMessage: 'Appelle Martin'),
      const AssistantState.processing(
        userMessage:
            '[phone] plusieurs contacts correspondent à "Martin" : Martin Jean et Martin Paul.',
      ),
      const AssistantState.speaking(responseText: _kAnswer),
    ],
    verify: (_) {
      verify(() => repository.ask(
            '[phone] plusieurs contacts correspondent à "Martin" : Martin Jean et Martin Paul.',
          )).called(1);
    },
  );

  blocTest<AssistantBloc, AssistantState>(
    'SendMessage with call_phone (PhoneCallError) → sends [phone] error feedback',
    build: () {
      const kErrMsg = "Je n'ai pas trouvé Inconnu dans vos contacts.";
      const kFeedback = '[phone] $kErrMsg';
      final phoneService = MockPhoneCallService();
      when(() => repository.ask('Appelle Inconnu')).thenAnswer(
        (_) async => AssistantResponse(
          text: '...',
          audioBytes: const [],
          callPhoneName: 'Inconnu',
        ),
      );
      when(() => phoneService.callByName('Inconnu', exactMatch: any(named: 'exactMatch')))
          .thenAnswer((_) async => PhoneCallError(kErrMsg));
      when(() => repository.ask(kFeedback))
          .thenAnswer((_) async => _kResponse);
      when(
        () => ttsService.play(any(), onComplete: any(named: 'onComplete')),
      ).thenAnswer((_) async {});
      return AssistantBloc(
        repository: repository,
        speechService: speechService,
        ttsService: ttsService,
        phoneCallService: phoneService,
      );
    },
    act: (bloc) =>
        bloc.add(const AssistantEvent.sendMessage('Appelle Inconnu')),
    expect: () => [
      const AssistantState.processing(userMessage: 'Appelle Inconnu'),
      const AssistantState.processing(
        userMessage:
            "[phone] Je n'ai pas trouvé Inconnu dans vos contacts.",
      ),
      const AssistantState.speaking(responseText: _kAnswer),
    ],
  );

  blocTest<AssistantBloc, AssistantState>(
    'SendMessage with call_phone (exactMatch=true) → passes exactMatch to callByName → sends feedback',
    build: () {
      const kFeedback = '[phone] Fred appelé.';
      final phoneService = MockPhoneCallService();
      when(() => repository.ask('Fred')).thenAnswer(
        (_) async => AssistantResponse(
          text: '...',
          audioBytes: const [],
          callPhoneName: 'Fred',
          callPhoneExactMatch: true,
        ),
      );
      // Stub only matches exactMatch=true — proves the flag is forwarded correctly.
      when(() => phoneService.callByName('Fred', exactMatch: true))
          .thenAnswer((_) async => PhoneCallSuccess());
      when(() => repository.ask(kFeedback)).thenAnswer((_) async => _kResponse);
      when(() => ttsService.play(any(), onComplete: any(named: 'onComplete')))
          .thenAnswer((_) async {});
      return AssistantBloc(
        repository: repository,
        speechService: speechService,
        ttsService: ttsService,
        phoneCallService: phoneService,
      );
    },
    act: (bloc) => bloc.add(const AssistantEvent.sendMessage('Fred')),
    expect: () => [
      const AssistantState.processing(userMessage: 'Fred'),
      const AssistantState.processing(userMessage: '[phone] Fred appelé.'),
      const AssistantState.speaking(responseText: _kAnswer),
    ],
    verify: (_) {
      verify(() => repository.ask('[phone] Fred appelé.')).called(1);
    },
  );

  // ── AudioFinished ─────────────────────────────────────────────────────────

  blocTest<AssistantBloc, AssistantState>(
    'AudioFinished → returns to Idle',
    build: () => _makeBloc(
      repository: repository,
      speechService: speechService,
      ttsService: ttsService,
    ),
    seed: () => const AssistantState.speaking(responseText: _kAnswer),
    act: (bloc) => bloc.add(const AssistantEvent.audioFinished()),
    expect: () => [const AssistantState.idle()],
  );

  // ── AudioFinished outside Speaking state → no state change ───────────────

  blocTest<AssistantBloc, AssistantState>(
    'AudioFinished outside Speaking state → ignored with no state change',
    build: () => _makeBloc(
      repository: repository,
      speechService: speechService,
      ttsService: ttsService,
    ),
    seed: () => const AssistantState.idle(),
    act: (bloc) => bloc.add(const AssistantEvent.audioFinished()),
    expect: () => [],
  );

  // ── ErrorOccurred ─────────────────────────────────────────────────────────

  blocTest<AssistantBloc, AssistantState>(
    'ErrorOccurred → switches to Error with the correct message',
    build: () => _makeBloc(
      repository: repository,
      speechService: speechService,
      ttsService: ttsService,
    ),
    act: (bloc) =>
        bloc.add(const AssistantEvent.errorOccurred('Rien entendu')),
    expect: () => [
      const AssistantState.error(message: 'Rien entendu'),
    ],
  );

  // ── STT unavailable → Error ───────────────────────────────────────────────

  blocTest<AssistantBloc, AssistantState>(
    'StartListening: STT unavailable → Error with explicit message',
    build: () {
      when(
        () => speechService.startListening(
          onInterim: any(named: 'onInterim'),
          onFinal: any(named: 'onFinal'),
          onTimeout: any(named: 'onTimeout'),
        ),
      ).thenAnswer((invocation) async {
        final onFinal = invocation.namedArguments[const Symbol('onFinal')]
            as void Function(String);
        onFinal('');
      });
      return _makeBloc(
        repository: repository,
        speechService: speechService,
        ttsService: ttsService,
      );
    },
    act: (bloc) => bloc.add(const AssistantEvent.startListening()),
    expect: () => [
      const AssistantState.listening(),
      const AssistantState.error(message: "Je n'ai rien entendu, réessayez."),
    ],
  );

  // ── STT final result → sendMessage ────────────────────────────────────────

  blocTest<AssistantBloc, AssistantState>(
    'StartListening: STT final result → triggers sendMessage flow',
    build: () {
      when(
        () => speechService.startListening(
          onInterim: any(named: 'onInterim'),
          onFinal: any(named: 'onFinal'),
          onTimeout: any(named: 'onTimeout'),
        ),
      ).thenAnswer((invocation) async {
        final onFinal = invocation.namedArguments[const Symbol('onFinal')]
            as void Function(String);
        onFinal(_kQuestion);
      });
      when(() => repository.ask(_kQuestion))
          .thenAnswer((_) async => _kResponse);
      when(
        () => ttsService.play(any(), onComplete: any(named: 'onComplete')),
      ).thenAnswer((_) async {});
      return _makeBloc(
        repository: repository,
        speechService: speechService,
        ttsService: ttsService,
      );
    },
    act: (bloc) => bloc.add(const AssistantEvent.startListening()),
    expect: () => [
      const AssistantState.listening(),
      const AssistantState.processing(userMessage: _kQuestion),
      const AssistantState.speaking(responseText: _kAnswer),
    ],
  );

  // ── onInterim callback ────────────────────────────────────────────────────

  blocTest<AssistantBloc, AssistantState>(
    'StartListening: onInterim callback → emits Listening with interimTranscript',
    build: () {
      when(
        () => speechService.startListening(
          onInterim: any(named: 'onInterim'),
          onFinal: any(named: 'onFinal'),
          onTimeout: any(named: 'onTimeout'),
        ),
      ).thenAnswer((invocation) async {
        final onInterim = invocation.namedArguments[const Symbol('onInterim')]
            as void Function(String);
        onInterim('Bon');
      });
      return _makeBloc(
        repository: repository,
        speechService: speechService,
        ttsService: ttsService,
      );
    },
    act: (bloc) => bloc.add(const AssistantEvent.startListening()),
    expect: () => [
      const AssistantState.listening(),
      const AssistantState.listening(interimTranscript: 'Bon'),
    ],
  );

  // ── StartListening while Listening → Idle ────────────────────────────────

  blocTest<AssistantBloc, AssistantState>(
    'StartListening while Listening → cancels STT and resets to Idle',
    build: () {
      when(() => speechService.stopListening()).thenAnswer((_) async {});
      return _makeBloc(
        repository: repository,
        speechService: speechService,
        ttsService: ttsService,
      );
    },
    seed: () =>
        const AssistantState.listening(interimTranscript: 'quelque chose'),
    act: (bloc) => bloc.add(const AssistantEvent.startListening()),
    expect: () => [const AssistantState.idle()],
    verify: (_) {
      verify(() => speechService.stopListening())
          .called(greaterThanOrEqualTo(1));
      verifyNever(
        () => speechService.startListening(
          onInterim: any(named: 'onInterim'),
          onFinal: any(named: 'onFinal'),
          onTimeout: any(named: 'onTimeout'),
        ),
      );
    },
  );

  blocTest<AssistantBloc, AssistantState>(
    'StartListening while Speaking → stops TTS and resets to Idle',
    build: () {
      when(() => ttsService.stop()).thenAnswer((_) async {});
      return _makeBloc(
        repository: repository,
        speechService: speechService,
        ttsService: ttsService,
      );
    },
    seed: () => const AssistantState.speaking(responseText: _kAnswer),
    act: (bloc) => bloc.add(const AssistantEvent.startListening()),
    expect: () => [const AssistantState.idle()],
  );

  // ── STT timeout → Idle ────────────────────────────────────────────────────

  blocTest<AssistantBloc, AssistantState>(
    'STT timeout (onTimeout callback) → resets to Idle',
    build: () {
      when(
        () => speechService.startListening(
          onInterim: any(named: 'onInterim'),
          onFinal: any(named: 'onFinal'),
          onTimeout: any(named: 'onTimeout'),
        ),
      ).thenAnswer((invocation) async {
        final onTimeout = invocation.namedArguments[const Symbol('onTimeout')]
            as void Function()?;
        onTimeout?.call();
      });
      when(() => speechService.stopListening()).thenAnswer((_) async {});
      return _makeBloc(
        repository: repository,
        speechService: speechService,
        ttsService: ttsService,
      );
    },
    act: (bloc) => bloc.add(const AssistantEvent.startListening()),
    expect: () => [
      const AssistantState.listening(),
      const AssistantState.idle(),
    ],
    verify: (_) => verifyNever(() => repository.ask(any())),
  );

  // ── AppResumed ────────────────────────────────────────────────────────────

  blocTest<AssistantBloc, AssistantState>(
    'AppResumed while Speaking → stops TTS and emits Idle',
    build: () {
      when(() => ttsService.stop()).thenAnswer((_) async {});
      return _makeBloc(
        repository: repository,
        speechService: speechService,
        ttsService: ttsService,
      );
    },
    seed: () => const AssistantState.speaking(responseText: _kAnswer),
    act: (bloc) => bloc.add(const AssistantEvent.appResumed()),
    expect: () => [const AssistantState.idle()],
  );

  blocTest<AssistantBloc, AssistantState>(
    'AppResumed while not Speaking → no state change',
    build: () => _makeBloc(
      repository: repository,
      speechService: speechService,
      ttsService: ttsService,
    ),
    seed: () => const AssistantState.idle(),
    act: (bloc) => bloc.add(const AssistantEvent.appResumed()),
    expect: () => [],
  );
}
