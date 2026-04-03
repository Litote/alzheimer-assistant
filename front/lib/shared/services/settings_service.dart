import 'package:shared_preferences/shared_preferences.dart';

/// Persists user-configurable runtime settings via SharedPreferences.
class SettingsService {
  static const _keyUseElevenLabs = 'use_elevenlabs';

  /// Returns whether ElevenLabs TTS is enabled. Defaults to [false].
  Future<bool> getUseElevenLabs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyUseElevenLabs) ?? false;
  }

  /// Persists the ElevenLabs TTS preference.
  Future<void> setUseElevenLabs(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUseElevenLabs, value);
  }
}
