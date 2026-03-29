import 'dart:typed_data';

import 'package:alzheimer_assistant/core/utils/app_logger.dart';
import 'package:record/record.dart';

/// Captures microphone input as a stream of raw PCM chunks.
///
/// Format: 16 kHz, 16-bit, mono — the format expected by the ADK Live API
/// (`audio/pcm;rate=16000`). Replaces [SpeechRecognitionService]: device-side
/// STT is no longer needed because the ADK Live API handles VAD + STT
/// server-side via Gemini.
///
/// iOS: requires NSMicrophoneUsageDescription in Info.plist (already present).
class MicrophoneStreamService {
  MicrophoneStreamService({AudioRecorder? recorder})
      : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;
  final _logger = appLogger;

  static const _config = RecordConfig(
    encoder: AudioEncoder.pcm16bits,
    sampleRate: 16000,
    numChannels: 1,
    noiseSuppress: true,
    echoCancel: true,
    autoGain: true,
  );

  /// Starts capturing and returns a stream of raw PCM 16-bit 16 kHz mono chunks.
  ///
  /// Throws if the microphone permission is denied.
  Future<Stream<Uint8List>> startStreaming() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      _logger.e('[Mic] Permission denied');
      throw Exception("Permission microphone refusée.");
    }

    _logger.i('[Mic] Starting stream (16 kHz, 16-bit, mono) with noise suppression');
    return _recorder.startStream(_config);
  }

  /// Stops capturing.
  Future<void> stop() async {
    await _recorder.stop();
    _logger.i('[Mic] Stopped');
  }

  /// Releases native resources. Call when the service is no longer needed.
  Future<void> dispose() async {
    await _recorder.dispose();
  }
}
