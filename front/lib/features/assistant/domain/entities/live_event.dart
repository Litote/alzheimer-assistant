import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'live_event.freezed.dart';

/// Downstream events received from the ADK Live WebSocket stream.
///
/// Protocol reference: Google GenAI Live API format.
/// Each case maps to a distinct server_content / tool_call message type.
@freezed
sealed class LiveEvent with _$LiveEvent {
  /// A chunk of raw PCM audio (24 kHz, 16-bit, mono) from the agent.
  const factory LiveEvent.audioChunk(Uint8List bytes) = LiveAudioChunk;

  /// An incremental text fragment from the agent's response.
  const factory LiveEvent.textDelta(String text) = LiveTextDelta;

  /// The agent wants to call a contact.
  /// [callId] must be echoed back in the tool response.
  const factory LiveEvent.callPhone({
    required String callId,
    required String contactName,
    required bool exactMatch,
  }) = LiveCallPhone;

  /// The agent has finished its current turn — audio + text are complete.
  const factory LiveEvent.turnComplete() = LiveTurnComplete;

  /// Server-side transcription of what the user said.
  const factory LiveEvent.inputTranscription(String text) = LiveInputTranscription;

  /// Server-side transcription of what the model said (TTS output).
  const factory LiveEvent.outputTranscription(String text) = LiveOutputTranscription;

  /// A status update from the server indicating which sub-agent is currently active.
  /// [label] is the human-readable name displayed to the user (e.g. "Maison & Cuisine").
  const factory LiveEvent.toolStatus(String label) = LiveToolStatus;

  /// Session-level information sent once after connection setup.
  /// [welcome] is a multi-line capabilities summary shown to the user.
  const factory LiveEvent.sessionInfo(String welcome) = LiveSessionInfo;

  /// Session identifier returned by the server on first connection.
  /// Must be forwarded in subsequent connections to resume the same session.
  const factory LiveEvent.sessionEstablished(String sessionId) =
      LiveSessionEstablished;

  /// A URL pointing to an image the agent wants to display to the user.
  const factory LiveEvent.imageUrl(String url) = LiveImageUrl;
}
