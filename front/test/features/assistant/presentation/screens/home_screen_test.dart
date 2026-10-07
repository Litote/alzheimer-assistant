import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alzheimer_assistant/app/theme.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_bloc.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_event.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_state.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/screens/home_screen.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/widgets/contact_choice_list.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/widgets/mic_button.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/widgets/response_bubble.dart';

class MockAssistantBloc extends MockBloc<AssistantEvent, AssistantState>
    implements AssistantBloc {}

Future<void> _pump(WidgetTester tester, AssistantState state) async {
  // Portrait phone (iPhone 16), as the app is locked to portrait.
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final bloc = MockAssistantBloc();
  whenListen(bloc, const Stream<AssistantState>.empty(), initialState: state);
  addTearDown(bloc.close);
  await tester.pumpWidget(
    BlocProvider<AssistantBloc>.value(
      value: bloc,
      child: MaterialApp(theme: AppTheme.light, home: const HomeScreen()),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('no pending choice → shows the response bubble', (tester) async {
    await _pump(
      tester,
      const AssistantState.speaking(responseText: 'Bonjour'),
    );

    expect(find.byType(ResponseBubble), findsOneWidget);
    expect(find.byType(ContactChoiceList), findsNothing);
  });

  testWidgets('pending choices → shows the contact list and the mic button',
      (tester) async {
    await _pump(
      tester,
      const AssistantState.speaking(
        responseText: 'Lequel ?',
        contactChoices: [
          (displayName: 'Martin Jean', number: '+33611111111'),
          (displayName: 'Martin Paul', number: '+33622222222'),
        ],
      ),
    );

    expect(find.byType(ContactChoiceList), findsOneWidget);
    expect(find.byType(ResponseBubble), findsNothing);
    expect(find.text('Martin Paul'), findsOneWidget);
    // The user can still answer by voice.
    expect(find.byType(MicButton), findsOneWidget);
  });
}
