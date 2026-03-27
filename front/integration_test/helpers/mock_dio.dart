import 'package:dio/dio.dart';

const String _kResponseText = 'Vos médicaments sont sur la table de nuit.';

// ── Disambiguation scenario ──────────────────────────────────────────────────

/// Agent texts used by [makeMockAdkDioForDisambiguation].
/// Exported so the test file can assert on them without duplicating the strings.
const String kDisambiguationAgentQuestion =
    'Souhaitez-vous appeler Marie Dupont ou Marie Martin ?';
const String kCallConfirmationAgentText =
    "J'appelle Marie Dupont. Bonne conversation !";

String _callPhoneSseBody(String text, String contactName) =>
    'data: {"content":{"role":"model","parts":[{"text":"$text"}]},'
    '"actions":{"stateDelta":{"action":{"type":"call_phone","payload":{"name":"$contactName"}}}}}\n\n';

String _textOnlySseBody(String text) =>
    'data: {"content":{"role":"model","parts":[{"text":"$text"}]}}\n\n';

/// ADK mock for the [phone] feedback loop (4 sequential /run_sse calls):
///
/// 1. "Appelle Marie"              → call_phone("Marie")         [text ignored by BLoC]
/// 2. "[phone] plusieurs…"     → disambiguation question      [spoken by TTS]
/// 3. "Marie Dupont"               → call_phone("Marie Dupont")  [text ignored by BLoC]
/// 4. "[phone] Marie Dupont…"  → confirmation text            [spoken by TTS]
Dio makeMockAdkDioForDisambiguation() {
  final dio = Dio(BaseOptions(baseUrl: 'http://mock-adk'));
  var runCallCount = 0;

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final path = options.path;

        if (path.contains('sessions')) {
          handler.resolve(Response<dynamic>(
            data: {'id': 'e2e-session-disambiguation'},
            statusCode: 200,
            requestOptions: options,
          ));
          return;
        }

        if (path.contains('/run_sse')) {
          runCallCount++;
          final body = switch (runCallCount) {
            1 => _callPhoneSseBody('...', 'Marie'),
            2 => _textOnlySseBody(kDisambiguationAgentQuestion),
            3 => _callPhoneSseBody('...', 'Marie Dupont'),
            _ => _textOnlySseBody(kCallConfirmationAgentText),
          };
          handler.resolve(Response<String>(
            data: body,
            statusCode: 200,
            requestOptions: options,
          ));
          return;
        }

        handler.next(options);
      },
    ),
  );

  return dio;
}

/// In-memory Dio interceptor for the ADK — no real network requests.
///
/// [simulate404OnFirstRun] reproduces the "session expired in memory" scenario:
/// the first /run call receives a 404, forcing the code to clear the session and
/// retry. The second call succeeds.
Dio makeMockAdkDio({bool simulate404OnFirstRun = false}) {
  final dio = Dio(BaseOptions(baseUrl: 'http://mock-adk'));
  var runCallCount = 0;

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final path = options.path;

        // ── /sessions ───────────────────────────────────────────────────────
        if (path.contains('sessions')) {
          handler.resolve(Response<dynamic>(
            data: {'id': 'e2e-session-${DateTime.now().millisecondsSinceEpoch}'},
            statusCode: 200,
            requestOptions: options,
          ));
          return;
        }

        // ── /run_sse ──────────────────────────────────────────────────────────
        if (path.contains('/run_sse')) {
          runCallCount++;

          if (simulate404OnFirstRun && runCallCount == 1) {
            // Simulates a session that disappeared on the ADK side (in-memory restart)
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response<dynamic>(
                  statusCode: 404,
                  requestOptions: options,
                ),
                type: DioExceptionType.badResponse,
              ),
              true, // callFollowingErrorInterceptor = false
            );
            return;
          }

          // SSE body in plain text format — identical to the real wire format.
          final sseBody =
              'data: {"content":{"role":"model","parts":[{"text":"$_kResponseText"}]}}\n\n';

          handler.resolve(Response<String>(
            data: sseBody,
            statusCode: 200,
            requestOptions: options,
          ));
          return;
        }

        // Unknown request — pass through (should not happen)
        handler.next(options);
      },
    ),
  );

  return dio;
}

/// Dio for ElevenLabs: immediately returns empty bytes.
/// The real ElevenLabs call is not needed in E2E because FakeTtsService
/// plays nothing — we just want _synthesizeSpeech() not to throw.
Dio makeMockElevenLabsDio() {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.resolve(Response<List<int>>(
          data: <int>[],
          statusCode: 200,
          requestOptions: options,
        ));
      },
    ),
  );
  return dio;
}
