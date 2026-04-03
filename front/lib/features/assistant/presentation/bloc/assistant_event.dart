import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:alzheimer_assistant/features/assistant/domain/entities/live_event.dart';

part 'assistant_event.freezed.dart';

@freezed
abstract class AssistantEvent with _$AssistantEvent {
  // ── User-initiated ─────────────────────────────────────────────────────────

  /// The user taps the mic button.
  /// - Idle       → connect + stream mic audio
  /// - Listening/Connecting → stop and return to Idle
  /// - Speaking   → interrupt agent, return to Idle
  /// - Error      → reset to Idle
  const factory AssistantEvent.startListening() = StartListening;

  /// An error occurred (network, permissions, etc.).
  const factory AssistantEvent.errorOccurred(String message) = ErrorOccurred;

  /// The app has returned to the foreground (Android lifecycle fix).
  const factory AssistantEvent.appResumed() = AppResumed;

  // ── Internal — dispatched by the BLoC itself ───────────────────────────────

  /// A downstream event arrived from the ADK Live WebSocket stream.
  const factory AssistantEvent.liveEventReceived(LiveEvent event) =
      LiveEventReceived;

  /// Buffered agent audio finished playing — transition back to Idle.
  const factory AssistantEvent.audioPlaybackFinished() = AudioPlaybackFinished;

  /// Device STT returned a final transcription (text mode only).
  /// Dispatched internally by the BLoC after [SpeechRecognitionService.onFinal].
  const factory AssistantEvent.speechRecognized(String text) = SpeechRecognized;
}
