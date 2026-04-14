import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:alzheimer_assistant/core/constants/app_constants.dart';
import 'package:alzheimer_assistant/core/utils/app_logger.dart';
import 'package:alzheimer_assistant/features/assistant/data/repositories/live_message_parser.dart';
import 'package:alzheimer_assistant/features/assistant/domain/entities/live_event.dart';
import 'package:alzheimer_assistant/features/assistant/domain/repositories/webrtc_repository.dart';
import 'package:alzheimer_assistant/shared/services/device_id_service.dart';
import 'package:livekit_client/livekit_client.dart';

/// Token and server URL returned by the backend.
typedef LiveKitCredentials = ({String url, String token, String room});

/// Fetches LiveKit credentials from the ADK backend.
/// Receives [useElevenLabs] and a stable [userId] so the backend can scope the
/// session to the device and encode the preference in room participant metadata.
typedef LiveKitTokenFetcher = Future<LiveKitCredentials> Function(
  bool useElevenLabs,
  String userId,
);

/// Audio-to-audio transport over WebRTC via LiveKit.
///
/// The SDK manages mic capture ([LocalAudioTrack]) and agent audio playback
/// ([RemoteAudioTrack]) automatically. Non-audio events (text, tool calls,
/// turn_complete) arrive as JSON Data Messages in the same format as the
/// WebSocket transport.
///
/// A new [Room] instance is created on every [connect] call (via [_roomFactory]).
/// Reusing the same Room across disconnect/connect cycles was previously
/// attempted to avoid `duplicateIdentity` server errors, but it caused stale
/// [RoomDisconnectedEvent]s from the previous session to fire on the new
/// listener, silently closing the new stream before the connection was usable.
///
/// VAD is handled by the LiveKit SDK on the server side (livekit-agents).
class LiveKitAudioRepository implements WebRtcRepository {
  LiveKitAudioRepository({
    LiveKitTokenFetcher? tokenFetcher,
    Room Function()? roomFactory,
    DeviceIdService? deviceIdService,
  })  : _tokenFetcher = tokenFetcher ?? _defaultTokenFetcher,
        _roomFactory = roomFactory ?? Room.new,
        _deviceIdService = deviceIdService ?? DeviceIdService();

  final LiveKitTokenFetcher _tokenFetcher;

  /// Factory called on each [connect] to produce a fresh [Room] instance.
  final Room Function() _roomFactory;

  final DeviceIdService _deviceIdService;

  /// Created on each [connect] call and discarded on [disconnect].
  Room? _room;

  EventsListener<RoomEvent>? _listener;
  StreamController<LiveEvent>? _controller;

  /// Incremented on every [disconnect] call.  A [_doConnect] coroutine
  /// captures the value at start and aborts after each await if it no longer
  /// matches, preventing stale continuations from operating on a reused room.
  int _connectGeneration = 0;

  /// Whether to use ElevenLabs TTS for this session (set on each [connect]).
  bool _useElevenLabs = false;

  final _parser = LiveMessageParser();
  final _logger = appLogger;

  // ── Public API ─────────────────────────────────────────────────────────────

  @override
  Stream<LiveEvent> connect({
    bool useElevenLabs = false,
    String? sessionId,
  }) {
    _useElevenLabs = useElevenLabs;
    _controller?.close();
    _controller = StreamController<LiveEvent>();

    _doConnect().catchError((Object e) {
      _logger.e('[LiveKit] Connection error: $e');
      if (!(_controller?.isClosed ?? true)) {
        _controller?.addError(e);
      }
    });

    return _controller!.stream;
  }

  @override
  void sendInterruption() {
    _sendData({
      'client_content': {'interrupted': true}
    });
  }

  @override
  void sendToolResponse({
    required String callId,
    required String functionName,
    required String result,
  }) {
    _sendData({
      'tool_response': {
        'function_responses': [
          {
            'id': callId,
            'name': functionName,
            'response': {'status': result},
          }
        ],
      },
    });
  }

