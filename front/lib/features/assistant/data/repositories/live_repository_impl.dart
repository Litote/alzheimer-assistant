import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:alzheimer_assistant/core/utils/app_logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:alzheimer_assistant/core/constants/app_constants.dart';
import 'package:alzheimer_assistant/features/assistant/domain/entities/live_event.dart';
import 'package:alzheimer_assistant/features/assistant/domain/repositories/live_repository.dart';

/// ADK Live bidi-streaming transport over WebSocket.
///
/// ## Protocol (Google GenAI Live API format)
///
/// ### Connection
/// After the WebSocket handshake, the client sends a `setup` message:
/// ```json
/// {"setup": {"app_name": "…", "user_id": "…"}}
/// ```
///
/// ### Upstream (client → server)
/// Audio chunk:
/// ```json
/// {"realtime_input": {"media_chunks": [{"mime_type": "audio/pcm;rate=16000", "data": "<b64>"}]}}
/// ```
/// Text message (phone-call result relay):
/// ```json
/// {"client_content": {"turns": [{"role": "user", "parts": [{"text": "…"}]}], "turn_complete": true}}
/// ```
/// Interruption:
/// ```json
/// {"client_content": {"interrupted": true}}
/// ```
/// Tool response:
/// ```json
/// {"tool_response": {"function_responses": [{"id": "…", "name": "…", "response": {"status": "…"}}]}}
/// ```
///
/// ### Downstream (server → client)
/// Text delta:
/// ```json
/// {"server_content": {"model_turn": {"parts": [{"text": "…"}]}, "turn_complete": false}}
/// ```
/// Audio chunk (PCM 24 kHz):
/// ```json
/// {"server_content": {"model_turn": {"parts": [{"inline_data": {"mime_type": "audio/pcm;rate=24000", "data": "<b64>"}}]}}}
/// ```
/// Turn complete:
/// ```json
/// {"server_content": {"turn_complete": true}}
/// ```
/// Tool call (call_phone):
/// ```json
/// {"tool_call": {"function_calls": [{"id": "…", "name": "call_phone", "args": {"contact_name": "…", "exact_match": false}}]}}
/// ```
class LiveRepositoryImpl implements LiveRepository {
  LiveRepositoryImpl({
    WebSocketChannel Function(Uri)? channelFactory,
  }) : _channelFactory = channelFactory ?? WebSocketChannel.connect;

  final WebSocketChannel Function(Uri) _channelFactory;
  WebSocketChannel? _channel;
  final _logger = appLogger;
  bool _firstChunkSent = false;
  bool _firstEventReceived = false;

  // ── Public API ─────────────────────────────────────────────────────────────

  @override
  Stream<LiveEvent> connect({bool useElevenLabs = false}) {
    final uri = _buildWsUri();
    _logger.i('[Live] Connecting → $uri (useElevenLabs: $useElevenLabs)');
    _firstChunkSent = false;
    _firstEventReceived = false;

    _channel = _channelFactory(uri);

    _sendJson({
      'setup': {
        'app_name': AppConstants.adkAppName,
        'user_id': AppConstants.adkUserId,
        'use_elevenlabs': useElevenLabs,
      },
    });

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
      _logger.i('[Live] → first audio chunk sent (${pcmBytes.length} bytes)');
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
  void sendText(String text) {
    _sendJson({
      'client_content': {
        'turns': [
          {
            'role': 'user',
            'parts': [
              {'text': text}
            ],
          }
        ],
        'turn_complete': true,
      },
    });
  }

  @override
  void sendInterruption() {
    _logger.i('[Live] → sending interruption signal');
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
    _logger.i('[Live] Disconnected');
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
        _logger.i('[Live] ← first server event received — keys: ${json.keys.toList()}');
      }

      // ── server_content ───────────────────────────────────────────────────
      final serverContent = json['server_content'];
      if (serverContent is Map<String, dynamic>) {
        if (serverContent['turn_complete'] == true) {
          _logger.i('[Live] ← turn_complete');
          return const LiveEvent.turnComplete();
        }

        final modelTurn = serverContent['model_turn'];
        if (modelTurn is Map<String, dynamic>) {
          final parts = modelTurn['parts'];
          if (parts is List && parts.isNotEmpty) {
            final part = parts.first as Map<String, dynamic>?;

            // Text deltas are ignored — transcriptions are used for display instead.
            final inlineData = part?['inline_data'] as Map<String, dynamic>?;
            final b64 = inlineData?['data'] as String?;
            if (b64 != null) {
              _logger.i('[Live] ← audioChunk (${b64.length} b64 chars)');
              return LiveEvent.audioChunk(base64.decode(b64));
            }
          }
        }
      }

      // ── input_transcription ──────────────────────────────────────────────
      final inputTranscription = json['input_transcription'];
      if (inputTranscription is Map<String, dynamic>) {
        final text = inputTranscription['text'] as String?;
        if (text != null && text.isNotEmpty) {
          _logger.i('[Live] ← input_transcription: "$text"');
          return LiveEvent.inputTranscription(text);
        }
      }

      // ── output_transcription ─────────────────────────────────────────────
      final outputTranscription = json['output_transcription'];
      if (outputTranscription is Map<String, dynamic>) {
        final text = outputTranscription['text'] as String?;
        if (text != null && text.isNotEmpty) {
          _logger.i('[Live] ← output_transcription: "$text"');
          return LiveEvent.outputTranscription(text);
        }
      }

      // ── tool_call ────────────────────────────────────────────────────────
      final toolCall = json['tool_call'];
      if (toolCall is Map<String, dynamic>) {
        final calls = toolCall['function_calls'];
        if (calls is List && calls.isNotEmpty) {
          final call = calls.first as Map<String, dynamic>?;
          final name = call?['name'] as String?;
          _logger.i('[Live] ← tool_call: name="$name" args=${call?['args']}');
          if (name == 'call_phone') {
            final callId = call!['id'] as String? ?? '';
            final args = call['args'] as Map<String, dynamic>?;
            // Server sends "name" / "exactMatch" (camelCase).
            // AI_CONTEXT.md contract uses "contact_name" / "exact_match" — update the contract.
            final contactName =
                (args?['contact_name'] ?? args?['name']) as String?;
            final exactMatch =
                (args?['exact_match'] ?? args?['exactMatch']) as bool? ?? false;
            if (contactName != null) {
              return LiveEvent.callPhone(
                callId: callId,
                contactName: contactName,
                exactMatch: exactMatch,
              );
            }
            _logger.w('[Live] ← call_phone with null contactName — full args: $args');
          }
        }
        return null;
      }

      // ── session_info ─────────────────────────────────────────────────────
      final sessionInfo = json['session_info'];
      if (sessionInfo is Map<String, dynamic>) {
        final welcome = sessionInfo['welcome'] as String?;
        if (welcome != null && welcome.isNotEmpty) {
          _logger.i('[Live] ← session_info welcome received');
          return LiveEvent.sessionInfo(welcome);
        }
      }

      // ── tool_status ──────────────────────────────────────────────────────
      final toolStatus = json['tool_status'];
      if (toolStatus is Map<String, dynamic>) {
        final label = toolStatus['label'] as String?;
        if (label != null && label.isNotEmpty) {
          _logger.i('[Live] ← tool_status: label="$label"');
          return LiveEvent.toolStatus(label);
        }
      }

      _logger.w('[Live] ← unrecognized message (ignored) — keys: ${json.keys.toList()}');
      return null;
    } catch (e) {
      _logger.w('[Live] Parse error (skipped): $e\n  raw: $raw');
      return null;
    }
  }
}
