import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:alzheimer_assistant/core/utils/app_logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:alzheimer_assistant/core/constants/app_constants.dart';
import 'package:alzheimer_assistant/features/assistant/domain/entities/live_event.dart';
import 'package:alzheimer_assistant/features/assistant/domain/repositories/audio_repository.dart';

/// Audio-to-audio bidi transport over WebSocket (`/run_live`).
///
/// Streams raw PCM from the mic upstream; receives PCM audio chunks and
/// transcriptions downstream. Server-side VAD and TTS are handled by the ADK
/// agent.
///
/// ## Protocol (Google GenAI Live API format)
///
/// ### Connection setup (client → server)
/// ```json
/// {"setup": {"app_name": "…", "user_id": "…", "use_elevenlabs": false}}
/// ```
///
/// ### Audio chunk (client → server)
/// ```json
/// {"realtime_input": {"media_chunks": [{"mime_type": "audio/pcm;rate=16000", "data": "<b64>"}]}}
/// ```
///
/// ### Interruption (client → server)
/// ```json
/// {"client_content": {"interrupted": true}}
/// ```
///
/// ### Tool response (client → server)
/// ```json
/// {"tool_response": {"function_responses": [{"id": "…", "name": "…", "response": {"status": "…"}}]}}
/// ```
class WsAudioRepository implements AudioRepository {
  WsAudioRepository({
    WebSocketChannel Function(Uri)? channelFactory,
  }) : _channelFactory = channelFactory ?? WebSocketChannel.connect;

  final WebSocketChannel Function(Uri) _channelFactory;
  WebSocketChannel? _channel;
  final _logger = appLogger;
  bool _firstChunkSent = false;
  bool _firstEventReceived = false;

  // ── Public API ─────────────────────────────────────────────────────────────

  @override
  Stream<LiveEvent> connect({
    bool useElevenLabs = false,
    String? sessionId,
  }) {
    final uri = _buildWsUri();
    _logger.i('[WsAudio] Connecting → $uri (useElevenLabs: $useElevenLabs)');
    _firstChunkSent = false;
    _firstEventReceived = false;

    _channel = _channelFactory(uri);

    final setup = <String, dynamic>{
      'app_name': AppConstants.adkAppName,
      'user_id': AppConstants.adkUserId,
      'use_elevenlabs': useElevenLabs,
    };
    _logger.i('[WsAudio] → setup: use_elevenlabs=$useElevenLabs app_name=${AppConstants.adkAppName}');
    _sendJson({'setup': setup});

    return _channel!.stream
        .where((msg) => msg is String)
        .cast<String>()
        .map(_parseMessage)
        .where((event) => event != null)
        .cast<LiveEvent>();
  }

  @override
  void sendAudio(Uint8List pcmBytes) {
    if (!_firstChunkSent) {
      _firstChunkSent = true;
      _logger.i('[WsAudio] → first audio chunk sent (${pcmBytes.length} bytes)');
    }
    _sendJson({
      'realtime_input': {
        'media_chunks': [
          {
            'mime_type': 'audio/pcm;rate=16000',
            'data': base64.encode(pcmBytes),
          }
        ],
      },
    });
  }

  @override
  void sendInterruption() {
    _logger.i('[WsAudio] → sending interruption signal');
    _sendJson({
      'client_content': {
        'interrupted': true,
      },
    });
  }

  @override
  void sendToolResponse({
    required String callId,
    required String functionName,
    required String result,
  }) {
    _sendJson({
      'tool_response': {
        'function_responses': [
          {
            'id': callId,
            'name': functionName,
            'response': {'status': result},
          }
        ],
      },
    });
  }

  @override
  Future<void> disconnect() async {
    await _channel?.sink.close();
    _channel = null;
    _logger.i('[WsAudio] Disconnected');
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  Uri _buildWsUri() {
    final base = AppConstants.adkBaseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    return Uri.parse('$base/run_live');
  }

  void _sendJson(Map<String, dynamic> data) {
    _channel?.sink.add(jsonEncode(data));
  }

  LiveEvent? _parseMessage(String raw) {
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (!_firstEventReceived) {
        _firstEventReceived = true;
        _logger.i('[WsAudio] ← first server event — keys: ${json.keys.toList()}');
      }
      final event = _parseServerContent(json) ??
          _parseInputTranscription(json) ??
          _parseOutputTranscription(json) ??
          _parseToolCall(json) ??
          _parseSessionInfo(json) ??
          _parseToolStatus(json) ??
          _parseImageUrl(json);
      if (event == null) {
        _logger.w('[WsAudio] ← unrecognized message — keys: ${json.keys.toList()}');
      }
      return event;
    } catch (e) {
      _logger.w('[WsAudio] Parse error (skipped): $e\n  raw: $raw');
      return null;
    }
  }

