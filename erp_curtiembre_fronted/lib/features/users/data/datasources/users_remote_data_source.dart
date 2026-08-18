import 'package:dio/dio.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/security/data/models/security_role_model.dart';
import 'package:erp_curtiembre_fronted/features/users/data/models/user_area_option_model.dart';
import 'package:erp_curtiembre_fronted/features/users/data/models/user_detail_model.dart';
import 'package:erp_curtiembre_fronted/features/users/data/models/user_list_item_model.dart';
import 'package:erp_curtiembre_fronted/features/users/data/models/user_mutation_result_model.dart';
import 'package:talker_flutter/talker_flutter.dart';

class UsersRemoteDataSource {
  UsersRemoteDataSource(this._dio, this._talker);

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

  Future<List<UserAreaOptionModel>> listActiveAreas() async {
    const path = '/api/configuracion/catalogos/areas/activas';

    try {
      _talker.dataSource('GET $path');
      final response = await _dio.get<List<dynamic>>(path);
      final items = response.data ?? const [];
      _talker.dataSource('GET $path completado con ${items.length} areas.');

      return items
          .map(
            (item) =>
                UserAreaOptionModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<List<UserListItemModel>> listUsers({
    String? texto,
    bool? activo,
  }) async {
    const path = '/api/seguridad/usuarios';

    try {
      _talker.dataSource(
        'GET $path con filtros texto=${_describeText(texto)}, activo=$activo',
      );
      final response = await _dio.get<List<dynamic>>(
        path,
        queryParameters: {
          if (texto != null && texto.trim().isNotEmpty) 'texto': texto.trim(),
          'activo': activo,
        },
      );
      final items = response.data ?? const [];
      _talker.dataSource('GET $path completado con ${items.length} usuarios.');

      return items
          .map(
            (item) => UserListItemModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<UserDetailModel> getUserDetail(int usuarioId) async {
    final path = '/api/seguridad/usuarios/$usuarioId';

    try {
      _talker.dataSource('GET $path');
      final response = await _dio.get<Map<String, dynamic>>(path);
      _talker.dataSource('GET $path completado.');

      return UserDetailModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<UserMutationResultModel> createUser({
    required String dni,
    required String nombres,
    required String apellidos,
    required String userName,
    required int rolId,
    required int areaId,
    String? passwordTemporal,
  }) async {
    const path = '/api/seguridad/usuarios';

    try {
      _talker.dataSource(
        'POST $path para userName=$userName, rolId=$rolId, areaId=$areaId',
      );
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: {
          'dni': dni,
          'nombres': nombres,
          'apellidos': apellidos,
          'userName': userName,
          'rolId': rolId,
          'areaId': areaId,
          'passwordTemporal': passwordTemporal,
        },
      );
      _talker.dataSource('POST $path completado para userName=$userName.');

      return UserMutationResultModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'POST $path');
    }
  }

  Future<UserMutationResultModel> updateUser({
    required int usuarioId,
    required String dni,
    required String nombres,
    required String apellidos,
    required String userName,
    required int rolId,
    required int areaId,
  }) async {
    final path = '/api/seguridad/usuarios/$usuarioId';

    try {
      _talker.dataSource(
        'PUT $path para userName=$userName, rolId=$rolId, areaId=$areaId',
      );
      final response = await _dio.put<Map<String, dynamic>>(
        path,
        data: {
          'dni': dni,
          'nombres': nombres,
          'apellidos': apellidos,
          'userName': userName,
          'rolId': rolId,
          'areaId': areaId,
        },
      );
      _talker.dataSource('PUT $path completado.');

      return UserMutationResultModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'PUT $path');
    }
  }

  Future<String> resetPassword({
    required int usuarioId,
    String? passwordTemporal,
  }) async {
    return _postMessage(
      '/api/seguridad/usuarios/$usuarioId/reset-password',
      data: {'passwordTemporal': passwordTemporal},
    );
  }

  Future<String> deactivateUser({
    required int usuarioId,
    String? motivo,
  }) async {
    return _postMessage(
      '/api/seguridad/usuarios/$usuarioId/deactivate',
      data: {'motivo': motivo},
    );
  }

  Future<String> reactivateUser({
    required int usuarioId,
    String? motivo,
  }) async {
    return _postMessage(
      '/api/seguridad/usuarios/$usuarioId/reactivate',
      data: {'motivo': motivo},
    );
  }

  Future<String> _postMessage(
    String path, {
    required Map<String, dynamic> data,
  }) async {
    try {
      _talker.dataSource('POST $path');
      final response = await _dio.post<Map<String, dynamic>>(path, data: data);
      _talker.dataSource('POST $path completado.');

      return response.data?['message'] as String? ??
          'Operacion completada correctamente.';
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

  String _describeText(String? texto) {
    final normalized = texto?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return '${normalized.length} caracteres';
  }
}
