import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:alzheimer_assistant/features/assistant/data/repositories/ws_audio_repository.dart';
import 'package:alzheimer_assistant/features/assistant/domain/entities/live_event.dart';

// ── Fake WebSocket channel ─────────────────────────────────────────────────

class _FakeChannel implements WebSocketChannel {
  final _inController = StreamController<dynamic>();
  final _outController = StreamController<dynamic>();

  final List<dynamic> sent = [];

  void serverSend(String message) => _inController.add(message);

  @override
  Stream get stream => _inController.stream;

  @override
  WebSocketSink get sink => _FakeSink(_outController, sent);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeSink implements WebSocketSink {
  _FakeSink(this._controller, this.sent);
  final StreamController<dynamic> _controller;
  final List<dynamic> sent;

  @override
  void add(dynamic data) => sent.add(data);

  @override
  Future<dynamic> close([int? closeCode, String? closeReason]) async {
    await _controller.close();
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

// ── Helpers ────────────────────────────────────────────────────────────────

WsAudioRepository _makeRepo(_FakeChannel channel) => WsAudioRepository(
      channelFactory: (_) => channel,
    );

String _serverContent(Map<String, dynamic> content) =>
    jsonEncode({'server_content': content});

String _toolCall(String name, String callId, Map<String, dynamic> args) =>
    jsonEncode({
      'tool_call': {
        'function_calls': [
          {'id': callId, 'name': name, 'args': args}
        ],
      },
    });

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  // ── connect() sends setup message ─────────────────────────────────────────

  test('connect() sends setup message immediately', () async {
    final channel = _FakeChannel();
    final repo = _makeRepo(channel);

    repo.connect().listen((_) {});
    await Future<void>.delayed(Duration.zero);

    expect(channel.sent, hasLength(1));
    final setup = jsonDecode(channel.sent.first as String) as Map;
    expect(setup['setup'], isNotNull);
    expect(setup['setup']['app_name'], 'alzheimerassistant');
    expect(setup['setup']['use_elevenlabs'], false);
    expect(setup['setup'].containsKey('reply_text'), isFalse);
  });

  test('connect(useElevenLabs: true) sets use_elevenlabs in setup message', () async {
    final channel = _FakeChannel();
    final repo = _makeRepo(channel);

    repo.connect(useElevenLabs: true).listen((_) {});
    await Future<void>.delayed(Duration.zero);

    final setup = jsonDecode(channel.sent.first as String) as Map;
    expect(setup['setup']['use_elevenlabs'], true);
  });

  // ── textDelta (ignored) ───────────────────────────────────────────────────

  test('server text part → ignored (transcriptions used for display)', () async {
    final channel = _FakeChannel();
    final repo = _makeRepo(channel);

    final events = <LiveEvent>[];
    repo.connect().listen(events.add);
    await Future<void>.delayed(Duration.zero);

    channel.serverSend(_serverContent({
      'model_turn': {
        'parts': [
          {'text': 'Bonjour !'}
        ]
      },
      'turn_complete': false,
    }));

    await Future<void>.delayed(Duration.zero);

    expect(events, isEmpty);
  });

  // ── outputTranscription ───────────────────────────────────────────────────

  test('server output_transcription → LiveOutputTranscription', () async {
    final channel = _FakeChannel();
    final repo = _makeRepo(channel);

    final events = <LiveEvent>[];
    repo.connect().listen(events.add);
    await Future<void>.delayed(Duration.zero);

    channel.serverSend(jsonEncode({
      'output_transcription': {'text': 'Bonjour !'},
    }));

    await Future<void>.delayed(Duration.zero);

    expect(events, [const LiveEvent.outputTranscription('Bonjour !')]);
  });

  // ── audioChunk ────────────────────────────────────────────────────────────

  test('server audio inline_data → LiveAudioChunk', () async {
    final channel = _FakeChannel();
    final repo = _makeRepo(channel);

    final events = <LiveEvent>[];
    repo.connect().listen(events.add);
    await Future<void>.delayed(Duration.zero);

    final pcm = Uint8List.fromList([1, 2, 3, 4]);
    channel.serverSend(_serverContent({
      'model_turn': {
        'parts': [
          {
            'inline_data': {
              'mime_type': 'audio/pcm;rate=24000',
              'data': base64.encode(pcm),
            }
          }
        ]
      },
    }));

    await Future<void>.delayed(Duration.zero);

    expect(events, hasLength(1));
    final chunk = events.first as LiveAudioChunk;
    expect(chunk.bytes, pcm);
  });

  // ── turnComplete ──────────────────────────────────────────────────────────

  test('server turn_complete:true → LiveTurnComplete', () async {
    final channel = _FakeChannel();
    final repo = _makeRepo(channel);

    final events = <LiveEvent>[];
    repo.connect().listen(events.add);
    await Future<void>.delayed(Duration.zero);

    channel.serverSend(_serverContent({'turn_complete': true}));
    await Future<void>.delayed(Duration.zero);

    expect(events, [const LiveEvent.turnComplete()]);
  });

  // ── callPhone ────────────────────────────────────────────────────────────

  test('server tool_call call_phone → LiveCallPhone', () async {
    final channel = _FakeChannel();
    final repo = _makeRepo(channel);

    final events = <LiveEvent>[];
    repo.connect().listen(events.add);
    await Future<void>.delayed(Duration.zero);

    channel.serverSend(_toolCall('call_phone', 'c-42', {
      'contact_name': 'Maman',
      'exact_match': true,
    }));
    await Future<void>.delayed(Duration.zero);

    expect(events, hasLength(1));
    expect(events.first, isA<LiveCallPhone>());
    final call = events.first as LiveCallPhone;
    expect(call.callId, 'c-42');
    expect(call.contactName, 'Maman');
    expect(call.exactMatch, isTrue);
  });

  // ── sendAudio encodes base64 ──────────────────────────────────────────────

  test('sendAudio() sends realtime_input with base64-encoded PCM', () async {
    final channel = _FakeChannel();
    final repo = _makeRepo(channel);

    repo.connect().listen((_) {});
    await Future<void>.delayed(Duration.zero);

    final pcm = Uint8List.fromList([10, 20, 30]);
    repo.sendAudio(pcm);

    expect(channel.sent, hasLength(2)); // setup + audio
    final msg = jsonDecode(channel.sent[1] as String) as Map;
    final chunk =
        (msg['realtime_input']['media_chunks'] as List).first as Map;
    expect(chunk['mime_type'], 'audio/pcm;rate=16000');
    expect(base64.decode(chunk['data'] as String), pcm);
  });

  // ── sendToolResponse ──────────────────────────────────────────────────────

  test('sendToolResponse() sends tool_response with correct fields', () async {
    final channel = _FakeChannel();
    final repo = _makeRepo(channel);

    repo.connect().listen((_) {});
    await Future<void>.delayed(Duration.zero);
    repo.sendToolResponse(
      callId: 'c-1',
      functionName: 'call_phone',
      result: 'Maman appelée.',
    );

    final msg = jsonDecode(channel.sent[1] as String) as Map;
    final response =
        (msg['tool_response']['function_responses'] as List).first as Map;
    expect(response['id'], 'c-1');
    expect(response['name'], 'call_phone');
    expect(response['response']['status'], 'Maman appelée.');
  });

  // ── sessionInfo ──────────────────────────────────────────────────────────

  test('server session_info → LiveSessionInfo', () async {
    final channel = _FakeChannel();
    final repo = _makeRepo(channel);

    final events = <LiveEvent>[];
    repo.connect().listen(events.add);
    await Future<void>.delayed(Duration.zero);

    channel.serverSend(jsonEncode({
      'session_info': {
        'welcome': 'Je peux vous aider avec :\n• Famille & Appels\n• Maison & Cuisine',
      },
    }));

    await Future<void>.delayed(Duration.zero);

    expect(events, [
      const LiveEvent.sessionInfo(
        'Je peux vous aider avec :\n• Famille & Appels\n• Maison & Cuisine',
      ),
    ]);
  });

  test('server session_info with empty welcome → no event emitted', () async {
    final channel = _FakeChannel();
    final repo = _makeRepo(channel);

    final events = <LiveEvent>[];
    repo.connect().listen(events.add);
    await Future<void>.delayed(Duration.zero);

    channel.serverSend(jsonEncode({
      'session_info': {'welcome': ''},
    }));

    await Future<void>.delayed(Duration.zero);

    expect(events, isEmpty);
  });

  // ── toolStatus ───────────────────────────────────────────────────────────

  test('server tool_status → LiveToolStatus', () async {
    final channel = _FakeChannel();
    final repo = _makeRepo(channel);

    final events = <LiveEvent>[];
    repo.connect().listen(events.add);
    await Future<void>.delayed(Duration.zero);

    channel.serverSend(jsonEncode({
      'tool_status': {'name': 'house_guide_agent', 'label': 'Maison & Cuisine'},
    }));

    await Future<void>.delayed(Duration.zero);

    expect(events, [const LiveEvent.toolStatus('Maison & Cuisine')]);
  });

  test('server tool_status with empty label → no event emitted', () async {
    final channel = _FakeChannel();
    final repo = _makeRepo(channel);

    final events = <LiveEvent>[];
    repo.connect().listen(events.add);
    await Future<void>.delayed(Duration.zero);

    channel.serverSend(jsonEncode({
      'tool_status': {'name': 'house_guide_agent', 'label': ''},
    }));

    await Future<void>.delayed(Duration.zero);

    expect(events, isEmpty);
  });

  // ── sessionEstablished ────────────────────────────────────────────────────

  test('server session_info with session_id → LiveSessionEstablished', () async {
    final channel = _FakeChannel();
    final repo = _makeRepo(channel);

    final events = <LiveEvent>[];
    repo.connect().listen(events.add);
    await Future<void>.delayed(Duration.zero);

    channel.serverSend(jsonEncode({
      'session_info': {'session_id': 'sess-xyz'},
    }));

    await Future<void>.delayed(Duration.zero);

    expect(events, [const LiveEvent.sessionEstablished('sess-xyz')]);
  });

  test('session_id takes priority over welcome in the same session_info message',
      () async {
    final channel = _FakeChannel();
    final repo = _makeRepo(channel);

    final events = <LiveEvent>[];
    repo.connect().listen(events.add);
    await Future<void>.delayed(Duration.zero);

    channel.serverSend(jsonEncode({
      'session_info': {
        'session_id': 'sess-xyz',
        'welcome': 'Je peux vous aider',
      },
    }));

    await Future<void>.delayed(Duration.zero);

    expect(events, [const LiveEvent.sessionEstablished('sess-xyz')]);
  });

  // ── malformed message ─────────────────────────────────────────────────────

  test('malformed server message → no event emitted', () async {
    final channel = _FakeChannel();
    final repo = _makeRepo(channel);

    final events = <LiveEvent>[];
    repo.connect().listen(events.add);
    await Future<void>.delayed(Duration.zero);

    channel.serverSend('not json at all {{{');
    await Future<void>.delayed(Duration.zero);

    expect(events, isEmpty);
  });
}
