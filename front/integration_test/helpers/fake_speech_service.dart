import 'package:alzheimer_assistant/shared/services/speech_recognition_service.dart';

/// Replaces the real STT for multi-turn scenarios (e.g. disambiguation).
/// Each call to [startListening] returns the next transcript in [transcripts].
/// When the list is exhausted, the last transcript is repeated.
class SequentialFakeSpeechRecognitionService implements SpeechRecognitionService {
  SequentialFakeSpeechRecognitionService({
    required this.transcripts,
    this.interimDelay = const Duration(milliseconds: 50),
    this.finalDelay = const Duration(milliseconds: 50),
  }) : assert(transcripts.isNotEmpty);

  final List<String> transcripts;
  final Duration interimDelay;
  final Duration finalDelay;

  int _callCount = 0;
  bool _stopped = false;

  @override
  Future<bool> initialize() async => true;

  @override
  Future<void> startListening({
    required void Function(String text) onInterim,
    required void Function(String text) onFinal,
    void Function()? onTimeout,
  }) async {
    _stopped = false;
    final transcript = _callCount < transcripts.length
        ? transcripts[_callCount]
        : transcripts.last;
    _callCount++;

    await Future<void>.delayed(interimDelay);
    if (_stopped) return;
    onInterim(transcript);

    await Future<void>.delayed(finalDelay);
    if (_stopped) return;
    onFinal(transcript);
  }

  @override
  Future<void> stopListening() async => _stopped = true;

  @override
  bool get isListening => !_stopped;
}

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
    void Function()? onTimeout,
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
