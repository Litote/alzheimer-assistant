import 'package:flutter_test/flutter_test.dart';
import 'package:alzheimer_assistant/core/constants/app_constants.dart';

void main() {
  test('adkLiveUrl appends /run_live to adkBaseUrl', () {
    // ADK_BASE_URL is empty in unit tests (no --dart-define injected),
    // so we verify the path suffix is correct.
    expect(AppConstants.adkLiveUrl, endsWith('/run_live'));
  });
}
