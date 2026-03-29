import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:alzheimer_assistant/core/utils/app_logger.dart';
import 'package:alzheimer_assistant/features/assistant/domain/entities/live_event.dart';
import 'package:alzheimer_assistant/features/assistant/domain/repositories/live_repository.dart';
import 'package:alzheimer_assistant/shared/services/microphone_stream_service.dart';
import 'package:alzheimer_assistant/shared/services/phone_call_service.dart';
import 'package:alzheimer_assistant/shared/services/settings_service.dart';
import 'package:alzheimer_assistant/shared/services/streaming_audio_player_service.dart';
import 'assistant_event.dart';
import 'assistant_state.dart';

class AssistantBloc extends Bloc<AssistantEvent, AssistantState> {
  AssistantBloc({
    required LiveRepository liveRepository,
    required MicrophoneStreamService micService,
    required StreamingAudioPlayerService audioPlayer,
    PhoneCallService? phoneCallService,
    SettingsService? settingsService,
    Duration responseTimeout = const Duration(seconds: 15),
    bool showTranscription = false,
  })  : _liveRepository = liveRepository,
        _micService = micService,
        _audioPlayer = audioPlayer,
        _phoneCallService = phoneCallService ?? PhoneCallService(),
        _settingsService = settingsService ?? SettingsService(),
        _responseTimeout = responseTimeout,
        _showTranscription = showTranscription,
        super(const AssistantState.idle()) {
    on<StartListening>(_onStartListening);
    on<LiveEventReceived>(_onLiveEventReceived);
    on<AudioPlaybackFinished>(_onAudioPlaybackFinished);
    on<ErrorOccurred>(_onErrorOccurred);
    on<AppResumed>(_onAppResumed);
  }

  final LiveRepository _liveRepository;
  final MicrophoneStreamService _micService;
  final StreamingAudioPlayerService _audioPlayer;
  final PhoneCallService _phoneCallService;
  final SettingsService _settingsService;
  final Duration _responseTimeout;
  final bool _showTranscription;
  final _logger = appLogger;

  StreamSubscription<LiveEvent>? _liveSubscription;
  StreamSubscription<Uint8List>? _micSubscription;
  Timer? _responseTimeoutTimer;

  /// Accumulated agent response text for the current Speaking state.
  String _responseText = '';

  /// Persistent welcome message received via session_info, shown when listening.
  String _welcomeText = '';

  // ── Event handlers ─────────────────────────────────────────────────────────

  Future<void> _onStartListening(
      StartListening event,
      Emitter<AssistantState> emit,
      ) async {
    if (state is AssistantError) {
      emit(const AssistantState.idle());
      return;
    }
    if (state is Speaking || state is Listening || state is Connecting) {
      await _disconnectAll();
      emit(const AssistantState.idle());
      return;
    }

    await _connect(emit);
  }

  Future<void> _onLiveEventReceived(
      LiveEventReceived event,
      Emitter<AssistantState> emit,
      ) async {
    switch (event.event) {
      case LiveAudioChunk(:final bytes):
      // Push to PCM buffer immediately
        _audioPlayer.addChunk(bytes);

        if (state is! Speaking) {
          // Clear welcome text so it doesn't reappear between conversation turns
          _welcomeText = '';
          emit(AssistantState.speaking(responseText: _responseText));
          // Start the PCM engine on first chunk
          _audioPlayer.playAndClear(onComplete: () {});
        }

      case LiveTextDelta():
      // Text deltas are ignored — output_transcription is used for display.
        break;

      case LiveCallPhone(:final callId, :final contactName, :final exactMatch):
        await _handleCallPhone(
          callId: callId,
          contactName: contactName,
          exactMatch: exactMatch,
          emit: emit,
        );

      case LiveTurnComplete():
        await _handleTurnComplete(emit);

      case LiveInputTranscription(:final text):
        if (_showTranscription) {
          emit(AssistantState.listening(interimTranscript: text));
        }

      case LiveOutputTranscription(:final text):
        if (_showTranscription) {
          _responseText += text;
          emit(AssistantState.speaking(responseText: _responseText));
        }

      case LiveToolStatus(:final label):
        if (state case Listening(:final interimTranscript)) {
          emit(AssistantState.listening(
            interimTranscript: interimTranscript,
            statusLabel: label,
            welcomeText: _welcomeText,
          ));
        }

      case LiveSessionInfo(:final welcome):
        _welcomeText = welcome;
        if (state case Listening(:final interimTranscript, :final statusLabel)) {
          emit(AssistantState.listening(
            interimTranscript: interimTranscript,
            statusLabel: statusLabel,
            welcomeText: _welcomeText,
          ));
        }
    }
  }

  void _onAudioPlaybackFinished(
      AudioPlaybackFinished event,
      Emitter<AssistantState> emit,
      ) {
    if (state is Speaking) {
      emit(AssistantState.listening(welcomeText: _welcomeText));
    }
  }

  void _onErrorOccurred(ErrorOccurred event, Emitter<AssistantState> emit) {
    emit(AssistantState.error(message: event.message));
  }

