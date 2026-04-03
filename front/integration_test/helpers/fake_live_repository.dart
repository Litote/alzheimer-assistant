import 'dart:async';
import 'dart:typed_data';

import 'package:alzheimer_assistant/features/assistant/domain/entities/live_event.dart';
import 'package:alzheimer_assistant/features/assistant/domain/repositories/audio_repository.dart';
import 'package:alzheimer_assistant/features/assistant/domain/repositories/text_repository.dart';

// ── Exported constants so the test can assert on them ─────────────────────

const String kAgentResponse = 'Vos médicaments sont sur la table de nuit.';
const String kDisambiguationAgentQuestion =
    'Souhaitez-vous appeler Marie Dupont ou Marie Martin ?';
const String kCallConfirmationAgentText =
    "J'appelle Marie Dupont. Bonne conversation !";

// ── FakeLiveRepository ────────────────────────────────────────────────────

/// In-memory [AudioRepository] for E2E tests.
///
/// A single persistent connection is simulated: [connect()] returns one stream
/// that emits all [sequences] in order (with a 50 ms gap between turns) and
/// then stays open until [disconnect()] is called.
class FakeLiveRepository implements AudioRepository, TextRepository {
  FakeLiveRepository({required List<List<LiveEvent>> sequences})
      : _sequences = sequences;

  final List<List<LiveEvent>> _sequences;
  bool _disconnected = false;
  Completer<void>? _disconnectCompleter;

  final List<String> sentToolResponses = [];

  @override
  Stream<LiveEvent> connect({
    bool useElevenLabs = false,
    String? sessionId,
  }) async* {
    _disconnected = false;
    _disconnectCompleter = Completer<void>();

    for (var i = 0; i < _sequences.length; i++) {
      for (final event in _sequences[i]) {
        if (_disconnected) return;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        yield event;
      }

      final isLast = i == _sequences.length - 1;
      if (!isLast && !_disconnected) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    }

    if (!_disconnected) {
      await _disconnectCompleter!.future;
    }
  }

  @override
  void sendAudio(Uint8List pcmBytes) {}

  @override
  void sendText(String text) {}

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

FakeLiveRepository makeFakeLiveRepository() => FakeLiveRepository(
      sequences: [
        [
          LiveEvent.audioChunk(Uint8List(128)),
          const LiveEvent.outputTranscription(kAgentResponse),
          const LiveEvent.turnComplete(),
        ],
      ],
    );

FakeLiveRepository makeFakeLiveRepositoryForInterrupt() => FakeLiveRepository(
      sequences: [
        [
          LiveEvent.audioChunk(Uint8List(128)),
        ],
      ],
    );

FakeLiveRepository makeFakeLiveRepositoryForDisambiguation() =>
    FakeLiveRepository(
      sequences: [
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
