import 'package:dio/dio.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/auth/data/models/auth_session_model.dart';
import 'package:erp_curtiembre_fronted/features/auth/data/models/change_password_request_model.dart';
import 'package:erp_curtiembre_fronted/features/auth/data/models/login_request_model.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<AuthSessionModel> login(LoginRequestModel request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/seguridad/auth/login',
        data: request.toJson(),
      );

      return AuthSessionModel.fromLoginJson(response.data!);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  Future<AuthSessionModel> fetchCurrentSession(String sessionToken) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/seguridad/auth/me');
      return AuthSessionModel.fromSessionJson(
        response.data!,
        sessionToken: sessionToken,
      );
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  Future<String?> logout() async {
    try {
      final response = await _dio.post<Map<String, dynamic>>('/api/seguridad/auth/logout');
      final data = response.data;
      if (data == null) {
        return null;
      }

      return data['message'] as String?;
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  Future<String> changePassword(ChangePasswordRequestModel request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/seguridad/auth/change-password',
        data: request.toJson(),
      );

      final data = response.data;
      return data?['message'] as String? ?? 'Contrasena actualizada correctamente.';
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }
}
