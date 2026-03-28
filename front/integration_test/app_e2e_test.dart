import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alzheimer_assistant/app/app.dart';
import 'package:alzheimer_assistant/features/assistant/data/repositories/assistant_repository_impl.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_bloc.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/widgets/mic_button.dart';
import 'package:alzheimer_assistant/shared/services/phone_call_service.dart';

import 'helpers/fake_speech_service.dart';
import 'helpers/fake_tts_service.dart';
import 'helpers/mock_dio.dart';

// ── Constants ──────────────────────────────────────────────────────────────

const _kQuestion = 'Où sont mes médicaments ?';
const _kResponse = 'Vos médicaments sont sur la table de nuit.';

// Scenario 3 constants come from mock_dio (kDisambiguationAgentQuestion,
// kCallConfirmationAgentText) to stay in sync with the mock responses.

// ── Fakes ──────────────────────────────────────────────────────────────────

/// Overrides [callByName] with a preset sequence of results, bypassing the
/// real contacts/permissions stack entirely.
class _FakePhoneCallService extends PhoneCallService {
  _FakePhoneCallService({required List<PhoneCallResult> results})
      : _results = results;

  final List<PhoneCallResult> _results;
  var _index = 0;

  @override
  Future<PhoneCallResult> callByName(String name, {bool exactMatch = false}) async =>
      _results[_index++];
}

// ── Helpers ────────────────────────────────────────────────────────────────

/// Creates a bloc wired with controllable services.
/// Returns the bloc AND the TTS service so the test can manually trigger
/// the end of audio playback.
({AssistantBloc bloc, ManualFakeTtsService tts}) _makeBloc({
  bool simulate404 = false,
}) {
  final tts = ManualFakeTtsService();
  final bloc = AssistantBloc(
    repository: AssistantRepositoryImpl(
      adkDio: makeMockAdkDio(simulate404OnFirstRun: simulate404),
      elevenLabsDio: makeMockElevenLabsDio(),
    ),
    speechService: FakeSpeechRecognitionService(transcript: _kQuestion),
    ttsService: tts,
  );
  return (bloc: bloc, tts: tts);
}

/// Taps the mic button (GestureDetector child of MicButton).
Future<void> _tapMic(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(MicButton),
      matching: find.byType(GestureDetector),
    ),
  );
  await tester.pump();
}

