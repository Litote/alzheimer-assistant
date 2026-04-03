class AppConstants {
  AppConstants._();

  static const String adkAppName = 'alzheimerassistant';
  static const String adkUserId = 'user';

  // Required via --dart-define at build time — no default, build fails if missing.
  static const String adkBaseUrl = String.fromEnvironment('ADK_BASE_URL');
  static const String elevenLabsApiKey = String.fromEnvironment(
    'ELEVENLABS_API_KEY',
  );
  static const String elevenLabsVoiceId = String.fromEnvironment(
    'ELEVENLABS_VOICE_ID',
  );
  static const String elevenLabsTtsModel = String.fromEnvironment(
    'ELEVENLABS_TTS_MODEL',
    defaultValue: 'eleven_flash_v2_5',
  );

  /// WebSocket endpoint for ADK audio-to-audio bidi streaming.
  static String get adkLiveUrl => '$adkBaseUrl/run_live';

  /// SSE endpoint for text-to-text mode.
  static String get adkTextUrl => '$adkBaseUrl/run_sse';
  static String elevenLabsTtsUrl(String voiceId) =>
      'https://api.elevenlabs.io/v1/text-to-speech/$voiceId';
}
