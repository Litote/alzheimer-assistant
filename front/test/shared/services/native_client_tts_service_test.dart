import 'package:alzheimer_assistant/shared/services/native_client_tts_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mocktail/mocktail.dart';

class MockFlutterTts extends Mock implements FlutterTts {}

void main() {
  late MockFlutterTts mockTts;
  late NativeClientTtsService service;

  setUpAll(() {
    registerFallbackValue(() {});
    registerFallbackValue((dynamic msg) {});
  });

  setUp(() {
    mockTts = MockFlutterTts();
    service = NativeClientTtsService(tts: mockTts);

    when(() => mockTts.setLanguage(any())).thenAnswer((_) async => 1);
    when(() => mockTts.setSpeechRate(any())).thenAnswer((_) async => 1);
    when(() => mockTts.setVolume(any())).thenAnswer((_) async => 1);
    when(() => mockTts.setPitch(any())).thenAnswer((_) async => 1);
    when(() => mockTts.stop()).thenAnswer((_) async => 1);
  });

  test('speak initialises and calls tts.speak', () async {
    when(() => mockTts.setCompletionHandler(any())).thenReturn(null);
    when(() => mockTts.setErrorHandler(any())).thenReturn(null);
    when(() => mockTts.speak(any())).thenAnswer((_) async => 1);
    
    await service.speak('Bonjour', onComplete: () {});

    verify(() => mockTts.setLanguage('fr-FR')).called(1);
    verify(() => mockTts.setSpeechRate(0.45)).called(1);
    verify(() => mockTts.setCompletionHandler(any())).called(1);
    verify(() => mockTts.setErrorHandler(any())).called(1);
    verify(() => mockTts.speak('Bonjour')).called(1);
  });

  test('speak calls onComplete when tts.speak throws', () async {
    when(() => mockTts.setCompletionHandler(any())).thenReturn(null);
    when(() => mockTts.setErrorHandler(any())).thenReturn(null);
    when(() => mockTts.speak(any())).thenThrow(Exception('error'));
    
    var completed = false;
    await service.speak('Bonjour', onComplete: () => completed = true);

    expect(completed, isTrue);
  });

  test('stop calls tts.stop', () async {
    await service.stop();
    verify(() => mockTts.stop()).called(1);
  });

  test('dispose calls tts.stop', () async {
    await service.dispose();
    verify(() => mockTts.stop()).called(1);
  });

  test('completion handler triggers onComplete', () async {
    void Function()? capturedOnComplete;
    when(() => mockTts.setCompletionHandler(any())).thenAnswer((invocation) {
      capturedOnComplete = invocation.positionalArguments[0] as void Function();
    });
    when(() => mockTts.setErrorHandler(any())).thenReturn(null);
    when(() => mockTts.speak(any())).thenAnswer((_) async => 1);

    var completed = false;
    await service.speak('Bonjour', onComplete: () => completed = true);

    expect(capturedOnComplete, isNotNull);
    capturedOnComplete!();
    expect(completed, isTrue);
  });

  test('error handler triggers onComplete', () async {
    void Function(dynamic)? capturedOnError;
    when(() => mockTts.setErrorHandler(any())).thenAnswer((invocation) {
      capturedOnError = invocation.positionalArguments[0] as void Function(dynamic);
    });
    when(() => mockTts.setCompletionHandler(any())).thenReturn(null);
    when(() => mockTts.speak(any())).thenAnswer((_) async => 1);

    var completed = false;
    await service.speak('Bonjour', onComplete: () => completed = true);

    expect(capturedOnError, isNotNull);
    capturedOnError!('some error');
    expect(completed, isTrue);
  });
}
