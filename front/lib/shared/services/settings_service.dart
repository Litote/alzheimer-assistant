import 'package:shared_preferences/shared_preferences.dart';

/// Persists user-configurable runtime settings via SharedPreferences.
class SettingsService {
  static const _keyUseElevenLabs = 'use_elevenlabs';
  static const _keyUseTextMode = 'use_text_mode';

  /// Returns whether ElevenLabs TTS is enabled. Defaults to [true].
  Future<bool> getUseElevenLabs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyUseElevenLabs) ?? true;
  }

  /// Persists the ElevenLabs TTS preference.
  Future<void> setUseElevenLabs(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUseElevenLabs, value);
  }

  /// Returns whether text-to-text mode is enabled (device STT → text → SSE →
  /// text → client TTS). Defaults to [false] (audio-to-audio via WebSocket).
  Future<bool> getUseTextMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyUseTextMode) ?? false;
  }

  /// Persists the text mode preference.
  Future<void> setUseTextMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUseTextMode, value);
  }
}
