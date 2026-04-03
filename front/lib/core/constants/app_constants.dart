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

  /// WebSocket endpoint for ADK Live bidi streaming.
  /// http(s) is converted to ws(s) in [LiveRepositoryImpl].
  static String get adkLiveUrl => '$adkBaseUrl/run_live';
}
