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

const _kCandidates = <PhoneCandidate>[
  (displayName: 'Maman Martin', number: '+33612345678'),
];
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

  // ── SendMessage (success) ─────────────────────────────────────────────────

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

  // ── pendingCallName in the Speaking state ─────────────────────────────────
  //
  // Verifies that the contact name is carried in the state (not in a
  // mutable Bloc field), enabling test via seed/expect.

  blocTest<AssistantBloc, AssistantState>(
    'SendMessage with callPhoneName → Speaking carries pendingCallName',
    build: () {
      when(() => repository.ask(_kQuestion)).thenAnswer(
        (_) async => AssistantResponse(
          text: _kAnswer,
          audioBytes: const [1, 2, 3],
          callPhoneName: 'Maman',
        ),
      );
      // play() does NOT trigger onComplete, to stay in Speaking
      when(
        () => ttsService.play(any(), onComplete: any(named: 'onComplete')),
      ).thenAnswer((_) async {});
      return _makeBloc(
        repository: repository,
        speechService: speechService,
        ttsService: ttsService,
      );
    },
    act: (bloc) => bloc.add(const AssistantEvent.sendMessage(_kQuestion)),
    expect: () => [
      const AssistantState.processing(userMessage: _kQuestion),
      const AssistantState.speaking(
        responseText: _kAnswer,
        pendingCallName: 'Maman',
      ),
    ],
  );

  // ── AudioFinished with pendingCallName → phone call ───────────────────────

  blocTest<AssistantBloc, AssistantState>(
    'AudioFinished with pendingCallName → triggers callByName then confirmation audio',
    build: () {
      final phoneService = MockPhoneCallService();
      when(() => phoneService.callByName('Maman'))
          .thenAnswer((_) async => PhoneCallSuccess());
      when(() => repository.synthesize(any()))
          .thenAnswer((_) async => [1, 2, 3]);
      when(() => ttsService.play(any(), onComplete: any(named: 'onComplete')))
          .thenAnswer((_) async {});
      return AssistantBloc(
        repository: repository,
        speechService: speechService,
        ttsService: ttsService,
        phoneCallService: phoneService,
      );
    },
    seed: () => const AssistantState.speaking(
      responseText: _kAnswer,
      pendingCallName: 'Maman',
    ),
    act: (bloc) => bloc.add(const AssistantEvent.audioFinished()),
    expect: () => [
      const AssistantState.idle(),
      const AssistantState.speaking(
        responseText: "J'appelle Maman. Bonne conversation !",
      ),
    ],
  );

  // ── synthesize() fails in _synthesizeAndSpeak → ErrorOccurred ────────────

  blocTest<AssistantBloc, AssistantState>(
    'synthesize() fails during a call error → Error with the text message',
    build: () {
      final phoneService = MockPhoneCallService();
      when(() => phoneService.callByName(any()))
          .thenAnswer((_) async => PhoneCallError("Contact introuvable."));
      when(() => repository.synthesize(any()))
          .thenThrow(Exception('ElevenLabs down'));
      return AssistantBloc(
        repository: repository,
        speechService: speechService,
        ttsService: ttsService,
        phoneCallService: phoneService,
      );
    },
    seed: () => const AssistantState.speaking(
      responseText: _kAnswer,
      pendingCallName: 'Inconnu',
    ),
    act: (bloc) => bloc.add(const AssistantEvent.audioFinished()),
    expect: () => [
      const AssistantState.idle(),
      const AssistantState.error(message: 'Contact introuvable.'),
    ],
  );

  // ── AudioFinished outside Speaking state → no state change ───────────────
  //
  // The `if (currentState is! Speaking) return` guard protects against an
  // unexpected AudioFinished (e.g. duplicate event). We verify it
  // emits no transition and does not crash.

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

  // ── STT unavailable → StartListening → Error (no crash) ──────────────────
  //
  // On devices without a microphone (simulator without configured mic,
  // accessibility devices…), initialize() returns false.
  // startListening() then calls onFinal('') which triggers errorOccurred
  // in the Bloc → the app switches to Error rather than staying in Listening.

  blocTest<AssistantBloc, AssistantState>(
    'StartListening: STT unavailable → Error with explicit message',
    build: () {
      when(
        () => speechService.startListening(
          onInterim: any(named: 'onInterim'),
          onFinal: any(named: 'onFinal'),
        ),
      ).thenAnswer((invocation) async {
        // Simulates initialize() → false: calls onFinal('') immediately
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

  // ── StartListening: STT final result triggers sendMessage ─────────────────
  //
  // Covers the onFinal callback with non-empty text (line 50 in bloc):
  // add(AssistantEvent.sendMessage(text))

  blocTest<AssistantBloc, AssistantState>(
    'StartListening: STT final result → triggers sendMessage flow',
    build: () {
      when(
        () => speechService.startListening(
          onInterim: any(named: 'onInterim'),
          onFinal: any(named: 'onFinal'),
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

  // ── StartListening: onInterim callback ────────────────────────────────────
  //
  // Covers the onInterim closure inside _onStartListening.

  blocTest<AssistantBloc, AssistantState>(
    'StartListening: onInterim callback → emits Listening with interimTranscript',
    build: () {
      when(
        () => speechService.startListening(
          onInterim: any(named: 'onInterim'),
          onFinal: any(named: 'onFinal'),
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

  // ── AudioFinished: awaitingDisambiguation ─────────────────────────────────
  //
  // After the disambiguation question is spoken, the bloc must re-enter
  // Listening with the pending candidates still attached.

  blocTest<AssistantBloc, AssistantState>(
    'AudioFinished with awaitingDisambiguation → Listening with pendingCandidates',
    build: () {
      when(
        () => speechService.startListening(
          onInterim: any(named: 'onInterim'),
          onFinal: any(named: 'onFinal'),
        ),
      ).thenAnswer((_) async {});
      return _makeBloc(
        repository: repository,
        speechService: speechService,
        ttsService: ttsService,
      );
    },
    seed: () => const AssistantState.speaking(
      responseText: _kAnswer,
      awaitingDisambiguation: true,
      pendingCandidates: _kCandidates,
    ),
    act: (bloc) => bloc.add(const AssistantEvent.audioFinished()),
    expect: () => [
      const AssistantState.listening(pendingCandidates: _kCandidates),
    ],
  );

  // ── AudioFinished during disambiguation: empty STT → Error ────────────────

  blocTest<AssistantBloc, AssistantState>(
    'AudioFinished with awaitingDisambiguation: empty STT → Error',
    build: () {
      when(
        () => speechService.startListening(
          onInterim: any(named: 'onInterim'),
          onFinal: any(named: 'onFinal'),
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
    seed: () => const AssistantState.speaking(
      responseText: _kAnswer,
      awaitingDisambiguation: true,
      pendingCandidates: _kCandidates,
    ),
    act: (bloc) => bloc.add(const AssistantEvent.audioFinished()),
    expect: () => [
      const AssistantState.listening(pendingCandidates: _kCandidates),
      const AssistantState.error(message: "Je n'ai rien entendu, réessayez."),
    ],
  );

  // ── DisambiguateCall: match found ─────────────────────────────────────────

  blocTest<AssistantBloc, AssistantState>(
    'DisambiguateCall: match found → callByNumber then PhoneCallSuccess',
    build: () {
      final phoneService = MockPhoneCallService();
      when(
        () => phoneService.callByNumber(
          '+33612345678',
          displayName: 'Maman Martin',
        ),
      ).thenAnswer((_) async => PhoneCallSuccess());
      when(() => repository.synthesize(any()))
          .thenAnswer((_) async => [1, 2, 3]);
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
    seed: () =>
        const AssistantState.listening(pendingCandidates: _kCandidates),
    act: (bloc) =>
        bloc.add(const AssistantEvent.disambiguateCall('Maman')),
    expect: () => [
      const AssistantState.idle(),
      const AssistantState.speaking(
        responseText: "J'appelle Maman Martin. Bonne conversation !",
      ),
    ],
  );

  // ── DisambiguateCall: no match ────────────────────────────────────────────

  blocTest<AssistantBloc, AssistantState>(
    'DisambiguateCall: no match → speaks disambiguation-error message',
    build: () {
      when(() => repository.synthesize(any()))
          .thenAnswer((_) async => [1, 2, 3]);
      when(
        () => ttsService.play(any(), onComplete: any(named: 'onComplete')),
      ).thenAnswer((_) async {});
      return _makeBloc(
        repository: repository,
        speechService: speechService,
        ttsService: ttsService,
      );
    },
    seed: () =>
        const AssistantState.listening(pendingCandidates: _kCandidates),
    act: (bloc) =>
        bloc.add(const AssistantEvent.disambiguateCall('Inconnu')),
    expect: () => [
      const AssistantState.speaking(
        responseText: "Je n'ai pas compris. Voulez-vous réessayer ?",
      ),
    ],
  );

  // ── DisambiguateCall: no pendingCandidates → ignored ─────────────────────

  blocTest<AssistantBloc, AssistantState>(
    'DisambiguateCall: no pendingCandidates → ignored',
    build: () => _makeBloc(
      repository: repository,
      speechService: speechService,
      ttsService: ttsService,
    ),
    seed: () => const AssistantState.idle(),
    act: (bloc) =>
        bloc.add(const AssistantEvent.disambiguateCall('Maman')),
    expect: () => [],
  );

  // ── PhoneCallAmbiguous → asks disambiguation question ─────────────────────

  blocTest<AssistantBloc, AssistantState>(
    'AudioFinished with PhoneCallAmbiguous → asks disambiguation question',
    build: () {
      final phoneService = MockPhoneCallService();
      when(() => phoneService.callByName('Martin'))
          .thenAnswer((_) async => PhoneCallAmbiguous(_kTwoCandidates));
      when(() => repository.synthesize(any()))
          .thenAnswer((_) async => [1, 2, 3]);
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
    seed: () => const AssistantState.speaking(
      responseText: _kAnswer,
      pendingCallName: 'Martin',
    ),
    act: (bloc) => bloc.add(const AssistantEvent.audioFinished()),
    expect: () => [
      const AssistantState.idle(),
      const AssistantState.speaking(
        responseText:
            "J'ai trouvé plusieurs contacts : Martin Jean et Martin Paul. Lequel voulez-vous appeler ?",
        awaitingDisambiguation: true,
        pendingCandidates: _kTwoCandidates,
      ),
    ],
  );
}
