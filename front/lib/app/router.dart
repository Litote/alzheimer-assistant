import 'package:go_router/go_router.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/screens/home_screen.dart';
import 'package:alzheimer_assistant/features/onboarding/presentation/screens/permission_onboarding_screen.dart';
import 'package:alzheimer_assistant/shared/services/permission_service.dart';

final _permissionService = PermissionService();

final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    final done = await _permissionService.isOnboardingDone();
    if (!done && state.matchedLocation != '/onboarding') {
      return '/onboarding';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => PermissionOnboardingScreen(
        service: _permissionService,
      ),
    ),
  ],
);
