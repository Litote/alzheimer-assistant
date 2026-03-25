import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class DioClient {
  DioClient._();

  static final _logger = Logger();

  static Dio create({String? baseUrl}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? '',
        connectTimeout: const Duration(seconds: 15),
        sendTimeout:    const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          _logger.e('Dio error: ${error.message}', error: error);
          handler.next(error);
        },
      ),
    );

    return dio;
  }
}
