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

  /// Active subscription to the onPlayerComplete stream. Only one is kept at a
  /// time: each call to play() cancels the previous one before creating a new
  /// one, preventing listener accumulation and duplicate callbacks.
  StreamSubscription<void>? _completionSub;

  /// Plays the MP3 bytes received from ElevenLabs.
  /// Calls [onComplete] when playback is finished.
  Future<void> play(
    List<int> audioBytes, {
    required void Function() onComplete,
  }) async {
    if (audioBytes.isEmpty) {
      _logger.w('TTS: empty audio bytes, playback skipped');
      onComplete();
      return;
    }

    // Cancel the previous subscription to avoid duplicate callbacks
    await _completionSub?.cancel();
    _completionSub = _player.onPlayerComplete.listen((_) {
      _completionSub = null;
      onComplete();
    });

    try {
      final tempDir = await _getTempDir();
      // Unique filename per playback to avoid race conditions if play() is
      // called while a previous write is still in progress.
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
