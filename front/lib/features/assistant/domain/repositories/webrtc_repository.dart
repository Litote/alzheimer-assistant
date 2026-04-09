import 'package:alzheimer_assistant/features/assistant/domain/repositories/conversation_repository.dart';

/// Transport contract for WebRTC-based audio (LiveKit).
///
/// Unlike [AudioRepository], this repository manages its own audio capture
/// (via WebRTC LocalAudioTrack) and playback (via RemoteAudioTrack). The
/// BLoC must not start its own mic streaming when using this repository.
///
/// Non-audio events (text, tool calls, turn_complete) are delivered via
/// LiveKit Data Messages in the same JSON format as the WebSocket transport.
abstract interface class WebRtcRepository implements ConversationRepository {
  /// Sends an interruption signal to stop the current agent turn.
  void sendInterruption();
}
