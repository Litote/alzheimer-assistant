import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:alzheimer_assistant/features/assistant/domain/repositories/assistant_repository.dart';
import 'package:alzheimer_assistant/shared/services/phone_call_service.dart';
import 'package:alzheimer_assistant/shared/services/speech_recognition_service.dart';
import 'package:alzheimer_assistant/shared/services/tts_service.dart';
import 'assistant_event.dart';
import 'assistant_state.dart';

class AssistantBloc extends Bloc<AssistantEvent, AssistantState> {
  AssistantBloc({
    required AssistantRepository repository,
    required SpeechRecognitionService speechService,
    required TtsService ttsService,
    PhoneCallService? phoneCallService,
  })  : _repository = repository,
        _speechService = speechService,
        _ttsService = ttsService,
        _phoneCallService = phoneCallService ?? PhoneCallService(),
        super(const AssistantState.idle()) {
    on<StartListening>(_onStartListening);
    on<InterimTranscript>(_onInterimTranscript);
    on<SendMessage>(_onSendMessage);
    on<SpeakResponse>(_onSpeakResponse);
    on<AudioFinished>(_onAudioFinished);
    on<ErrorOccurred>(_onErrorOccurred);
    on<DisambiguateCall>(_onDisambiguateCall);
  }

  final AssistantRepository _repository;
  final SpeechRecognitionService _speechService;
  final TtsService _ttsService;
  final PhoneCallService _phoneCallService;

  Future<void> _onStartListening(
    StartListening event,
    Emitter<AssistantState> emit,
  ) async {
    // If in error state, reset to idle on first tap
    if (state is AssistantError) {
      emit(const AssistantState.idle());
      return;
    }

    emit(const AssistantState.listening());

    await _speechService.startListening(
      onInterim: (text) => add(AssistantEvent.interimTranscript(text)),
      onFinal: (text) {
        if (text.isNotEmpty) {
          add(AssistantEvent.sendMessage(text));
        } else {
          add(const AssistantEvent.errorOccurred("Je n'ai rien entendu, réessayez."));
        }
      },
    );
  }

  void _onInterimTranscript(
    InterimTranscript event,
    Emitter<AssistantState> emit,
  ) {
    emit(AssistantState.listening(interimTranscript: event.text));
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<AssistantState> emit,
  ) async {
    emit(AssistantState.processing(userMessage: event.text));

    try {
      final response = await _repository.ask(event.text);
      add(AssistantEvent.speakResponse(
        text: response.text,
        audioBytes: response.audioBytes,
        callPhoneName: response.callPhoneName,
      ));
    } catch (e) {
      add(const AssistantEvent.errorOccurred('Désolé, une erreur est survenue.'));
    }
  }

  Future<void> _onSpeakResponse(
    SpeakResponse event,
    Emitter<AssistantState> emit,
  ) async {
    emit(AssistantState.speaking(
      responseText: event.text,
      pendingCallName: event.callPhoneName,
      awaitingDisambiguation: event.awaitingDisambiguation,
      pendingCandidates: event.pendingCandidates,
    ));

    await _ttsService.play(
      event.audioBytes,
      onComplete: () => add(const AssistantEvent.audioFinished()),
    );
  }

  Future<void> _onAudioFinished(
    AudioFinished event,
    Emitter<AssistantState> emit,
  ) async {
    final currentState = state;
    if (currentState is! Speaking) return;

    // After the disambiguation question → listen for the user's answer
    if (currentState.awaitingDisambiguation) {
      final candidates = currentState.pendingCandidates;
      emit(AssistantState.listening(pendingCandidates: candidates));
      await _speechService.startListening(
        onInterim: (text) => add(AssistantEvent.interimTranscript(text)),
        onFinal: (text) {
          if (text.isNotEmpty) {
            add(AssistantEvent.disambiguateCall(text));
          } else {
            add(const AssistantEvent.errorOccurred("Je n'ai rien entendu, réessayez."));
          }
        },
      );
      return;
    }

    final callName = currentState.pendingCallName;
    emit(const AssistantState.idle());

    if (callName == null) return;

    final result = await _phoneCallService.callByName(callName);
    await _handlePhoneCallResult(result, displayName: callName);
  }

  Future<void> _onDisambiguateCall(
    DisambiguateCall event,
    Emitter<AssistantState> emit,
  ) async {
    final currentState = state;
    final candidates = currentState is Listening ? currentState.pendingCandidates : null;

    if (candidates == null) return;

    final spokenLower = event.spokenText.toLowerCase();
    final match = candidates.firstWhere(
      (c) => c.displayName
          .toLowerCase()
          .split(' ')
          .any((part) => part.length > 2 && spokenLower.contains(part)),
      orElse: () => (displayName: '', number: ''),
    );

    if (match.number.isEmpty) {
      const msg = "Je n'ai pas compris. Voulez-vous réessayer ?";
      await _synthesizeAndSpeak(msg);
      return;
    }

    emit(const AssistantState.idle());
    final result = await _phoneCallService.callByNumber(
      match.number,
      displayName: match.displayName,
    );
    await _handlePhoneCallResult(result, displayName: match.displayName);
  }

  Future<void> _handlePhoneCallResult(
    PhoneCallResult result, {
    String? displayName,
  }) async {
    switch (result) {
      case PhoneCallSuccess():
        final name = displayName ?? 'votre contact';
        await _synthesizeAndSpeak("J'appelle $name. Bonne conversation !");
      case PhoneCallError(:final message):
        await _synthesizeAndSpeak(message);
      case PhoneCallAmbiguous(:final candidates):
        final names = _formatNames(candidates.map((c) => c.displayName).toList());
        final msg = "J'ai trouvé plusieurs contacts : $names. Lequel voulez-vous appeler ?";
        await _synthesizeAndSpeak(
          msg,
          awaitingDisambiguation: true,
          pendingCandidates: candidates,
        );
    }
  }

  /// Synthesises [msg] and emits a [SpeakResponse]. On network error,
  /// emits [ErrorOccurred] directly with the message text.
  Future<void> _synthesizeAndSpeak(
    String msg, {
    bool awaitingDisambiguation = false,
    List<PhoneCandidate>? pendingCandidates,
  }) async {
    try {
      final audioBytes = await _repository.synthesize(msg);
      add(AssistantEvent.speakResponse(
        text: msg,
        audioBytes: audioBytes,
        awaitingDisambiguation: awaitingDisambiguation,
        pendingCandidates: pendingCandidates,
      ));
    } catch (_) {
      add(AssistantEvent.errorOccurred(msg));
    }
  }

  String _formatNames(List<String> names) {
    if (names.length == 1) return names.first;
    return '${names.sublist(0, names.length - 1).join(', ')} et ${names.last}';
  }

  void _onErrorOccurred(
    ErrorOccurred event,
    Emitter<AssistantState> emit,
  ) {
    emit(AssistantState.error(message: event.message));
  }

  @override
  Future<void> close() async {
    await _speechService.stopListening();
    await _ttsService.stop();
    await _ttsService.dispose();
    return super.close();
  }
}
