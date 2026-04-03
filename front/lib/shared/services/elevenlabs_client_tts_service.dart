import 'dart:convert';
import 'dart:io';

import 'package:alzheimer_assistant/core/constants/app_constants.dart';
import 'package:alzheimer_assistant/core/utils/app_logger.dart';
import 'package:alzheimer_assistant/shared/services/client_tts_service.dart';
import 'package:alzheimer_assistant/shared/services/tts_service.dart';

/// [ClientTtsService] that synthesises text via the ElevenLabs REST API and
/// plays the resulting MP3 through [TtsService].
class ElevenLabsClientTtsService implements ClientTtsService {
  ElevenLabsClientTtsService({TtsService? ttsService})
      : _ttsService = ttsService ?? TtsService();

  final TtsService _ttsService;
  final _logger = appLogger;

  @override
  Future<void> speak(
    String text, {
    required void Function() onComplete,
  }) async {
    try {
      final bytes = await _fetchAudio(text);
      await _ttsService.play(bytes, onComplete: onComplete);
    } catch (e) {
      _logger.e('[ElevenLabsTTS] Error: $e');
      onComplete();
    }
  }

  Future<List<int>> _fetchAudio(String text) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse(
        AppConstants.elevenLabsTtsUrl(AppConstants.elevenLabsVoiceId),
      );
      final request = await client.postUrl(uri);
      request.headers
        ..set('xi-api-key', AppConstants.elevenLabsApiKey)
        ..set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8')
        ..set(HttpHeaders.acceptHeader, 'audio/mpeg');
      request.add(utf8.encode(jsonEncode({
        'text': text,
        'model_id': AppConstants.elevenLabsTtsModel,
        'voice_settings': {'stability': 0.5, 'similarity_boost': 0.75},
      })));
      final response = await request.close();
      if (response.statusCode != 200) {
        final body = await response.transform(utf8.decoder).join();
        throw Exception('ElevenLabs HTTP ${response.statusCode}: $body');
      }
      final bytes = <int>[];
      await for (final chunk in response) {
        bytes.addAll(chunk);
      }
      return bytes;
    } finally {
      client.close();
    }
  }

  @override
  Future<void> stop() => _ttsService.stop();

  @override
  Future<void> dispose() => _ttsService.dispose();
}
