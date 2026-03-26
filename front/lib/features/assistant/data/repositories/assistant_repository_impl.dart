import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alzheimer_assistant/core/constants/app_constants.dart';
import 'package:alzheimer_assistant/core/network/dio_client.dart';
import 'package:alzheimer_assistant/features/assistant/domain/entities/assistant_response.dart';
import 'package:alzheimer_assistant/features/assistant/domain/repositories/assistant_repository.dart';

class AssistantRepositoryImpl implements AssistantRepository {
  AssistantRepositoryImpl({Dio? adkDio, Dio? elevenLabsDio, SharedPreferences? prefs})
      : _dio = adkDio ?? DioClient.create(baseUrl: AppConstants.adkBaseUrl),
        _elevenLabsDio = elevenLabsDio ?? DioClient.create(),
        _prefs = prefs {
    _logger.i('[Config] ADK base URL  : ${AppConstants.adkBaseUrl}');
    _logger.i('[Config] ADK /run_sse  : ${AppConstants.runSseUrl}');
    _logger.i('[Config] ADK /sessions : ${AppConstants.sessionUrl}');
  }

  final Dio _dio;
  final Dio _elevenLabsDio;
  final _logger = Logger();
  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async =>
      _prefs ??= await SharedPreferences.getInstance();

  static const _sessionKey = 'adk_session_id';

  // ── Session ────────────────────────────────────────────────────────────────

  Future<String> _getSessionId() async {
    final prefs = await _getPrefs();
    final stored = prefs.getString(_sessionKey);
    if (stored != null && stored.isNotEmpty) {
      _logger.d('[Session] Reusing existing session: $stored');
      return stored;
    }

    _logger.i('[Session] Creating new session → ${AppConstants.sessionUrl}');
    final response = await _dio.post<dynamic>(AppConstants.sessionUrl);
    final data = response.data;
    _logger.d('[Session] Session creation response: $data');
    String? sessionId;

    if (data is List && data.isNotEmpty) {
      final first = data.first;
      sessionId = first['id']?.toString() ?? first['sessionId']?.toString();
    } else if (data is Map) {
      sessionId =
          data['id']?.toString() ?? data['sessionId']?.toString();
    } else if (data is String) {
      sessionId = data;
    }

    if (sessionId != null && sessionId.isNotEmpty) {
      _logger.i('[Session] Session created: $sessionId');
      await prefs.setString(_sessionKey, sessionId);
      return sessionId;
    }

    throw Exception('[Session] Unexpected server response: $data');
  }

  Future<void> _clearSession() async {
    final prefs = await _getPrefs();
    await prefs.remove(_sessionKey);
  }

  // ── ADK /run_sse ───────────────────────────────────────────────────────────

  Future<({String text, String? callPhoneName})> _callAdk(
    String question, {
    bool isRetry = false,
  }) async {
    final sessionId = await _getSessionId();
    final url = AppConstants.runSseUrl;
    final payload = {
      'app_name': AppConstants.adkAppName,
      'user_id': AppConstants.adkUserId,
      'session_id': sessionId,
      'new_message': {
        'role': 'user',
        'parts': [
          {'text': question}
        ],
      },
      'streaming': true,
    };

    _logger.i('[ADK] POST $url${isRetry ? ' (retry)' : ''}');
    _logger.d('[ADK] Payload : ${jsonEncode(payload)}');

    try {
      final response = await _dio.post<String>(
        url,
        data: payload,
        options: Options(responseType: ResponseType.plain),
      );

      _logger.d('[ADK] Raw SSE response:\n${response.data}');
      final result = _parseSseBody(response.data ?? '');
      _logger.i('[ADK] Extracted text: "${result.text}"');
      if (result.callPhoneName != null) {
        _logger.i('[ADK] call_phone action detected: "${result.callPhoneName}"');
      }
      return (
        text: result.text.isNotEmpty ? result.text : 'Pas de réponse reçue',
        callPhoneName: result.callPhoneName,
      );
    } on DioException catch (e) {
      _logger.e('[ADK] HTTP error ${e.response?.statusCode}: ${e.message}');
      if (e.response?.statusCode == 404 && !isRetry) {
        _logger.i('[ADK] Session 404 — clearing session and retrying');
        await _clearSession();
        return _callAdk(question, isRetry: true);
      }
      rethrow;
    }
  }

