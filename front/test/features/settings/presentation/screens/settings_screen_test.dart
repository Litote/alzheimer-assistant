import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alzheimer_assistant/features/settings/presentation/screens/settings_screen.dart';
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

void main() {
  // ── Loading state ──────────────────────────────────────────────────────────

  testWidgets('shows loading indicator before settings load', (tester) async {
    final service = _FakeSettingsService();
    await tester.pumpWidget(MaterialApp(
      home: SettingsScreen(settingsService: service),
    ));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(Switch), findsNothing);
  });

  // ── Loaded state ───────────────────────────────────────────────────────────

  testWidgets('shows three cards with toggles after settings load', (tester) async {
    final service = _FakeSettingsService();
    await tester.pumpWidget(MaterialApp(
      home: SettingsScreen(settingsService: service),
    ));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(Switch), findsNWidgets(3));
    expect(find.text('Voix Haute Qualité'), findsOneWidget);
    expect(find.text('Mode Alterné (Texte)'), findsOneWidget);
    expect(find.text('Mode WebRTC (LiveKit)'), findsOneWidget);
  });

  // ── Initial value reflected ────────────────────────────────────────────────

  testWidgets('ElevenLabs toggle starts off when initial value is false',
      (tester) async {
    final service = _FakeSettingsService(initial: false);
    await tester.pumpWidget(MaterialApp(
      home: SettingsScreen(settingsService: service),
    ));
    await tester.pump();

    final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
    expect(switches[0].value, isFalse);
  });

  testWidgets('ElevenLabs toggle starts on when initial value is true',
      (tester) async {
    final service = _FakeSettingsService(initial: true);
    await tester.pumpWidget(MaterialApp(
      home: SettingsScreen(settingsService: service),
    ));
    await tester.pump();

    final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
    expect(switches[0].value, isTrue);
  });

  // ── ElevenLabs toggle interaction ──────────────────────────────────────────

  testWidgets('tapping ElevenLabs toggle enables it and persists the change',
      (tester) async {
    final service = _FakeSettingsService(initial: false);
    await tester.pumpWidget(MaterialApp(
      home: SettingsScreen(settingsService: service),
    ));
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
    await tester.pumpWidget(MaterialApp(
      home: SettingsScreen(settingsService: service),
    ));
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
    await tester.pumpWidget(MaterialApp(
      home: SettingsScreen(settingsService: service),
    ));
    await tester.pump();

    await tester.tap(find.text('Voix Haute Qualité'));
    await tester.pump();

    expect(service.elevenLabs, isTrue);
  });

  // ── Text mode toggle ───────────────────────────────────────────────────────

  testWidgets('text mode toggle starts off by default', (tester) async {
    final service = _FakeSettingsService();
    await tester.pumpWidget(MaterialApp(
      home: SettingsScreen(settingsService: service),
    ));
    await tester.pump();

    final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
    expect(switches[1].value, isFalse);
  });

  testWidgets('text mode toggle starts on when initial value is true',
      (tester) async {
    final service = _FakeSettingsService(textModeInitial: true);
    await tester.pumpWidget(MaterialApp(
      home: SettingsScreen(settingsService: service),
    ));
    await tester.pump();

    final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
    expect(switches[1].value, isTrue);
  });

  testWidgets('tapping text mode toggle enables it and persists', (tester) async {
    final service = _FakeSettingsService();
    await tester.pumpWidget(MaterialApp(
      home: SettingsScreen(settingsService: service),
    ));
    await tester.pump();

    final textModeCard = find.ancestor(
      of: find.text('Mode Alterné (Texte)'),
      matching: find.byType(Card),
    );
    await tester.tap(find.descendant(of: textModeCard, matching: find.byType(Switch)));
    await tester.pump();

    expect(service.textMode, isTrue);
  });

  // ── LiveKit toggle ─────────────────────────────────────────────────────────

  testWidgets('LiveKit toggle starts off by default', (tester) async {
    final service = _FakeSettingsService();
    await tester.pumpWidget(MaterialApp(
      home: SettingsScreen(settingsService: service),
    ));
    await tester.pump();

    final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
    expect(switches[2].value, isFalse);
  });

  testWidgets('LiveKit toggle starts on when initial value is true',
      (tester) async {
    final service = _FakeSettingsService(liveKitInitial: true);
    await tester.pumpWidget(MaterialApp(
      home: SettingsScreen(settingsService: service),
    ));
    await tester.pump();

    final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
    expect(switches[2].value, isTrue);
  });

  testWidgets('tapping LiveKit toggle enables it and persists', (tester) async {
    final service = _FakeSettingsService();
    await tester.pumpWidget(MaterialApp(
      home: SettingsScreen(settingsService: service),
    ));
    await tester.pump();

    // The third card may be below the default test viewport (800×600).
    // ensureVisible + pumpAndSettle scrolls it fully into view.
    await tester.ensureVisible(find.text('Mode WebRTC (LiveKit)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mode WebRTC (LiveKit)'));
    await tester.pump();

    expect(service.liveKit, isTrue);
  });

  testWidgets('tapping LiveKit toggle disables it when previously enabled',
      (tester) async {
    final service = _FakeSettingsService(liveKitInitial: true);
    await tester.pumpWidget(MaterialApp(
      home: SettingsScreen(settingsService: service),
    ));
    await tester.pump();

    await tester.ensureVisible(find.text('Mode WebRTC (LiveKit)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mode WebRTC (LiveKit)'));
    await tester.pump();

    expect(service.liveKit, isFalse);
  });
}