/// Waits for the FakeSpeechService to fire onFinal and for the async chain
/// (mock API → SpeakResponse → Speaking) to resolve.
/// delay = interimDelay + finalDelay + margin for microtasks.
Future<void> _waitForSpeaking(WidgetTester tester, {int extraMs = 0}) async {
  await tester.pump(Duration(milliseconds: 150 + extraMs));
  await tester.pumpAndSettle();
}

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Assistant App — E2E', () {
    setUp(() async {
      // Mark onboarding as done so the router goes directly to HomeScreen.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_done', true);
    });
    // ── Scenario 1: nominal flow ───────────────────────────────────────────

    testWidgets(
      'Scenario 1: tap → listen → response displayed → back to Idle',
      (tester) async {
        final (:bloc, :tts) = _makeBloc();

        await tester.pumpWidget(App.forTesting(bloc: bloc));
        await tester.pumpAndSettle();

        // ── 1. Initial state: Idle ─────────────────────────────────────────
        expect(
          find.text('Appuyez pour parler'),
          findsOneWidget,
          reason: 'Button must show the initial invitation text',
        );
        expect(
          find.text('Appuyez sur le bouton pour me parler.'),
          findsOneWidget,
        );

        // ── 2. Tap → Listening (state emitted synchronously) ───────────────
        await _tapMic(tester);

        expect(
          find.text('Écoute en cours…'),
          findsOneWidget,
          reason: 'Listening must be visible immediately after tap',
        );
        expect(find.text('Je vous écoute…'), findsOneWidget);

        // ── 3. Wait for Speaking state: STT (100ms) + mock API + Speaking
        //      ManualFakeTtsService blocks here → we stay in Speaking ───────
        // Note: interim transcript is tested at unit level (BLoC test).
        // In E2E we don't test microsecond timers: too fragile on CI.
        await _waitForSpeaking(tester);

        expect(
          find.text(_kResponse),
          findsOneWidget,
          reason: 'The assistant response must appear in the bubble',
        );
        expect(
          find.text('En train de répondre…'),
          findsOneWidget,
          reason: 'The button label must indicate playback in progress',
        );
        expect(
          find.text('Appuyez pour réessayer'),
          findsNothing,
          reason: 'No error must appear on the nominal flow',
        );

        // ── 5. End of audio playback → Idle ───────────────────────────────
        // The test manually triggers TTS end (no in-flight timer)
        tts.completePlayback();
        await tester.pump(); // processes AudioFinished → emit Idle
        await tester.pumpAndSettle();

        expect(
          find.text('Appuyez pour parler'),
          findsOneWidget,
          reason: 'The app must return to Idle after playback',
        );

        // Clean close: all async operations are finished
        await bloc.close();
      },
    );

    // ── Scenario 3: ambiguous call → [phone] feedback loop ────────────
    //
    // Full flow ([phone] architecture):
    //   Tap 1: "Appelle Marie"
    //     → ADK call_phone("Marie") — BLoC skips TTS
    //     → callByName("Marie") → PhoneCallAmbiguous
    //     → sendMessage("[phone] plusieurs contacts…")
    //     → ADK responds with disambiguation question → Speaking → Idle
    //   Tap 2: "Marie Dupont"
    //     → ADK call_phone("Marie Dupont") — BLoC skips TTS
    //     → callByName("Marie Dupont") → PhoneCallSuccess
    //     → sendMessage("[phone] Marie Dupont appelé.")
    //     → ADK responds with confirmation → Speaking → Idle

    testWidgets(
      'Scenario 3: ambiguous call → [phone] feedback → agent asks → user answers → call initiated',
      (tester) async {
        final tts = ManualFakeTtsService();
        final bloc = AssistantBloc(
          repository: AssistantRepositoryImpl(
            adkDio: makeMockAdkDioForDisambiguation(),
            elevenLabsDio: makeMockElevenLabsDio(),
          ),
          speechService: SequentialFakeSpeechRecognitionService(
            transcripts: ['Appelle Marie', 'Marie Dupont'],
          ),
          ttsService: tts,
          phoneCallService: _FakePhoneCallService(
            results: [
              PhoneCallAmbiguous([
                (displayName: 'Marie Dupont', number: '0601020304'),
                (displayName: 'Marie Martin', number: '0605060708'),
              ]),
              PhoneCallSuccess(),
            ],
          ),
        );

        await tester.pumpWidget(App.forTesting(bloc: bloc));
        await tester.pumpAndSettle();
        expect(find.text('Appuyez pour parler'), findsOneWidget);

        // ── Tap 1: "Appelle Marie" ──────────────────────────────────────────
        // ADK call 1 → call_phone("Marie") → callByName → PhoneCallAmbiguous
        // → sendMessage("[phone] plusieurs contacts…")
        // ADK call 2 → disambiguation question → Speaking
        await _tapMic(tester);
        expect(find.text('Écoute en cours…'), findsOneWidget);

        // Two sequential ADK calls happen before Speaking — give extra margin.
        await _waitForSpeaking(tester, extraMs: 100);

        expect(
          find.text(kDisambiguationAgentQuestion),
          findsOneWidget,
          reason: 'Agent disambiguation question must appear in the bubble',
        );
        expect(find.text('En train de répondre…'), findsOneWidget);

        // TTS ends → Idle (user must tap again to answer)
        tts.completePlayback();
        await tester.pump();
        await tester.pumpAndSettle();
        expect(find.text('Appuyez pour parler'), findsOneWidget);

        // ── Tap 2: "Marie Dupont" ──────────────────────────────────────────
        // ADK call 3 → call_phone("Marie Dupont") → callByName → PhoneCallSuccess
        // → sendMessage("[phone] Marie Dupont appelé.")
        // ADK call 4 → confirmation text → Speaking
        await _tapMic(tester);
        expect(find.text('Écoute en cours…'), findsOneWidget);

        await _waitForSpeaking(tester, extraMs: 100);

        expect(
          find.text(kCallConfirmationAgentText),
          findsOneWidget,
          reason: 'Agent confirmation must appear after the call is initiated',
        );

        // TTS ends → Idle
        tts.completePlayback();
        await tester.pump();
        await tester.pumpAndSettle();

        expect(
          find.text('Appuyez pour parler'),
          findsOneWidget,
          reason: 'App must return to Idle after the call confirmation',
        );

        await bloc.close();
      },
    );

    // ── Scenario 2: expired ADK session → 404 → transparent retry ─────────
    //
    // Reproduces the production bug: ADK agent in-memory restarted → session lost
    // → first /run returns 404 → the fix clears the session and retries.
    // The user sees no error message.

    testWidgets(
      'Scenario 2: expired session (404) → silent retry → normal response',
      (tester) async {
        final (:bloc, :tts) = _makeBloc(simulate404: true);

        await tester.pumpWidget(App.forTesting(bloc: bloc));
        await tester.pumpAndSettle();

        expect(find.text('Appuyez pour parler'), findsOneWidget);

        // Tap → Listening
        await _tapMic(tester);
        expect(find.text('Écoute en cours…'), findsOneWidget);

        // Wait: STT (100ms) + 404 + clear session + retry + API → Speaking
        // Give a larger margin for the 404 → retry cycle
        await _waitForSpeaking(tester, extraMs: 100);

        // ── The user does NOT see an error ────────────────────────────────
        expect(
          find.text('Appuyez pour réessayer'),
          findsNothing,
          reason: 'The 404 must be absorbed internally without an error state',
        );

        // ── The response appears as if nothing happened ────────────────────
        expect(
          find.text(_kResponse),
          findsOneWidget,
          reason: 'The final response must appear despite the initial 404',
        );

        // Clean close
        tts.completePlayback();
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text('Appuyez pour parler'), findsOneWidget);
        await bloc.close();
      },
    );
  });
}
