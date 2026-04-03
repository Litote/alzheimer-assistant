import 'package:freezed_annotation/freezed_annotation.dart';

part 'assistant_state.freezed.dart';

@freezed
sealed class AssistantState with _$AssistantState {
  /// Idle — mic button available, no active connection.
  const factory AssistantState.idle() = Idle;

  /// WebSocket handshake in progress — button disabled.
  const factory AssistantState.connecting() = Connecting;

  /// Connected and streaming mic audio — waiting for the agent to respond.
  const factory AssistantState.listening({
    @Default('') String interimTranscript,
    @Default('') String statusLabel,
    @Default('') String welcomeText,
  }) = Listening;

  /// Agent is responding — audio buffer is filling, text is streaming in.
  const factory AssistantState.speaking({
    @Default('') String responseText,
  }) = Speaking;

  /// Error — displays a message and returns to Idle on next tap.
  const factory AssistantState.error({required String message}) = AssistantError;
}
