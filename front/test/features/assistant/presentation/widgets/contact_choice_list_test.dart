import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_bloc.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_event.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_state.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/widgets/contact_choice_list.dart';
import 'package:alzheimer_assistant/shared/services/phone_call_service.dart';

// ── Mocks ──────────────────────────────────────────────────────────────────

class MockAssistantBloc extends Mock implements AssistantBloc {}

// ── Test data ──────────────────────────────────────────────────────────────

const _kTwoCandidates = <PhoneCandidate>[
  (displayName: 'Martin Jean', number: '+33611111111'),
  (displayName: 'Martin Paul', number: '+33622222222'),
];

const _kHomonyms = <PhoneCandidate>[
  (displayName: 'Paul', number: '+33611111234'),
  (displayName: 'Paul', number: '+33622225678'),
];

// ── Helpers ────────────────────────────────────────────────────────────────

Future<void> _pump(WidgetTester tester, MockAssistantBloc mockBloc) async {
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<AssistantBloc>.value(
        value: mockBloc,
        child: const Scaffold(body: ContactChoiceList()),
      ),
    ),
  );
}

void main() {
  late MockAssistantBloc mockBloc;

  setUpAll(() {
    registerFallbackValue(const AssistantEvent.appResumed());
  });

  setUp(() {
    mockBloc = MockAssistantBloc();
    when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockBloc.close()).thenAnswer((_) async {});
  });

  testWidgets('no pending choice → renders nothing', (tester) async {
    when(() => mockBloc.state).thenReturn(const AssistantState.idle());

    await _pump(tester, mockBloc);

    expect(find.byType(Card), findsNothing);
    expect(find.text('Qui voulez-vous appeler ?'), findsNothing);
  });

  testWidgets('pending choices → one card per contact', (tester) async {
    when(() => mockBloc.state).thenReturn(
      const AssistantState.speaking(contactChoices: _kTwoCandidates),
    );

    await _pump(tester, mockBloc);

    expect(find.text('Qui voulez-vous appeler ?'), findsOneWidget);
    expect(find.byType(Card), findsNWidgets(2));
    expect(find.text('Martin Jean'), findsOneWidget);
    expect(find.text('Martin Paul'), findsOneWidget);
    expect(find.text('MJ'), findsOneWidget);
    expect(find.bySemanticsLabel('Appeler Martin Paul'), findsOneWidget);
    // Distinct names: no number hint.
    expect(find.textContaining('…'), findsNothing);
  });

  testWidgets('homonyms → shows the end of each number', (tester) async {
    when(() => mockBloc.state).thenReturn(
      const AssistantState.listening(contactChoices: _kHomonyms),
    );

    await _pump(tester, mockBloc);

    expect(find.text('… 1234'), findsOneWidget);
    expect(find.text('… 5678'), findsOneWidget);
  });

  testWidgets('tap on a contact → dispatches contactChosen', (tester) async {
    when(() => mockBloc.state).thenReturn(
      const AssistantState.idle(contactChoices: _kTwoCandidates),
    );

    await _pump(tester, mockBloc);
    await tester.tap(find.text('Martin Paul'));

    verify(() => mockBloc.add(AssistantEvent.contactChosen(_kTwoCandidates[1])))
        .called(1);
  });

  testWidgets('tap on Annuler → dispatches contactChoiceCancelled',
      (tester) async {
    when(() => mockBloc.state).thenReturn(
      const AssistantState.listening(contactChoices: _kTwoCandidates),
    );

    await _pump(tester, mockBloc);
    await tester.tap(find.text('Annuler'));

    verify(() => mockBloc.add(const AssistantEvent.contactChoiceCancelled()))
        .called(1);
  });
}
