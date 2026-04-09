import 'dart:convert';

import 'package:alzheimer_assistant/core/utils/app_logger.dart';
import 'package:alzheimer_assistant/features/assistant/domain/entities/live_event.dart';

/// Parses raw JSON strings from any live transport (WebSocket, LiveKit data
/// messages) into [LiveEvent]s.
///
/// The format matches the Google GenAI Live API wire protocol used by the ADK
/// agent.
class LiveMessageParser {
  LiveMessageParser();

  final _logger = appLogger;

  /// Parses [raw] JSON and returns the corresponding [LiveEvent], or `null`
  /// when the message is known but carries no actionable content.
  LiveEvent? parse(String raw) {
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final event = _parseServerContent(json) ??
          _parseInputTranscription(json) ??
          _parseOutputTranscription(json) ??
          _parseToolCall(json) ??
          _parseSessionInfo(json) ??
          _parseToolStatus(json) ??
          _parseImageUrl(json);
      if (event == null) {
        _logger.w('[Parser] unrecognized message — keys: ${json.keys.toList()}');
      }
      return event;
    } catch (e) {
      _logger.w('[Parser] parse error (skipped): $e\n  raw: $raw');
      return null;
    }
  }

  LiveEvent? _parseServerContent(Map<String, dynamic> json) {
    final serverContent = json['server_content'];
    if (serverContent is! Map<String, dynamic>) return null;
    if (serverContent['turn_complete'] == true) {
      _logger.i('[Parser] ← turn_complete');
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
      final bytes = base64.decode(b64);
      _logger.i('[Parser] ← audioChunk (${b64.length} b64 chars → ${bytes.length} bytes)');
      return LiveEvent.audioChunk(bytes);
    }
    _logger.w('[Parser] ← model_turn part has no inline_data.data'
        ' — part keys: ${part?.keys.toList()}');
    return null;
  }

  LiveEvent? _parseInputTranscription(Map<String, dynamic> json) {
    final t = json['input_transcription'];
    if (t is! Map<String, dynamic>) return null;
    final text = t['text'] as String?;
    if (text != null && text.isNotEmpty) {
      _logger.i('[Parser] ← input_transcription: "$text"');
      return LiveEvent.inputTranscription(text);
    }
    return null;
  }

  LiveEvent? _parseOutputTranscription(Map<String, dynamic> json) {
    final t = json['output_transcription'];
    if (t is! Map<String, dynamic>) return null;
    final text = t['text'] as String?;
    if (text != null && text.isNotEmpty) {
      _logger.i('[Parser] ← output_transcription: "$text"');
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
    _logger.i('[Parser] ← tool_call: name="$name" args=${call?['args']}');
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
    _logger.w('[Parser] ← call_phone with null contactName — args: $args');
    return null;
  }

  LiveEvent? _parseSessionInfo(Map<String, dynamic> json) {
    final sessionInfo = json['session_info'];
    if (sessionInfo is! Map<String, dynamic>) return null;
    final sessionId = sessionInfo['session_id'] as String?;
    if (sessionId != null && sessionId.isNotEmpty) {
      _logger.i('[Parser] ← session_established: $sessionId');
      return LiveEvent.sessionEstablished(sessionId);
    }
    final welcome = sessionInfo['welcome'] as String?;
    if (welcome != null && welcome.isNotEmpty) {
      _logger.i('[Parser] ← session_info welcome received');
      return LiveEvent.sessionInfo(welcome);
    }
    return null;
  }

  LiveEvent? _parseToolStatus(Map<String, dynamic> json) {
    final toolStatus = json['tool_status'];
    if (toolStatus is! Map<String, dynamic>) return null;
    final label = toolStatus['label'] as String?;
    if (label != null && label.isNotEmpty) {
      _logger.i('[Parser] ← tool_status: label="$label"');
      return LiveEvent.toolStatus(label);
    }
    return null;
  }

  LiveEvent? _parseImageUrl(Map<String, dynamic> json) {
    final url = json['image_url'];
    if (url is String && url.isNotEmpty) {
      _logger.i('[Parser] ← image_url: "$url"');
      return LiveEvent.imageUrl(url);
    }
    return null;
  }
}
