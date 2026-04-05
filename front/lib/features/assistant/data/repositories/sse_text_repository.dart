import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:alzheimer_assistant/core/constants/app_constants.dart';
import 'package:alzheimer_assistant/core/utils/app_logger.dart';
import 'package:alzheimer_assistant/features/assistant/domain/entities/live_event.dart';
import 'package:alzheimer_assistant/features/assistant/domain/repositories/text_repository.dart';

/// Function type used to POST to the SSE endpoint and return a line stream.
///
/// Injectable for testing — production code uses [_httpFetch].
typedef SseFetchFn = Stream<String> Function(Uri uri, String jsonBody);

/// Text-to-text transport implementing [TextRepository].
///
/// Device STT transcribes speech; [sendText] forwards the transcription to
/// the server via POST `/run_sse`; the server replies with SSE events;
/// client-side TTS reads the response aloud.
///
/// Tool responses (e.g. phone call results) are sent as a new POST using the
/// ADK `functionResponse` part format so the agent can continue the turn.
class SseTextRepository implements TextRepository {
  SseTextRepository({SseFetchFn? fetchFn})
      : _fetchFn = fetchFn ?? _httpFetch;

  final SseFetchFn _fetchFn;
  final _logger = appLogger;

  StreamController<LiveEvent>? _controller;
  String? _sessionId;

  // ── Public API ─────────────────────────────────────────────────────────────

  @override
  Stream<LiveEvent> connect({bool useElevenLabs = false, String? sessionId}) {
    _controller?.close();
    _controller = StreamController<LiveEvent>();
    // session_id is required by the server — generate one if not resuming.
    _sessionId = sessionId ?? _generateSessionId();
    _logger.i('[SseText] Ready (sessionId: $_sessionId)');
    // Notify the BLoC immediately so it persists the session ID.
    _controller!.add(LiveEvent.sessionEstablished(_sessionId!));
    return _controller!.stream;
  }

  @override
  void sendText(String text) {
    _logger.d('[SseText] sendText: "$text"');
    _postMessage({
      'role': 'user',
      'parts': [
        {'text': text},
      ],
    });
  }

  @override
  void sendToolResponse({
    required String callId,
    required String functionName,
    required String result,
  }) {
    _logger.d('[SseText] sendToolResponse: $functionName ($callId) → "$result"');
    _postMessage({
      'role': 'user',
      'parts': [
        {
          'functionResponse': {
            'id': callId,
            'name': functionName,
            'response': {'status': result},
          },
        },
      ],
    });
  }

