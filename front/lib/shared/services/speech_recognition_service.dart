import 'package:speech_to_text/speech_to_text.dart';
import 'package:logger/logger.dart';

class SpeechRecognitionService {
  SpeechRecognitionService({SpeechToText? stt}) : _stt = stt ?? SpeechToText();

  final SpeechToText _stt;
  final _logger = Logger();

  bool _initialized = false;

  Future<bool> initialize() async {
    if (_initialized) return true;
    _initialized = await _stt.initialize(
      onError: (error) => _logger.e('STT error: ${error.errorMsg}'),
    );
    if (!_initialized) {
      _logger.w('Speech recognition not available on this device');
    }
    return _initialized;
  }

  /// Starts listening in fr-FR.
  /// [onInterim] receives partial results (live display).
  /// [onFinal]   receives the final transcription.
  Future<void> startListening({
    required void Function(String text) onInterim,
    required void Function(String text) onFinal,
  }) async {
    if (!await initialize()) {
      _logger.w('Speech recognition unavailable — onFinal(\'\') triggered');
      onFinal('');
      return;
    }

    try {
      await _stt.listen(
        localeId: 'fr_FR',
        // Reduce pauseFor as iOS handles its own timeout better in confirmation mode
        pauseFor: const Duration(seconds: 2),
        listenFor: const Duration(seconds: 20),
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.confirmation, // Garde confirmation mais parle de suite
          cancelOnError: false, // IMPORTANT: prevents the plugin from cutting out on silence
          partialResults: true,
        ),
        onResult: (result) {
          if (result.finalResult) {
            onFinal(result.recognizedWords);
          } else {
            onInterim(result.recognizedWords);
          }
        },
      );
    } catch (e) {
      _logger.e('STT listen() error: $e');
      onFinal('');
    }
  }

  Future<void> stopListening() async {
    await _stt.stop();
  }

  bool get isListening => _stt.isListening;
}
