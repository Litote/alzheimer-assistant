import 'package:alzheimer_assistant/features/assistant/domain/repositories/conversation_repository.dart';

/// Transport contract for text-to-text mode (SSE).
///
/// Device STT transcribes the user's speech; the transcription is sent as
/// text. The server replies with text; client-side TTS reads it aloud.
abstract interface class TextRepository implements ConversationRepository {
  /// Sends a text message upstream (user transcription).
  void sendText(String text);
}
