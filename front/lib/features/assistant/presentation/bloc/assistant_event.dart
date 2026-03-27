import 'package:freezed_annotation/freezed_annotation.dart';

part 'assistant_event.freezed.dart';

@freezed
abstract class AssistantEvent with _$AssistantEvent {
  /// The user taps the mic button.
  const factory AssistantEvent.startListening() = StartListening;

  /// Intermediate result from speech recognition.
  const factory AssistantEvent.interimTranscript(String text) = InterimTranscript;

  /// Final transcription — triggers the API call.
  const factory AssistantEvent.sendMessage(String text) = SendMessage;

  /// The API response is ready — triggers audio playback.
  const factory AssistantEvent.speakResponse({
    required String text,
    required List<int> audioBytes,
  }) = SpeakResponse;

  /// Audio playback has ended — returns to Idle.
  const factory AssistantEvent.audioFinished() = AudioFinished;

  /// An error occurred.
  const factory AssistantEvent.errorOccurred(String message) = ErrorOccurred;

  /// The app has returned to the foreground (Android lifecycle).
  const factory AssistantEvent.appResumed() = AppResumed;
}
