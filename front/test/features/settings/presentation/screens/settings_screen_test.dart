import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alzheimer_assistant/features/settings/presentation/screens/settings_screen.dart';
import 'package:alzheimer_assistant/shared/services/auth_service.dart';
import 'package:alzheimer_assistant/shared/services/settings_service.dart';

class _FakeSettingsService implements SettingsService {
  bool elevenLabs;
  bool textMode;
  bool liveKit;

  _FakeSettingsService({
    bool initial = false,
    bool textModeInitial = false,
    bool liveKitInitial = false,
  })  : elevenLabs = initial,
        textMode = textModeInitial,
        liveKit = liveKitInitial;

  @override
  Future<bool> getUseElevenLabs() async => elevenLabs;

  @override
  Future<void> setUseElevenLabs(bool newValue) async => elevenLabs = newValue;

  @override
  Future<bool> getUseTextMode() async => textMode;

  @override
  Future<void> setUseTextMode(bool newValue) async => textMode = newValue;

  @override
  Future<bool> getUseLiveKit() async => liveKit;

  @override
  Future<void> setUseLiveKit(bool value) async => liveKit = value;
}

Widget _buildScreen({
  _FakeSettingsService? settingsService,
  AuthService? authService,
}) {
  return MaterialApp(
    home: SettingsScreen(
      settingsService: settingsService ?? _FakeSettingsService(),
      authService: authService ??
          AuthService.test(
            authStateChanges: const Stream.empty(),
          ),
    ),
  );
}

