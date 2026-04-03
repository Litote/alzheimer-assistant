import 'dart:typed_data';

import 'package:alzheimer_assistant/features/assistant/domain/entities/live_event.dart';

/// Contract for the ADK Live bidi-streaming transport.
///
/// One [connect] call opens a WebSocket session. The returned stream
/// emits [LiveEvent]s until the agent's turn is complete or an error
/// occurs. Callers must [disconnect] to release the underlying channel.
abstract interface class LiveRepository {
  /// Opens a WebSocket connection to the ADK Live endpoint and returns a
  /// stream of downstream events.
  ///
  /// [useElevenLabs] is forwarded to the server in the setup message.
  /// Throws if the connection cannot be established.
  Stream<LiveEvent> connect({bool useElevenLabs = false});

  /// Sends a raw PCM 16 kHz 16-bit mono audio chunk upstream.
  void sendAudio(Uint8List pcmBytes);

  /// Sends a text message upstream (e.g. phone-call result relay).
  void sendText(String text);

  /// Sends an interruption signal to the agent.
  void sendInterruption();

  /// Sends a tool response back to the agent after executing a tool call.
  void sendToolResponse({
    required String callId,
    required String functionName,
    required String result,
  });

  /// Closes the WebSocket channel.
  Future<void> disconnect();
}
