import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:alzheimer_assistant/shared/services/auth_service.dart';

class MockUser extends Mock implements User {}

class MockAuthState extends Mock implements AuthState {}

void main() {
  group('AuthService', () {
    test('returns the current Supabase user details when signed in', () {
      final user = MockUser();
      when(() => user.id).thenReturn('supabase-user-id');

      final service = AuthService.test(currentUser: () => user);

      expect(service.currentUser, same(user));
      expect(service.supabaseUserId, 'supabase-user-id');
      expect(service.isSignedIn, isTrue);
    });

    test('reports a signed-out state when there is no current user', () {
      final service = AuthService.test();

      expect(service.currentUser, isNull);
      expect(service.supabaseUserId, isEmpty);
      expect(service.isSignedIn, isFalse);
    });

    test('delegates Google sign-in to the injected auth client', () async {
      var signInCalls = 0;
      final service = AuthService.test(
        signInWithGoogle: () async => signInCalls += 1,
      );

      await service.signInWithGoogle();

      expect(signInCalls, 1);
    });

    test('delegates sign-out to the injected auth client', () async {
      var signOutCalls = 0;
      final service = AuthService.test(
        signOut: () async => signOutCalls += 1,
      );

      await service.signOut();

      expect(signOutCalls, 1);
    });

    test('exposes the injected auth state stream', () async {
      final controller = StreamController<AuthState>();
      addTearDown(controller.close);
      final authState = MockAuthState();
      final service = AuthService.test(
        authStateChanges: controller.stream,
      );

      unawaited(Future<void>.microtask(() => controller.add(authState)));

      await expectLater(service.authStateChanges, emits(same(authState)));
    });
  });
}
