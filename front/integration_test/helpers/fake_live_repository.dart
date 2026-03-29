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
/// Each call to [connect()] yields the next sequence of events from the
/// [_sequences] list. When the list is exhausted, the last sequence is
/// repeated. This allows simulating multi-turn conversations.
class FakeLiveRepository implements LiveRepository {
  FakeLiveRepository({required List<List<LiveEvent>> sequences})
      : _sequences = sequences;

  final List<List<LiveEvent>> _sequences;
  int _callCount = 0;
  bool _disconnected = false;

  final List<String> sentTexts = [];
  final List<String> sentToolResponses = [];

  @override
  Stream<LiveEvent> connect({bool useElevenLabs = false}) async* {
    _disconnected = false;
    final sequence = _callCount < _sequences.length
        ? _sequences[_callCount]
        : _sequences.last;
    _callCount++;

    for (final event in sequence) {
      if (_disconnected) return;
      // Small delay so the BLoC has time to process each event
      await Future<void>.delayed(const Duration(milliseconds: 10));
      yield event;
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
  }
}

// ── Factory helpers ────────────────────────────────────────────────────────

/// Simple nominal scenario: agent responds with text + audio, then done.
FakeLiveRepository makeFakeLiveRepository() => FakeLiveRepository(
      sequences: [
        [
          const LiveEvent.textDelta(kAgentResponse),
          LiveEvent.audioChunk(Uint8List(128)),
          const LiveEvent.turnComplete(),
        ],
      ],
    );

/// Disambiguation scenario (4 turns):
/// 1. call_phone("Marie")   → sends tool response → agent asks disambiguation
/// 2. call_phone("Marie Dupont") → sends tool response → agent confirms
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
          const LiveEvent.textDelta(kDisambiguationAgentQuestion),
          LiveEvent.audioChunk(Uint8List(128)),
          const LiveEvent.turnComplete(),
        ],
        // Turn 2: user says "Marie Dupont"
        [
          const LiveEvent.callPhone(
            callId: 'call-2',
            contactName: 'Marie Dupont',
            exactMatch: false,
          ),
          const LiveEvent.textDelta(kCallConfirmationAgentText),
          LiveEvent.audioChunk(Uint8List(128)),
          const LiveEvent.turnComplete(),
        ],
      ],
    );
