import 'package:dio/dio.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/finance/activos/data/models/activo_depreciable_record_model.dart';
import 'package:talker_flutter/talker_flutter.dart';

class ActivosRemoteDataSource {
  ActivosRemoteDataSource(this._dio, this._talker);

  final Dio _dio;
  final Talker _talker;

  Future<List<ActivoDepreciableRecordModel>> listActivos({
    String? texto,
    bool? activo,
  }) async {
    const path = '/api/finanzas/activos';

    try {
      final queryParameters = <String, dynamic>{};
      if (texto != null && texto.trim().isNotEmpty) {
        queryParameters['texto'] = texto.trim();
      }
      if (activo != null) {
        queryParameters['activo'] = activo;
      }

      _talker.dataSource(
        'GET $path con filtros texto=${_describeText(texto)}, activo=${_describeBool(activo)}',
      );
      final response = await _dio.get<List<dynamic>>(
        path,
        queryParameters: queryParameters,
      );
      final items = response.data ?? const [];
      _talker.dataSource('GET $path completado con ${items.length} activos.');
      return items
          .map(
            (item) => ActivoDepreciableRecordModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(growable: false);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<ActivoDepreciableRecordModel> getActivo(int id) async {
    final path = '/api/finanzas/activos/$id';

    try {
      _talker.dataSource('GET $path');
      final response = await _dio.get<Map<String, dynamic>>(path);
      _talker.dataSource('GET $path completado.');
      return ActivoDepreciableRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<ActivoDepreciableRecordModel> createActivo({
    required String codigo,
    required String nombre,
    required double valorCompra,
    required DateTime fechaCompra,
    required int vidaUtilMeses,
    required double valorResidual,
    required bool activo,
  }) async {
    const path = '/api/finanzas/activos';

    try {
      _talker.dataSource(
        'POST $path para codigo=${_describeText(codigo)}, nombre=${_describeText(nombre)}, valorCompra=$valorCompra, fechaCompra=${fechaCompra.toIso8601String()}, vidaUtilMeses=$vidaUtilMeses, valorResidual=$valorResidual, activo=$activo',
      );
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: {
          'codigo': codigo,
          'nombre': nombre,
          'valorCompra': valorCompra,
          'fechaCompra': fechaCompra.toIso8601String(),
          'vidaUtilMeses': vidaUtilMeses,
          'valorResidual': valorResidual,
          'activo': activo,
        },
      );
      _talker.dataSource('POST $path completado.');
      return ActivoDepreciableRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'POST $path');
    }
  }

  Future<ActivoDepreciableRecordModel> updateActivo({
    required int id,
    required String codigo,
    required String nombre,
    required double valorCompra,
    required DateTime fechaCompra,
    required int vidaUtilMeses,
    required double valorResidual,
    required bool activo,
  }) async {
    final path = '/api/finanzas/activos/$id';

    try {
      _talker.dataSource(
        'PUT $path para codigo=${_describeText(codigo)}, nombre=${_describeText(nombre)}, valorCompra=$valorCompra, fechaCompra=${fechaCompra.toIso8601String()}, vidaUtilMeses=$vidaUtilMeses, valorResidual=$valorResidual, activo=$activo',
      );
      final response = await _dio.put<Map<String, dynamic>>(
        path,
        data: {
          'codigo': codigo,
          'nombre': nombre,
          'valorCompra': valorCompra,
          'fechaCompra': fechaCompra.toIso8601String(),
          'vidaUtilMeses': vidaUtilMeses,
          'valorResidual': valorResidual,
          'activo': activo,
        },
      );
      _talker.dataSource('PUT $path completado.');
      return ActivoDepreciableRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'PUT $path');
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

  String _describeText(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return '${normalized.length} caracteres';
  }

  String _describeBool(bool? value) {
    if (value == null) {
      return 'sin-filtro';
    }

    return value.toString();
  }
}
