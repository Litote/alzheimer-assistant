import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alzheimer_assistant/app/app.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_bloc.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_state.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/widgets/mic_button.dart';
import 'package:alzheimer_assistant/shared/services/settings_service.dart';
import 'package:alzheimer_assistant/shared/services/client_tts_service.dart';
import 'package:alzheimer_assistant/shared/services/speech_recognition_service.dart';

import 'helpers/fake_live_repository.dart';
import 'helpers/fake_speech_service.dart';

// ── Fakes ──────────────────────────────────────────────────────────────────

/// Fake for STT (Speech-To-Text) used in text mode.
class _FakeSpeechRecognitionService extends SpeechRecognitionService {
  _FakeSpeechRecognitionService({required this.recognizedText});
  final String recognizedText;

  @override
  Future<void> startListening({
    required void Function(String text) onInterim,
    required void Function(String text) onFinal,
    void Function()? onTimeout,
  }) async {
    // Simulate a brief delay then the final result.
    await Future.delayed(const Duration(milliseconds: 100));
    onFinal(recognizedText);
  }

  @override
  Future<void> stopListening() async {}
}

/// Fake for TTS (Text-To-Speech) used in text mode.
/// Uses 'implements' because ClientTtsService is an 'interface class'.
class _FakeClientTtsService implements ClientTtsService {
  bool speakCalled = false;
  String? lastSpokenText;
  void Function()? _onComplete;

  @override
  Future<void> speak(String text, {required void Function() onComplete}) async {
    speakCalled = true;
    lastSpokenText = text;
    _onComplete = onComplete;
  }

  void completePlayback() {
    _onComplete?.call();
    _onComplete = null;
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

// ── Helpers ────────────────────────────────────────────────────────────────

/// Creates a bloc wired for text-to-text mode testing.
({AssistantBloc bloc, _FakeClientTtsService tts}) _makeTextBloc({
  String userVoiceInput = 'Bonjour',
  FakeLiveRepository? liveRepository,
}) {
  final tts = _FakeClientTtsService();
  final bloc = AssistantBloc(
    textRepository: liveRepository ?? makeFakeLiveRepository(),
    micService: FakeMicrophoneStreamService(),
    speechService: _FakeSpeechRecognitionService(recognizedText: userVoiceInput),
    nativeTtsService: tts,
    elevenLabsTtsService: tts,
    settingsService: SettingsService(),
    showTranscription: true,
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

/// Pumps [step] at a time until [condition] returns true or [timeout] elapses.
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

  group('Assistant App — Text to Text E2E', () {
    setUp(() async {
      // Mark onboarding as done so the router goes directly to HomeScreen.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_done', true);
      // Force text mode for these tests.
      await prefs.setBool('use_text_mode', true);
    });

    // ── Scenario 1: Nominal text round-trip ───────────────────────────────

    testWidgets(
      'Scenario 1: Voice Input → Text → Agent → TTS Output → Return to Idle',
      (tester) async {
        const kUserInput = 'Quelle heure est-il ?';
        final (:bloc, :tts) = _makeTextBloc(userVoiceInput: kUserInput);

        await tester.pumpWidget(App.forTesting(bloc: bloc));
        await tester.pumpAndSettle();

        // ── 1. Initial state: Idle ─────────────────────────────────────────
        expect(find.text('Appuyez pour parler'), findsOneWidget);

        // ── 2. Tap Mic → Triggers STT → emits Speaking ─────────────────────
        await _tapMic(tester);
        
        await _pumpUntil(tester, () => bloc.state is Speaking);
        // User transcript or interim text might be emitted.

        await tester.pump(const Duration(milliseconds: 50));
        expect(find.text(kUserInput), findsOneWidget);
        
        // ── 3. Wait for Agent Response ─────────────────────────────────────
        await _pumpUntil(tester, () => switch (bloc.state) {
              Speaking(:final responseText) => responseText == "",
              _ => false,
            });
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.text(kUserInput), findsOneWidget);

        // ── 4. Wait for TTS to be triggered (triggered on TurnComplete) ─────
        await _pumpUntil(tester, () => tts.speakCalled);
        expect(tts.lastSpokenText, kAgentResponse);

        // ── 5. Complete TTS playback → Should return to Idle ────────────────
        tts.completePlayback();
        await _pumpUntil(tester, () => bloc.state is Idle);
        await tester.pumpAndSettle();
        expect(find.text('Appuyez pour parler'), findsOneWidget);

        await bloc.close();
      },
    );

    // ── Scenario 2: Settings navigation & mode toggle ─────────────────────

    testWidgets(
      'Scenario 2: Navigate to settings → Toggle mode → Verify persistence',
      (tester) async {
        final (:bloc, :tts) = _makeTextBloc();

        await tester.pumpWidget(App.forTesting(bloc: bloc));
        await tester.pumpAndSettle();

        // 1. Open Settings
        final settingsButton = find.byTooltip('Paramètres avancés');
        expect(settingsButton, findsOneWidget);
        await tester.tap(settingsButton);
        await tester.pumpAndSettle();

        // 2. Locate and toggle the Text Mode switch.
        // Assuming "Mode texte uniquement" is present.
        final textModeSwitch = find.byType(Switch).last;
        expect(textModeSwitch, findsOneWidget);
        await tester.tap(textModeSwitch);
        await tester.pumpAndSettle();

        // 3. Go back to Home
        final backButton = find.byType(BackButton);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton);
        } else {
          await tester.pageBack();
        }
        await tester.pumpAndSettle();

        // 4. Verify shared preferences directly to confirm persistence.
        final prefs = await SharedPreferences.getInstance();
        // Since we forced 'true' in setUp, toggling it should make it 'false'.
        expect(prefs.getBool('use_text_mode'), false);

        await bloc.close();
      },
    );
  });
}
