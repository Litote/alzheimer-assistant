import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

class TtsService {
  TtsService({AudioPlayer? player, Future<Directory> Function()? getTempDir})
      : _player = player ?? AudioPlayer(),
        _getTempDir = getTempDir ?? getTemporaryDirectory;

  final AudioPlayer _player;
  final Future<Directory> Function() _getTempDir;
  final _logger = Logger();

  StreamSubscription<void>? _completionSub;

  /// Plays the MP3 bytes received from ElevenLabs.
  /// Calls [onComplete] when playback is finished or on any error.
  Future<void> play(
    List<int> audioBytes, {
    required void Function() onComplete,
  }) async {
    if (audioBytes.isEmpty) {
      _logger.w('TTS: empty audio bytes, playback skipped');
      onComplete();
      return;
    }

    await _completionSub?.cancel();
    // Mon idée, tu risques de saturer le device si tu supprimes pas tes fichiers audios
    File? tempFile;

    _completionSub = _player.onPlayerComplete.listen(
      (_) {
        _completionSub = null;
        // Suppression du fichier après lecture
        if (tempFile != null && await tempFile!.exists()) {
          await tempFile!.delete();
          _logger.d('Fichier audio temporaire supprimé.');
        }
        onComplete();
      },
      // Platform errors propagate through eventStream — catch them here to
      // avoid unhandled exceptions and still call onComplete so the BLoC
      // transitions back to Idle.
      onError: (Object e) {
        _logger.e('TTS player error: $e');
        _completionSub = null;
        // Nettoyage en cas d'erreur également
        if (tempFile != null && await tempFile!.exists()) {
          await tempFile!.delete();
        }
        onComplete();
      },
    );

    try {
      final tempDir = await _getTempDir();
      // Unique filename per playback to avoid race conditions.
      final fileName = 'tts_${DateTime.now().millisecondsSinceEpoch}.mp3';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(audioBytes);

      await _player.play(DeviceFileSource(file.path));
    } catch (e) {
      _logger.e('TTS Error: $e');
      await _completionSub?.cancel();
      _completionSub = null;
      onComplete();
    }
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> dispose() async {
    await _completionSub?.cancel();
    _completionSub = null;
    await _player.dispose();
  }
}
