import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:alzheimer_assistant/shared/services/phone_call_service.dart';

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
    /// Contact name to call after playback ends (null = no call).
    @Default(null) String? callPhoneName,
    /// True if this audio is a phone call disambiguation question.
    @Default(false) bool awaitingDisambiguation,
    /// Candidates to disambiguate (null when not in disambiguation).
    @Default(null) List<PhoneCandidate>? pendingCandidates,
  }) = SpeakResponse;

  /// Audio playback has ended — returns to Idle.
  const factory AssistantEvent.audioFinished() = AudioFinished;

  /// An error occurred.
  const factory AssistantEvent.errorOccurred(String message) = ErrorOccurred;

  /// The user has responded to disambiguate a call.
  const factory AssistantEvent.disambiguateCall(String spokenText) = DisambiguateCall;
}
