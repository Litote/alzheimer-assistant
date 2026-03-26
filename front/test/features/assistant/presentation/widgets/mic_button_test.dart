import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_bloc.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_event.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_state.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/widgets/mic_button.dart';

// ── Mocks ──────────────────────────────────────────────────────────────────

class MockAssistantBloc extends Mock implements AssistantBloc {}

// ── Helpers ────────────────────────────────────────────────────────────────

/// Pumps a [MicButton] wrapped in a [MaterialApp] and [BlocProvider].
Future<void> _pump(
  WidgetTester tester,
  MockAssistantBloc mockBloc,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<AssistantBloc>.value(
        value: mockBloc,
        child: const Scaffold(body: MicButton()),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  late MockAssistantBloc mockBloc;

  setUpAll(() {
    registerFallbackValue(const AssistantEvent.startListening());
  });

  setUp(() {
    mockBloc = MockAssistantBloc();
    when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockBloc.close()).thenAnswer((_) async {});
  });

  // ── Idle state ─────────────────────────────────────────────────────────────

  testWidgets(
    'Idle state → shows mic icon and label, tap dispatches StartListening',
    (tester) async {
      when(() => mockBloc.state).thenReturn(const AssistantState.idle());
      when(() => mockBloc.add(any())).thenReturn(null);

      await _pump(tester, mockBloc);

      expect(find.byIcon(Icons.mic), findsOneWidget);
      expect(find.text('Appuyez pour parler'), findsOneWidget);

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();

      verify(() => mockBloc.add(const AssistantEvent.startListening())).called(1);
    },
  );

  // ── Listening state ────────────────────────────────────────────────────────

  testWidgets('Listening state → shows mic icon and listening label',
      (tester) async {
    when(() => mockBloc.state).thenReturn(const AssistantState.listening());

    await _pump(tester, mockBloc);

    expect(find.byIcon(Icons.mic), findsOneWidget);
    expect(find.text('Écoute en cours…'), findsOneWidget);
  });

  // ── Processing state ───────────────────────────────────────────────────────

  testWidgets('Processing state → shows CircularProgressIndicator',
      (tester) async {
    when(() => mockBloc.state).thenReturn(
      const AssistantState.processing(userMessage: ''),
    );

    await _pump(tester, mockBloc);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  // ── Speaking state ─────────────────────────────────────────────────────────

  testWidgets('Speaking state → shows volume_up icon and responding label',
      (tester) async {
    when(() => mockBloc.state).thenReturn(
      const AssistantState.speaking(responseText: ''),
    );

    await _pump(tester, mockBloc);

    expect(find.byIcon(Icons.volume_up), findsOneWidget);
    expect(find.text('En train de répondre…'), findsOneWidget);
  });

  // ── Error state ────────────────────────────────────────────────────────────

  testWidgets('AssistantError state → shows refresh icon and retry label',
      (tester) async {
    when(() => mockBloc.state).thenReturn(
      const AssistantState.error(message: ''),
    );

    await _pump(tester, mockBloc);

    expect(find.byIcon(Icons.refresh), findsOneWidget);
    expect(find.text('Appuyez pour réessayer'), findsOneWidget);
  });

  // ── Disabled state (Listening) ─────────────────────────────────────────────

  testWidgets(
    'Listening state (disabled) → tap does nothing (no event dispatched)',
    (tester) async {
      when(() => mockBloc.state).thenReturn(const AssistantState.listening());
      when(() => mockBloc.add(any())).thenReturn(null);

      await _pump(tester, mockBloc);

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();

      verifyNever(() => mockBloc.add(any()));
    },
  );
}
