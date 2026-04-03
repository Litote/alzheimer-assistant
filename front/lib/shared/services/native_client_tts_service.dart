import 'package:alzheimer_assistant/core/utils/app_logger.dart';
import 'package:alzheimer_assistant/shared/services/client_tts_service.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// [ClientTtsService] backed by the device's built-in TTS engine via
/// [FlutterTts].  Uses French language and a slightly reduced speech rate
/// suitable for elderly users.
class NativeClientTtsService implements ClientTtsService {
  NativeClientTtsService({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;
  final _logger = appLogger;
  bool _initialised = false;

  Future<void> _ensureInitialised() async {
    if (_initialised) return;
    _initialised = true;
    await _tts.setLanguage('fr-FR');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  @override
  Future<void> speak(
    String text, {
    required void Function() onComplete,
  }) async {
    try {
      await _ensureInitialised();
      _tts.setCompletionHandler(onComplete);
      _tts.setErrorHandler((dynamic msg) {
        _logger.e('[NativeTTS] Error: $msg');
        onComplete();
      });
      await _tts.speak(text);
    } catch (e) {
      _logger.e('[NativeTTS] Speak error: $e');
      onComplete();
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (e) {
      _logger.w('[NativeTTS] Stop error: $e');
    }
  }

  @override
  Future<void> dispose() async => stop();
}
