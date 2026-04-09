import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:alzheimer_assistant/features/assistant/data/repositories/livekit_audio_repository.dart';
import 'package:alzheimer_assistant/features/assistant/domain/entities/live_event.dart';

// ── Mocks ──────────────────────────────────────────────────────────────────

class MockRoom extends Mock implements Room {}

class MockLocalParticipant extends Mock implements LocalParticipant {}

class MockEventsListener extends Mock implements EventsListener<RoomEvent> {}

// ── Helpers ────────────────────────────────────────────────────────────────

/// Builds a [LiveKitAudioRepository] with controllable token and room.
LiveKitAudioRepository _makeRepo({
  required Room room,
  LiveKitCredentials credentials = (
    url: 'wss://test.livekit.cloud',
    token: 'tok',
    room: 'room-1',
  ),
}) {
  return LiveKitAudioRepository(
    tokenFetcher: (_, __) async => credentials,
    roomFactory: () => room,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockRoom room;
  late MockLocalParticipant localParticipant;
  late MockEventsListener eventsListener;

  // Captures registered event handlers so tests can fire them manually.
  final Map<Type, Function> handlers = {};

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    handlers.clear();
    room = MockRoom();
    localParticipant = MockLocalParticipant();
    eventsListener = MockEventsListener();

    when(() => room.localParticipant).thenReturn(localParticipant);
    when(() => room.connect(any(), any())).thenAnswer((_) async {});
    when(() => room.disconnect()).thenAnswer((_) async {});
    when(
      () => localParticipant.setMicrophoneEnabled(
        any(),
        audioCaptureOptions: any(named: 'audioCaptureOptions'),
      ),
    ).thenAnswer((_) async => null);
    when(
      () => localParticipant.publishData(
        any(),
        reliable: any(named: 'reliable'),
      ),
    ).thenAnswer((_) async {});

    // Capture event handlers registered via on<T>()
    when(() => room.createListener()).thenReturn(eventsListener);
    when(
      () => eventsListener.on<DataReceivedEvent>(any()),
    ).thenAnswer((inv) {
      handlers[DataReceivedEvent] = inv.positionalArguments.first as Function;
      return () async {};
    });
    when(
      () => eventsListener.on<RoomDisconnectedEvent>(any()),
    ).thenAnswer((inv) {
      handlers[RoomDisconnectedEvent] =
          inv.positionalArguments.first as Function;
      return () async {};
    });
    when(() => eventsListener.dispose()).thenAnswer((_) async => true);
  });

  // ── connect / credentials ─────────────────────────────────────────────────

  test('connect calls Room.connect with fetched credentials', () async {
    final repo = _makeRepo(
      room: room,
      credentials: (url: 'wss://lk.example.com', token: 'jwt', room: 'r'),
    );
    repo.connect().listen((_) {});
    await Future<void>.delayed(const Duration(milliseconds: 50));

    verify(() => room.connect('wss://lk.example.com', 'jwt')).called(1);
  });

  test('connect enables microphone', () async {
    final repo = _makeRepo(room: room);
    repo.connect().listen((_) {});
    await Future<void>.delayed(const Duration(milliseconds: 50));

    verify(
      () => localParticipant.setMicrophoneEnabled(
        true,
        audioCaptureOptions: any(named: 'audioCaptureOptions'),
      ),
    ).called(1);
  });

  // ── data messages → LiveEvent ─────────────────────────────────────────────

  test('emits turnComplete from data message', () async {
    final repo = _makeRepo(room: room);
    final events = <LiveEvent>[];
    repo.connect().listen(events.add);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final raw = utf8.encode(
      jsonEncode({'server_content': {'turn_complete': true}}),
    );
    (handlers[DataReceivedEvent]! as Function)(
      DataReceivedEvent(
        data: raw,
        participant: null,
        topic: null,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(events, [const LiveEvent.turnComplete()]);
  });

  test('emits outputTranscription from data message', () async {
    final repo = _makeRepo(room: room);
    final events = <LiveEvent>[];
    repo.connect().listen(events.add);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final raw = utf8.encode(
      jsonEncode({'output_transcription': {'text': 'Bonjour'}}),
    );
    (handlers[DataReceivedEvent]! as Function)(
      DataReceivedEvent(data: raw, participant: null, topic: null),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(events, [const LiveEvent.outputTranscription('Bonjour')]);
  });

  // ── sendInterruption / sendToolResponse ───────────────────────────────────

  test('sendInterruption publishes interrupted JSON', () async {
    final repo = _makeRepo(room: room);
    repo.connect().listen((_) {});
    await Future<void>.delayed(const Duration(milliseconds: 50));

    repo.sendInterruption();
    await Future<void>.delayed(const Duration(milliseconds: 10));

    final captured = verify(
      () => localParticipant.publishData(
        captureAny(),
        reliable: any(named: 'reliable'),
      ),
    ).captured;
    final json = jsonDecode(utf8.decode(captured.last as List<int>))
        as Map<String, dynamic>;
    expect(json['client_content']['interrupted'], isTrue);
  });

  test('sendToolResponse publishes tool_response JSON', () async {
    final repo = _makeRepo(room: room);
    repo.connect().listen((_) {});
    await Future<void>.delayed(const Duration(milliseconds: 50));

    repo.sendToolResponse(
      callId: 'id-1',
      functionName: 'call_phone',
      result: 'Marie appelée.',
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));

    final captured = verify(
      () => localParticipant.publishData(
        captureAny(),
        reliable: any(named: 'reliable'),
      ),
    ).captured;
    final json = jsonDecode(utf8.decode(captured.last as List<int>))
        as Map<String, dynamic>;
    final responses =
        json['tool_response']['function_responses'] as List<dynamic>;
    expect(responses.first['id'], 'id-1');
    expect(responses.first['name'], 'call_phone');
    expect(responses.first['response']['status'], 'Marie appelée.');
  });

  // ── disconnect ────────────────────────────────────────────────────────────

  test('disconnect calls room.disconnect and disposes listener', () async {
    final repo = _makeRepo(room: room);
    repo.connect().listen((_) {});
    await Future<void>.delayed(const Duration(milliseconds: 50));

    await repo.disconnect();

    verify(() => room.disconnect()).called(1);
    verify(() => eventsListener.dispose()).called(1);
  });

  // ── room disconnection closes stream ─────────────────────────────────────

  test('RoomDisconnectedEvent closes the stream', () async {
    final repo = _makeRepo(room: room);
    var streamDone = false;
    repo.connect().listen((_) {}, onDone: () => streamDone = true);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    (handlers[RoomDisconnectedEvent]! as Function)(
      RoomDisconnectedEvent(reason: DisconnectReason.unknown),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(streamDone, isTrue);
  });

  // ── generation counter: stale connect aborts after disconnect ────────────

  test('disconnect before token fetch completes aborts _doConnect', () async {
    final completer = Completer<LiveKitCredentials>();
    final repo = LiveKitAudioRepository(
      tokenFetcher: (_, __) => completer.future,
      roomFactory: () => room,
    );

    var connectCalled = false;
    when(() => room.connect(any(), any())).thenAnswer((_) async {
      connectCalled = true;
    });

    repo.connect().listen((_) {});
    // disconnect while token fetch is still pending
    await repo.disconnect();

    // resolve the token fetch — _doConnect should detect stale generation
    completer.complete((
      url: 'wss://lk.example.com',
      token: 'jwt',
      room: 'r',
    ));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(connectCalled, isFalse);
  });

  // ── token fetch error ─────────────────────────────────────────────────────

  test('token fetch error propagates as stream error', () async {
    final repo = LiveKitAudioRepository(
      tokenFetcher: (_, __) async => throw Exception('Network error'),
      roomFactory: () => room,
    );

    Object? streamError;
    repo.connect().listen((_) {}, onError: (e) => streamError = e);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(streamError, isNotNull);
  });

  // ── room recreation after disconnect ──────────────────────────────────────

  test('connect after disconnect creates a new Room via factory', () async {
    var factoryCallCount = 0;
    final rooms = <MockRoom>[];

    // Create two independent room mocks for the two connect calls.
    for (var i = 0; i < 2; i++) {
      final r = MockRoom();
      final lp = MockLocalParticipant();
      final el = MockEventsListener();
      final localHandlers = <Type, Function>{};

      when(() => r.localParticipant).thenReturn(lp);
      when(() => r.connect(any(), any())).thenAnswer((_) async {});
      when(() => r.disconnect()).thenAnswer((_) async {});
      when(
        () => lp.setMicrophoneEnabled(
          any(),
          audioCaptureOptions: any(named: 'audioCaptureOptions'),
        ),
      ).thenAnswer((_) async => null);
      when(() => r.createListener()).thenReturn(el);
      when(() => el.on<DataReceivedEvent>(any())).thenAnswer((inv) {
        localHandlers[DataReceivedEvent] =
            inv.positionalArguments.first as Function;
        return () async {};
      });
      when(() => el.on<RoomDisconnectedEvent>(any())).thenAnswer((inv) {
        localHandlers[RoomDisconnectedEvent] =
            inv.positionalArguments.first as Function;
        return () async {};
      });
      when(() => el.dispose()).thenAnswer((_) async => true);

      rooms.add(r);
    }

    final repo = LiveKitAudioRepository(
      tokenFetcher: (_, __) async =>
          (url: 'wss://test.livekit.cloud', token: 'tok', room: 'room-1'),
      roomFactory: () => rooms[factoryCallCount++],
    );

    // First connect — uses rooms[0].
    repo.connect().listen((_) {});
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(factoryCallCount, 1);

    await repo.disconnect();

    // Second connect — must use a fresh Room (rooms[1]).
    repo.connect().listen((_) {});
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(factoryCallCount, 2);
  });
}
