import 'package:alzheimer_assistant/shared/services/speech_recognition_service.dart';

/// Replaces the real STT (unavailable in CI without a microphone).
/// Uses a [_stopped] flag to avoid calling [onFinal] if
/// [stopListening] is called before completion (e.g. during bloc.close()).
class FakeSpeechRecognitionService implements SpeechRecognitionService {
  FakeSpeechRecognitionService({
    required this.transcript,
    this.interimDelay = const Duration(milliseconds: 50),
    this.finalDelay = const Duration(milliseconds: 50),
  });

  final String transcript;
  final Duration interimDelay;
  final Duration finalDelay;

  bool _stopped = false;

  @override
  Future<bool> initialize() async => true;

  @override
  Future<void> startListening({
    required void Function(String text) onInterim,
    required void Function(String text) onFinal,
  }) async {
    _stopped = false;

    await Future<void>.delayed(interimDelay);
    if (_stopped) return;
    onInterim(transcript);

    await Future<void>.delayed(finalDelay);
    if (_stopped) return;
    onFinal(transcript);
  }

  @override
  Future<void> stopListening() async {
    _stopped = true;
  }

  @override
  bool get isListening => !_stopped;
}
