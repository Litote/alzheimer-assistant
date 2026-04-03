import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:alzheimer_assistant/shared/services/speech_recognition_service.dart';

// ── Mock ────────────────────────────────────────────────────────────────────

class MockSpeechToText extends Mock implements SpeechToText {}

// ── Helpers ─────────────────────────────────────────────────────────────────

SpeechRecognitionResult _result(String words, {bool isFinal = true}) =>
    SpeechRecognitionResult(
      [SpeechRecognitionWords(words, null, 1.0)],
      isFinal,
    );

/// Stubs [mock.listen] to immediately invoke [onResult] with [result].
void _stubListen(MockSpeechToText mock, SpeechRecognitionResult result) {
  when(
    () => mock.listen(
      onResult: any(named: 'onResult'),
      localeId: any(named: 'localeId'),
      pauseFor: any(named: 'pauseFor'),
      listenFor: any(named: 'listenFor'),
      listenOptions: any(named: 'listenOptions'),
    ),
  ).thenAnswer((invocation) async {
    final cb = invocation.namedArguments[const Symbol('onResult')]
        as void Function(SpeechRecognitionResult)?;
    cb?.call(result);
  });
}

void main() {
  late MockSpeechToText mockStt;

  setUp(() {
    mockStt = MockSpeechToText();
    when(() => mockStt.stop()).thenAnswer((_) async {});
    when(() => mockStt.cancel()).thenAnswer((_) async => true);
  });

  // ── initialize ────────────────────────────────────────────────────────────

  test('initialize: delegates to stt and returns false when unavailable', () async {
    when(
      () => mockStt.initialize(onError: any(named: 'onError')),
    ).thenAnswer((_) async => false);
    final service = SpeechRecognitionService(stt: mockStt);

    final result = await service.initialize();

    expect(result, isFalse);
    verify(() => mockStt.initialize(onError: any(named: 'onError'))).called(1);
  });

  test('initialize: called twice, stt.initialize called only once', () async {
    when(
      () => mockStt.initialize(onError: any(named: 'onError')),
    ).thenAnswer((_) async => true);
    final service = SpeechRecognitionService(stt: mockStt);

    await service.initialize();
    final second = await service.initialize();

    expect(second, isTrue);
    verify(() => mockStt.initialize(onError: any(named: 'onError'))).called(1);
  });

  // ── startListening: initialize fails ──────────────────────────────────────

  test('startListening: initialize fails → calls onFinal with empty string', () async {
    when(
      () => mockStt.initialize(onError: any(named: 'onError')),
    ).thenAnswer((_) async => false);
    final service = SpeechRecognitionService(stt: mockStt);

    String? finalText;
    await service.startListening(
      onInterim: (_) {},
      onFinal: (t) => finalText = t,
    );

    expect(finalText, '');
    verifyNever(
      () => mockStt.listen(
        onResult: any(named: 'onResult'),
        localeId: any(named: 'localeId'),
        pauseFor: any(named: 'pauseFor'),
        listenFor: any(named: 'listenFor'),
        listenOptions: any(named: 'listenOptions'),
      ),
    );
  });

  // ── startListening: final result ──────────────────────────────────────────

  test('startListening: final result → calls onFinal with recognised words', () async {
    when(
      () => mockStt.initialize(onError: any(named: 'onError')),
    ).thenAnswer((_) async => true);
    _stubListen(mockStt, _result('Bonjour', isFinal: true));
    final service = SpeechRecognitionService(stt: mockStt);

    String? finalText;
    await service.startListening(
      onInterim: (_) {},
      onFinal: (t) => finalText = t,
    );

    expect(finalText, 'Bonjour');
  });

  // ── startListening: partial result ────────────────────────────────────────

  test('startListening: partial result → calls onInterim with recognised words', () async {
    when(
      () => mockStt.initialize(onError: any(named: 'onError')),
    ).thenAnswer((_) async => true);
    _stubListen(mockStt, _result('Bon', isFinal: false));
    final service = SpeechRecognitionService(stt: mockStt);

    String? interimText;
    await service.startListening(
      onInterim: (t) => interimText = t,
      onFinal: (_) {},
    );

    expect(interimText, 'Bon');
  });

  // ── startListening: listen throws ─────────────────────────────────────────

  test('startListening: listen throws → calls onFinal with empty string', () async {
    when(
      () => mockStt.initialize(onError: any(named: 'onError')),
    ).thenAnswer((_) async => true);
    when(
      () => mockStt.listen(
        onResult: any(named: 'onResult'),
        localeId: any(named: 'localeId'),
        pauseFor: any(named: 'pauseFor'),
        listenFor: any(named: 'listenFor'),
        listenOptions: any(named: 'listenOptions'),
      ),
    ).thenThrow(Exception('microphone unavailable'));
    final service = SpeechRecognitionService(stt: mockStt);

    String? finalText;
    await service.startListening(
      onInterim: (_) {},
      onFinal: (t) => finalText = t,
    );

    expect(finalText, '');
  });

  // ── startListening: timeout / no-match → calls onTimeout ─────────────────
  //
  // When Android fires error_speech_timeout or error_no_match the session
  // is stuck (cancelOnError: false). The service must stop the recogniser
  // and invoke onTimeout so the BLoC can reset to Idle without an error msg.

  test('error_speech_timeout → stops STT and calls onTimeout', () async {
    void Function(SpeechRecognitionError)? capturedOnError;
    when(
      () => mockStt.initialize(onError: any(named: 'onError')),
    ).thenAnswer((invocation) async {
      capturedOnError = invocation.namedArguments[const Symbol('onError')]
          as void Function(SpeechRecognitionError);
      return true;
    });
    when(
      () => mockStt.listen(
        onResult: any(named: 'onResult'),
        localeId: any(named: 'localeId'),
        pauseFor: any(named: 'pauseFor'),
        listenFor: any(named: 'listenFor'),
        listenOptions: any(named: 'listenOptions'),
      ),
    ).thenAnswer((_) async {});
    final service = SpeechRecognitionService(stt: mockStt);

    bool timeoutCalled = false;
    await service.startListening(
      onInterim: (_) {},
      onFinal: (_) {},
      onTimeout: () => timeoutCalled = true,
    );

    capturedOnError!(SpeechRecognitionError('error_speech_timeout', false));

    expect(timeoutCalled, isTrue);
    verify(() => mockStt.stop()).called(greaterThanOrEqualTo(1));
  });

  test('error_no_match → stops STT and calls onTimeout', () async {
    void Function(SpeechRecognitionError)? capturedOnError;
    when(
      () => mockStt.initialize(onError: any(named: 'onError')),
    ).thenAnswer((invocation) async {
      capturedOnError = invocation.namedArguments[const Symbol('onError')]
          as void Function(SpeechRecognitionError);
      return true;
    });
    when(
      () => mockStt.listen(
        onResult: any(named: 'onResult'),
        localeId: any(named: 'localeId'),
        pauseFor: any(named: 'pauseFor'),
        listenFor: any(named: 'listenFor'),
        listenOptions: any(named: 'listenOptions'),
      ),
    ).thenAnswer((_) async {});
    final service = SpeechRecognitionService(stt: mockStt);

    bool timeoutCalled = false;
    await service.startListening(
      onInterim: (_) {},
      onFinal: (_) {},
      onTimeout: () => timeoutCalled = true,
    );

    capturedOnError!(SpeechRecognitionError('error_no_match', false));

    expect(timeoutCalled, isTrue);
    verify(() => mockStt.stop()).called(greaterThanOrEqualTo(1));
  });

  test('other error codes → onTimeout NOT called', () async {
    void Function(SpeechRecognitionError)? capturedOnError;
    when(
      () => mockStt.initialize(onError: any(named: 'onError')),
    ).thenAnswer((invocation) async {
      capturedOnError = invocation.namedArguments[const Symbol('onError')]
          as void Function(SpeechRecognitionError);
      return true;
    });
    when(
      () => mockStt.listen(
        onResult: any(named: 'onResult'),
        localeId: any(named: 'localeId'),
        pauseFor: any(named: 'pauseFor'),
        listenFor: any(named: 'listenFor'),
        listenOptions: any(named: 'listenOptions'),
      ),
    ).thenAnswer((_) async {});
    final service = SpeechRecognitionService(stt: mockStt);

    bool timeoutCalled = false;
    await service.startListening(
      onInterim: (_) {},
      onFinal: (_) {},
      onTimeout: () => timeoutCalled = true,
    );

    capturedOnError!(SpeechRecognitionError('error_client', false));

    expect(timeoutCalled, isFalse);
  });

  // ── startListening: cancel before listen ──────────────────────────────────
  //
  // On Android, calling listen() while a previous SpeechRecognizer session is
  // still tearing down produces ERROR_CLIENT, which with cancelOnError:false
  // causes an infinite error/restart loop. Calling cancel() first forces the
  // native session to be destroyed before a new one is created.

  test('startListening: cancels any previous session before calling listen()', () async {
    when(() => mockStt.initialize(onError: any(named: 'onError')))
        .thenAnswer((_) async => true);
    _stubListen(mockStt, _result('Bonjour', isFinal: true));
    final service = SpeechRecognitionService(stt: mockStt);

    await service.startListening(onInterim: (_) {}, onFinal: (_) {});

    verify(() => mockStt.cancel()).called(1);
  });

  // ── stopListening ─────────────────────────────────────────────────────────

  test('stopListening: delegates to stt.stop()', () async {
    final service = SpeechRecognitionService(stt: mockStt);

    await service.stopListening();

    verify(() => mockStt.stop()).called(1);
  });

  // ── isListening ───────────────────────────────────────────────────────────

  test('isListening: delegates to stt.isListening', () {
    when(() => mockStt.isListening).thenReturn(true);
    final service = SpeechRecognitionService(stt: mockStt);

    expect(service.isListening, isTrue);
  });
}
