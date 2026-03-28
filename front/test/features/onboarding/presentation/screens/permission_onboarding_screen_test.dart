import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alzheimer_assistant/features/onboarding/presentation/screens/permission_onboarding_screen.dart';
import 'package:alzheimer_assistant/shared/services/permission_service.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

/// Builds a [PermissionService] with all operations stubbed.
PermissionService _makeService({
  Future<Map<Permission, PermissionStatus>> Function()? requestPermissions,
}) =>
    PermissionService(
      requestPermissions: requestPermissions ?? () async => {},
    );

/// Pumps the onboarding screen inside a real GoRouter for navigation testing.
Future<GoRouter> _pumpScreen(
  WidgetTester tester,
  PermissionService service,
) async {
  final router = GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) =>
            PermissionOnboardingScreen(service: service),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const Scaffold(body: Text('home')),
      ),
    ],
  );

  await tester.pumpWidget(
    MaterialApp.router(routerConfig: router),
  );
  await tester.pumpAndSettle();

  return router;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ── Rendering ─────────────────────────────────────────────────────────────

  testWidgets('screen shows permission items and authorize button',
      (tester) async {
    await _pumpScreen(tester, _makeService());

    // Microphone
    expect(find.byIcon(Icons.mic), findsOneWidget);
    expect(find.textContaining('Microphone'), findsOneWidget);

    // Contacts
    expect(find.byIcon(Icons.contacts), findsOneWidget);
    expect(find.textContaining('Contacts'), findsOneWidget);

    // Phone
    expect(find.byIcon(Icons.phone), findsOneWidget);
    expect(find.textContaining('Téléphone'), findsOneWidget);

    // Primary button
    expect(find.text('Autoriser les permissions'), findsOneWidget);
  });

  // ── Button tap: calls service methods ─────────────────────────────────────

  testWidgets('tapping button calls requestAll then markOnboardingDone',
      (tester) async {
    var requestAllCalled = false;
    var markDoneCalled = false;

    // requestAll is injected; markOnboardingDone writes to SharedPreferences
    final service = _makeService(
      requestPermissions: () async {
        requestAllCalled = true;
        return {};
      },
    );

    await _pumpScreen(tester, service);

    await tester.tap(find.text('Autoriser les permissions'));
    await tester.pumpAndSettle();

    // requestAll must be called via injected function
    expect(requestAllCalled, isTrue);

    // markOnboardingDone stores the flag in SharedPreferences
    markDoneCalled = await service.isOnboardingDone();
    expect(markDoneCalled, isTrue);
  });

  // ── Navigation ────────────────────────────────────────────────────────────

  testWidgets('tapping button navigates to home screen', (tester) async {
    await _pumpScreen(tester, _makeService());

    await tester.tap(find.text('Autoriser les permissions'));
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
  });
}
