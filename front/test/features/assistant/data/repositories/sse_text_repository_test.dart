import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:alzheimer_assistant/features/assistant/data/repositories/sse_text_repository.dart';
import 'package:alzheimer_assistant/features/assistant/domain/entities/live_event.dart';

// ── Helpers ────────────────────────────────────────────────────────────────

/// Builds an SSE line for a given JSON payload.
String _sseLine(Map<String, dynamic> json) => 'data: ${jsonEncode(json)}';

/// Creates a [SseTextRepository] whose fetch function returns [lines].
SseTextRepository _makeRepo(List<String> lines) {
  return SseTextRepository(
    fetchFn: (_, __) => Stream.fromIterable(lines),
  );
}

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  // ── connect() ─────────────────────────────────────────────────────────────

  test('connect() returns a stream that immediately emits sessionEstablished', () async {
    final repo = _makeRepo([]);
    final events = <LiveEvent>[];
    repo.connect(sessionId: 'sess-abc').listen(events.add);
    await Future<void>.delayed(Duration.zero);

    expect(events, [const LiveEvent.sessionEstablished('sess-abc')]);
  });

  test('connect() emits events from sendText() after sessionEstablished', () async {
    final repo = _makeRepo([
      _sseLine({
        'content': {'role': 'model', 'parts': [{'text': 'Pong'}]},
        'invocationId': 'x',
        'author': 'agent',
      }),
    ]);

    final events = <LiveEvent>[];
    repo.connect(sessionId: 's1').listen(events.add);
    repo.sendText('Ping');

    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(events.first, const LiveEvent.sessionEstablished('s1'));
    expect(events, containsAll([
      const LiveEvent.outputTranscription('Pong'),
      const LiveEvent.turnComplete(),
    ]));
  });

  test('connect() with sessionId forwards it in the POST body', () async {
    Uri? capturedUri;
    String? capturedBody;

    final repo = SseTextRepository(
      fetchFn: (uri, body) {
        capturedUri = uri;
        capturedBody = body;
        return const Stream.empty();
      },
    );

    repo.connect(sessionId: 'sess-99');
    repo.sendText('hello');
    await Future<void>.delayed(Duration.zero);

    expect(capturedUri?.path, contains('run_sse'));
    final decoded = jsonDecode(capturedBody!) as Map<String, dynamic>;
    expect(decoded['session_id'], 'sess-99');
  });

  test('connect() without sessionId generates one automatically', () async {
    String? capturedBody;

    final repo = SseTextRepository(
      fetchFn: (_, body) {
        capturedBody = body;
        return const Stream.empty();
      },
    );

    repo.connect();
    repo.sendText('hello');
    await Future<void>.delayed(Duration.zero);

    final decoded = jsonDecode(capturedBody!) as Map<String, dynamic>;
    expect(decoded['session_id'], isA<String>());
    expect((decoded['session_id'] as String).isNotEmpty, isTrue);
  });

  // ── sendText() ─────────────────────────────────────────────────────────────

  test('sendText() posts new_message with role user and text', () async {
    Map<String, dynamic>? capturedBody;

    final repo = SseTextRepository(
      fetchFn: (_, body) {
        capturedBody = jsonDecode(body) as Map<String, dynamic>;
        return const Stream.empty();
      },
    );

    repo.connect();
    repo.sendText('Appelle maman');
    await Future<void>.delayed(Duration.zero);

    expect(capturedBody!['new_message'], {
      'role': 'user',
      'parts': [
        {'text': 'Appelle maman'},
      ],
    });
    expect(capturedBody!['streaming'], false);
  });

  // ── sendToolResponse() ─────────────────────────────────────────────────────

  test('sendToolResponse() posts functionResponse part', () async {
    Map<String, dynamic>? capturedBody;

    final repo = SseTextRepository(
      fetchFn: (_, body) {
        capturedBody = jsonDecode(body) as Map<String, dynamic>;
        return const Stream.empty();
      },
    );

    repo.connect();
    repo.sendToolResponse(
      callId: 'call-1',
      functionName: 'call_phone',
      result: 'Marie appelée.',
    );
    await Future<void>.delayed(Duration.zero);

    final parts =
        (capturedBody!['new_message']['parts'] as List).first as Map;
    final fn = parts['functionResponse'] as Map;
    expect(fn['id'], 'call-1');
    expect(fn['name'], 'call_phone');
    expect(fn['response']['status'], 'Marie appelée.');
  });

  // ── event parsing ──────────────────────────────────────────────────────────

  test('parses ADK turnComplete', () async {
    final repo = _makeRepo([
      _sseLine({'turnComplete': true, 'invocationId': 'x', 'author': 'agent'}),
    ]);

    final events = await _collectEvents(repo);
    expect(events, [const LiveEvent.turnComplete()]);
  });

  test('emits implicit turnComplete when stream ends after content', () async {
    final repo = _makeRepo([
      _sseLine({
        'content': {'role': 'model', 'parts': [{'text': 'Bonjour'}]},
        'invocationId': 'x',
        'author': 'agent',
      }),
    ]);

    final events = await _collectEvents(repo);
    expect(events, [
      const LiveEvent.outputTranscription('Bonjour'),
      const LiveEvent.turnComplete(),
    ]);
  });

  test('does not emit implicit turnComplete when stream ends with no content', () async {
    final repo = _makeRepo([
      _sseLine({'invocationId': 'x', 'author': 'agent', 'actions': {}}),
    ]);

    final events = await _collectRaw(repo);
    expect(events, isEmpty);
  });

  test('parses content.parts[].text as outputTranscription', () async {
    final repo = _makeRepo([
      _sseLine({
        'content': {'role': 'model', 'parts': [{'text': 'Bonjour !'}]},
        'invocationId': 'x',
        'author': 'agent',
      }),
    ]);

    final events = await _collectEvents(repo);
    expect(events, [
      const LiveEvent.outputTranscription('Bonjour !'),
      const LiveEvent.turnComplete(),
    ]);
  });

  test('concatenates multiple text parts into one outputTranscription', () async {
    final repo = _makeRepo([
      _sseLine({
        'content': {
          'role': 'model',
          'parts': [{'text': 'Bonjour'}, {'text': ' !'}],
        },
        'invocationId': 'x',
        'author': 'agent',
      }),
    ]);

    final events = await _collectEvents(repo);
    expect(events, [
      const LiveEvent.outputTranscription('Bonjour !'),
      const LiveEvent.turnComplete(),
    ]);
  });

  test('ADK events without content or turnComplete are silently dropped', () async {
    final repo = _makeRepo([
      _sseLine({'invocationId': 'x', 'author': 'agent', 'actions': {}}),
      _sseLine({'turnComplete': true}),
    ]);

    final events = await _collectEvents(repo);
    expect(events, [const LiveEvent.turnComplete()]);
  });

  test('parses phone_event tool_status', () async {
    final repo = _makeRepo([
      _sseLine({
        'phone_event': {'type': 'tool_status', 'name': 'phone', 'label': 'Appel en cours'},
      }),
    ]);

    final events = await _collectRaw(repo);
    expect(events, [const LiveEvent.toolStatus('Appel en cours')]);
  });

  test('parses phone_event phone_call', () async {
    final repo = _makeRepo([
      _sseLine({
        'phone_event': {
          'type': 'phone_call',
          'call_id': 'cid-1',
          'args': {'name': 'Marie', 'exactMatch': true},
        },
      }),
    ]);

    final events = await _collectRaw(repo);
    expect(events, [
      const LiveEvent.callPhone(
        callId: 'cid-1',
        contactName: 'Marie',
        exactMatch: true,
      ),
    ]);
  });

  test('phone_event phone_call with contact_name field', () async {
    final repo = _makeRepo([
      _sseLine({
        'phone_event': {
          'type': 'phone_call',
          'call_id': 'cid-2',
          'args': {'contact_name': 'Paul', 'exact_match': false},
        },
      }),
    ]);

    final events = await _collectRaw(repo);
    expect(events, [
      const LiveEvent.callPhone(
        callId: 'cid-2',
        contactName: 'Paul',
        exactMatch: false,
      ),
    ]);
  });

  test('parses image_url frame', () async {
    final repo = _makeRepo([
      _sseLine({'image_url': 'https://example.com/photo.jpg'}),
    ]);

    final events = await _collectRaw(repo);
    expect(events, [const LiveEvent.imageUrl('https://example.com/photo.jpg')]);
  });

  test('image_url frame with empty string is silently dropped', () async {
    final repo = _makeRepo([
      _sseLine({'image_url': ''}),
    ]);

    final events = await _collectRaw(repo);
    expect(events, isEmpty);
  });

  test('skips non-data lines and [DONE]', () async {
    final repo = _makeRepo([
      'event: message',
      '',
      _sseLine({'content': {'role': 'model', 'parts': [{'text': 'Hi'}]}}),
      'data: [DONE]',
    ]);

    final events = await _collectEvents(repo);
    expect(events, [
      const LiveEvent.outputTranscription('Hi'),
      const LiveEvent.turnComplete(),
    ]);
  });

  test('skips malformed JSON without throwing', () async {
    final repo = _makeRepo([
      'data: not-valid-json',
      _sseLine({'content': {'role': 'model', 'parts': [{'text': 'Hi'}]}}),
    ]);

    final events = await _collectEvents(repo);
    expect(events, [
      const LiveEvent.outputTranscription('Hi'),
      const LiveEvent.turnComplete(),
    ]);
  });

  test('unrecognized events are silently dropped', () async {
    final repo = _makeRepo([
      _sseLine({'invocationId': 'x', 'author': 'agent'}),
      _sseLine({'content': {'role': 'model', 'parts': [{'text': 'Hi'}]}}),
    ]);

    final events = await _collectEvents(repo);
    expect(events, [
      const LiveEvent.outputTranscription('Hi'),
      const LiveEvent.turnComplete(),
    ]);
  });

  // ── disconnect() ──────────────────────────────────────────────────────────

  test('disconnect() closes the stream', () async {
    final repo = _makeRepo([]);
    final stream = repo.connect();
    var done = false;
    stream.listen((_) {}, onDone: () => done = true);

    await repo.disconnect();
    await Future<void>.delayed(Duration.zero);

    expect(done, isTrue);
  });

  test('sendText() after disconnect() is a no-op', () async {
    int callCount = 0;
    final repo = SseTextRepository(
      fetchFn: (_, __) {
        callCount++;
        return const Stream.empty();
      },
    );

    repo.connect();
    await repo.disconnect();
    repo.sendText('hello');
    await Future<void>.delayed(Duration.zero);

    expect(callCount, 0);
  });

  // ── error propagation ─────────────────────────────────────────────────────

  test('fetch error is forwarded to stream as error', () async {
    final repo = SseTextRepository(
      fetchFn: (_, __) => Stream.error(Exception('network error')),
    );

    final completer = Completer<Object>();
    repo.connect().listen((_) {}, onError: completer.complete);
    repo.sendText('test');

    final caught = await completer.future.timeout(const Duration(seconds: 5));
    expect(caught, isA<Exception>());
  });
}

