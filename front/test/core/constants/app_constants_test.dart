import 'package:flutter_test/flutter_test.dart';
import 'package:alzheimer_assistant/core/constants/app_constants.dart';

void main() {
  test('elevenLabsTtsUrl returns the correct ElevenLabs URL', () {
    expect(
      AppConstants.elevenLabsTtsUrl('my-voice-id'),
      'https://api.elevenlabs.io/v1/text-to-speech/my-voice-id',
    );
  });
}
