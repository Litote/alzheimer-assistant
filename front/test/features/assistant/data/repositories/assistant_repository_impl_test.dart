import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alzheimer_assistant/features/assistant/data/repositories/assistant_repository_impl.dart';

// ── Mocks ──────────────────────────────────────────────────────────────────

class MockDio extends Mock implements Dio {}

// ── Helpers ────────────────────────────────────────────────────────────────

/// Builds a minimal [RequestOptions] for Dio objects
RequestOptions _opts([String path = '']) => RequestOptions(path: path);

/// Builds a successful [Response<String>] 200 for the /run_sse endpoint (SSE format).
Response<String> _runSuccess(String text) => Response<String>(
      data: 'data: {"content":{"role":"model","parts":[{"text":"$text"}]}}\n\n',
      statusCode: 200,
      requestOptions: _opts('/run_sse'),
    );

/// Multi-event ADK SSE response: fragmented text + tool call in between.
Response<String> _runSuccessMultiEvent(String part1, String part2) {
  final event1 =
      'data: {"content":{"role":"model","parts":[{"text":"$part1"},{"functionCall":{"name":"lookup","args":{}}}]}}\n\n';
  final event2 =
      'data: {"content":{"role":"model","parts":[{"functionResponse":{"name":"lookup","response":{}}}]}}\n\n';
  final event3 =
      'data: {"content":{"role":"model","parts":[{"text":"$part2"}]}}\n\n';
  return Response<String>(
    data: '$event1$event2$event3',
    statusCode: 200,
    requestOptions: _opts('/run_sse'),
  );
}

/// Builds a successful [Response] 200 for the /sessions endpoint
Response<dynamic> _sessionSuccess(String id) => Response<dynamic>(
      data: {'id': id},
      statusCode: 200,
      requestOptions: _opts('/sessions'),
    );

/// [DioException] 404 simulating an expired session on the ADK side
DioException dioException404(String path) => DioException(
      requestOptions: _opts(path),
      response: Response<dynamic>(
        statusCode: 404,
        requestOptions: _opts(path),
      ),
      type: DioExceptionType.badResponse,
    );

