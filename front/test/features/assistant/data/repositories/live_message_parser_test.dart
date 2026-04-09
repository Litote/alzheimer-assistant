import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:alzheimer_assistant/features/assistant/data/repositories/live_message_parser.dart';
import 'package:alzheimer_assistant/features/assistant/domain/entities/live_event.dart';

void main() {
  late LiveMessageParser parser;

  setUp(() => parser = LiveMessageParser());

  // ── turn_complete ──────────────────────────────────────────────────────────

  test('parses turn_complete', () {
    final raw = jsonEncode({'server_content': {'turn_complete': true}});
    expect(parser.parse(raw), const LiveEvent.turnComplete());
  });

  // ── audioChunk ─────────────────────────────────────────────────────────────

  test('parses audioChunk from inline_data', () {
    final bytes = Uint8List.fromList([1, 2, 3]);
    final b64 = base64.encode(bytes);
    final raw = jsonEncode({
      'server_content': {
        'model_turn': {
          'parts': [
            {
              'inline_data': {'mime_type': 'audio/pcm;rate=24000', 'data': b64}
            }
          ]
        }
      }
    });
    final event = parser.parse(raw);
    expect(event, isA<LiveAudioChunk>());
    expect((event! as LiveAudioChunk).bytes, bytes);
  });

  // ── inputTranscription ─────────────────────────────────────────────────────

  test('parses inputTranscription', () {
    final raw = jsonEncode({'input_transcription': {'text': 'bonjour'}});
    expect(parser.parse(raw), const LiveEvent.inputTranscription('bonjour'));
  });

  test('ignores empty inputTranscription', () {
    final raw = jsonEncode({'input_transcription': {'text': ''}});
    expect(parser.parse(raw), isNull);
  });

  // ── outputTranscription ───────────────────────────────────────────────────

  test('parses outputTranscription', () {
    final raw = jsonEncode({'output_transcription': {'text': 'réponse'}});
    expect(parser.parse(raw), const LiveEvent.outputTranscription('réponse'));
  });

  // ── toolCall / call_phone ─────────────────────────────────────────────────

  test('parses call_phone tool call', () {
    final raw = jsonEncode({
      'tool_call': {
        'function_calls': [
          {
            'id': 'call-1',
            'name': 'call_phone',
            'args': {'contact_name': 'Marie', 'exact_match': true},
          }
        ]
      }
    });
    final event = parser.parse(raw);
    expect(event, isA<LiveCallPhone>());
    final call = event! as LiveCallPhone;
    expect(call.callId, 'call-1');
    expect(call.contactName, 'Marie');
    expect(call.exactMatch, isTrue);
  });

  test('ignores unknown tool call name', () {
    final raw = jsonEncode({
      'tool_call': {
        'function_calls': [
          {'id': 'x', 'name': 'unknown_tool', 'args': {}}
        ]
      }
    });
    expect(parser.parse(raw), isNull);
  });

  // ── sessionInfo / sessionEstablished ──────────────────────────────────────

  test('parses sessionEstablished', () {
    final raw = jsonEncode({'session_info': {'session_id': 'abc123'}});
    expect(parser.parse(raw), const LiveEvent.sessionEstablished('abc123'));
  });

  test('parses sessionInfo welcome', () {
    final raw = jsonEncode({'session_info': {'welcome': 'Bonjour !'}});
    expect(parser.parse(raw), const LiveEvent.sessionInfo('Bonjour !'));
  });

  // ── toolStatus ─────────────────────────────────────────────────────────────

  test('parses toolStatus', () {
    final raw = jsonEncode({'tool_status': {'label': 'Maison'}});
    expect(parser.parse(raw), const LiveEvent.toolStatus('Maison'));
  });

  // ── imageUrl ───────────────────────────────────────────────────────────────

  test('parses imageUrl', () {
    final raw = jsonEncode({'image_url': 'https://example.com/img.png'});
    expect(parser.parse(raw), const LiveEvent.imageUrl('https://example.com/img.png'));
  });

  // ── unknown / malformed ───────────────────────────────────────────────────

  test('returns null for unrecognized message', () {
    final raw = jsonEncode({'unknown_key': 'value'});
    expect(parser.parse(raw), isNull);
  });

  test('returns null for malformed JSON', () {
    expect(parser.parse('not json {'), isNull);
  });
}
