import 'package:speech_to_text/speech_to_text.dart';
import 'package:logger/logger.dart';

class SpeechRecognitionService {
  SpeechRecognitionService({SpeechToText? stt}) : _stt = stt ?? SpeechToText();

  final SpeechToText _stt;
  final _logger = Logger();

  bool _initialized = false;

  /// Registered by [startListening]; called at most once when
  /// [error_speech_timeout] or [error_no_match] fires so the BLoC can reset.
  void Function()? _currentOnTimeout;

  Future<bool> initialize() async {
    if (_initialized) return true;
    _initialized = await _stt.initialize(
      onError: (error) {
        _logger.e('STT error: ${error.errorMsg}');
        // Timeout and no-match mean the recogniser gave up without receiving
        // usable audio. Call onTimeout so the BLoC can reset to Idle instead
        // of staying stuck in Listening forever.
        if (error.errorMsg == 'error_speech_timeout' ||
            error.errorMsg == 'error_no_match') {
          final cb = _currentOnTimeout;
          if (cb != null) {
            _currentOnTimeout = null;
            _stt.stop();
            cb();
          }
        }
      },
    );
    if (!_initialized) {
      _logger.w('Speech recognition not available on this device');
    }
    return _initialized;
  }

  /// Starts listening in fr-FR.
  /// [onInterim] receives partial results (live display).
  /// [onFinal]   receives the final transcription.
  /// [onTimeout] called when STT gives up (timeout / no-match) so the caller
  ///             can reset to Idle without showing an error message.
  Future<void> startListening({
    required void Function(String text) onInterim,
    required void Function(String text) onFinal,
    void Function()? onTimeout,
  }) async {
    _currentOnTimeout = onTimeout;

    if (!await initialize()) {
      _logger.w('Speech recognition unavailable — onFinal(\'\') triggered');
      _currentOnTimeout = null;
      onFinal('');
      return;
    }

    try {
      // Cancel any lingering Android SpeechRecognizer session before starting
      // a new one. Without this, calling listen() while a previous session is
      // still tearing down causes ERROR_CLIENT, which with cancelOnError:false
      // triggers an infinite error/restart loop.
      await _stt.cancel();
      await _stt.listen(
        localeId: 'fr_FR',
        // Reduce pauseFor as iOS handles its own timeout better in confirmation mode
        pauseFor: const Duration(seconds: 2),
        listenFor: const Duration(seconds: 20),
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.confirmation, // Keeps confirmation mode but speaks immediately
          cancelOnError: false, // IMPORTANT: prevents the plugin from cutting out on silence
          partialResults: true,
        ),
        onResult: (result) {
          if (result.finalResult) {
            _currentOnTimeout = null;
            onFinal(result.recognizedWords);
          } else {
            onInterim(result.recognizedWords);
          }
        },
      );
    } catch (e) {
      _logger.e('STT listen() error: $e');
      _currentOnTimeout = null;
      onFinal('');
    }
  }

  Future<void> stopListening() async {
    _currentOnTimeout = null;
    await _stt.stop();
  }

  bool get isListening => _stt.isListening;
}