  @override
  Future<void> disconnect() async {
    // Invalidate any in-flight _doConnect so it aborts after its next await.
    _connectGeneration++;

    // Dispose listeners first so _onDisconnected does not fire when we call
    // room.disconnect() below.
    _listener?.dispose();
    _listener = null;

    // Close the event stream before disconnecting the room.
    _controller?.close();
    _controller = null;

    await _room?.disconnect();
    // Discard the room so the next connect() starts with a fresh instance.
    // This prevents stale RoomDisconnectedEvents from a previous session
    // firing on the new listener and corrupting the reconnect flow.
    _room = null;
    _logger.i('[LiveKit] Disconnected');
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  Future<void> _doConnect() async {
    final generation = _connectGeneration;

    final userId = await _deviceIdService.getOrCreate();
    if (generation != _connectGeneration) return; // stale — abort
    _logger.i(
      '[LiveKit] Preparing session → deviceId="$userId" useElevenLabs=$_useElevenLabs',
    );

    final creds = await _tokenFetcher(_useElevenLabs, userId);
    if (generation != _connectGeneration) return; // stale — abort

    final identity = _extractIdentityFromToken(creds.token);
    _logger.i(
      '[LiveKit] Token received → url="${creds.url}" room="${creds.room}" identity="${identity ?? 'unknown'}"',
    );

    // Create the Room lazily on the first connect, then reuse it.
    _room ??= _roomFactory();

    // Register listeners before connecting so no events are missed.
    _listener?.dispose();
    _listener = _room!.createListener()
      ..on<DataReceivedEvent>(_onDataReceived)
      ..on<RoomConnectedEvent>(_onConnected)
      ..on<RoomDisconnectedEvent>(_onDisconnected)
      ..on<RoomReconnectingEvent>(_onReconnecting)
      ..on<RoomReconnectedEvent>(_onReconnected)
      ..on<LocalTrackPublishedEvent>(_onLocalTrackPublished);

    _logger.i(
      '[LiveKit] room.connect() starting → room="${creds.room}" url="${creds.url}" state=${_room!.connectionState.name}',
    );
    try {
      await _room!.connect(creds.url, creds.token);
    } catch (e, stackTrace) {
      _logger.e(
        '[LiveKit] room.connect() failed → room="${creds.room}" url="${creds.url}" error=$e',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
    if (generation != _connectGeneration) return; // stale — abort

    _logger.i(
      '[LiveKit] room.connect() succeeded → state=${_room!.connectionState.name}',
    );
    _logger.i('[LiveKit] Enabling microphone');

    final localParticipant = _room!.localParticipant;
    if (localParticipant == null) {
      throw StateError('[LiveKit] localParticipant unavailable after connect');
    }

    // The SDK captures mic audio and sends it via LocalAudioTrack (WebRTC).
    // VAD is handled server-side by the livekit-agents framework.
    try {
      await localParticipant.setMicrophoneEnabled(
        true,
        audioCaptureOptions: const AudioCaptureOptions(
          echoCancellation: true,
          noiseSuppression: true,
          autoGainControl: true,
        ),
      );
    } catch (e, stackTrace) {
      _logger.e(
        '[LiveKit] setMicrophoneEnabled(true) failed → error=$e',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }

    if (generation != _connectGeneration) return; // stale — abort
    _logger.i('[LiveKit] setMicrophoneEnabled(true) succeeded');
  }

  void _onConnected(RoomConnectedEvent event) {
    _logger.i(
      '[LiveKit] onConnected → metadata="${event.metadata}" state=${event.room.connectionState.name}',
    );
  }

  void _onDataReceived(DataReceivedEvent event) {
    final ctrl = _controller;
    if (ctrl == null || ctrl.isClosed) return;
    try {
      final raw = utf8.decode(event.data);
      _logger.d('[LiveKit] ← data: $raw');
      final liveEvent = _parser.parse(raw);
      if (liveEvent != null) ctrl.add(liveEvent);
    } catch (e) {
      _logger.w('[LiveKit] data decode error: $e');
    }
  }

  void _onReconnecting(RoomReconnectingEvent event) {
    _logger.w('[LiveKit] onReconnecting');
  }

  void _onReconnected(RoomReconnectedEvent event) {
    _logger.i('[LiveKit] onReconnected');
  }

  void _onDisconnected(RoomDisconnectedEvent event) {
    _logger.i('[LiveKit] onDisconnected → reason=${event.reason}');
    final ctrl = _controller;
    if (ctrl == null || ctrl.isClosed) return;
    ctrl.close();
  }

  void _onLocalTrackPublished(LocalTrackPublishedEvent event) {
    _logger.i(
      '[LiveKit] Local track published → sid="${event.publication.sid}" name="${event.publication.name}" source=${event.publication.source.name}',
    );
  }

  void _sendData(Map<String, dynamic> payload) {
    _room?.localParticipant
        ?.publishData(
          utf8.encode(jsonEncode(payload)),
          reliable: true,
        )
        .ignore();
  }
}

// ── Default token fetcher ──────────────────────────────────────────────────

Future<LiveKitCredentials> _defaultTokenFetcher(
  bool useElevenLabs,
  String userId,
) async {
  final uri = Uri.parse('${AppConstants.adkBaseUrl}/livekit-token')
      .replace(queryParameters: {
    'use_elevenlabs': useElevenLabs.toString(),
    'user_id': userId,
  });
  final client = HttpClient();
  try {
    final req = await client.getUrl(uri);
    req.headers.set(HttpHeaders.acceptHeader, 'application/json');
    final response = await req.close();
    if (response.statusCode != 200) {
      throw Exception(
        '[LiveKit] Token fetch failed: HTTP ${response.statusCode}',
      );
    }
    final body = await response.transform(utf8.decoder).join();
    final json = jsonDecode(body) as Map<String, dynamic>;
    return (
      url: json['url'] as String,
      token: json['token'] as String,
      room: json['room'] as String,
    );
  } finally {
    client.close();
  }
}

String? _extractIdentityFromToken(String token) {
  final parts = token.split('.');
  if (parts.length != 3) return null;

  try {
    final normalized = base64Url.normalize(parts[1]);
    final payload = jsonDecode(utf8.decode(base64Url.decode(normalized)))
        as Map<String, dynamic>;
    final video = payload['video'];
    if (video is Map<String, dynamic>) {
      final identity = video['identity'];
      if (identity is String && identity.isNotEmpty) {
        return identity;
      }
    }
  } catch (_) {
    return null;
  }

  return null;
}
