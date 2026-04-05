import 'package:alzheimer_assistant/shared/services/elevenlabs_client_tts_service.dart';
import 'package:alzheimer_assistant/shared/services/tts_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTtsService extends Mock implements TtsService {}

void main() {
  late MockTtsService mockTtsService;
  late ElevenLabsClientTtsService service;

  setUp(() {
    mockTtsService = MockTtsService();
    service = ElevenLabsClientTtsService(ttsService: mockTtsService);
    
    when(() => mockTtsService.stop()).thenAnswer((_) async {});
    when(() => mockTtsService.dispose()).thenAnswer((_) async {});
  });

  group('ElevenLabsClientTtsService', () {
    test('stop calls ttsService.stop', () async {
      await service.stop();
      verify(() => mockTtsService.stop()).called(1);
    });

    test('dispose calls ttsService.dispose', () async {
      await service.dispose();
      verify(() => mockTtsService.dispose()).called(1);
    });

    test('speak calls onComplete on error (network failure)', () async {
      // This will fail because HttpClient is not mocked, 
      // but it will trigger the catch block in speak()
      var completed = false;
      await service.speak('Hello', onComplete: () => completed = true);

      expect(completed, isTrue);
    });
  });
}