  /// Extracts and concatenates all text fragments from an SSE body,
  /// and detects [stateDelta] actions (e.g. call_phone).
  ///
  /// Expected format (one line per event):
  ///   data: {"content":{"parts":[{"text":"…"}]}}\n
  ///   \n
  ({String text, String? callPhoneName}) _parseSseBody(String body) {
    final buffer = StringBuffer();
    String? callPhoneName;
    var eventIndex = 0;

    for (final line in body.split('\n')) {
      final payload = _extractSsePayload(line);
      if (payload == null) continue;

      eventIndex++;
      try {
        final decoded = jsonDecode(payload) as Map<String, dynamic>?;
        _appendModelTexts(buffer, decoded, eventIndex);
        callPhoneName ??= _extractCallPhoneName(decoded, eventIndex);
      } catch (e) {
        _logger.w('[SSE event #$eventIndex] Parse error (skipped): $e');
      }
    }

    _logger.i('[SSE] $eventIndex event(s) received, final text: "${buffer.toString()}"');
    return (text: buffer.toString(), callPhoneName: callPhoneName);
  }

  /// Returns the payload string from a `data: ...` SSE line, or null to skip.
  String? _extractSsePayload(String line) {
    final trimmed = line.trim();
    if (!trimmed.startsWith('data:')) return null;
    final payload = trimmed.substring(5).trim();
    if (payload == '[DONE]' || payload.isEmpty) return null;
    return payload;
  }

  /// Appends non-partial model text fragments to [buffer].
  void _appendModelTexts(
    StringBuffer buffer,
    Map<String, dynamic>? decoded,
    int eventIndex,
  ) {
    final role = decoded?['content']?['role'] as String?;
    final partial = decoded?['partial'] as bool?;
    final parts = decoded?['content']?['parts'];
    final texts = (parts is List)
        ? parts.whereType<Map>().map((p) => p['text']).whereType<String>().where((t) => t.isNotEmpty).toList()
        : <String>[];

    _logger.d('[SSE event #$eventIndex] role=$role partial=$partial texts=$texts');

    if (role != 'model' || partial == true) return;
    for (final t in texts) {
      buffer.write(t);
    }
  }

  /// Extracts the contact name from a `call_phone` stateDelta action, or null.
  String? _extractCallPhoneName(Map<String, dynamic>? decoded, int eventIndex) {
    final actions = decoded?['actions'];
    if (actions is! Map) return null;
    final stateDelta = actions['stateDelta'];
    if (stateDelta is! Map) return null;
    final action = stateDelta['action'];
    if (action is! Map || action['type'] != 'call_phone') return null;
    final name = action['payload']?['name'] as String?;
    _logger.d('[SSE event #$eventIndex] stateDelta call_phone → $name');
    return name;
  }

  // ── ElevenLabs TTS ────────────────────────────────────────────────────────

  Future<List<int>> _synthesizeSpeech(String text) async {
    const apiKey = AppConstants.elevenLabsApiKey;
    const voiceId = AppConstants.elevenLabsVoiceId;

    if (apiKey.isEmpty || voiceId.isEmpty) {
      _logger.w('[TTS] Missing ElevenLabs keys — synthesis skipped');
      return [];
    }

    final url = AppConstants.elevenLabsTtsUrl(voiceId);
    _logger.i('[TTS] POST $url');
    _logger.d('[TTS] Text to synthesise: "$text"');

    final response = await _elevenLabsDio.post<List<int>>(
      url,
      options: Options(
        headers: {
          'xi-api-key': apiKey,
          'Content-Type': 'application/json',
        },
        responseType: ResponseType.bytes,
      ),
      data: {
        'text': text,
        'model_id': AppConstants.elevenLabsTtsModel,
        'voice_settings': {
          'stability': 0.5,
          'similarity_boost': 0.90,
          'style': 0.0,
          'use_speaker_boost': true,
        },
      },
    );

    final bytes = response.data ?? [];
    _logger.i('[TTS] Audio received: ${bytes.length} bytes');
    return bytes;
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  @override
  Future<List<int>> synthesize(String text) => _synthesizeSpeech(text);

  @override
  Future<AssistantResponse> ask(String question) async {
    _logger.i('[Repository] ask() → "$question"');
    final (:text, :callPhoneName) = await _callAdk(question);
    final audioBytes = await _synthesizeSpeech(text);
    _logger.i('[Repository] Final response: "$text" (${audioBytes.length} audio bytes)');
    return AssistantResponse(
      text: text,
      audioBytes: audioBytes,
      callPhoneName: callPhoneName,
    );
  }
}
