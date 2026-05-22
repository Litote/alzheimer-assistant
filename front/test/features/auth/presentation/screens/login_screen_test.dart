import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alzheimer_assistant/features/auth/presentation/screens/login_screen.dart';
import 'package:alzheimer_assistant/shared/services/auth_service.dart';

void main() {
  Future<void> pumpLoginScreen(
    WidgetTester tester,
    AuthService authService,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(authService: authService),
      ),
    );
  }

  testWidgets('shows the Google sign-in call to action', (tester) async {
    await pumpLoginScreen(tester, AuthService.test());

    expect(find.text('Mémoire'), findsOneWidget);
    expect(find.text('Votre assistant bienveillant'), findsOneWidget);
    expect(find.text('Continuer avec Google'), findsOneWidget);
  });

  testWidgets('shows a loading state while sign-in is in progress',
      (tester) async {
    final completer = Completer<void>();
    var signInCalls = 0;
    final authService = AuthService.test(
      signInWithGoogle: () {
        signInCalls += 1;
        return completer.future;
      },
    );

    await pumpLoginScreen(tester, authService);

    await tester.tap(find.text('Continuer avec Google'));
    await tester.pump();

    expect(signInCalls, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Connexion…'), findsOneWidget);
  });

  testWidgets('shows an error message when Google sign-in fails',
      (tester) async {
    final authService = AuthService.test(
      signInWithGoogle: () async => throw Exception('OAuth failed'),
    );

    await pumpLoginScreen(tester, authService);

    await tester.tap(find.text('Continuer avec Google'));
    await tester.pump();

    expect(
      find.text('Connexion impossible. Veuillez réessayer.'),
      findsOneWidget,
    );
    expect(find.text('Continuer avec Google'), findsOneWidget);
  });
}
