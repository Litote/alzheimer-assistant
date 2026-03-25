import 'package:dio/dio.dart';

const String _kResponseText = 'Vos médicaments sont sur la table de nuit.';

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
              'data: {"content":{"parts":[{"text":"$_kResponseText"}]}}\n\n';

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
