import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:alzheimer_assistant/shared/services/buffered_audio_player_service.dart';

// ── Mocks ──────────────────────────────────────────────────────────────────

class MockAudioPlayer extends Mock implements AudioPlayer {}

void main() {
  late MockAudioPlayer player;
  late Directory tempDir;

  setUpAll(() {
    registerFallbackValue(DeviceFileSource(''));
  });

  setUp(() async {
    player = MockAudioPlayer();
    tempDir = await Directory.systemTemp.createTemp('sap_test_');

    when(() => player.onPlayerComplete)
        .thenAnswer((_) => const Stream.empty());
    when(() => player.play(any())).thenAnswer((_) async {});
    when(() => player.stop()).thenAnswer((_) async {});
    when(() => player.dispose()).thenAnswer((_) async {});
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  // ── hasChunks ─────────────────────────────────────────────────────────────

  test('hasChunks is false initially', () {
    final service = BufferedAudioPlayerService(
      player: player,
      getTempDir: () async => tempDir,
    );
    expect(service.hasChunks, isFalse);
  });

  test('hasChunks is true after addChunk', () {
    final service = BufferedAudioPlayerService(
      player: player,
      getTempDir: () async => tempDir,
    );
    service.addChunk(Uint8List.fromList([1, 2, 3]));
    expect(service.hasChunks, isTrue);
  });

  // ── playAndClear with empty buffer ────────────────────────────────────────

  test('playAndClear with empty buffer → calls onComplete immediately', () async {
    final service = BufferedAudioPlayerService(
      player: player,
      getTempDir: () async => tempDir,
    );
    var called = false;
    await service.playAndClear(onComplete: () => called = true);
    expect(called, isTrue);
    verifyNever(() => player.play(any()));
  });

  // ── playAndClear produces valid WAV ───────────────────────────────────────

  test('playAndClear writes a valid WAV file to temp dir', () async {
    final service = BufferedAudioPlayerService(
      player: player,
      getTempDir: () async => tempDir,
    );

    // Capture what file was played
    final completeController = StreamController<void>();
    when(() => player.onPlayerComplete)
        .thenAnswer((_) => completeController.stream);

    // Add two chunks (8 bytes each = 4 int16 samples per chunk)
    service.addChunk(Uint8List.fromList([0x10, 0x00, 0x20, 0x00, 0x30, 0x00, 0x40, 0x00]));
    service.addChunk(Uint8List.fromList([0x50, 0x00, 0x60, 0x00, 0x70, 0x00, 0x80, 0x00]));

    String? playedPath;
    when(() => player.play(any())).thenAnswer((invocation) async {
      final source = invocation.positionalArguments[0] as DeviceFileSource;
      playedPath = source.path;
    });

    service.playAndClear(onComplete: () {});
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(playedPath, isNotNull);
    final file = File(playedPath!);
    expect(await file.exists(), isTrue);

    final bytes = await file.readAsBytes();
    // WAV header is 44 bytes + 16 PCM bytes = 60 bytes total
    expect(bytes.length, 60);

    // Verify RIFF header magic bytes
    expect(bytes.sublist(0, 4), [82, 73, 70, 70]); // 'RIFF'
    expect(bytes.sublist(8, 12), [87, 65, 86, 69]); // 'WAVE'

    await completeController.close();
  });

  // ── stop clears the buffer ────────────────────────────────────────────────

  test('stop() clears the buffer', () async {
    final service = BufferedAudioPlayerService(
      player: player,
      getTempDir: () async => tempDir,
    );
    service.addChunk(Uint8List.fromList([1, 2, 3]));
    expect(service.hasChunks, isTrue);
    await service.stop();
    expect(service.hasChunks, isFalse);
  });

  // ── playAndClear — play() throws ──────────────────────────────────────────

  test('playAndClear — play() throws → calls onComplete immediately', () async {
    final service = BufferedAudioPlayerService(
      player: player,
      getTempDir: () async => tempDir,
    );
    service.addChunk(Uint8List.fromList([1, 2, 3, 4]));

    final completeController = StreamController<void>();
    when(() => player.onPlayerComplete)
        .thenAnswer((_) => completeController.stream);
    when(() => player.play(any())).thenThrow(Exception('playback error'));

    var called = false;
    await service.playAndClear(onComplete: () => called = true);

    expect(called, isTrue);
    await completeController.close();
  });

  // ── dispose ────────────────────────────────────────────────────────────────

  test('dispose() disposes the audio player', () async {
    final service = BufferedAudioPlayerService(
      player: player,
      getTempDir: () async => tempDir,
    );

    await service.dispose();

    verify(() => player.dispose()).called(1);
  });

  test('dispose() with active playback cancels subscription', () async {
    final service = BufferedAudioPlayerService(
      player: player,
      getTempDir: () async => tempDir,
    );
    service.addChunk(Uint8List.fromList([1, 2, 3, 4]));

    // Start playback but do not fire onPlayerComplete so subscription is active
    final completeController = StreamController<void>();
    when(() => player.onPlayerComplete)
        .thenAnswer((_) => completeController.stream);

    // Don't await — we want _completionSub to be set before dispose
    unawaited(service.playAndClear(onComplete: () {}));
    await Future<void>.delayed(const Duration(milliseconds: 10));

    await service.dispose();

    verify(() => player.dispose()).called(1);
    await completeController.close();
  });
}
