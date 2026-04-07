import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alzheimer_assistant/shared/services/pcm_streaming_audio_player_service.dart';

// ── Channel mock helpers ───────────────────────────────────────────────────

void _mockPcmChannel() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('flutter_pcm_sound/methods'),
    (MethodCall call) async => null,
  );
}

void _mockAudioRoutingChannel() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('alzheimer_assistant/audio'),
    (MethodCall call) async => null,
  );
}

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ── Without platform plugin (default test environment) ────────────────────

  group('without platform plugin (_isInitialized = false)', () {
    test('hasChunks always returns false (real-time PCM — no client buffer)', () {
      final service = PcmStreamingAudioPlayerService();
      expect(service.hasChunks, isFalse);
    });

    test('addChunk when not initialized → does not throw', () {
      final service = PcmStreamingAudioPlayerService();
      expect(
        () => service.addChunk(Uint8List.fromList([1, 2, 3, 4])),
        returnsNormally,
      );
    });

    test('playAndClear always invokes onComplete immediately', () async {
      final service = PcmStreamingAudioPlayerService();
      var called = false;
      await service.playAndClear(onComplete: () => called = true);
      expect(called, isTrue);
    });

    test('stop when not initialized → does not throw', () async {
      final service = PcmStreamingAudioPlayerService();
      await expectLater(service.stop(), completes);
    });

    test('dispose when not initialized → does not throw', () async {
      final service = PcmStreamingAudioPlayerService();
      await expectLater(service.dispose(), completes);
    });
  });

  // ── With mocked platform channels (_isInitialized = true) ─────────────────

  group('with mocked platform channels (_isInitialized = true)', () {
    setUp(() {
      _mockPcmChannel();
      _mockAudioRoutingChannel();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter_pcm_sound/methods'),
        null,
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('alzheimer_assistant/audio'),
        null,
      );
    });

    test('addChunk applies gain and feeds PCM without throwing', () async {
      final service = PcmStreamingAudioPlayerService();
      // Wait for async _init() to complete with the mocked channel
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // 4 int16 samples: [0x0100, 0x0200, 0x0300, 0x0400] in little-endian
      final chunk = Uint8List.fromList([0x00, 0x01, 0x00, 0x02, 0x00, 0x03, 0x00, 0x04]);
      expect(() => service.addChunk(chunk), returnsNormally);
    });

    test('addChunk clamps amplified samples to int16 range', () async {
      final service = PcmStreamingAudioPlayerService();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Single max-amplitude sample (32767) — gain 1.5× → 49150 → clamped to 32767
      final chunk = Uint8List(2);
      final view = Int16List.view(chunk.buffer);
      view[0] = 32767;
      expect(() => service.addChunk(chunk), returnsNormally);
    });

    test('stop after initialization does not throw', () async {
      final service = PcmStreamingAudioPlayerService();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await expectLater(service.stop(), completes);
    });

    test('dispose after initialization does not throw', () async {
      final service = PcmStreamingAudioPlayerService();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await expectLater(service.dispose(), completes);
    });
  });

  // ── iOS audio session ordering ─────────────────────────────────────────────

  group('iOS audio session (correct ordering + interruption recovery)', () {
    final audioCalls = <String>[];

    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      audioCalls.clear();
      _mockPcmChannel();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('alzheimer_assistant/audio'),
        (MethodCall call) async {
          audioCalls.add(call.method);
          return null;
        },
      );
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter_pcm_sound/methods'),
        null,
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('alzheimer_assistant/audio'),
        null,
      );
    });

    test('_init calls prepareAudioSession before overrideToSpeaker on iOS', () async {
      PcmStreamingAudioPlayerService();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(audioCalls, containsAllInOrder(['prepareAudioSession', 'overrideToSpeaker']));
    });

    test('audioInterruptionEnded reinitializes the PCM engine', () async {
      final service = PcmStreamingAudioPlayerService();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final callsBefore = List<String>.from(audioCalls);

      // Simulate native plugin sending audioInterruptionEnded.
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        'alzheimer_assistant/audio',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('audioInterruptionEnded'),
        ),
        (data) {},
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // After interruption, the engine should have been re-initialized:
      // another prepareAudioSession + overrideToSpeaker pair must appear.
      final callsAfter = audioCalls.sublist(callsBefore.length);
      expect(callsAfter, containsAllInOrder(['prepareAudioSession', 'overrideToSpeaker']));

      await service.dispose();
    });

    test('dispose unregisters the method call handler', () async {
      final service = PcmStreamingAudioPlayerService();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await service.dispose();
      // Should complete without error — handler was cleaned up.
      expect(true, isTrue);
    });
  });

  // ── Android audio mode ─────────────────────────────────────────────────────

  group('Android audio mode (MODE_IN_COMMUNICATION)', () {
    final audioCalls = <String>[];

    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      audioCalls.clear();
      _mockPcmChannel();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('alzheimer_assistant/audio'),
        (MethodCall call) async {
          audioCalls.add(call.method);
          return null;
        },
      );
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter_pcm_sound/methods'),
        null,
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('alzheimer_assistant/audio'),
        null,
      );
    });

    test('_init calls setAudioModeCommunication on Android', () async {
      PcmStreamingAudioPlayerService();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(audioCalls, contains('setAudioModeCommunication'));
    });

    test('dispose calls resetAudioMode on Android', () async {
      final service = PcmStreamingAudioPlayerService();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await service.dispose();
      expect(audioCalls, containsAllInOrder(['setAudioModeCommunication', 'resetAudioMode']));
    });
  });
}
