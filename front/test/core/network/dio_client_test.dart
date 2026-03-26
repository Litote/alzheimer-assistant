import 'package:flutter_test/flutter_test.dart';
import 'package:alzheimer_assistant/core/network/dio_client.dart';

void main() {
  test('create() returns a Dio with the given baseUrl', () {
    final dio = DioClient.create(baseUrl: 'https://example.com');
    expect(dio.options.baseUrl, 'https://example.com');
  });

  test('create() with no baseUrl uses empty string', () {
    final dio = DioClient.create();
    expect(dio.options.baseUrl, '');
  });

  test('create() adds an error interceptor', () {
    final dio = DioClient.create(baseUrl: 'https://example.com');
    expect(dio.interceptors, isNotEmpty);
  });
}
