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

    // Hoisted so both the completion callback and the error handler can delete it.
    File? tempFile;

    _completionSub = _player.onPlayerComplete.listen(
      (_) async {
        _completionSub = null;
        // Delete the temporary MP3 file to avoid filling device storage.
        final f = tempFile;
        if (f != null && await f.exists()) {
          await f.delete();
          _logger.d('TTS: temporary MP3 file deleted.');
        }
        onComplete();
      },
      // Platform errors propagate through eventStream — catch them here to
      // avoid unhandled exceptions and still call onComplete so the BLoC
      // transitions back to Idle.
      onError: (Object e) async {
        _logger.e('TTS player error: $e');
        _completionSub = null;
        // Clean up on error too.
        final f = tempFile;
        if (f != null && await f.exists()) await f.delete();
        onComplete();
      },
    );

    try {
      final tempDir = await _getTempDir();
      // Unique filename per playback to avoid race conditions.
      final fileName = 'tts_${DateTime.now().millisecondsSinceEpoch}.mp3';
      tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(audioBytes);

      await _player.play(DeviceFileSource(tempFile.path));
    } catch (e) {
      _logger.e('TTS Error: $e');
      await _completionSub?.cancel();
      _completionSub = null;
      // Clean up the file even when the player throws.
      final f = tempFile;
      if (f != null && await f.exists()) await f.delete();
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
