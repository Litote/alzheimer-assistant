import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:alzheimer_assistant/shared/services/tts_service.dart';

// ── Mocks ──────────────────────────────────────────────────────────────────

class MockAudioPlayer extends Mock implements AudioPlayer {}

class FakeSource extends Fake implements Source {}

// ── Helpers ────────────────────────────────────────────────────────────────

/// Injectable [getTempDir] that returns the system temp directory (always exists).
Future<Directory> _systemTempDir() async => Directory.systemTemp;

TtsService _makeService(MockAudioPlayer player) => TtsService(
      player: player,
      getTempDir: _systemTempDir,
    );

void main() {
  late MockAudioPlayer mockPlayer;

  setUpAll(() {
    registerFallbackValue(FakeSource());
  });

  setUp(() {
    mockPlayer = MockAudioPlayer();
    when(() => mockPlayer.stop()).thenAnswer((_) async {});
    when(() => mockPlayer.dispose()).thenAnswer((_) async {});
  });

  // ── onComplete called for empty bytes ─────────────────────────────────────

  test('play() with empty bytes calls onComplete immediately', () async {
    final service = _makeService(mockPlayer);
    var completed = false;

    await service.play([], onComplete: () => completed = true);

    expect(completed, isTrue);
    verifyNever(() => mockPlayer.play(any()));
  });

  // ── Nominal path: playback via DeviceFileSource ────────────────────────
  //
  // BEFORE fix: BytesSource(Uint8List.fromList(...)) → crash on iOS with
  // "Unable to play audio" because iPhone does not support in-memory ByteSource.
  //
  // AFTER fix: write a temporary MP3 file and play via
  // DeviceFileSource, which iOS handles correctly.

  test(
    'play() uses DeviceFileSource (disk file) instead of BytesSource',
    () async {
      when(() => mockPlayer.onPlayerComplete).thenAnswer((_) => const Stream.empty());
      when(() => mockPlayer.play(any())).thenAnswer((_) async {});

      final service = _makeService(mockPlayer);
      await service.play([1, 2, 3], onComplete: () {});

      final captured = verify(() => mockPlayer.play(captureAny())).captured;
      expect(
        captured.single,
        isA<DeviceFileSource>(),
        reason: 'iOS requires a file on disk, not in-memory bytes',
      );
      expect(
        (captured.single as DeviceFileSource).path,
        endsWith('.mp3'),
        reason: 'The temporary file must have the .mp3 extension',
      );
    },
  );

  // ── Unique filenames across two consecutive plays ──────────────────────
  //
  // BEFORE fix: tts_response.mp3 used for all calls → race condition
  // if play() is called before the previous write finishes.
  //
  // AFTER fix: timestamp in the name → two consecutive plays
  // produce two distinct files.

  test(
    'play() generates unique filenames for two consecutive plays',
    () async {
      // Broadcast stream: can be listened to multiple times, reflecting
      // the real behaviour of AudioPlayer.onPlayerComplete.
      final controller = StreamController<void>.broadcast();
      when(() => mockPlayer.onPlayerComplete)
          .thenAnswer((_) => controller.stream);
      when(() => mockPlayer.play(any())).thenAnswer((_) async {});

      final service = _makeService(mockPlayer);

      await service.play([1, 2, 3], onComplete: () {});
      // Small delay to guarantee a different timestamp
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await service.play([4, 5, 6], onComplete: () {});

      final captured = verify(() => mockPlayer.play(captureAny())).captured;
      expect(captured.length, 2);
      final path1 = (captured[0] as DeviceFileSource).path;
      final path2 = (captured[1] as DeviceFileSource).path;
      expect(path1, isNot(equals(path2)), reason: 'Each playback must use a distinct file');

      await controller.close();
    },
  );

  // ── No double callback across two successive plays ─────────────────────
  //
  // BEFORE fix: each play() added a listener without cancelling the previous one.
  // On the 2nd play, onComplete was called twice (both listeners active).
  //
  // AFTER fix: the previous listener is cancelled before each play() →
  // onComplete is called only once, regardless of history.

  test(
    'play() called twice: onComplete from 2nd play called exactly once',
    () async {
      final controller1 = StreamController<void>();
      final controller2 = StreamController<void>();
      var callCount = 0;

      // First play → stream 1
      when(() => mockPlayer.onPlayerComplete)
          .thenAnswer((_) => controller1.stream);
      when(() => mockPlayer.play(any())).thenAnswer((_) async {});

      final service = _makeService(mockPlayer);
      await service.play([1, 2, 3], onComplete: () => callCount++);

      // Second play → stream 2 (before the first one has finished)
      when(() => mockPlayer.onPlayerComplete)
          .thenAnswer((_) => controller2.stream);
      await service.play([4, 5, 6], onComplete: () => callCount++);

      // Only the 2nd stream should trigger onComplete
      controller1.add(null); // event from the first stream (should be ignored)
      controller2.add(null); // event from the second stream (should trigger)
      await Future<void>.microtask(() {});

      expect(
        callCount,
        1,
        reason:
            'The first listener must be cancelled: only the 2nd onComplete '
            'should be called, not both',
      );

      await controller1.close();
      await controller2.close();
    },
  );

  // ── onComplete called even when the player crashes ─────────────────────
  //
  // BEFORE fix: no try/catch → if AudioPlayer.play() threw an exception
  // (iOS error, unsupported codec…), onComplete was never called → the BLoC
  // remained stuck in the Speaking state indefinitely.
  //
  // AFTER fix: the catch block calls onComplete() so the BLoC
  // always returns to Idle, even on audio error.

  test(
    'play(): player error → onComplete still called (BLoC does not stay stuck)',
    () async {
      when(() => mockPlayer.onPlayerComplete).thenAnswer((_) => const Stream.empty());
      when(() => mockPlayer.play(any())).thenThrow(Exception('iOS audio error'));

      final service = _makeService(mockPlayer);
      var completed = false;

      // Must not throw to the caller
      await expectLater(
        service.play([1, 2, 3], onComplete: () => completed = true),
        completes,
      );

      expect(
        completed,
        isTrue,
        reason:
            'onComplete must be called even when the player fails, '
            'otherwise the BLoC remains stuck in the Speaking state',
      );
    },
  );

  // ── dispose() cancels the active subscription ─────────────────────────

  test('dispose() cancels the active listener to prevent a late callback', () async {
    final controller = StreamController<void>();
    var callCount = 0;

    when(() => mockPlayer.onPlayerComplete).thenAnswer((_) => controller.stream);
    when(() => mockPlayer.play(any())).thenAnswer((_) async {});

    final service = _makeService(mockPlayer);
    await service.play([1, 2, 3], onComplete: () => callCount++);

    // dispose() before the stream fires
    await service.dispose();

    // Event fires after dispose → must no longer trigger onComplete
    controller.add(null);
    await Future<void>.microtask(() {});

    expect(callCount, 0, reason: 'After dispose(), no callback should be triggered');

    await controller.close();
  });

  // ── stop() and dispose() ──────────────────────────────────────────────

  test('stop() delegates to the player', () async {
    final service = _makeService(mockPlayer);
    await service.stop();
    verify(() => mockPlayer.stop()).called(1);
  });

  test('dispose() delegates to the player', () async {
    final service = _makeService(mockPlayer);
    await service.dispose();
    verify(() => mockPlayer.dispose()).called(1);
  });
}