  LiveEvent? _parseServerContent(Map<String, dynamic> json) {
    final serverContent = json['server_content'];
    if (serverContent is! Map<String, dynamic>) return null;
    if (serverContent['turn_complete'] == true) {
      _logger.i('[WsAudio] ← turn_complete');
      return const LiveEvent.turnComplete();
    }
    final modelTurn = serverContent['model_turn'];
    if (modelTurn is! Map<String, dynamic>) return null;
    final parts = modelTurn['parts'];
    if (parts is! List || parts.isEmpty) return null;
    final part = parts.first as Map<String, dynamic>?;
    final inlineData = part?['inline_data'] as Map<String, dynamic>?;
    final b64 = inlineData?['data'] as String?;
    if (b64 != null) {
      final decodedBytes = base64.decode(b64);
      _logger.i('[WsAudio] ← audioChunk (${b64.length} b64 chars → ${decodedBytes.length} bytes)');
      return LiveEvent.audioChunk(decodedBytes);
    }
    _logger.w('[WsAudio] ← model_turn part has no inline_data.data — part keys: ${part?.keys.toList()}, inlineData keys: ${inlineData?.keys.toList()}');
    return null;
  }

  LiveEvent? _parseInputTranscription(Map<String, dynamic> json) {
    final inputTranscription = json['input_transcription'];
    if (inputTranscription is! Map<String, dynamic>) return null;
    final text = inputTranscription['text'] as String?;
    if (text != null && text.isNotEmpty) {
      _logger.i('[WsAudio] ← input_transcription: "$text"');
      return LiveEvent.inputTranscription(text);
    }
    return null;
  }

  LiveEvent? _parseOutputTranscription(Map<String, dynamic> json) {
    final outputTranscription = json['output_transcription'];
    if (outputTranscription is! Map<String, dynamic>) return null;
    final text = outputTranscription['text'] as String?;
    if (text != null && text.isNotEmpty) {
      _logger.i('[WsAudio] ← output_transcription: "$text"');
      return LiveEvent.outputTranscription(text);
    }
    return null;
  }

  LiveEvent? _parseToolCall(Map<String, dynamic> json) {
    final toolCall = json['tool_call'];
    if (toolCall is! Map<String, dynamic>) return null;
    final calls = toolCall['function_calls'];
    if (calls is! List || calls.isEmpty) return null;
    final call = calls.first as Map<String, dynamic>?;
    final name = call?['name'] as String?;
    _logger.i('[WsAudio] ← tool_call: name="$name" args=${call?['args']}');
    if (name != 'call_phone') return null;
    final callId = call!['id'] as String? ?? '';
    final args = call['args'] as Map<String, dynamic>?;
    final contactName = (args?['contact_name'] ?? args?['name']) as String?;
    final exactMatch =
        (args?['exact_match'] ?? args?['exactMatch']) as bool? ?? false;
    if (contactName != null) {
      return LiveEvent.callPhone(
        callId: callId,
        contactName: contactName,
        exactMatch: exactMatch,
      );
    }
    _logger.w('[WsAudio] ← call_phone with null contactName — args: $args');
    return null;
  }

  LiveEvent? _parseSessionInfo(Map<String, dynamic> json) {
    final sessionInfo = json['session_info'];
    if (sessionInfo is! Map<String, dynamic>) return null;
    final sessionId = sessionInfo['session_id'] as String?;
    if (sessionId != null && sessionId.isNotEmpty) {
      _logger.i('[WsAudio] ← session_established: $sessionId');
      return LiveEvent.sessionEstablished(sessionId);
    }
    final welcome = sessionInfo['welcome'] as String?;
    if (welcome != null && welcome.isNotEmpty) {
      _logger.i('[WsAudio] ← session_info welcome received');
      return LiveEvent.sessionInfo(welcome);
    }
    return null;
  }

  LiveEvent? _parseToolStatus(Map<String, dynamic> json) {
    final toolStatus = json['tool_status'];
    if (toolStatus is! Map<String, dynamic>) return null;
    final label = toolStatus['label'] as String?;
    if (label != null && label.isNotEmpty) {
      _logger.i('[WsAudio] ← tool_status: label="$label"');
      return LiveEvent.toolStatus(label);
    }
    return null;
  }

  LiveEvent? _parseImageUrl(Map<String, dynamic> json) {
    final url = json['image_url'];
    if (url is String && url.isNotEmpty) {
      _logger.i('[WsAudio] ← image_url: "$url"');
      return LiveEvent.imageUrl(url);
    }
    return null;
  }
}
