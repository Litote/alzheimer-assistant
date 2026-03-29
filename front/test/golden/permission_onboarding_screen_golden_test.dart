@Tags(['golden'])
library;

// ── Golden tests — PermissionOnboardingScreen (multi-device) ─────────────────
//
// Covers 1 state × 8 devices = 8 goldens.
//
// The Platform.isIOS branch cannot be toggled in host tests: these goldens
// always show the Android variant (Téléphone / phone icon).
//
// Devices tested:
//   iOS    : iPhone SE 3, iPhone 16, iPhone 16 Pro Max
//   Android: Galaxy S24, Galaxy S24 Ultra, Pixel 9
//   Web    : laptop 1280×800, desktop 1920×1080
//
// GENERATE reference files (macOS only):
//   flutter test test/golden/ --update-goldens --tags golden
//
// VERIFY:
//   flutter test test/golden/ --tags golden

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alzheimer_assistant/app/theme.dart';
import 'package:alzheimer_assistant/features/onboarding/presentation/screens/permission_onboarding_screen.dart';
import 'package:alzheimer_assistant/shared/services/permission_service.dart';

// ── Devices ───────────────────────────────────────────────────────────────────

class _Device {
  const _Device(this.id, this.logicalWidth, this.logicalHeight, this.ratio);

  final String id;
  final double logicalWidth;
  final double logicalHeight;
  final double ratio;

  Size get physical => Size(logicalWidth * ratio, logicalHeight * ratio);
}

const List<_Device> _devices = [
  // ── iOS ───────────────────────────────────────────────────────────────────
  _Device('iphone_se3', 375, 667, 2.0),
  _Device('iphone_16', 390, 844, 3.0),
  _Device('iphone_16_pro_max', 440, 956, 3.0),
  // ── Android ───────────────────────────────────────────────────────────────
  _Device('galaxy_s24', 360, 780, 3.0),
  _Device('galaxy_s24_ultra', 412, 932, 3.5),
  _Device('pixel_9', 412, 892, 2.75),
  // ── Web ───────────────────────────────────────────────────────────────────
  _Device('web_laptop', 1280, 800, 1.0),
  _Device('web_desktop', 1920, 1080, 1.0),
];

// ── Helpers ───────────────────────────────────────────────────────────────────

PermissionService _makeService() => PermissionService(
      requestPermissions: () async => <Permission, PermissionStatus>{},
    );

Widget _buildApp(PermissionService service) => MaterialApp(
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      home: PermissionOnboardingScreen(service: service),
    );

void _setDevice(WidgetTester tester, _Device device) {
  tester.view.physicalSize = device.physical;
  tester.view.devicePixelRatio = device.ratio;
}

void _resetDevice(WidgetTester tester) {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;

    final fontLoader = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await fontLoader.load();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PermissionOnboardingScreen', () {
    for (final device in _devices) {
      testWidgets(device.id, (tester) async {
        _setDevice(tester, device);
        addTearDown(() => _resetDevice(tester));

        await tester.pumpWidget(_buildApp(_makeService()));
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/permission_onboarding_${device.id}.png'),
        );
      });
    }
  });
}