// ── Helper ─────────────────────────────────────────────────────────────────

/// Sends one [sendText] call and waits until [turnComplete] is received (or
/// times out). Filters out [sessionEstablished] emitted by [connect()].
Future<List<LiveEvent>> _collectEvents(SseTextRepository repo) async {
  final events = <LiveEvent>[];
  final completer = Completer<void>();

  repo.connect().listen(
    (event) {
      events.add(event);
      if (event is LiveTurnComplete && !completer.isCompleted) {
        completer.complete();
      }
    },
    onDone: () {
      if (!completer.isCompleted) completer.complete();
    },
    onError: (Object e) {
      if (!completer.isCompleted) completer.completeError(e);
    },
  );
  repo.sendText('test');

  await completer.future.timeout(const Duration(seconds: 5));
  return events.where((e) => e is! LiveSessionEstablished).toList();
}

/// Sends one [sendText] call and collects events with a short delay.
/// Use for tests where no [turnComplete] is expected (e.g., phone events).
Future<List<LiveEvent>> _collectRaw(SseTextRepository repo) async {
  final events = <LiveEvent>[];
  repo.connect().listen(events.add);
  repo.sendText('test');
  await Future<void>.delayed(const Duration(milliseconds: 20));
  return events.where((e) => e is! LiveSessionEstablished).toList();
}
