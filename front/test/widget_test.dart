// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:alzheimer_assistant/app/app.dart';
import 'package:alzheimer_assistant/shared/services/auth_service.dart';

class _MockUser extends Mock implements User {}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'onboarding_done': true});
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    final user = _MockUser();
    when(() => user.id).thenReturn('user-123');

    await tester.pumpWidget(
      App(
        authService: AuthService.test(currentUser: () => user),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bonjour, je suis là\npour vous aider'), findsOneWidget);
  });
}
