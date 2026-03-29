import 'dart:typed_data';

/// Abstract interface for audio playback of PCM chunks received from the agent.
///
/// Two implementations are available, selectable at build time via
/// `--dart-define=AUDIO_PLAYER_MODE=pcm` (default) or `buffered`.
///
/// - [PcmStreamingAudioPlayerService]: real-time PCM via flutter_pcm_sound.
///   Low latency, hardware AEC. Best for bidi streaming.
/// - [BufferedAudioPlayerService]: buffers chunks into a WAV file, plays via
///   audioplayers once the agent's turn is complete. More compatible.
abstract class StreamingAudioPlayerService {
  /// Whether there are buffered chunks ready to play.
  bool get hasChunks;

  /// Feeds an incoming PCM chunk (24 kHz, 16-bit, mono) to the player.
  void addChunk(Uint8List bytes);

  /// Starts or signals playback. Calls [onComplete] when playback finishes.
  Future<void> playAndClear({required void Function() onComplete});

  /// Stops playback immediately (e.g. user interrupts the agent).
  Future<void> stop();

  /// Releases audio resources.
  Future<void> dispose();
}
