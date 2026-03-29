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
    on<AppResumed>(_onAppResumed);
  }

  final AssistantRepository _repository;
  final SpeechRecognitionService _speechService;
  final TtsService _ttsService;
  final PhoneCallService _phoneCallService;

  Future<void> _onStartListening(
    StartListening event,
    Emitter<AssistantState> emit,
  ) async {
    if (state is AssistantError) {
      emit(const AssistantState.idle());
      return;
    }
    if (state is Speaking) {
      await _ttsService.stop();
      emit(const AssistantState.idle());
      return;
    }
    if (state is Listening) {
      await _speechService.stopListening();
      emit(const AssistantState.idle());
      return;
    }

    await _startListening(emit);
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

      if (response.callPhoneName != null) {
        // The agent wants to call a contact — resolve and initiate the call.
        // On success, return to Idle immediately: playing TTS while the phone
        // is dialling would be disruptive and confusing for the user.
        // Only errors and ambiguity require a follow-up message to the agent.
        final result = await _phoneCallService.callByName(
          response.callPhoneName!,
          exactMatch: response.callPhoneExactMatch,
        );
        if (result is PhoneCallSuccess) {
          emit(const AssistantState.idle());
          return;
        }
        add(AssistantEvent.sendMessage(
          _phoneResultMessage(result, response.callPhoneName!),
        ));
      } else {
        add(AssistantEvent.speakResponse(
          text: response.text,
          audioBytes: response.audioBytes,
        ));
      }
    } catch (e) {
      add(const AssistantEvent.errorOccurred('Désolé, une erreur est survenue.'));
    }
  }

  Future<void> _onSpeakResponse(
    SpeakResponse event,
    Emitter<AssistantState> emit,
  ) async {
    emit(AssistantState.speaking(responseText: event.text));

    await _ttsService.play(
      event.audioBytes,
      onComplete: () => add(const AssistantEvent.audioFinished()),
    );
  }

  Future<void> _onAudioFinished(
    AudioFinished event,
    Emitter<AssistantState> emit,
  ) async {
    if (state is! Speaking) return;
    emit(const AssistantState.idle());
  }

  void _onErrorOccurred(
    ErrorOccurred event,
    Emitter<AssistantState> emit,
  ) {
    emit(AssistantState.error(message: event.message));
  }

  /// Resets to Idle when the app returns to the foreground while audio is
  /// playing. On Android, the dialer backgrounds the app and interrupts
  /// [AudioPlayer], which never fires onPlayerComplete, leaving the bloc
  /// stuck in [Speaking].
  Future<void> _onAppResumed(
    AppResumed event,
    Emitter<AssistantState> emit,
  ) async {
    if (state is! Speaking) return;
    await _ttsService.stop();
    emit(const AssistantState.idle());
  }

  Future<void> _startListening(Emitter<AssistantState> emit) async {
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
      onTimeout: () => add(const AssistantEvent.startListening()),
    );
  }

  /// Formats the phone call result as a [phone] system message to be
  /// sent back to the agent so it can respond naturally to the outcome.
  String _phoneResultMessage(PhoneCallResult result, String requestedName) =>
      switch (result) {
        PhoneCallSuccess() => '[phone] $requestedName appelé.',
        PhoneCallError(:final message) => '[phone] $message',
        PhoneCallAmbiguous(:final candidates) =>
          '[phone] plusieurs contacts correspondent à "$requestedName" : '
          '${_formatNames(candidates.map((c) => c.displayName).toList())}.',
      };

  String _formatNames(List<String> names) {
    if (names.length == 1) return names.first;
    return '${names.sublist(0, names.length - 1).join(', ')} et ${names.last}';
  }

  @override
  Future<void> close() async {
    await _speechService.stopListening();
    await _ttsService.stop();
    await _ttsService.dispose();
    return super.close();
  }
}
