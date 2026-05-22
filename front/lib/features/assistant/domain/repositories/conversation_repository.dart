import 'package:alzheimer_assistant/features/assistant/domain/entities/live_event.dart';

/// Common interface for both text-to-text (SSE) and audio-to-audio (WebSocket)
/// transports.
abstract interface class ConversationRepository {
  /// Opens a connection and returns a stream of downstream events.
  ///
  /// [useElevenLabs] is forwarded to the server in the setup message
  /// (audio mode only — ignored by SSE).
  /// [sessionId] resumes an existing session (text mode only — ignored by WS).
  /// [supabaseUserId] is the authenticated Supabase user UUID. The agent uses
  /// it to scope all Supabase queries to the correct user.
  Stream<LiveEvent> connect({
    bool useElevenLabs = false,
    String? sessionId,
    String supabaseUserId = '',
  });

  /// Sends a tool response back to the agent after executing a tool call.
  void sendToolResponse({
    required String callId,
    required String functionName,
    required String result,
  });

  /// Closes the connection.
  Future<void> disconnect();
}
