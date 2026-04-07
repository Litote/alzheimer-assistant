import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/screens/home_screen.dart';
import 'package:alzheimer_assistant/features/onboarding/presentation/screens/permission_onboarding_screen.dart';
import 'package:alzheimer_assistant/features/settings/presentation/screens/settings_screen.dart';
import 'package:alzheimer_assistant/shared/services/permission_service.dart';
import 'package:alzheimer_assistant/shared/services/settings_service.dart';

final _permissionService = PermissionService();

const _onboardingPath = '/onboarding';

final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    final done = await _permissionService.isOnboardingDone();
    if (!done && state.matchedLocation != _onboardingPath) {
      return _onboardingPath;
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
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
        service: _permissionService,
      ),
    ),
  ],
);