  Future<void> _onAppResumed(
      AppResumed event,
      Emitter<AssistantState> emit,
      ) async {
    // Always stop and re-init the audio player so the iOS audio session is
    // restored after a phone call interruption (playAndRecord + defaultToSpeaker).
    await _audioPlayer.stop();
    if (state is! Speaking) return;
    await _disconnectAll();
    emit(const AssistantState.idle());
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<void> _connect(Emitter<AssistantState> emit) async {
    emit(const AssistantState.connecting());
    _responseText = '';
    _welcomeText = '';

    try {
      final useElevenLabs = await _settingsService.getUseElevenLabs();
      _liveSubscription = _liveRepository.connect(useElevenLabs: useElevenLabs).listen(
            (e) {
          _cancelResponseTimeout();
          add(AssistantEvent.liveEventReceived(e));
        },
        onError: (Object e) {
          _cancelResponseTimeout();
          _logger.e('[Bloc] Live stream error: $e');
          add(const AssistantEvent.errorOccurred('Connexion perdue.'));
        },
        onDone: () {
          _cancelResponseTimeout();
          if (state is! Idle && state is! AssistantError) {
            _logger.i('[Bloc] WebSocket closed by server');
            add(const AssistantEvent.errorOccurred('Session terminée.'));
          }
        },
      );

      final micStream = await _micService.startStreaming();

      const targetSize = 3200;
      final buffer = Uint8List(targetSize);
      int offset = 0;

      _micSubscription = micStream.listen(
            (chunk) {
          int chunkOffset = 0;
          while (chunkOffset < chunk.length) {
            final remaining = targetSize - offset;
            final toCopy = (chunk.length - chunkOffset).clamp(0, remaining);
            buffer.setRange(offset, offset + toCopy, chunk, chunkOffset);
            offset += toCopy;
            chunkOffset += toCopy;

            if (offset == targetSize) {
              final rms = _calculateRMS(buffer);

              if (state is Speaking && rms > 3500) {
                _logger.i('[Bloc] Interruption detected (RMS: ${rms.toStringAsFixed(0)})');
                _handleInterruption();
              }

              _applyGain(buffer, 2.0);
              _liveRepository.sendAudio(Uint8List.fromList(buffer));
              offset = 0;
            }
          }
        },
        onError: (Object e) => _logger.e('[Bloc] Mic stream error: $e'),
      );

      emit(AssistantState.listening(welcomeText: _welcomeText));
      _startResponseTimeout();
    } catch (e) {
      _logger.e('[Bloc] Connection error: $e');
      await _disconnectAll();
      emit(AssistantState.error(message: 'Impossible de se connecter.'));
    }
  }

  double _calculateRMS(Uint8List bytes) {
    final samples = Int16List.view(bytes.buffer, bytes.offsetInBytes, bytes.length ~/ 2);
    if (samples.isEmpty) return 0.0;
    double sum = 0;
    for (final sample in samples) {
      sum += (sample.toDouble() * sample.toDouble());
    }
    return math.sqrt(sum / samples.length);
  }

  Future<void> _handleInterruption() async {
    await _audioPlayer.stop();
    _liveRepository.sendInterruption();
    _responseText = '';
  }

  void _applyGain(Uint8List bytes, double factor) {
    final samples = Int16List.view(bytes.buffer, bytes.offsetInBytes, bytes.length ~/ 2);
    for (var i = 0; i < samples.length; i++) {
      samples[i] = (samples[i] * factor).round().clamp(-32768, 32767);
    }
  }

  Future<void> _handleTurnComplete(Emitter<AssistantState> emit) async {
    if (state is Speaking) {
      emit(AssistantState.listening(welcomeText: _welcomeText));
    }
  }

  Future<void> _handleCallPhone({
    required String callId,
    required String contactName,
    required bool exactMatch,
    required Emitter<AssistantState> emit,
  }) async {
    final result = await _phoneCallService.callByName(contactName, exactMatch: exactMatch);
    final resultMessage = switch (result) {
      PhoneCallSuccess() => '$contactName appelé.',
      PhoneCallError(:final message) => message,
      PhoneCallAmbiguous(:final candidates) =>
      'Plusieurs contacts correspondent à "$contactName" : ${_formatNames(candidates.map((c) => c.displayName).toList())}.',
    };
    _liveRepository.sendToolResponse(callId: callId, functionName: 'call_phone', result: resultMessage);
  }

  void _startResponseTimeout() {
    _responseTimeoutTimer = Timer(_responseTimeout, () {
      if (state is Listening || state is Connecting) {
        add(const AssistantEvent.errorOccurred('Le serveur ne répond pas.'));
      }
    });
  }

  void _cancelResponseTimeout() {
    _responseTimeoutTimer?.cancel();
    _responseTimeoutTimer = null;
  }

  Future<void> _disconnectAll() async {
    _cancelResponseTimeout();
    await _micSubscription?.cancel();
    _micSubscription = null;
    await _micService.stop();
    await _liveSubscription?.cancel();
    _liveSubscription = null;
    await _liveRepository.disconnect();
  }

  String _formatNames(List<String> names) {
    if (names.isEmpty) return '';
    if (names.length == 1) return names.first;
    return '${names.sublist(0, names.length - 1).join(', ')} et ${names.last}';
  }

  @override
  Future<void> close() async {
    await _disconnectAll();
    await _audioPlayer.stop();
    await _audioPlayer.dispose();
    return super.close();
  }
}
