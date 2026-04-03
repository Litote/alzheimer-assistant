@Tags(['golden'])
library;

// ── Golden tests — HomeScreen (multi-device) ──────────────────────────────
//
// Covers 2 states × 8 devices = 16 goldens.
//
// Devices tested:
//   iOS    : iPhone SE 3, iPhone 16, iPhone 16 Pro Max
//   Android: Galaxy S24, Galaxy S24 Ultra, Pixel 9
//   Web    : laptop 1280×800, desktop 1920×1080
//
// GENERATE reference files (macOS CI):
//   flutter test test/golden/ --update-goldens --tags golden
//
// VERIFY (macOS CI):
//   flutter test test/golden/ --tags golden
//
// IMPORTANT: goldens are tied to the rendering platform (macOS ≠ Linux).
// Always generate and validate on macOS (workflow "Update Golden Screenshots").

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alzheimer_assistant/app/theme.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_bloc.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_event.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_state.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/screens/home_screen.dart';

// ── Devices ───────────────────────────────────────────────────────────────

class _Device {
  const _Device(this.id, this.logicalWidth, this.logicalHeight, this.ratio);

  /// Short identifier used in the golden filename.
  final String id;
  final double logicalWidth;
  final double logicalHeight;

  /// devicePixelRatio (physical pixels / logical pixels).
  final double ratio;

  Size get physical => Size(logicalWidth * ratio, logicalHeight * ratio);
}

/// Most popular mobile devices in 2025 + common web breakpoints.
const List<_Device> _devices = [
  // ── iOS ──────────────────────────────────────────────────────────────
  _Device('iphone_se3',        375,  667, 2.0),  // iPhone SE 3rd gen
  _Device('iphone_16',         390,  844, 3.0),  // iPhone 16
  _Device('iphone_16_pro_max', 440,  956, 3.0),  // iPhone 16 Pro Max
  // ── Android ──────────────────────────────────────────────────────────
  _Device('galaxy_s24',        360,  780, 3.0),  // Samsung Galaxy S24
  _Device('galaxy_s24_ultra',  412,  932, 3.5),  // Samsung Galaxy S24 Ultra
  _Device('pixel_9',           412,  892, 2.75), // Google Pixel 9
  // ── Web ──────────────────────────────────────────────────────────────
  _Device('web_laptop',       1280,  800, 1.0),  // Laptop 1280×800
  _Device('web_desktop',      1920, 1080, 1.0),  // Desktop 1920×1080
];

// ── Mock ──────────────────────────────────────────────────────────────────

class MockAssistantBloc
    extends MockBloc<AssistantEvent, AssistantState>
    implements AssistantBloc {}

// ── Helpers ───────────────────────────────────────────────────────────────

/// Creates a MockBloc fixed in [state], with no transitions.
MockAssistantBloc _blocWith(AssistantState state) {
  final bloc = MockAssistantBloc();
  whenListen(
    bloc,
    Stream<AssistantState>.empty(),
    initialState: state,
  );
  return bloc;
}

Widget _buildApp(AssistantBloc bloc) => BlocProvider<AssistantBloc>.value(
      value: bloc,
      child: MaterialApp(
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        home: const HomeScreen(),
      ),
    );

void _setDevice(WidgetTester tester, _Device device) {
  tester.view.physicalSize = device.physical;
  tester.view.devicePixelRatio = device.ratio;
}

void _resetDevice(WidgetTester tester) {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

Future<void> _loadFonts() async {
  final interLoader = FontLoader('Inter')
    ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-Medium.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-SemiBold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-Bold.ttf'));
  
  await interLoader.load();

  final materialIconsLoader = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('assets/fonts/MaterialIcons-Regular.otf'));

  await materialIconsLoader.load();
}

// ── Tests ─────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() async {
    await _loadFonts();
  });

  // ── Idle state ──────────────────────────────────────────────────────────
  
  group('HomeScreen — idle', () {
    for (final device in _devices) {
      testWidgets(device.id, (tester) async {
        _setDevice(tester, device);
        addTearDown(() => _resetDevice(tester));

        final bloc = _blocWith(const AssistantState.idle());
        addTearDown(bloc.close);

        await tester.pumpWidget(_buildApp(bloc));
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/home_idle_${device.id}.png'),
        );
      });
    }
  });

  // ── Speaking state ──────────────────────────────────────────────────────

  group('HomeScreen — speaking', () {
    for (final device in _devices) {
      testWidgets(device.id, (tester) async {
        _setDevice(tester, device);
        addTearDown(() => _resetDevice(tester));

        final bloc = _blocWith(
          const AssistantState.speaking(
            responseText:
                'Vos médicaments sont dans l\'armoire à pharmacie, dans la salle de bain.',
          ),
        );
        addTearDown(bloc.close);

        await tester.pumpWidget(_buildApp(bloc));
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/home_speaking_${device.id}.png'),
        );
      });
    }
  });
}
