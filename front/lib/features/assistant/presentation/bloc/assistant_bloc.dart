import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:alzheimer_assistant/core/utils/app_logger.dart';
import 'package:alzheimer_assistant/features/assistant/domain/entities/live_event.dart';
import 'package:alzheimer_assistant/features/assistant/domain/repositories/audio_repository.dart';
import 'package:alzheimer_assistant/features/assistant/domain/repositories/conversation_repository.dart';
import 'package:alzheimer_assistant/features/assistant/domain/repositories/text_repository.dart';
import 'package:alzheimer_assistant/shared/services/client_tts_service.dart';
import 'package:alzheimer_assistant/shared/services/microphone_stream_service.dart';
import 'package:alzheimer_assistant/shared/services/pcm_streaming_audio_player_service.dart';
import 'package:alzheimer_assistant/shared/services/phone_call_service.dart';
import 'package:alzheimer_assistant/shared/services/settings_service.dart';
import 'package:alzheimer_assistant/shared/services/speech_recognition_service.dart';
import 'package:alzheimer_assistant/shared/services/streaming_audio_player_service.dart';
import 'assistant_event.dart';
import 'assistant_state.dart';

class AssistantBloc extends Bloc<AssistantEvent, AssistantState> {
  AssistantBloc({
    required TextRepository textRepository,
    AudioRepository? audioRepository,
    required MicrophoneStreamService micService,
    StreamingAudioPlayerService? audioPlayer,
    PhoneCallService? phoneCallService,
    SettingsService? settingsService,
    SpeechRecognitionService? speechService,
    ClientTtsService? elevenLabsTtsService,
    ClientTtsService? nativeTtsService,
    Duration responseTimeout = const Duration(seconds: 15),
    bool showTranscription = false,
  })  : _textRepository = textRepository,
        _audioRepository = audioRepository,
        _micService = micService,
        _audioPlayer = audioPlayer,
        _phoneCallService = phoneCallService ?? PhoneCallService(),
        _settingsService = settingsService ?? SettingsService(),
        _speechService = speechService ?? SpeechRecognitionService(),
        _elevenLabsTtsService = elevenLabsTtsService,
        _nativeTtsService = nativeTtsService,
        _responseTimeout = responseTimeout,
        _showTranscription = showTranscription,
        super(const AssistantState.idle()) {
    on<StartListening>(_onStartListening);
    on<LiveEventReceived>(_onLiveEventReceived);
    on<AudioPlaybackFinished>(_onAudioPlaybackFinished);
    on<ErrorOccurred>(_onErrorOccurred);
    on<AppResumed>(_onAppResumed);
    on<SpeechRecognized>(_onSpeechRecognized);
  }

  final TextRepository _textRepository;
  final AudioRepository? _audioRepository;
  final MicrophoneStreamService _micService;
  // Nullable: lazily created (PcmStreamingAudioPlayerService) on first audio
  // mode connect, to avoid touching the iOS audio session in text mode.
  StreamingAudioPlayerService? _audioPlayer;
  final PhoneCallService _phoneCallService;
  final SettingsService _settingsService;
  final SpeechRecognitionService _speechService;
  final ClientTtsService? _elevenLabsTtsService;
  final ClientTtsService? _nativeTtsService;
  final Duration _responseTimeout;
  final bool _showTranscription;
  final _logger = appLogger;

  StreamSubscription<LiveEvent>? _liveSubscription;
  StreamSubscription<Uint8List>? _micSubscription;
  Timer? _responseTimeoutTimer;

  /// Accumulated agent response text for the current Speaking state.
  String _responseText = '';

  /// Text transcribed from the user's last utterance.
  String _userTranscript = '';

  /// Persistent welcome message shown when listening.
  String _welcomeText = '';

  /// Session identifier persisted across turns (text mode only).
  String? _sessionId;

  /// Whether text mode was active when the current connection was opened.
  bool _textMode = false;

  /// Whether ElevenLabs TTS was enabled when the current connection was opened.
  bool _useElevenLabs = false;

  /// True once TTS has been started for the current turn.
  bool _ttsStarted = false;

  // ── Active repository accessor ────────────────────────────────────────────

  /// Returns the repository for the current (or upcoming) mode.
  /// Falls back to [_textRepository] if [_audioRepository] is null.
  ConversationRepository get _activeRepo =>
      _textMode ? _textRepository : (_audioRepository ?? _textRepository);

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