void main() {
  // SharedPreferences relies on a Flutter channel — required in unit tests.
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDio mockAdkDio;
  late MockDio mockElevenLabsDio;

  setUp(() {
    mockAdkDio = MockDio();
    mockElevenLabsDio = MockDio();

    // Fallback values required by mocktail for complex types
    registerFallbackValue(_opts());
    registerFallbackValue(Options());
  });

  // ── Normal success (no 404) ───────────────────────────────────────────────

  test('ask() returns the ADK text when /run responds 200', () async {
    SharedPreferences.setMockInitialValues({'adk_session_id': 'sess-ok'});

    when(() => mockAdkDio.post<String>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        )).thenAnswer((_) async => _runSuccess('Vos médicaments sont sur la table.'));

    // ElevenLabs returns empty bytes to keep the test simple
    when(() => mockElevenLabsDio.post<List<int>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        )).thenAnswer((_) async => Response<List<int>>(
          data: [],
          statusCode: 200,
          requestOptions: _opts(),
        ));

    final repo = AssistantRepositoryImpl(
      adkDio: mockAdkDio,
      elevenLabsDio: mockElevenLabsDio,
    );

    final response = await repo.ask('Où sont mes médicaments ?');
    expect(response.text, 'Vos médicaments sont sur la table.');
  });

  // ── Multi-event response (agent with tool calls) ──────────────────────────
  //
  // The agent can fragment its response: partial text → tool call →
  // tool response → final text. We must concatenate all fragments.

  test(
    'ask() concatenates text fragments from multiple ADK events',
    () async {
      SharedPreferences.setMockInitialValues({'adk_session_id': 'sess-ok'});

      when(() => mockAdkDio.post<String>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onSendProgress: any(named: 'onSendProgress'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => _runSuccessMultiEvent(
            'Vos médicaments',
            ' sont dans l\'armoire à pharmacie.',
          ));

      when(() => mockElevenLabsDio.post<List<int>>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onSendProgress: any(named: 'onSendProgress'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => Response<List<int>>(
            data: [],
            statusCode: 200,
            requestOptions: _opts(),
          ));

      final repo = AssistantRepositoryImpl(
        adkDio: mockAdkDio,
        elevenLabsDio: mockElevenLabsDio,
      );

      final response = await repo.ask('Où sont mes médicaments ?');
      expect(
        response.text,
        'Vos médicaments sont dans l\'armoire à pharmacie.',
      );
    },
  );

  // ── Fixed scenario: expired session → 404 → retry ─────────────────────────
  //
  // BEFORE fix: the 404 bubbled up directly as a generic exception,
  // the app displayed "Désolé, une erreur est survenue" and the session
  // stayed in the SharedPreferences cache → every subsequent call received a 404.
  //
  // AFTER fix: the 404 triggers _clearSession() + a retry with a
  // new session, transparent to the user.

  test(
    'ask(): 404 on /run → clears cached session and retries → success',
    () async {
      SharedPreferences.setMockInitialValues(
          {'adk_session_id': 'session-expiree'});

      var runCallCount = 0;

      // First /run call → 404 (session expired on the ADK in-memory side)
      // Second /run call → 200 (after new session)
      when(() => mockAdkDio.post<String>(
            any(that: contains('/run')),
            data: any(named: 'data'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onSendProgress: any(named: 'onSendProgress'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async {
        runCallCount++;
        if (runCallCount == 1) throw dioException404('/run');
        return _runSuccess('Nouvelle réponse après retry');
      });

      // /sessions call during retry (to create a new session)
      when(() => mockAdkDio.post<dynamic>(
            any(that: contains('/sessions')),
            data: any(named: 'data'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onSendProgress: any(named: 'onSendProgress'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => _sessionSuccess('session-nouvelle'));

      when(() => mockElevenLabsDio.post<List<int>>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onSendProgress: any(named: 'onSendProgress'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => Response<List<int>>(
            data: [],
            statusCode: 200,
            requestOptions: _opts(),
          ));

      final repo = AssistantRepositoryImpl(
        adkDio: mockAdkDio,
        elevenLabsDio: mockElevenLabsDio,
      );

      final response = await repo.ask('Bonjour');

      expect(response.text, 'Nouvelle réponse après retry');
      expect(runCallCount, 2, reason: '/run must be called exactly 2 times');

      // Verify that the expired session was properly cleared from preferences
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString('adk_session_id'),
        'session-nouvelle',
        reason: 'The new session must be persisted after the retry',
      );
    },
  );

  // ── Retry also fails → exception bubbles up ───────────────────────────────
  //
  // Guarantees that the isRetry=true flag blocks the infinite loop:
  // if the second call also receives a 404, we do not retry a 3rd time.

  test(
    'ask(): persistent 404 on /run (even after retry) → rethrow',
    () async {
      SharedPreferences.setMockInitialValues(
          {'adk_session_id': 'session-expiree'});

      // Both /run calls return 404
      when(() => mockAdkDio.post<String>(
            any(that: contains('/run')),
            data: any(named: 'data'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onSendProgress: any(named: 'onSendProgress'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenThrow(dioException404('/run'));

      // /sessions for the retry
      when(() => mockAdkDio.post<dynamic>(
            any(that: contains('/sessions')),
            data: any(named: 'data'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onSendProgress: any(named: 'onSendProgress'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => _sessionSuccess('session-nouvelle'));

      final repo = AssistantRepositoryImpl(
        adkDio: mockAdkDio,
        elevenLabsDio: mockElevenLabsDio,
      );

      await expectLater(
        () => repo.ask('Bonjour'),
        throwsA(isA<DioException>()),
        reason: 'A persistent 404 must bubble up, not loop indefinitely',
      );
    },
  );

  // ── Session creation failure → exception propagated ──────────────────────
  //
  // Before fix: _getSessionId() returned 'temp_session' on /sessions error,
  // masking the problem and entering a 404 loop.
  // After fix: the exception bubbles up directly.

  test(
    'ask(): session creation failure (no cached session) → rethrow',
    () async {
      SharedPreferences.setMockInitialValues({});

      // /sessions fails
      when(() => mockAdkDio.post<dynamic>(
            any(that: contains('/sessions')),
            data: any(named: 'data'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onSendProgress: any(named: 'onSendProgress'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenThrow(Exception('timeout'));

      final repo = AssistantRepositoryImpl(
        adkDio: mockAdkDio,
        elevenLabsDio: mockElevenLabsDio,
      );

      await expectLater(
        () => repo.ask('Bonjour'),
        throwsA(isA<Exception>()),
        reason:
            'A session creation failure must bubble up as an exception, not return temp_session',
      );
    },
  );

  // ── ADK returns empty text → fallback message ─────────────────────────────
  //
  // If the model produces no text fragment (e.g. pure tool response),
  // the repository must return 'Pas de réponse reçue' rather than an empty
  // string that would leave the UI silent.

  test('ask(): ADK returns empty text → returns the fallback message', () async {
    SharedPreferences.setMockInitialValues({'adk_session_id': 'sess-ok'});

    // SSE response with no text fragment
    when(() => mockAdkDio.post<String>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        )).thenAnswer((_) async => Response<String>(
          data: 'data: {"content":{"role":"model","parts":[{"functionCall":{"name":"lookup"}}]}}\n\n',
          statusCode: 200,
          requestOptions: _opts('/run_sse'),
        ));

    when(() => mockElevenLabsDio.post<List<int>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        )).thenAnswer((_) async => Response<List<int>>(
          data: [],
          statusCode: 200,
          requestOptions: _opts(),
        ));

    final repo = AssistantRepositoryImpl(
      adkDio: mockAdkDio,
      elevenLabsDio: mockElevenLabsDio,
    );

    final response = await repo.ask('Bonjour');
    expect(
      response.text,
      'Pas de réponse reçue',
      reason: 'Empty text must be replaced by the fallback message',
    );
  });

  // ── Session response as a List ─────────────────────────────────────────────
  //
  // Some ADK versions return a JSON array for the session endpoint.
  // The first element's 'id' field must be extracted.

  test(
    '_getSessionId(): server returns List → extracts first element id',
    () async {
      SharedPreferences.setMockInitialValues({});

      when(() => mockAdkDio.post<dynamic>(
            any(that: contains('/sessions')),
            data: any(named: 'data'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onSendProgress: any(named: 'onSendProgress'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => Response<dynamic>(
            data: [
              {'id': 'sess-from-list'}
            ],
            statusCode: 200,
            requestOptions: _opts('/sessions'),
          ));

      when(() => mockAdkDio.post<String>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onSendProgress: any(named: 'onSendProgress'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => _runSuccess('ok'));

      when(() => mockElevenLabsDio.post<List<int>>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onSendProgress: any(named: 'onSendProgress'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => Response<List<int>>(
            data: [],
            statusCode: 200,
            requestOptions: _opts(),
          ));

      final repo = AssistantRepositoryImpl(
        adkDio: mockAdkDio,
        elevenLabsDio: mockElevenLabsDio,
      );
      final response = await repo.ask('test');
      expect(response.text, 'ok');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('adk_session_id'), 'sess-from-list');
    },
  );

  // ── Session response with sessionId key ───────────────────────────────────

  test(
    '_getSessionId(): server returns Map with sessionId key',
    () async {
      SharedPreferences.setMockInitialValues({});

      when(() => mockAdkDio.post<dynamic>(
            any(that: contains('/sessions')),
            data: any(named: 'data'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onSendProgress: any(named: 'onSendProgress'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => Response<dynamic>(
            data: {'sessionId': 'sess-alt-key'},
            statusCode: 200,
            requestOptions: _opts('/sessions'),
          ));

      when(() => mockAdkDio.post<String>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onSendProgress: any(named: 'onSendProgress'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => _runSuccess('ok'));

      when(() => mockElevenLabsDio.post<List<int>>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onSendProgress: any(named: 'onSendProgress'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => Response<List<int>>(
            data: [],
            statusCode: 200,
            requestOptions: _opts(),
          ));

      final repo = AssistantRepositoryImpl(
        adkDio: mockAdkDio,
        elevenLabsDio: mockElevenLabsDio,
      );
      await repo.ask('test');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('adk_session_id'), 'sess-alt-key');
    },
  );

  // ── Unexpected session response format ─────────────────────────────────────

  test(
    '_getSessionId(): unexpected response format → throws Exception',
    () async {
      SharedPreferences.setMockInitialValues({});

      when(() => mockAdkDio.post<dynamic>(
            any(that: contains('/sessions')),
            data: any(named: 'data'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onSendProgress: any(named: 'onSendProgress'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => Response<dynamic>(
            data: 42, // unexpected integer type
            statusCode: 200,
            requestOptions: _opts('/sessions'),
          ));

      final repo = AssistantRepositoryImpl(
        adkDio: mockAdkDio,
        elevenLabsDio: mockElevenLabsDio,
      );

      await expectLater(
        () => repo.ask('test'),
        throwsA(isA<Exception>()),
        reason: 'Unexpected session format must throw an Exception',
      );
    },
  );

  // ── call_phone stateDelta action ───────────────────────────────────────────
  //
  // When the ADK SSE contains a stateDelta with action.type == 'call_phone',
  // the repository must extract the contact name and return it.

  test('ask(): SSE with call_phone stateDelta → returns callPhoneName',
      () async {
    SharedPreferences.setMockInitialValues({'adk_session_id': 'sess-ok'});

    const sseBody =
        'data: {"content":{"role":"model","parts":[{"text":"Je vais appeler Maman"}]},"actions":{"stateDelta":{"action":{"type":"call_phone","payload":{"name":"Maman"}}}}}\n\n';

    when(() => mockAdkDio.post<String>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        )).thenAnswer((_) async => Response<String>(
          data: sseBody,
          statusCode: 200,
          requestOptions: _opts('/run_sse'),
        ));

    when(() => mockElevenLabsDio.post<List<int>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        )).thenAnswer((_) async => Response<List<int>>(
          data: [],
          statusCode: 200,
          requestOptions: _opts(),
        ));

    final repo = AssistantRepositoryImpl(
      adkDio: mockAdkDio,
      elevenLabsDio: mockElevenLabsDio,
    );

    final response = await repo.ask('Appelle maman');
    expect(response.callPhoneName, 'Maman');
  });

  // ── Malformed JSON in SSE ──────────────────────────────────────────────────
  //
  // Parse errors on individual SSE events must be swallowed.
  // Valid subsequent events must still be processed.

  test(
    'ask(): malformed JSON in SSE → skipped, returns valid text from other events',
    () async {
      SharedPreferences.setMockInitialValues({'adk_session_id': 'sess-ok'});

      const sseBody =
          'data: {invalid json}\ndata: {"content":{"role":"model","parts":[{"text":"Bonjour"}]}}\n\n';

      when(() => mockAdkDio.post<String>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onSendProgress: any(named: 'onSendProgress'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => Response<String>(
            data: sseBody,
            statusCode: 200,
            requestOptions: _opts('/run_sse'),
          ));

      when(() => mockElevenLabsDio.post<List<int>>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onSendProgress: any(named: 'onSendProgress'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => Response<List<int>>(
            data: [],
            statusCode: 200,
            requestOptions: _opts(),
          ));

      final repo = AssistantRepositoryImpl(
        adkDio: mockAdkDio,
        elevenLabsDio: mockElevenLabsDio,
      );

      final response = await repo.ask('Bonjour');
      expect(response.text, 'Bonjour');
    },
  );

  // ── partial=true event ─────────────────────────────────────────────────────
  //
  // SSE events with partial=true must not be appended to the text buffer.

  test(
    '_appendModelTexts(): partial=true event → text not appended',
    () async {
      SharedPreferences.setMockInitialValues({'adk_session_id': 'sess-ok'});

      // First event has partial=true — must be skipped.
      // Second event has no partial flag — must be included.
      const sseBody =
          'data: {"content":{"role":"model","parts":[{"text":"partiel"}]},"partial":true}\n\n'
          'data: {"content":{"role":"model","parts":[{"text":"final"}]}}\n\n';

      when(() => mockAdkDio.post<String>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onSendProgress: any(named: 'onSendProgress'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => Response<String>(
            data: sseBody,
            statusCode: 200,
            requestOptions: _opts('/run_sse'),
          ));

      when(() => mockElevenLabsDio.post<List<int>>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onSendProgress: any(named: 'onSendProgress'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => Response<List<int>>(
            data: [],
            statusCode: 200,
            requestOptions: _opts(),
          ));

      final repo = AssistantRepositoryImpl(
        adkDio: mockAdkDio,
        elevenLabsDio: mockElevenLabsDio,
      );

      final response = await repo.ask('test');
      expect(
        response.text,
        'final',
        reason: 'Only non-partial events must contribute to the final text',
      );
    },
  );
}
