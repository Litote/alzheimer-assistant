import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alzheimer_assistant/features/settings/presentation/screens/settings_screen.dart';
import 'package:alzheimer_assistant/shared/services/settings_service.dart';

class _FakeSettingsService implements SettingsService {
  bool value;
  _FakeSettingsService({bool initial = false}) : value = initial;

  @override
  Future<bool> getUseElevenLabs() async => value;

  @override
  Future<void> setUseElevenLabs(bool newValue) async => value = newValue;
}

void main() {
  // ── Loading state ──────────────────────────────────────────────────────────

  testWidgets('shows loading indicator before settings load', (tester) async {
    final service = _FakeSettingsService();
    await tester.pumpWidget(MaterialApp(
      home: SettingsScreen(settingsService: service),
    ));

    // Do NOT pump again — the Future has not resolved yet.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(SwitchListTile), findsNothing);
  });

  // ── Loaded state ───────────────────────────────────────────────────────────

  testWidgets('shows ElevenLabs toggle after settings load', (tester) async {
    final service = _FakeSettingsService();
    await tester.pumpWidget(MaterialApp(
      home: SettingsScreen(settingsService: service),
    ));
    await tester.pump(); // let getUseElevenLabs() Future resolve

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(SwitchListTile), findsOneWidget);
    expect(find.text('Synthèse vocale ElevenLabs'), findsOneWidget);
  });

  // ── Initial value reflected ────────────────────────────────────────────────

  testWidgets('toggle starts off when initial value is false', (tester) async {
    final service = _FakeSettingsService(initial: false);
    await tester.pumpWidget(MaterialApp(
      home: SettingsScreen(settingsService: service),
    ));
    await tester.pump();

    final toggle = tester.widget<Switch>(find.byType(Switch));
    expect(toggle.value, isFalse);
  });

  testWidgets('toggle starts on when initial value is true', (tester) async {
    final service = _FakeSettingsService(initial: true);
    await tester.pumpWidget(MaterialApp(
      home: SettingsScreen(settingsService: service),
    ));
    await tester.pump();

    final toggle = tester.widget<Switch>(find.byType(Switch));
    expect(toggle.value, isTrue);
  });

  // ── Toggle interaction ─────────────────────────────────────────────────────

  testWidgets('tapping toggle enables ElevenLabs and persists the change', (tester) async {
    final service = _FakeSettingsService(initial: false);
    await tester.pumpWidget(MaterialApp(
      home: SettingsScreen(settingsService: service),
    ));
    await tester.pump();

    await tester.tap(find.byType(Switch));
    await tester.pump();

    expect(service.value, isTrue);
    final toggle = tester.widget<Switch>(find.byType(Switch));
    expect(toggle.value, isTrue);
  });

  testWidgets('tapping toggle disables ElevenLabs when previously enabled', (tester) async {
    final service = _FakeSettingsService(initial: true);
    await tester.pumpWidget(MaterialApp(
      home: SettingsScreen(settingsService: service),
    ));
    await tester.pump();

    await tester.tap(find.byType(Switch));
    await tester.pump();

    expect(service.value, isFalse);
    final toggle = tester.widget<Switch>(find.byType(Switch));
    expect(toggle.value, isFalse);
  });
}
