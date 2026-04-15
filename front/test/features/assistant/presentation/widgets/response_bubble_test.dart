import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_bloc.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_state.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/widgets/response_bubble.dart';

// ── Mocks ──────────────────────────────────────────────────────────────────

class MockAssistantBloc extends Mock implements AssistantBloc {}

// ── Helpers ────────────────────────────────────────────────────────────────

/// Pumps a [ResponseBubble] wrapped in a [MaterialApp] and [BlocProvider].
Future<void> _pump(
  WidgetTester tester,
  MockAssistantBloc mockBloc,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<AssistantBloc>.value(
        value: mockBloc,
        child: const Scaffold(body: ResponseBubble()),
      ),
    ),
  );
  await tester.pump(); // allow animations to start
}

void main() {
  late MockAssistantBloc mockBloc;

  setUp(() {
    mockBloc = MockAssistantBloc();
    when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockBloc.close()).thenAnswer((_) async {});
  });

  // ── Idle state ─────────────────────────────────────────────────────────────

  testWidgets('Idle state → SizedBox.shrink (no text visible)', (tester) async {
    when(() => mockBloc.state).thenReturn(const AssistantState.idle());

    await _pump(tester, mockBloc);

    expect(find.byType(SizedBox), findsWidgets);
    expect(find.byType(Card), findsNothing);
  });

  // ── Listening state ────────────────────────────────────────────────────────

  testWidgets('Listening state → shows interim transcript', (tester) async {
    when(() => mockBloc.state).thenReturn(
      const AssistantState.listening(interimTranscript: 'Bonjour'),
    );

    await _pump(tester, mockBloc);

    expect(find.text('Bonjour'), findsOneWidget);
  });

  // ── Starting state ────────────────────────────────────────────────────────

  testWidgets('Starting state → SizedBox.shrink (no bubble)', (tester) async {
    when(() => mockBloc.state).thenReturn(const AssistantState.starting());

    await _pump(tester, mockBloc);

    expect(find.byType(Card), findsNothing);
  });

  // ── Connecting state ──────────────────────────────────────────────────────

  testWidgets('Connecting state → SizedBox.shrink (no bubble)', (tester) async {
    when(() => mockBloc.state).thenReturn(const AssistantState.connecting());

    await _pump(tester, mockBloc);

    expect(find.byType(Card), findsNothing);
  });

  // ── Speaking state ─────────────────────────────────────────────────────────

  testWidgets('Speaking state → shows response text', (tester) async {
    when(() => mockBloc.state).thenReturn(
      const AssistantState.speaking(
        responseText: 'Vos clés sont sur la table.',
      ),
    );

    await _pump(tester, mockBloc);

    expect(find.text('Vos clés sont sur la table.'), findsOneWidget);
  });

  // ── Error state ────────────────────────────────────────────────────────────

  testWidgets('AssistantError state → shows error text', (tester) async {
    when(() => mockBloc.state).thenReturn(
      const AssistantState.error(message: 'Erreur réseau'),
    );

    await _pump(tester, mockBloc);

    expect(find.text('Erreur réseau'), findsOneWidget);
  });
}
