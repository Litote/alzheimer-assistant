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
/// Returns the bloc AND the audio player so the test can manually trigger
/// the end of audio playback.
({AssistantBloc bloc, ManualFakeStreamingAudioPlayerService audio}) _makeBloc({
  FakeLiveRepository? liveRepository,
  PhoneCallService? phoneCallService,
}) {
  final audio = ManualFakeStreamingAudioPlayerService();
  final bloc = AssistantBloc(
    liveRepository: liveRepository ?? makeFakeLiveRepository(),
    micService: FakeMicrophoneStreamService(),
    audioPlayer: audio,
    phoneCallService: phoneCallService,
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

/// Waits for the fake live stream events and the BLoC async chain to resolve
/// into a Speaking state.
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
      'Scenario 1: tap → listening → agent responds → back to Idle',
      (tester) async {
        final (:bloc, :audio) = _makeBloc();

        await tester.pumpWidget(App.forTesting(bloc: bloc));
        await tester.pumpAndSettle();

        // ── 1. Initial state: Idle ─────────────────────────────────────────
        expect(find.text('Appuyez pour parler'), findsOneWidget);
        expect(find.text('Appuyez sur le bouton pour me parler.'), findsOneWidget);

        // ── 2. Tap → Connecting → Listening ───────────────────────────────
        await _tapMic(tester);
        // Give the async _connect() time to transition past Connecting
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        // "Je vous écoute…" appears in both the header and the mic button
        expect(find.text('Je vous écoute…'), findsNWidgets(2));

        // ── 3. Fake stream emits events → Speaking ─────────────────────────
        await _waitForSpeaking(tester);

        expect(find.text(kAgentResponse), findsOneWidget,
            reason: 'Agent text delta must appear in the bubble');
        expect(find.text('Paul répond…'), findsOneWidget);
        expect(find.text('Je vous réponds.'), findsOneWidget);
        expect(find.text('Appuyez pour réessayer'), findsNothing);

        // ── 4. Audio playback ends → Idle ──────────────────────────────────
        audio.completePlayback();
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text('Appuyez pour parler'), findsOneWidget,
            reason: 'Must return to Idle after playback completes');

        await bloc.close();
      },
    );

    // ── Scenario 2: interrupt ─────────────────────────────────────────────

    testWidgets(
      'Scenario 2: tap while agent is speaking → stops and returns to Idle',
      (tester) async {
        final (:bloc, :audio) = _makeBloc();

        await tester.pumpWidget(App.forTesting(bloc: bloc));
        await tester.pumpAndSettle();

        await _tapMic(tester);
        await _waitForSpeaking(tester);

        expect(find.text('Paul répond…'), findsOneWidget);

        // Tap while Speaking → interrupt
        await _tapMic(tester);
        await tester.pumpAndSettle();

        expect(find.text('Appuyez pour parler'), findsOneWidget,
            reason: 'Interrupt must return app to Idle');

        await bloc.close();
      },
    );

    // ── Scenario 3: ambiguous call → tool response → disambiguation ────────

    testWidgets(
      'Scenario 3: ambiguous call → tool response → agent asks → user answers → call initiated',
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
        );

        await tester.pumpWidget(App.forTesting(bloc: bloc));
        await tester.pumpAndSettle();
        expect(find.text('Appuyez pour parler'), findsOneWidget);

        // ── Turn 1 ─────────────────────────────────────────────────────────
        await _tapMic(tester);
        await _waitForSpeaking(tester, extraMs: 100);

        expect(find.text(kDisambiguationAgentQuestion), findsOneWidget,
            reason: 'Agent disambiguation question must appear in the bubble');
        expect(find.text('Paul répond…'), findsOneWidget);

        audio.completePlayback();
        await tester.pump();
        await tester.pumpAndSettle();
        expect(find.text('Appuyez pour parler'), findsOneWidget);

        // ── Turn 2 ─────────────────────────────────────────────────────────
        await _tapMic(tester);
        await _waitForSpeaking(tester, extraMs: 100);

        expect(find.text(kCallConfirmationAgentText), findsOneWidget,
            reason: 'Confirmation text must appear after successful call');

        audio.completePlayback();
        await tester.pump();
        await tester.pumpAndSettle();
        expect(find.text('Appuyez pour parler'), findsOneWidget);

        await bloc.close();
      },
    );
  });
}
