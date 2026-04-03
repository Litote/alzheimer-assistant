import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alzheimer_assistant/app/app.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_bloc.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_state.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/widgets/mic_button.dart';
import 'package:alzheimer_assistant/shared/services/phone_call_service.dart';

import 'helpers/fake_live_repository.dart';
import 'helpers/fake_speech_service.dart';
import 'helpers/fake_tts_service.dart';

// ── Fakes ──────────────────────────────────────────────────────────────────

/// Overrides [callByName] with a preset sequence of results, bypassing the
/// real contacts/permissions stack entirely.
class _FakePhoneCallService extends PhoneCallService {
  _FakePhoneCallService({required List<PhoneCallResult> results})
      : _results = results;

  final List<PhoneCallResult> _results;
  var _index = 0;

  @override
  Future<PhoneCallResult> callByName(String name,
          {bool exactMatch = false}) async =>
      _results[_index++];
}

// ── Helpers ────────────────────────────────────────────────────────────────

/// Creates a bloc wired with controllable fakes.
({AssistantBloc bloc, ManualFakeStreamingAudioPlayerService audio}) _makeBloc({
  FakeLiveRepository? liveRepository,
  PhoneCallService? phoneCallService,
  bool showTranscription = false,
}) {
  final audio = ManualFakeStreamingAudioPlayerService();
  final repo = liveRepository ?? makeFakeLiveRepository();
  final bloc = AssistantBloc(
    audioRepository: repo,
    textRepository: repo,
    micService: FakeMicrophoneStreamService(),
    audioPlayer: audio,
    phoneCallService: phoneCallService,
    showTranscription: showTranscription,
  );
  return (bloc: bloc, audio: audio);
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

/// Pumps [step] at a time until [condition] returns true or [timeout] elapses.
///
/// Unlike [WidgetTester.pumpAndSettle], this helper works even when the widget
/// tree contains infinite animations (e.g. the pulsing MicButton in
/// Listening/Speaking states).
Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  Duration step = const Duration(milliseconds: 50),
  Duration timeout = const Duration(seconds: 10),
}) async {
  final end = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(end)) {
      throw StateError('_pumpUntil timed out after $timeout');
    }
    await tester.pump(step);
  }
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

    // ── Scenario 1: nominal bidi round-trip ───────────────────────────────

    testWidgets(
      'Scenario 1: tap → Listening → Speaking (text visible) → Listening → Idle',
      (tester) async {
        // showTranscription: true so outputTranscription populates the bubble.
        final (:bloc, :audio) = _makeBloc(showTranscription: true);

        await tester.pumpWidget(App.forTesting(bloc: bloc));
        await tester.pumpAndSettle();

        // ── 1. Initial state: Idle ─────────────────────────────────────────
        expect(find.text('Appuyez pour parler'), findsOneWidget);
        expect(find.text('Appuyez sur le bouton pour me parler.'), findsOneWidget);

        // ── 2. Tap → Connecting → Listening ───────────────────────────────
        await _tapMic(tester);

        // ── 3. Speaking: wait until agent text arrives ────────────────────
        // The MicButton has an infinite repeat animation while Speaking/Listening
        // so we must NOT use pumpAndSettle here — use _pumpUntil instead.
        await _pumpUntil(tester, () => switch (bloc.state) {
              Speaking(:final responseText) => responseText == kAgentResponse,
              _ => false,
            });
        // One extra pump so the widget tree renders the new state.
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.text(kAgentResponse), findsOneWidget,
            reason: 'outputTranscription must appear in the response bubble');
        expect(find.text('Réponse…'), findsOneWidget);
        expect(find.text('Je vous réponds.'), findsOneWidget);
        expect(find.text('Appuyez pour réessayer'), findsNothing);

        // ── 4. turnComplete → Listening (bidi: mic stays active) ──────────
        await _pumpUntil(tester, () => bloc.state is Listening);
        // Extra pump so AnimatedSwitcher renders the new label in both
        // Header and MicButton (both transitions start immediately but
        // the widget is created on the first frame after state change).
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.text('Je vous écoute…'), findsNWidgets(2));

        // ── 5. Tap → cancel → Idle ─────────────────────────────────────────
        await _tapMic(tester);
        await _pumpUntil(tester, () => bloc.state is Idle);
        // Idle state: _controller.stop() is called so the infinite animation
        // ends; pumpAndSettle is safe here to let AnimatedContainer /
        // AnimatedSwitcher finish their finite transitions.
        await tester.pumpAndSettle();
        expect(find.text('Appuyez pour parler'), findsOneWidget,
            reason: 'Cancelling while Listening must return to Idle');

        await bloc.close();
      },
    );

    // ── Scenario 2: interrupt while Speaking ──────────────────────────────

    testWidgets(
      'Scenario 2: tap while agent is speaking → stops and returns to Idle',
      (tester) async {
        // Use a fake with no turnComplete so state stays in Speaking.
        final (:bloc, :audio) =
            _makeBloc(liveRepository: makeFakeLiveRepositoryForInterrupt());

        await tester.pumpWidget(App.forTesting(bloc: bloc));
        await tester.pumpAndSettle();

        // Tap → Speaking (audioChunk fires, no turnComplete)
        await _tapMic(tester);
        await _pumpUntil(tester, () => bloc.state is Speaking);
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.text('Réponse…'), findsOneWidget);
        expect(find.text('Je vous réponds.'), findsOneWidget);

        // Tap while Speaking → interrupt → Idle
        await _tapMic(tester);
        await _pumpUntil(tester, () => bloc.state is Idle);
        await tester.pumpAndSettle();

        expect(find.text('Appuyez pour parler'), findsOneWidget,
            reason: 'Interrupt must return app to Idle');

        await bloc.close();
      },
    );

    // ── Scenario 3: ambiguous call → disambiguation → call confirmed ───────

    testWidgets(
      'Scenario 3: ambiguous call → agent asks → second turn on same connection → call confirmed',
      (tester) async {
        final (:bloc, :audio) = _makeBloc(
          liveRepository: makeFakeLiveRepositoryForDisambiguation(),
          phoneCallService: _FakePhoneCallService(
            results: [
              PhoneCallAmbiguous([
                (displayName: 'Marie Dupont', number: '0601020304'),
                (displayName: 'Marie Martin', number: '0605060708'),
              ]),
              PhoneCallSuccess(),
            ],
          ),
          showTranscription: true,
        );

        await tester.pumpWidget(App.forTesting(bloc: bloc));
        await tester.pumpAndSettle();
        expect(find.text('Appuyez pour parler'), findsOneWidget);

        // ── Single tap: one connection handles BOTH turns ──────────────────
        await _tapMic(tester);

        // ── Turn 1: wait for Speaking with disambiguation text ─────────────
        await _pumpUntil(tester, () => switch (bloc.state) {
              Speaking(:final responseText) =>
                responseText == kDisambiguationAgentQuestion,
              _ => false,
            });
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.text(kDisambiguationAgentQuestion), findsOneWidget,
            reason: 'Agent disambiguation question must appear in the bubble');
        expect(find.text('Réponse…'), findsOneWidget);

        // ── Turn 1 → turnComplete → Listening ─────────────────────────────
        await _pumpUntil(tester, () => bloc.state is Listening);
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.text('Je vous écoute…'), findsNWidgets(2));

        // ── Turn 2: arrives on the same connection after the inter-turn pause.
        // Wait for Speaking with the call-confirmation text.
        await _pumpUntil(tester, () => switch (bloc.state) {
              Speaking(:final responseText) =>
                responseText == kCallConfirmationAgentText,
              _ => false,
            });
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.text(kCallConfirmationAgentText), findsOneWidget,
            reason: 'Confirmation text must appear after successful call');
        expect(find.text('Réponse…'), findsOneWidget);

        // ── Turn 2 → turnComplete → Listening ─────────────────────────────
        await _pumpUntil(tester, () => bloc.state is Listening);
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.text('Je vous écoute…'), findsNWidgets(2));

        // ── Tap → cancel → Idle ────────────────────────────────────────────
        await _tapMic(tester);
        await _pumpUntil(tester, () => bloc.state is Idle);
        await tester.pumpAndSettle();
        expect(find.text('Appuyez pour parler'), findsOneWidget);

        await bloc.close();
      },
    );
  });
}
