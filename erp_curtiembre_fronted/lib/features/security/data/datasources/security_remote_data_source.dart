import 'package:dio/dio.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/security/data/models/permission_check_result_model.dart';
import 'package:erp_curtiembre_fronted/features/security/data/models/security_permission_model.dart';
import 'package:erp_curtiembre_fronted/features/security/data/models/security_role_model.dart';
import 'package:talker_flutter/talker_flutter.dart';

class SecurityRemoteDataSource {
  SecurityRemoteDataSource(this._dio, this._talker);

  final Dio _dio;
  final Talker _talker;

  Future<List<SecurityRoleModel>> listRoles() async {
    const path = '/api/seguridad/roles';

    try {
      _talker.dataSource('GET $path');
      final response = await _dio.get<List<dynamic>>(path);
      final items = response.data ?? const [];
      _talker.dataSource('GET $path completado con ${items.length} roles.');

      return items
          .map(
            (item) => SecurityRoleModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<List<SecurityPermissionModel>> listPermissions() async {
    const path = '/api/seguridad/permisos';

    try {
      _talker.dataSource('GET $path con activo=true');
      final response = await _dio.get<List<dynamic>>(
        path,
        queryParameters: const {'activo': true},
      );
      final items = response.data ?? const [];
      _talker.dataSource('GET $path completado con ${items.length} permisos.');

      return items
          .map(
            (item) =>
                SecurityPermissionModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<List<String>> getPermissionsByUser(int usuarioId) async {
    final path = '/api/seguridad/usuarios/$usuarioId/permisos';

    try {
      _talker.dataSource('GET $path');
      final response = await _dio.get<Map<String, dynamic>>(path);
      final data = response.data;
      final items = data?['permissionCodes'] as List<dynamic>? ?? const [];
      _talker.dataSource(
        'GET $path completado con ${items.length} codigos de permiso.',
      );

      return items.map((item) => item.toString()).toList(growable: false);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<List<String>> getCurrentUserPermissions() async {
    const path = '/api/seguridad/mis-permisos';

    try {
      _talker.dataSource('GET $path');
      final response = await _dio.get<Map<String, dynamic>>(path);
      final data = response.data;
      final items = data?['permissionCodes'] as List<dynamic>? ?? const [];
      _talker.dataSource(
        'GET $path completado con ${items.length} permisos del usuario actual.',
      );

      return items.map((item) => item.toString()).toList(growable: false);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<PermissionCheckResultModel> checkPermission({
    required int usuarioId,
    required String permissionCode,
  }) async {
    const path = '/api/seguridad/check-permission';

    try {
      _talker.dataSource(
        'POST $path para usuarioId=$usuarioId, permissionCode=$permissionCode',
      );
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: {'usuarioId': usuarioId, 'permissionCode': permissionCode},
      );
      _talker.dataSource(
        'POST $path completado para usuarioId=$usuarioId, permissionCode=$permissionCode.',
      );

      return PermissionCheckResultModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'POST $path');
    }
  }

  ApiException _mapAndLogDioException(
    DioException exception, {
    required String operation,
  }) {
    final apiException = ApiException.fromDioException(exception);
    _talker.dataSource(
      '$operation fallo con status=${apiException.statusCode ?? 'sin-status'} y mensaje="${apiException.message}"',
      logLevel: LogLevel.error,
      exception: apiException,
      stackTrace: exception.stackTrace,
    );
    return apiException;
  }
}
