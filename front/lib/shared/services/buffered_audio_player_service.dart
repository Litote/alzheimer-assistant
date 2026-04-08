import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:alzheimer_assistant/core/utils/app_logger.dart';
import 'package:alzheimer_assistant/shared/services/streaming_audio_player_service.dart';
import 'package:path_provider/path_provider.dart';

/// Buffers PCM chunks into a WAV file and plays it via audioplayers once the
/// agent's turn is complete ([LiveTurnComplete] received).
///
/// More compatible across devices than real-time PCM, but introduces a
/// delay equal to the agent's full response duration before audio starts.
/// Does not provide hardware AEC — use [PcmStreamingAudioPlayerService] for
/// bidi streaming with echo cancellation.
class BufferedAudioPlayerService implements StreamingAudioPlayerService {
  BufferedAudioPlayerService({
    AudioPlayer? player,
    Future<Directory> Function()? getTempDir,
  }) : _player = player ?? _createPlayer(),
       _getTempDir = getTempDir ?? getTemporaryDirectory;

  static AudioPlayer _createPlayer() {
    final player = AudioPlayer();
    player.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          audioFocus: AndroidAudioFocus.none,
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.speech,
          usageType: AndroidUsageType.assistant,
        ),
      ),
    );

    return player;
  }

  final AudioPlayer _player;
  final Future<Directory> Function() _getTempDir;
  final _logger = appLogger;

  static const int _sampleRate = 24000;
  static const int _channels = 1;
  static const int _bitsPerSample = 16;

  final List<int> _pcmBuffer = [];
  StreamSubscription<void>? _completionSub;

  @override
  bool get hasChunks => _pcmBuffer.isNotEmpty;

  @override
  void addChunk(Uint8List bytes) {
    _pcmBuffer.addAll(bytes);
  }

  @override
  Future<void> playAndClear({required void Function() onComplete}) async {
    if (_pcmBuffer.isEmpty) {
      _logger.w('[BufferedPlayer] Empty buffer — skipping playback');
      onComplete();
      return;
    }

    final pcm = List<int>.unmodifiable(_pcmBuffer);
    _pcmBuffer.clear();

    await _completionSub?.cancel();

    // Même logique de nettoyage : fichier en cours
    String? currentFilePath;

    _completionSub = _player.onPlayerComplete.listen((_) {
      _completionSub = null;
      // on nettoie en fin de lecture
      if (currentFilePath != null) {
        final file = File(currentFilePath!);
        if (await file.exists()) {
          await file.delete();
          _logger.d('[BufferedPlayer] Fichier WAV temporaire supprimé.');
        }
      }
      onComplete();
    });

    try {
      final wav = _buildWav(pcm);
      final dir = await _getTempDir();

      // Conservation du chemin
      currentFilePath = '${dir.path}/agent_${DateTime.now().millisecondsSinceEpoch}.wav';
      final file = File(currentFilePath!);
      await file.writeAsBytes(wav);

      _logger.i(
        '[BufferedPlayer] Playing ${pcm.length} PCM bytes as WAV → $path',
      );
      await _player.play(DeviceFileSource(path));
    } catch (e) {
      _logger.e('[BufferedPlayer] Playback error: $e');
      await _completionSub?.cancel();
      _completionSub = null;
      
      // Nettoyage même en cas d'erreur de lecture
      if (currentFilePath != null) {
        final file = File(currentFilePath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      onComplete();
    }
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    _pcmBuffer.clear();
  }

  @override
  Future<void> dispose() async {
    await _completionSub?.cancel();
    _completionSub = null;
    await _player.dispose();
  }

  // ── WAV encoding ─────────────────────────────────────────────────────────

  Uint8List _buildWav(List<int> pcm) {
    final dataSize = pcm.length;
    const byteRate = _sampleRate * _channels * (_bitsPerSample ~/ 8);
    const blockAlign = _channels * (_bitsPerSample ~/ 8);

    final header = ByteData(44);
    _setFourCC(header, 0, 'RIFF');
    header.setUint32(4, 36 + dataSize, Endian.little);
    _setFourCC(header, 8, 'WAVE');
    _setFourCC(header, 12, 'fmt ');
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, _channels, Endian.little);
    header.setUint32(24, _sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, _bitsPerSample, Endian.little);
    _setFourCC(header, 36, 'data');
    header.setUint32(40, dataSize, Endian.little);

    return Uint8List.fromList([...header.buffer.asUint8List(), ...pcm]);
  }

  void _setFourCC(ByteData data, int offset, String cc) {
    for (var i = 0; i < 4; i++) {
      data.setUint8(offset + i, cc.codeUnitAt(i));
    }
  }
}
