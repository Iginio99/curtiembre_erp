import 'package:dio/dio.dart';
import 'package:erp_curtiembre_fronted/core/config/api_config.dart';
import 'package:erp_curtiembre_fronted/core/storage/session_storage.dart';

abstract final class ApiClient {
  static Dio create(SessionStorage sessionStorage) {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final sessionToken = await sessionStorage.readSessionToken();
          if (sessionToken != null && sessionToken.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $sessionToken';
          }

          handler.next(options);
        },
      ),
    );

    return dio;
  }
}
