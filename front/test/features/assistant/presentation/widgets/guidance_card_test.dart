import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:alzheimer_assistant/features/assistant/domain/entities/guidance.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_bloc.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_state.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/widgets/guidance_card.dart';

class MockAssistantBloc extends Mock implements AssistantBloc {}

const _kGuidance = Guidance(
  destination: 'Boulangerie',
  instruction: 'Tourner à droite sur Rue du Four',
  maneuver: 'TURN_RIGHT',
  distanceMeters: 100,
);

Future<void> _pump(WidgetTester tester, MockAssistantBloc mockBloc) async {
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<AssistantBloc>.value(
        value: mockBloc,
        child: const Scaffold(body: GuidanceCard()),
      ),
    ),
  );
}

IconData _shownIcon(WidgetTester tester) =>
    tester.widget<Icon>(find.byKey(const Key('guidance-maneuver'))).icon!;

void main() {
  late MockAssistantBloc mockBloc;

  setUp(() {
    mockBloc = MockAssistantBloc();
    when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockBloc.close()).thenAnswer((_) async {});
  });

  testWidgets('no guidance → renders nothing', (tester) async {
    when(() => mockBloc.state).thenReturn(const AssistantState.listening());

    await _pump(tester, mockBloc);

    expect(find.byKey(const Key('guidance-maneuver')), findsNothing);
  });

  testWidgets('shows the destination, the exact instruction and the distance',
      (tester) async {
    when(() => mockBloc.state)
        .thenReturn(const AssistantState.listening(guidance: _kGuidance));

    await _pump(tester, mockBloc);

    expect(find.text('Vers Boulangerie'), findsOneWidget);
    expect(find.text('Tourner à droite sur Rue du Four'), findsOneWidget);
    expect(find.text('puis 100 mètres'), findsOneWidget);
    expect(_shownIcon(tester), Icons.turn_right);
  });

  testWidgets('stays visible while the agent speaks', (tester) async {
    when(() => mockBloc.state)
        .thenReturn(const AssistantState.speaking(guidance: _kGuidance));

    await _pump(tester, mockBloc);

    expect(find.text('Tourner à droite sur Rue du Four'), findsOneWidget);
  });

  testWidgets('a very short step shows no distance', (tester) async {
    when(() => mockBloc.state).thenReturn(AssistantState.listening(
      guidance: _kGuidance.copyWith(distanceMeters: 4, destination: ''),
    ));

    await _pump(tester, mockBloc);

    expect(find.textContaining('mètres'), findsNothing);
    expect(find.textContaining('Vers'), findsNothing);
  });

  testWidgets('a long instruction does not overflow a small screen',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 300));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    when(() => mockBloc.state).thenReturn(AssistantState.listening(
      guidance: _kGuidance.copyWith(
        instruction: 'Prendre la direction nord-ouest sur le Chemin de la '
            'Grande-Fontaine-des-Trois-Rois vers la Place du Marché',
      ),
    ));

    await _pump(tester, mockBloc);

    expect(tester.takeException(), isNull);
  });

  test('arrow matches the manoeuvre of the routing service', () {
    expect(maneuverIcon('TURN_LEFT'), Icons.turn_left);
    expect(maneuverIcon('TURN_SLIGHT_LEFT'), Icons.turn_left);
    expect(maneuverIcon('TURN_SHARP_RIGHT'), Icons.turn_right);
    expect(maneuverIcon('UTURN_RIGHT'), Icons.u_turn_left);
    expect(maneuverIcon('DEPART'), Icons.straight);
    expect(maneuverIcon(''), Icons.straight);
  });

  test('guidanceOf reads the step of conversational states only', () {
    expect(guidanceOf(const AssistantState.listening(guidance: _kGuidance)), _kGuidance);
    expect(guidanceOf(const AssistantState.speaking(guidance: _kGuidance)), _kGuidance);
    expect(guidanceOf(const AssistantState.idle()), isNull);
    expect(guidanceOf(const AssistantState.connecting()), isNull);
  });
}
