import 'dart:async';
import 'dart:typed_data';

import 'package:alzheimer_assistant/shared/services/streaming_audio_player_service.dart';

/// Manual [StreamingAudioPlayerService] that only calls [onComplete] when the
/// test explicitly calls [completePlayback()].
///
/// This gives the test full control over when audio "finishes", so it can
/// assert on the Speaking state before the transition to Idle.
///
/// If [dispose()] is called before [completePlayback()] (e.g. during teardown
/// after an assertion failure), the completer is resolved silently to prevent
/// "Cannot add events after close" errors on the bloc.
class ManualFakeStreamingAudioPlayerService extends StreamingAudioPlayerService {
  ManualFakeStreamingAudioPlayerService();

  Completer<void>? _completer;
  bool _disposed = false;

  /// Call from the test to simulate the end of audio playback.
  void completePlayback() {
    if (_completer != null && !_completer!.isCompleted) {
      _completer!.complete();
    }
  }

  @override
  bool get hasChunks => true;

  @override
  void addChunk(Uint8List bytes) {}

  @override
  Future<void> playAndClear({required void Function() onComplete}) async {
    _disposed = false;
    _completer = Completer<void>();
    await _completer!.future;
    if (!_disposed) onComplete();
  }

  @override
  Future<void> stop() async {
    if (_completer != null && !_completer!.isCompleted) {
      _completer!.complete();
    }
    _completer = null;
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    if (_completer != null && !_completer!.isCompleted) {
      _completer!.complete();
    }
    _completer = null;
  }
}
