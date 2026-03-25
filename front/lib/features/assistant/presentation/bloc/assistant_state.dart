import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:alzheimer_assistant/shared/services/phone_call_service.dart';

part 'assistant_state.freezed.dart';

@freezed
abstract class AssistantState with _$AssistantState {
  /// Idle — mic button available.
  const factory AssistantState.idle() = Idle;

  /// Listening — displays the interim transcript.
  const factory AssistantState.listening({
    @Default('') String interimTranscript,
    /// Pending candidates during a phone call disambiguation.
    @Default(null) List<PhoneCandidate>? pendingCandidates,
  }) = Listening;

  /// API call in progress — button disabled, spinner shown.
  const factory AssistantState.processing({required String userMessage}) =
      Processing;

  /// Audio playback in progress — displays the response.
  const factory AssistantState.speaking({
    required String responseText,
    /// Contact name to call after playback ends (null = no call).
    @Default(null) String? pendingCallName,
    /// True if the current audio is a disambiguation question.
    @Default(false) bool awaitingDisambiguation,
    /// Candidates to disambiguate (null when not in disambiguation).
    @Default(null) List<PhoneCandidate>? pendingCandidates,
  }) = Speaking;

  /// Error — displays a message and returns to Idle on next tap.
  const factory AssistantState.error({required String message}) = AssistantError;
}