void main() {
  // ── Loading state ──────────────────────────────────────────────────────────

  testWidgets('shows loading indicator before settings load', (tester) async {
    await tester.pumpWidget(_buildScreen());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(Switch), findsNothing);
  });

  // ── Loaded state ───────────────────────────────────────────────────────────

  testWidgets('shows three cards with toggles after settings load', (tester) async {
    await tester.pumpWidget(_buildScreen());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(Switch, skipOffstage: false), findsNWidgets(3));
    expect(find.text('Voix Haute Qualité'), findsOneWidget);
    expect(find.text('Mode Alterné (Texte)', skipOffstage: false), findsOneWidget);
    expect(find.text('Mode WebRTC (LiveKit)', skipOffstage: false), findsOneWidget);
  });

  testWidgets('shows sign out button after settings load', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_buildScreen());
    await tester.pump();

    expect(find.byKey(const Key('sign-out-button')), findsOneWidget);
  });

  // ── Initial value reflected ────────────────────────────────────────────────

  testWidgets('ElevenLabs toggle starts off when initial value is false',
      (tester) async {
    await tester.pumpWidget(_buildScreen(settingsService: _FakeSettingsService(initial: false)));
    await tester.pump();

    final switches = tester.widgetList<Switch>(find.byType(Switch, skipOffstage: false)).toList();
    expect(switches[0].value, isFalse);
  });

  testWidgets('ElevenLabs toggle starts on when initial value is true',
      (tester) async {
    await tester.pumpWidget(_buildScreen(settingsService: _FakeSettingsService(initial: true)));
    await tester.pump();

    final switches = tester.widgetList<Switch>(find.byType(Switch, skipOffstage: false)).toList();
    expect(switches[0].value, isTrue);
  });

  // ── ElevenLabs toggle interaction ──────────────────────────────────────────

  testWidgets('tapping ElevenLabs toggle enables it and persists the change',
      (tester) async {
    final service = _FakeSettingsService(initial: false);
    await tester.pumpWidget(_buildScreen(settingsService: service));
    await tester.pump();

    final elevenLabsCard = find.ancestor(
      of: find.text('Voix Haute Qualité'),
      matching: find.byType(Card),
    );
    await tester.tap(find.descendant(of: elevenLabsCard, matching: find.byType(Switch)));
    await tester.pump();

    expect(service.elevenLabs, isTrue);
  });

  testWidgets('tapping ElevenLabs toggle disables it when previously enabled',
      (tester) async {
    final service = _FakeSettingsService(initial: true);
    await tester.pumpWidget(_buildScreen(settingsService: service));
    await tester.pump();

    final elevenLabsCard = find.ancestor(
      of: find.text('Voix Haute Qualité'),
      matching: find.byType(Card),
    );
    await tester.tap(find.descendant(of: elevenLabsCard, matching: find.byType(Switch)));
    await tester.pump();

    expect(service.elevenLabs, isFalse);
  });

  testWidgets('tapping the ElevenLabs card body also toggles the setting',
      (tester) async {
    final service = _FakeSettingsService(initial: false);
    await tester.pumpWidget(_buildScreen(settingsService: service));
    await tester.pump();

    await tester.tap(find.text('Voix Haute Qualité'));
    await tester.pump();

    expect(service.elevenLabs, isTrue);
  });

  // ── Text mode toggle ───────────────────────────────────────────────────────

  testWidgets('text mode toggle starts off by default', (tester) async {
    await tester.pumpWidget(_buildScreen());
    await tester.pump();

    final switches = tester.widgetList<Switch>(find.byType(Switch, skipOffstage: false)).toList();
    expect(switches[1].value, isFalse);
  });

  testWidgets('text mode toggle starts on when initial value is true',
      (tester) async {
    await tester.pumpWidget(_buildScreen(settingsService: _FakeSettingsService(textModeInitial: true)));
    await tester.pump();

    final switches = tester.widgetList<Switch>(find.byType(Switch, skipOffstage: false)).toList();
    expect(switches[1].value, isTrue);
  });

  testWidgets('tapping text mode toggle enables it and persists', (tester) async {
    final service = _FakeSettingsService();
    await tester.pumpWidget(_buildScreen(settingsService: service));
    await tester.pump();

    final textModeCard = find.ancestor(
      of: find.text('Mode Alterné (Texte)', skipOffstage: false),
      matching: find.byType(Card),
    );
    await tester.ensureVisible(find.descendant(of: textModeCard, matching: find.byType(Switch), skipOffstage: false));
    await tester.tap(find.descendant(of: textModeCard, matching: find.byType(Switch), skipOffstage: false));
    await tester.pump();

    expect(service.textMode, isTrue);
  });

  // ── LiveKit toggle ─────────────────────────────────────────────────────────

  testWidgets('LiveKit toggle starts off by default', (tester) async {
    await tester.pumpWidget(_buildScreen());
    await tester.pump();

    final switches = tester.widgetList<Switch>(find.byType(Switch, skipOffstage: false)).toList();
    expect(switches[2].value, isFalse);
  });

  testWidgets('LiveKit toggle starts on when initial value is true',
      (tester) async {
    await tester.pumpWidget(_buildScreen(settingsService: _FakeSettingsService(liveKitInitial: true)));
    await tester.pump();

    final switches = tester.widgetList<Switch>(find.byType(Switch, skipOffstage: false)).toList();
    expect(switches[2].value, isTrue);
  });

  testWidgets('tapping LiveKit toggle enables it and persists', (tester) async {
    final service = _FakeSettingsService();
    await tester.pumpWidget(_buildScreen(settingsService: service));
    await tester.pump();

    await tester.ensureVisible(find.text('Mode WebRTC (LiveKit)', skipOffstage: false));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mode WebRTC (LiveKit)', skipOffstage: false));
    await tester.pump();

    expect(service.liveKit, isTrue);
  });

  testWidgets('tapping LiveKit toggle disables it when previously enabled',
      (tester) async {
    final service = _FakeSettingsService(liveKitInitial: true);
    await tester.pumpWidget(_buildScreen(settingsService: service));
    await tester.pump();

    await tester.ensureVisible(find.text('Mode WebRTC (LiveKit)', skipOffstage: false));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mode WebRTC (LiveKit)', skipOffstage: false));
    await tester.pump();

    expect(service.liveKit, isFalse);
  });

  // ── Sign out ───────────────────────────────────────────────────────────────

  testWidgets('tapping sign out shows confirmation dialog', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_buildScreen());
    await tester.pump();

    await tester.tap(find.byKey(const Key('sign-out-button')));
    await tester.pumpAndSettle();

    expect(find.text('Se déconnecter ?'), findsOneWidget);
    expect(find.text('Annuler'), findsOneWidget);
  });

  testWidgets('cancelling sign out dialog does not call signOut', (tester) async {
    var signOutCalled = false;
    final auth = AuthService.test(
      signOut: () async => signOutCalled = true,
      authStateChanges: const Stream.empty(),
    );
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_buildScreen(authService: auth));
    await tester.pump();

    await tester.tap(find.byKey(const Key('sign-out-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(signOutCalled, isFalse);
    expect(find.text('Se déconnecter ?'), findsNothing);
  });

  testWidgets('confirming sign out dialog calls signOut', (tester) async {
    var signOutCalled = false;
    final auth = AuthService.test(
      signOut: () async => signOutCalled = true,
      authStateChanges: const Stream.empty(),
    );
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_buildScreen(authService: auth));
    await tester.pump();

    await tester.tap(find.byKey(const Key('sign-out-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Se déconnecter'),
    ));
    await tester.pumpAndSettle();

    expect(signOutCalled, isTrue);
  });
}
