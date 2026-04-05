import 'dart:typed_data';
import 'package:alzheimer_assistant/shared/services/microphone_stream_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:record/record.dart';

class MockAudioRecorder extends Mock implements AudioRecorder {}

void main() {
  late MockAudioRecorder mockRecorder;
  late MicrophoneStreamService service;

  setUp(() {
    mockRecorder = MockAudioRecorder();
    service = MicrophoneStreamService(recorder: mockRecorder);
    registerFallbackValue(const RecordConfig());
  });

  test('startStreaming returns stream when permission is granted', () async {
    final expectedStream = Stream.fromIterable([Uint8List.fromList([1, 2, 3])]);
    when(() => mockRecorder.hasPermission()).thenAnswer((_) async => true);
    when(() => mockRecorder.startStream(any())).thenAnswer((_) async => expectedStream);

    final stream = await service.startStreaming();

    expect(stream, isNotNull);
    final chunks = await stream.toList();
    expect(chunks.first, Uint8List.fromList([1, 2, 3]));
  });

  test('startStreaming throws exception when permission is denied', () async {
    when(() => mockRecorder.hasPermission()).thenAnswer((_) async => false);

    expect(() => service.startStreaming(), throwsA(isA<Exception>()));
  });

  test('stop calls recorder.stop', () async {
    when(() => mockRecorder.stop()).thenAnswer((_) async => '');
    await service.stop();
    verify(() => mockRecorder.stop()).called(1);
  });

  test('dispose calls recorder.dispose', () async {
    when(() => mockRecorder.dispose()).thenAnswer((_) async {});
    await service.dispose();
    verify(() => mockRecorder.dispose()).called(1);
  });
}
