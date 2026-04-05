import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:alzheimer_assistant/shared/services/buffered_audio_player_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAudioPlayer extends Mock implements AudioPlayer {}
class MockSource extends Fake implements Source {}
class FakeAudioContext extends Fake implements AudioContext {}

void main() {
  late MockAudioPlayer mockPlayer;
  late BufferedAudioPlayerService service;

  setUpAll(() {
    registerFallbackValue(MockSource());
    registerFallbackValue(FakeAudioContext());
  });

  setUp(() {
    mockPlayer = MockAudioPlayer();
    service = BufferedAudioPlayerService(
      player: mockPlayer,
      getTempDir: () async => Directory.systemTemp,
    );

    when(() => mockPlayer.setAudioContext(any())).thenAnswer((_) async {});
    when(() => mockPlayer.stop()).thenAnswer((_) async {});
    when(() => mockPlayer.dispose()).thenAnswer((_) async {});
    when(() => mockPlayer.play(any())).thenAnswer((_) async {});
    when(() => mockPlayer.onPlayerComplete).thenAnswer((_) => const Stream.empty());
  });

  test('addChunk adds bytes to buffer', () {
    final chunk = Uint8List.fromList([1, 2, 3]);
    service.addChunk(chunk);
    expect(service.hasChunks, isTrue);
  });

  test('playAndClear calls onComplete immediately if buffer is empty', () async {
    var completed = false;
    await service.playAndClear(onComplete: () => completed = true);
    expect(completed, isTrue);
    verifyNever(() => mockPlayer.play(any()));
  });

  test('playAndClear plays WAV and clears buffer', () async {
    service.addChunk(Uint8List.fromList([0, 0, 0, 0]));
    
    await service.playAndClear(onComplete: () {});
    
    expect(service.hasChunks, isFalse);
    verify(() => mockPlayer.play(any())).called(1);
  });

  test('stop clears buffer and stops player', () async {
    service.addChunk(Uint8List.fromList([1, 2, 3]));
    await service.stop();
    expect(service.hasChunks, isFalse);
    verify(() => mockPlayer.stop()).called(1);
  });

  test('dispose cancels subscription and disposes player', () async {
    await service.dispose();
    verify(() => mockPlayer.dispose()).called(1);
  });

  test('playAndClear calls onComplete when player finishes', () async {
    final completionController = StreamController<void>();
    when(() => mockPlayer.onPlayerComplete).thenAnswer((_) => completionController.stream);
    
    service.addChunk(Uint8List.fromList([0, 0, 0, 0]));
    
    var completed = false;
    await service.playAndClear(onComplete: () => completed = true);
    
    completionController.add(null);
    await Future<void>.delayed(Duration.zero);
    
    expect(completed, isTrue);
    await completionController.close();
  });
}
