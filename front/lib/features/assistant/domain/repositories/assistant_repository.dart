import 'package:alzheimer_assistant/features/assistant/domain/entities/assistant_response.dart';

abstract interface class AssistantRepository {
  /// Sends the user's question and returns the text + audio response.
  Future<AssistantResponse> ask(String question);

  /// Synthesises [text] via ElevenLabs and returns the audio bytes.
  Future<List<int>> synthesize(String text);
}
