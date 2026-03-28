import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alzheimer_assistant/shared/services/permission_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ── isOnboardingDone: no key stored ───────────────────────────────────────

  test('isOnboardingDone returns false when key not set', () async {
    final service = PermissionService(requestPermissions: () async => {});

    expect(await service.isOnboardingDone(), isFalse);
  });

  // ── markOnboardingDone then isOnboardingDone ──────────────────────────────

  test('isOnboardingDone returns true after markOnboardingDone', () async {
    final service = PermissionService(requestPermissions: () async => {});

    await service.markOnboardingDone();

    expect(await service.isOnboardingDone(), isTrue);
  });

  // ── requestAll: calls injected function ───────────────────────────────────

  test('requestAll calls the injected requestPermissions function', () async {
    var called = false;
    final service = PermissionService(
      requestPermissions: () async {
        called = true;
        return {Permission.microphone: PermissionStatus.granted};
      },
    );

    await service.requestAll();

    expect(called, isTrue);
  });
}
