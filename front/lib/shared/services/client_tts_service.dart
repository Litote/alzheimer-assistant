/// Abstract interface for client-side TTS engines.
///
/// Implementations:
/// - [ElevenLabsClientTtsService] — fetches audio from ElevenLabs API, plays MP3.
/// - [NativeClientTtsService]    — uses the device's built-in TTS engine.
abstract interface class ClientTtsService {
  /// Synthesises [text] and plays it back.
  /// Calls [onComplete] when playback finishes (or on error).
  Future<void> speak(String text, {required void Function() onComplete});

  /// Stops any in-progress playback immediately.
  Future<void> stop();

  /// Releases underlying resources.
  Future<void> dispose();
}
