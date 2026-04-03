import 'dart:async';
import 'dart:typed_data';

import 'package:alzheimer_assistant/features/assistant/domain/entities/live_event.dart';
import 'package:alzheimer_assistant/features/assistant/domain/repositories/live_repository.dart';

// ── Exported constants so the test can assert on them ─────────────────────

const String kAgentResponse = 'Vos médicaments sont sur la table de nuit.';
const String kDisambiguationAgentQuestion =
    'Souhaitez-vous appeler Marie Dupont ou Marie Martin ?';
const String kCallConfirmationAgentText =
    "J'appelle Marie Dupont. Bonne conversation !";

// ── FakeLiveRepository ────────────────────────────────────────────────────

/// In-memory [LiveRepository] for E2E tests.
///
/// A single persistent connection is simulated: [connect()] returns one stream
/// that emits all [sequences] in order (with a 50 ms gap between turns) and
/// then stays open until [disconnect()] is called. This mirrors the bidi
/// streaming model where [turnComplete] transitions to Listening without
/// closing the connection.
class FakeLiveRepository implements LiveRepository {
  FakeLiveRepository({required List<List<LiveEvent>> sequences})
      : _sequences = sequences;

  final List<List<LiveEvent>> _sequences;
  bool _disconnected = false;
  Completer<void>? _disconnectCompleter;

  final List<String> sentTexts = [];
  final List<String> sentToolResponses = [];

  @override
  Stream<LiveEvent> connect({bool useElevenLabs = false}) async* {
    _disconnected = false;
    _disconnectCompleter = Completer<void>();

    for (var i = 0; i < _sequences.length; i++) {
      for (final event in _sequences[i]) {
        if (_disconnected) return;
        // Small delay so the BLoC has time to process each event
        await Future<void>.delayed(const Duration(milliseconds: 10));
        yield event;
      }

      // Pause between turns to simulate the user speaking before the next
      // server response, without closing the connection.
      final isLast = i == _sequences.length - 1;
      if (!isLast && !_disconnected) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    }

    // Keep stream alive until disconnect() is called. In bidi streaming the
    // connection persists across turns — only torn down by the client.
    if (!_disconnected) {
      await _disconnectCompleter!.future;
    }
  }

  @override
  void sendAudio(Uint8List pcmBytes) {}

  @override
  void sendText(String text) => sentTexts.add(text);

  @override
  void sendToolResponse({
    required String callId,
    required String functionName,
    required String result,
  }) =>
      sentToolResponses.add('$functionName:$result');

  @override
  void sendInterruption() {}

  @override
  Future<void> disconnect() async {
    _disconnected = true;
    if (_disconnectCompleter != null && !_disconnectCompleter!.isCompleted) {
      _disconnectCompleter!.complete();
    }
  }
}

// ── Factory helpers ────────────────────────────────────────────────────────

/// Simple nominal scenario: agent sends audio + transcription then completes.
FakeLiveRepository makeFakeLiveRepository() => FakeLiveRepository(
      sequences: [
        [
          // audioChunk first → triggers Speaking state
          LiveEvent.audioChunk(Uint8List(128)),
          // outputTranscription → populates responseText while Speaking
          const LiveEvent.outputTranscription(kAgentResponse),
          const LiveEvent.turnComplete(),
        ],
      ],
    );

/// Single-turn fake with no turnComplete: state stays Speaking until the test
/// interrupts by tapping the mic button.
FakeLiveRepository makeFakeLiveRepositoryForInterrupt() => FakeLiveRepository(
      sequences: [
        [
          LiveEvent.audioChunk(Uint8List(128)),
          // No turnComplete — stream stays alive, state remains Speaking
        ],
      ],
    );

/// Disambiguation scenario (2 turns on the same persistent connection):
/// 1. call_phone("Marie")        → ambiguous → agent asks which one
/// 2. call_phone("Marie Dupont") → success   → agent confirms
FakeLiveRepository makeFakeLiveRepositoryForDisambiguation() =>
    FakeLiveRepository(
      sequences: [
        // Turn 1: user says "Appelle Marie"
        [
          const LiveEvent.callPhone(
            callId: 'call-1',
            contactName: 'Marie',
            exactMatch: false,
          ),
          LiveEvent.audioChunk(Uint8List(128)),
          const LiveEvent.outputTranscription(kDisambiguationAgentQuestion),
          const LiveEvent.turnComplete(),
        ],
        // Turn 2: arrives on the same connection after the 50 ms inter-turn pause
        [
          const LiveEvent.callPhone(
            callId: 'call-2',
            contactName: 'Marie Dupont',
            exactMatch: false,
          ),
          LiveEvent.audioChunk(Uint8List(128)),
          const LiveEvent.outputTranscription(kCallConfirmationAgentText),
          const LiveEvent.turnComplete(),
        ],
      ],
    );
