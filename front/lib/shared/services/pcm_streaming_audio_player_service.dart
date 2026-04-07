import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';
import 'package:alzheimer_assistant/core/utils/app_logger.dart';
import 'package:alzheimer_assistant/shared/services/streaming_audio_player_service.dart';

/// Real-time PCM playback via flutter_pcm_sound.
///
/// Feeds chunks directly to the audio hardware as they arrive — no buffering,
/// no WAV encoding. Enables hardware Acoustic Echo Cancellation (AEC) via
/// [IosAudioCategory.playAndRecord] on iOS and
/// [AndroidAudioUsage.voiceCommunication] on Android.
///
/// Best for bidi streaming where low latency and AEC matter.
class PcmStreamingAudioPlayerService implements StreamingAudioPlayerService {
  PcmStreamingAudioPlayerService() {
    _init();
  }

  final _logger = appLogger;
  bool _isInitialized = false;
  // Tracks whether setAudioModeCommunication was called so resetAudioMode is
  // only invoked when there is actually a mode to restore.
  bool _audioModeSet = false;

  static const int _sampleRate = 24000;
  static const _audioChannel = MethodChannel('alzheimer_assistant/audio');

  // Software gain applied to every output chunk.
  // AVAudioSessionCategoryPlayAndRecord (needed for simultaneous mic + speaker)
  // reduces output vs the playback-only category. A 1.5× factor partially
  // compensates for that reduction. Clipping is prevented by clamping to int16
  // range. Adjust if audio is too loud or distorts on louder content.
  static const double _outputGain = 1.0;

  Future<void> _init() async {
    try {
      await FlutterPcmSound.setup(
        sampleRate: _sampleRate,
        channelCount: 1,
        // playAndRecord shares the audio session with `record`, preserving
        // OS-level AEC on iOS.
        iosAudioCategory: IosAudioCategory.playAndRecord,
        // voiceCommunication activates hardware AEC on Android so the mic
        // does not capture speaker output during bidi streaming.
        androidAudioUsage: AndroidAudioUsage.voiceCommunication,
      );
      // flutter_pcm_sound sets playAndRecord without AVAudioSessionCategoryOptionDefaultToSpeaker,
      // which causes iOS to route audio through the earpiece instead of the speaker.
      // Override immediately after setup so the correct route is active from the first chunk.
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _audioChannel.invokeMethod<void>('overrideToSpeaker');
      }
      // Android hardware AEC requires AudioManager.MODE_IN_COMMUNICATION to be active
      // so the audio HAL can provide the playback reference signal to the AEC algorithm.
      // Without this mode, AEC has no reference and the mic captures speaker output as echo.
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _audioChannel.invokeMethod<void>('setAudioModeCommunication');
        _audioModeSet = true;
      }
      _isInitialized = true;
      _logger.i('[PcmPlayer] FlutterPcmSound initialized at ${_sampleRate}Hz');
    } catch (e) {
      _logger.e('[PcmPlayer] Initialization error: $e');
    }
  }

  @override
  bool get hasChunks => false;

  @override
  void addChunk(Uint8List bytes) {
    if (!_isInitialized) {
      _logger.w('[PcmPlayer] addChunk called but not initialized — dropped ${bytes.length} bytes');
      return;
    }
    try {
      final amplified = _outputGain == 1.0 ? bytes : _applyGain(bytes, _outputGain);
      _logger.d('[PcmPlayer] feeding ${bytes.length} bytes to FlutterPcmSound');
      FlutterPcmSound.feed(
        PcmArrayInt16(
          bytes: amplified.buffer.asByteData(amplified.offsetInBytes, amplified.length),
        ),
      );
    } catch (e) {
      _logger.e('[PcmPlayer] Error feeding PCM data: $e');
    }
  }

  /// Amplifies [bytes] (16-bit little-endian PCM) by [factor], clamping to
  /// prevent int16 overflow. Returns a new buffer — the input is not mutated.
  Uint8List _applyGain(Uint8List bytes, double factor) {
    final out = Uint8List.fromList(bytes);
    final samples = Int16List.view(out.buffer, out.offsetInBytes, out.length ~/ 2);
    for (var i = 0; i < samples.length; i++) {
      samples[i] = (samples[i] * factor).round().clamp(-32768, 32767);
    }
    return out;
  }

  @override
  Future<void> playAndClear({required void Function() onComplete}) async {
    // Data is already streamed to hardware — just invoke the callback.
    onComplete();
  }

  @override
  Future<void> stop() async {
    if (_isInitialized) {
      await FlutterPcmSound.release();
      _isInitialized = false;
      _init();
    }
    _logger.i('[PcmPlayer] Playback stopped');
  }

  @override
  Future<void> dispose() async {
    if (_isInitialized) {
      await FlutterPcmSound.release();
      _isInitialized = false;
    }
    if (_audioModeSet) {
      _audioModeSet = false;
      await _audioChannel.invokeMethod<void>('resetAudioMode');
    }
  }
}
