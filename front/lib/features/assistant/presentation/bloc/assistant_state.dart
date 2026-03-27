import 'package:freezed_annotation/freezed_annotation.dart';

part 'assistant_state.freezed.dart';

@freezed
abstract class AssistantState with _$AssistantState {
  /// Idle — mic button available.
  const factory AssistantState.idle() = Idle;

  /// Listening — displays the interim transcript.
  const factory AssistantState.listening({
    @Default('') String interimTranscript,
  }) = Listening;

  /// API call in progress — button disabled, spinner shown.
  const factory AssistantState.processing({required String userMessage}) =
      Processing;

  /// Audio playback in progress — displays the response.
  const factory AssistantState.speaking({
    required String responseText,
  }) = Speaking;

  /// Error — displays a message and returns to Idle on next tap.
  const factory AssistantState.error({required String message}) = AssistantError;
}
