import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alzheimer_assistant/shared/services/settings_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ── useElevenLabs ──────────────────────────────────────────────────────────

  test('getUseElevenLabs returns true by default', () async {
    final service = SettingsService();
    expect(await service.getUseElevenLabs(), isTrue);
  });

  test('setUseElevenLabs(true) is persisted', () async {
    final service = SettingsService();
    await service.setUseElevenLabs(true);
    expect(await service.getUseElevenLabs(), isTrue);
  });

  test('setUseElevenLabs can be toggled back to false', () async {
    final service = SettingsService();
    await service.setUseElevenLabs(true);
    await service.setUseElevenLabs(false);
    expect(await service.getUseElevenLabs(), isFalse);
  });

  test('two SettingsService instances share the same underlying store', () async {
    await SettingsService().setUseElevenLabs(true);
    expect(await SettingsService().getUseElevenLabs(), isTrue);
  });

  // ── useTextMode ────────────────────────────────────────────────────────────

  test('getUseTextMode returns true by default', () async {
    final service = SettingsService();
    expect(await service.getUseTextMode(), isTrue);
  });

  test('setUseTextMode(true) is persisted', () async {
    final service = SettingsService();
    await service.setUseTextMode(true);
    expect(await service.getUseTextMode(), isTrue);
  });

  test('setUseTextMode can be toggled back to false', () async {
    final service = SettingsService();
    await service.setUseTextMode(true);
    await service.setUseTextMode(false);
    expect(await service.getUseTextMode(), isFalse);
  });

  test('useTextMode and useElevenLabs are independent preferences', () async {
    final service = SettingsService();
    await service.setUseElevenLabs(true);
    await service.setUseTextMode(false);
    expect(await service.getUseElevenLabs(), isTrue);
    expect(await service.getUseTextMode(), isFalse);
  });
}