    _textMode = await _settingsService.getUseTextMode();
    if (_textMode) {
      await _connectTextMode(emit);
    } else {
      await _connect(emit);
    }
  }

  Future<void> _onSpeechRecognized(
    SpeechRecognized event,
    Emitter<AssistantState> emit,
  ) async {
    if (event.text.isEmpty) {
      await _disconnectAll();
      emit(const AssistantState.idle());
      return;
    }
    await _speechService.stopListening();
    _textRepository.sendText(event.text);
    _userTranscript = event.text;
    _responseText = '';
    emit(AssistantState.speaking(userTranscript: _userTranscript));
    _startResponseTimeout();
  }

  Future<void> _onLiveEventReceived(
    LiveEventReceived event,
    Emitter<AssistantState> emit,
  ) async {
    switch (event.event) {
      case LiveAudioChunk(:final bytes):
        // Audio chunks are only relevant in audio-to-audio mode.
        if (_textMode) {
          _logger.w('[Bloc] LiveAudioChunk received but _textMode=true — dropped');
          break;
        }
        _logger.i('[Bloc] LiveAudioChunk: ${bytes.length} bytes, state=${state.runtimeType}, player=${_audioPlayer.runtimeType}');
        _audioPlayer!.addChunk(bytes);
        if (state is! Speaking) {
          _welcomeText = '';
          _logger.i('[Bloc] → first chunk: emitting Speaking + calling playAndClear');
          emit(AssistantState.speaking(responseText: _responseText));
          _audioPlayer!.playAndClear(onComplete: () {
            _logger.i('[Bloc] playAndClear onComplete fired');
          });
        }

      case LiveTextDelta():
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

      case LiveSessionEstablished(:final sessionId):
        _sessionId = sessionId;
        _logger.i('[Bloc] Session established: $sessionId');

      case LiveInputTranscription(:final text):
        if (_showTranscription || _textMode) {
          emit(AssistantState.listening(interimTranscript: text));
        }

      case LiveOutputTranscription(:final text):
        if (_showTranscription || _textMode) {
          if (text == _responseText) {
            // Final echo — start TTS immediately in text mode.
            if (_textMode && !_ttsStarted && text.isNotEmpty) {
              _ttsStarted = true;
              final tts = _useElevenLabs ? _elevenLabsTtsService : _nativeTtsService;
              if (tts != null) {
                _responseText = '';
                await tts.speak(
                  text,
                  onComplete: () => add(const AssistantEvent.audioPlaybackFinished()),
                );
              }
            }
            break;
          }
          _responseText += text;
          // When an image is displayed, accumulate text for TTS but keep the
          // image visible — skip the text state update.
          final current = state;
          if (current is Speaking && current.imageUrl.isNotEmpty) break;
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

      case LiveImageUrl(:final url):
        _logger.i('[Bloc] LiveImageUrl: $url');
        final current = state;
        if (current is Speaking) {
          emit(current.copyWith(imageUrl: url));
        } else {
          emit(AssistantState.speaking(imageUrl: url));
        }
    }
  }

  Future<void> _onAudioPlaybackFinished(
    AudioPlaybackFinished event,
    Emitter<AssistantState> emit,
  ) async {
    if (state case Speaking(:final imageUrl)) {
      if (_textMode) {
        await _disconnectAll();
        emit(AssistantState.idle(imageUrl: imageUrl));
      } else {
        emit(AssistantState.listening(welcomeText: _welcomeText));
      }
    }
  }

  void _onErrorOccurred(ErrorOccurred event, Emitter<AssistantState> emit) {
    emit(AssistantState.error(message: event.message));
  }

  Future<void> _onAppResumed(
    AppResumed event,
    Emitter<AssistantState> emit,
  ) async {
    await _audioPlayer?.stop();
    if (state is! Speaking) return;
    await _disconnectAll();
    emit(const AssistantState.idle());
  }

  // ── Connection helpers ─────────────────────────────────────────────────────

  Future<void> _connect(Emitter<AssistantState> emit) async {
    emit(const AssistantState.connecting());
    _responseText = '';
    _userTranscript = '';
    _welcomeText = '';

    try {
      _useElevenLabs = await _settingsService.getUseElevenLabs();

      // Lazily initialize the PCM player on first audio-mode connect to avoid
      // modifying the iOS audio session when running in text mode.
      _audioPlayer ??= PcmStreamingAudioPlayerService();

      final audioRepo = _audioRepository!;
      _liveSubscription = audioRepo.connect(useElevenLabs: _useElevenLabs).listen(
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
              audioRepo.sendAudio(Uint8List.fromList(buffer));
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

  Future<void> _connectTextMode(Emitter<AssistantState> emit) async {
    emit(const AssistantState.connecting());
    _responseText = '';
    _userTranscript = '';
    _ttsStarted = false;

    try {
      _useElevenLabs = await _settingsService.getUseElevenLabs();
      _liveSubscription = _textRepository
          .connect(
            useElevenLabs: _useElevenLabs,
            sessionId: _sessionId,
          )
          .listen(
        (e) {
          _cancelResponseTimeout();
          add(AssistantEvent.liveEventReceived(e));
        },
        onError: (Object e) {
          _cancelResponseTimeout();
          _logger.e('[Bloc] Live stream error (text mode): $e');
          add(const AssistantEvent.errorOccurred('Connexion perdue.'));
        },
        onDone: () {
          _cancelResponseTimeout();
          if (state is! Idle && state is! AssistantError) {
            _logger.i('[Bloc] Connection closed by server (text mode)');
            add(const AssistantEvent.errorOccurred('Session terminée.'));
          }
        },
      );

      emit(const AssistantState.listening());
      _startResponseTimeout();

      await _speechService.startListening(
        onInterim: (text) {
          if (state case Listening()) {
            add(AssistantEvent.liveEventReceived(
              LiveEvent.inputTranscription(text),
            ));
          }
        },
        onFinal: (text) => add(AssistantEvent.speechRecognized(text)),
        onTimeout: () {
          if (state is Listening) {
            add(const AssistantEvent.startListening());
          }
        },
      );
    } catch (e) {
      _logger.e('[Bloc] Text mode connection error: $e');
      await _disconnectAll();
      emit(AssistantState.error(message: 'Impossible de se connecter.'));
    }
  }

  // ── Turn / call helpers ────────────────────────────────────────────────────

  double _calculateRMS(Uint8List bytes) {
    final samples =
        Int16List.view(bytes.buffer, bytes.offsetInBytes, bytes.length ~/ 2);
    if (samples.isEmpty) return 0.0;
    double sum = 0;
    for (final sample in samples) {
      sum += (sample.toDouble() * sample.toDouble());
    }
    return math.sqrt(sum / samples.length);
  }

  Future<void> _handleInterruption() async {
    await _audioPlayer?.stop();
    _audioRepository?.sendInterruption();
    _responseText = '';
  }

  void _applyGain(Uint8List bytes, double factor) {
    final samples =
        Int16List.view(bytes.buffer, bytes.offsetInBytes, bytes.length ~/ 2);
    for (var i = 0; i < samples.length; i++) {
      samples[i] = (samples[i] * factor).round().clamp(-32768, 32767);
    }
  }

  Future<void> _handleTurnComplete(Emitter<AssistantState> emit) async {
    if (state case Speaking(:final imageUrl)) {
      if (_textMode) {
        if (_ttsStarted && _responseText.isEmpty) {
          // TTS already running with no new text accumulated — AudioPlaybackFinished
          // will disconnect when playback ends.
          return;
        }
        // Either first turn, or new text arrived after a previous TTS started
        // (e.g. tool-response turn). Reset flag and speak the accumulated text.
        _ttsStarted = false;
        // Fallback: start TTS with accumulated text.
        final textToSpeak = _responseText;
        _responseText = '';
        if (textToSpeak.isNotEmpty) {
          _ttsStarted = true;
          final tts = _useElevenLabs ? _elevenLabsTtsService : _nativeTtsService;
          if (tts != null) {
            await tts.speak(
              textToSpeak,
              onComplete: () => add(const AssistantEvent.audioPlaybackFinished()),
            );
            return;
          }
        }
        // No text or no TTS service: disconnect immediately.
        await _disconnectAll();
        emit(AssistantState.idle(imageUrl: imageUrl));
      } else {
        _responseText = '';
        final newTextMode = await _settingsService.getUseTextMode();
        final newUseElevenLabs = await _settingsService.getUseElevenLabs();
        if (newTextMode != _textMode || newUseElevenLabs != _useElevenLabs) {
          _logger.i('[Bloc] Settings changed after turn — reconnecting');
          await _disconnectAll();
          emit(AssistantState.idle(imageUrl: imageUrl));
        } else {
          emit(AssistantState.listening(welcomeText: _welcomeText));
        }
      }
    }
  }

  Future<void> _handleCallPhone({
    required String callId,
    required String contactName,
    required bool exactMatch,
    required Emitter<AssistantState> emit,
  }) async {
    final result =
        await _phoneCallService.callByName(contactName, exactMatch: exactMatch);
    final resultMessage = switch (result) {
      PhoneCallSuccess() => '$contactName appelé.',
      PhoneCallError(:final message) => message,
      PhoneCallAmbiguous(:final candidates) =>
        'Plusieurs contacts correspondent à "$contactName" : '
            '${_formatNames(candidates.map((c) => c.displayName).toList())}.',
    };
    _activeRepo.sendToolResponse(
      callId: callId,
      functionName: 'call_phone',
      result: resultMessage,
    );
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
    await _speechService.stopListening();
    await _liveSubscription?.cancel();
    _liveSubscription = null;
    await _activeRepo.disconnect();
    await _elevenLabsTtsService?.stop();
    await _nativeTtsService?.stop();
  }

  String _formatNames(List<String> names) {
    if (names.isEmpty) return '';
    if (names.length == 1) return names.first;
    return '${names.sublist(0, names.length - 1).join(', ')} et ${names.last}';
  }

  @override
  Future<void> close() async {
    await _disconnectAll();
    await _audioPlayer?.stop();
    await _audioPlayer?.dispose();
    await _elevenLabsTtsService?.dispose();
    await _nativeTtsService?.dispose();
    return super.close();
  }
}
