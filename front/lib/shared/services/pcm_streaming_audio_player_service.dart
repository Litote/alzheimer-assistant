import 'dart:collection';
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
///
/// Gemini streams audio faster than realtime, so chunks are kept in a Dart
/// queue and fed to the plugin only [_leadFrames] ahead of playback (driven by
/// the plugin's feed callback). flutter_pcm_sound has no flush API: this is
/// what lets [stop] silence the agent within ~[_leadFrames] on barge-in.
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

  // Audio fed to the plugin ahead of playback. The feed callback fires when
  // fewer than [_feedThresholdFrames] remain; we then top up to [_leadFrames].
  static const int _feedThresholdFrames = _sampleRate ~/ 5; // 200 ms
  static const int _leadFrames = _sampleRate * 2 ~/ 5; // 400 ms

  final Queue<Uint8List> _pending = Queue<Uint8List>();
  // True when the last feed callback found the queue empty: no further
  // callback is pending, so the next chunk must be fed from [addChunk].
  bool _starved = true;
  static const _audioChannel = MethodChannel('alzheimer_assistant/audio');

  // Software gain applied to every output chunk.
  // AVAudioSessionCategoryPlayAndRecord (needed for simultaneous mic + speaker)
  // reduces output vs the playback-only category. A 1.5× factor partially
  // compensates for that reduction. Clipping is prevented by clamping to int16
  // range. Adjust if audio is too loud or distorts on louder content.
  static const double _outputGain = 1.0;

  Future<void> _init() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        // Configure AVAudioSession with the correct mode BEFORE flutter_pcm_sound
        // activates it. Apple requires: setCategory → setMode → setPreferred → setActive
        // → start engine. This call handles the first three steps + setActive.
        await _audioChannel.invokeMethod<void>('prepareAudioSession');
      }

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
      await FlutterPcmSound.setFeedThreshold(_feedThresholdFrames);
      FlutterPcmSound.setFeedCallback(_onFeed);

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        // flutter_pcm_sound's setup() resets the session mode to .default via its own
        // setCategory call. Restore mode: .voiceChat without calling setActive again
        // to avoid triggering a phantom interruption on the already-running engine.
        await _audioChannel.invokeMethod<void>('overrideToSpeaker');
        // Register handler for native interruption-ended events so the engine can
        // be restarted after a phone call or Siri session ends.
        _audioChannel.setMethodCallHandler(_onNativeCall);
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

  Future<dynamic> _onNativeCall(MethodCall call) async {
    if (call.method == 'audioInterruptionEnded') {
      _logger.i('[PcmPlayer] Audio interruption ended — restarting PCM engine');
      _isInitialized = false;
      _starved = true;
      await FlutterPcmSound.release();
      await _init();
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
    _pending.add(_outputGain == 1.0 ? bytes : _applyGain(bytes, _outputGain));
    if (_starved) _feed(0);
  }

  /// Plugin feed callback: fires once per feed when the buffer falls below
  /// [_feedThresholdFrames], and once when it is fully drained (0).
  void _onFeed(int remainingFrames) {
    if (_pending.isEmpty) {
      _starved = true;
      return;
    }
    _feed(remainingFrames);
  }

  /// Moves queued chunks to the plugin until ~[_leadFrames] are buffered.
  void _feed(int remainingFrames) {
    if (!_isInitialized || _pending.isEmpty) return;
    final builder = BytesBuilder(copy: false);
    var frames = remainingFrames;
    while (_pending.isNotEmpty && frames < _leadFrames) {
      final chunk = _pending.removeFirst();
      builder.add(chunk);
      frames += chunk.length ~/ 2;
    }
    final out = builder.takeBytes();
    _starved = false;
    _logger.d('[PcmPlayer] feeding ${out.length} bytes (${_pending.length} chunks queued)');
    try {
      FlutterPcmSound.feed(
        PcmArrayInt16(bytes: out.buffer.asByteData(out.offsetInBytes, out.length)),
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
    // We avoid full release() + _init() cycle on every stop to prevent
    // AVAudioSession churn which causes interruptions on newer iOS devices.
    // Dropping the Dart queue is enough: at most [_leadFrames] (plus one
    // chunk) already handed to the plugin will still play.
    _logger.i('[PcmPlayer] Playback stop requested — dropping ${_pending.length} queued chunks (keeping engine alive)');
    _pending.clear();
  }

  @override
  Future<void> dispose() async {
    _pending.clear();
    FlutterPcmSound.setFeedCallback(null);
    _audioChannel.setMethodCallHandler(null);
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
