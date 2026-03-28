// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alzheimer_assistant/app/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Mark onboarding as done so the router skips the onboarding screen.
    SharedPreferences.setMockInitialValues({'onboarding_done': true});

    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    expect(find.text('Bonjour, je suis là\npour vous aider'), findsOneWidget);
  });
}
