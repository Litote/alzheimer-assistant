import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alzheimer_assistant/app/app.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_bloc.dart';
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
  final bloc = AssistantBloc(
    liveRepository: liveRepository ?? makeFakeLiveRepository(),
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
        // Give the async _connect() time to establish the session and emit Listening.
        // Fake events start at t=10 ms — pump(50ms) puts us after audioChunk
        // (t=10ms) and outputTranscription (t=20ms) but before turnComplete
        // (t=30ms), so the Speaking state is visible.
        await tester.pump(const Duration(milliseconds: 50));

        // ── 3. Speaking: agent text and UI labels are visible ──────────────
        expect(find.text(kAgentResponse), findsOneWidget,
            reason: 'outputTranscription must appear in the response bubble');
        expect(find.text('Paul répond…'), findsOneWidget);
        expect(find.text('Je vous réponds.'), findsOneWidget);
        expect(find.text('Appuyez pour réessayer'), findsNothing);

        // ── 4. turnComplete → Listening (bidi: mic stays active) ──────────
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();
        expect(find.text('Je vous écoute…'), findsNWidgets(2));

        // ── 5. Tap → cancel → Idle ─────────────────────────────────────────
        await _tapMic(tester);
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

        // Tap → Speaking (audioChunk fires at t≈10ms, no turnComplete)
        await _tapMic(tester);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        expect(find.text('Paul répond…'), findsOneWidget);
        expect(find.text('Je vous réponds.'), findsOneWidget);

        // Tap while Speaking → interrupt → Idle
        await _tapMic(tester);
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

        // ── Turn 1 ─────────────────────────────────────────────────────────
        // Events: callPhone(10ms) + audioChunk(20ms) + outputTranscription(30ms)
        // + turnComplete(40ms). Pump 35ms → Speaking with disambiguation text.
        await tester.pump(const Duration(milliseconds: 35));

        expect(find.text(kDisambiguationAgentQuestion), findsOneWidget,
            reason: 'Agent disambiguation question must appear in the bubble');
        expect(find.text('Paul répond…'), findsOneWidget);

        // Let turnComplete process → Listening
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();
        expect(find.text('Je vous écoute…'), findsNWidgets(2));

        // ── Turn 2 ─────────────────────────────────────────────────────────
        // After 50ms inter-turn pause, turn 2 events arrive on the same connection.
        // Pump 200ms to pass the pause + get audioChunk + outputTranscription.
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text(kCallConfirmationAgentText), findsOneWidget,
            reason: 'Confirmation text must appear after successful call');
        expect(find.text('Paul répond…'), findsOneWidget);

        // Let turnComplete process → Listening
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();
        expect(find.text('Je vous écoute…'), findsNWidgets(2));

        // ── Tap → cancel → Idle ────────────────────────────────────────────
        await _tapMic(tester);
        await tester.pumpAndSettle();
        expect(find.text('Appuyez pour parler'), findsOneWidget);

        await bloc.close();
      },
    );
  });
}
