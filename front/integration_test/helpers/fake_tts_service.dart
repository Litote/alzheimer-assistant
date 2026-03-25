import 'dart:async';
import 'package:alzheimer_assistant/shared/services/tts_service.dart';

/// Manual TTS: only calls [onComplete] when the test explicitly calls
/// [completePlayback()].
///
/// This avoids any in-flight timers when the test ends:
/// the test controls precisely when playback "finishes", which
/// allows verifying the Speaking state before transitioning to Idle.
///
/// If [bloc.close()] is called before [completePlayback()] (e.g. teardown
/// after an assertion failure), [dispose()] completes the completer without
/// calling [onComplete], preventing "Cannot add events after calling close".
class ManualFakeTtsService implements TtsService {
  Completer<void>? _completer;
  bool _disposed = false;

  /// Call from the test to simulate the end of audio playback.
  void completePlayback() {
    if (_completer != null && !_completer!.isCompleted) {
      _completer!.complete();
    }
  }

  @override
  Future<void> play(
    List<int> audioBytes, {
    required void Function() onComplete,
  }) async {
    _disposed = false;
    _completer = Completer<void>();
    await _completer!.future;
    // Only call onComplete if the service has not been disposed
    // (avoids add() on a closed bloc during an early teardown)
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
