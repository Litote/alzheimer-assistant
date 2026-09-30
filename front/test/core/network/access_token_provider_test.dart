import 'package:flutter_test/flutter_test.dart';
import 'package:alzheimer_assistant/core/network/access_token_provider.dart';

void main() {
  test('bearerAuthHeaders() builds a bearer Authorization header', () {
    expect(bearerAuthHeaders('jwt-123'), {'Authorization': 'Bearer jwt-123'});
  });

  test('bearerAuthHeaders() returns no header for an empty token', () {
    expect(bearerAuthHeaders(''), isEmpty);
  });

  test('noAccessToken() returns an empty token', () {
    expect(noAccessToken(), isEmpty);
  });
}
