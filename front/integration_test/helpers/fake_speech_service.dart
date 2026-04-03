import 'dart:async';
import 'dart:typed_data';

import 'package:alzheimer_assistant/shared/services/microphone_stream_service.dart';

/// Fake [MicrophoneStreamService] that immediately emits a single silent PCM
/// chunk and closes the stream, simulating a brief microphone burst without
/// requiring a real device or permission grant.
///
/// The server-side VAD in the ADK Live API is responsible for detecting
/// speech — the client just streams audio bytes.
class FakeMicrophoneStreamService extends MicrophoneStreamService {
  FakeMicrophoneStreamService({
    this.chunkDelay = const Duration(milliseconds: 50),
  }) : super(recorder: null);

  final Duration chunkDelay;
  bool _stopped = false;

  @override
  Future<Stream<Uint8List>> startStreaming() async {
    _stopped = false;
    final controller = StreamController<Uint8List>();
    Future.delayed(chunkDelay, () {
      if (!_stopped && !controller.isClosed) {
        // Silent 16kHz PCM chunk (512 zero bytes ≈ 16 ms of audio)
        controller.add(Uint8List(512));
        controller.close();
      }
    });
    return controller.stream;
  }

  @override
  Future<void> stop() async {
    _stopped = true;
  }

  @override
  Future<void> dispose() async {}
}