  @override
  Future<void> disconnect() async {
    _controller?.close();
    _controller = null;
    _logger.i('[SseText] Disconnected');
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  void _postMessage(Map<String, dynamic> message) {
    final ctrl = _controller;
    if (ctrl == null || ctrl.isClosed) {
      _logger.w('[SseText] _postMessage called with no active controller');
      return;
    }
    _doPost(message, ctrl).ignore();
  }

  Future<void> _doPost(
    Map<String, dynamic> message,
    StreamController<LiveEvent> ctrl,
  ) async {
    final uri = Uri.parse(AppConstants.adkTextUrl);
    final body = <String, dynamic>{
      'app_name': AppConstants.adkAppName,
      'user_id': AppConstants.adkUserId,
      'session_id': _sessionId,
      'new_message': message,
      'streaming': false,
    };

    try {
      _logger.i('[SseText] POST → $uri');
      _logger.d('[SseText] body: ${jsonEncode(body)}');
      var hasTextContent = false;
      await for (final line in _fetchFn(uri, jsonEncode(body))) {
        if (ctrl.isClosed) break;
        _logger.d('[SseText] raw line: "$line"');
        if (!line.startsWith('data: ')) continue;
        final data = line.substring(6).trim();
        if (data.isEmpty || data == '[DONE]') {
          _logger.d('[SseText] skip: "${data.isEmpty ? '<empty>' : data}"');
          continue;
        }
        final event = _parseMessage(data);
        if (event != null) {
          if (event is LiveOutputTranscription) hasTextContent = true;
          _logger.d('[SseText] emit: ${event.runtimeType}');
          ctrl.add(event);
        }
      }
      // The server closes the stream after the last ADK event without sending
      // an explicit turnComplete frame. Emit it now so the BLoC triggers TTS.
      if (!ctrl.isClosed && hasTextContent) {
        _logger.i('[SseText] ← stream ended → implicit turnComplete');
        ctrl.add(const LiveEvent.turnComplete());
      } else if (!ctrl.isClosed && !hasTextContent) {
        _logger.w('[SseText] ← stream ended with no text content — no turnComplete emitted');
      }
    } catch (e) {
      _logger.e('[SseText] Request failed: $e');
      if (!ctrl.isClosed) ctrl.addError(e);
    }
  }

  LiveEvent? _parseMessage(String raw) {
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _logger.d('[SseText] ← ${json.keys.toList()}');

      // ── image_url (custom frame) ──────────────────────────────────────────
      final imageUrl = json['image_url'];
      if (imageUrl is String && imageUrl.isNotEmpty) {
        _logger.i('[SseText] ← image_url: "$imageUrl"');
        return LiveEvent.imageUrl(imageUrl);
      }

      // ── phone_event (custom frame) ────────────────────────────────────────
      final phoneEvent = json['phone_event'];
      if (phoneEvent is Map<String, dynamic>) {
        final type = phoneEvent['type'] as String?;
        if (type == 'tool_status') {
          final label = phoneEvent['label'] as String?;
          if (label != null && label.isNotEmpty) {
            _logger.i('[SseText] ← tool_status: "$label"');
            return LiveEvent.toolStatus(label);
          }
        }
        if (type == 'phone_call') {
          final callId = phoneEvent['call_id'] as String? ?? '';
          final args = phoneEvent['args'] as Map<String, dynamic>?;
          final contactName =
              (args?['contact_name'] ?? args?['name']) as String?;
          final exactMatch =
              (args?['exact_match'] ?? args?['exactMatch']) as bool? ?? false;
          if (contactName != null) {
            _logger.i('[SseText] ← phone_call: "$contactName"');
            return LiveEvent.callPhone(
              callId: callId,
              contactName: contactName,
              exactMatch: exactMatch,
            );
          }
        }
        return null;
      }

      // ── ADK native Event (by_alias=True → camelCase) ──────────────────────

      // turn_complete → "turnComplete"
      if (json['turnComplete'] == true) {
        _logger.i('[SseText] ← turnComplete');
        return const LiveEvent.turnComplete();
      }

      // content.parts[].text → agent text response
      final content = json['content'];
      if (content is Map<String, dynamic>) {
        final parts = content['parts'];
        if (parts is List) {
          final buffer = StringBuffer();
          for (final part in parts) {
            if (part is Map<String, dynamic>) {
              final text = part['text'] as String?;
              if (text != null && text.isNotEmpty) buffer.write(text);
            }
          }
          final text = buffer.toString();
          if (text.isNotEmpty) {
            _logger.i('[SseText] ← content.text: "$text"');
            return LiveEvent.outputTranscription(text);
          }
        }
      }

      // All other ADK events (routing, actions, metadata…) are expected and
      // silently ignored — no need to warn.
      return null;
    } catch (e) {
      _logger.w('[SseText] Parse error (skipped): $e\n  raw: $raw');
      return null;
    }
  }

  static String _generateSessionId() {
    final rng = Random.secure();
    final bytes = List<int>.generate(8, (_) => rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}

// ── Default HTTP implementation ────────────────────────────────────────────

Stream<String> _httpFetch(Uri uri, String jsonBody) async* {
  final client = HttpClient();
  try {
    final req = await client.postUrl(uri);
    req.headers.contentType = ContentType.json;
    req.write(jsonBody);
    final response = await req.close();
    if (response.statusCode != 200) {
      throw Exception('Server error ${response.statusCode}');
    }
    yield* response.transform(utf8.decoder).transform(const LineSplitter());
  } finally {
    client.close();
  }
}
