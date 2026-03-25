import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:alzheimer_assistant/app/app.dart';
import 'package:alzheimer_assistant/features/assistant/data/repositories/assistant_repository_impl.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_bloc.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/widgets/mic_button.dart';

import 'helpers/fake_speech_service.dart';
import 'helpers/fake_tts_service.dart';
import 'helpers/mock_dio.dart';

// ── Constants ──────────────────────────────────────────────────────────────

const _kQuestion = 'Où sont mes médicaments ?';
const _kResponse = 'Vos médicaments sont sur la table de nuit.';

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
