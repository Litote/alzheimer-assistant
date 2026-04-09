import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:alzheimer_assistant/core/utils/app_logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:alzheimer_assistant/core/constants/app_constants.dart';
import 'package:alzheimer_assistant/features/assistant/data/repositories/live_message_parser.dart';
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
  final _parser = LiveMessageParser();
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
    if (!_firstEventReceived) {
      _firstEventReceived = true;
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        _logger.i('[WsAudio] ← first server event — keys: ${json.keys.toList()}');
      } catch (_) {}
    }
    return _parser.parse(raw);
  }
}
