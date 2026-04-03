import 'dart:typed_data';

import 'package:alzheimer_assistant/features/assistant/domain/repositories/conversation_repository.dart';

/// Transport contract for audio-to-audio mode (WebSocket bidi streaming).
///
/// Streams raw PCM from the microphone to the server, which handles VAD and
/// replies with PCM audio chunks.
abstract interface class AudioRepository implements ConversationRepository {
  /// Sends a raw PCM 16 kHz 16-bit mono audio chunk upstream.
  void sendAudio(Uint8List pcmBytes);

  /// Sends an interruption signal to stop the current agent turn.
  void sendInterruption();
}
