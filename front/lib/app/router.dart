import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/screens/home_screen.dart';
import 'package:alzheimer_assistant/features/auth/presentation/screens/login_screen.dart';
import 'package:alzheimer_assistant/features/onboarding/presentation/screens/permission_onboarding_screen.dart';
import 'package:alzheimer_assistant/features/settings/presentation/screens/settings_screen.dart';
import 'package:alzheimer_assistant/shared/services/auth_service.dart';
import 'package:alzheimer_assistant/shared/services/permission_service.dart';
import 'package:alzheimer_assistant/shared/services/settings_service.dart';

const _onboardingPath = '/onboarding';
const _loginPath = '/login';

GoRouter createAppRouter({
  required AuthService authService,
  PermissionService? permissionService,
}) {
  final resolvedPermissionService = permissionService ?? PermissionService();

  return GoRouter(
    initialLocation: '/',
    // Refresh the router whenever the Supabase auth state changes (sign in/out,
    // or when the app resumes from the OAuth browser callback).
    refreshListenable: _GoRouterAuthNotifier(authService),
    redirect: (context, state) async {
      // 1. Auth check — redirect to login if not signed in.
      if (!authService.isSignedIn && state.matchedLocation != _loginPath) {
        return _loginPath;
      }
      // 2. Onboarding check — only after auth is confirmed.
      if (authService.isSignedIn) {
        final done = await resolvedPermissionService.isOnboardingDone();
        if (!done && state.matchedLocation != _onboardingPath) {
          return _onboardingPath;
        }
        // Redirect away from login once signed in.
        if (state.matchedLocation == _loginPath) return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: _loginPath,
        builder: (context, state) => LoginScreen(authService: authService),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => SettingsScreen(
          settingsService: context.read<SettingsService>(),
        ),
      ),
      GoRoute(
        path: _onboardingPath,
        builder: (context, state) => PermissionOnboardingScreen(
          service: resolvedPermissionService,
        ),
      ),
    ],
  );
}

/// Bridges Supabase auth state changes to GoRouter's refresh mechanism.
class _GoRouterAuthNotifier extends ChangeNotifier {
  _GoRouterAuthNotifier(AuthService authService) {
    _subscription = authService.authStateChanges.listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
