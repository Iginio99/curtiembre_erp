import 'package:dio/dio.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/finance/costos/data/models/costo_orden_record_model.dart';
import 'package:erp_curtiembre_fronted/features/finance/costos/data/models/costo_proceso_record_model.dart';
import 'package:talker_flutter/talker_flutter.dart';

class CostosFinanzasRemoteDataSource {
  CostosFinanzasRemoteDataSource(this._dio, this._talker);

  final Dio _dio;
  final Talker _talker;

  Future<List<CostoProcesoRecordModel>> listCostosProceso({
    int? ordenProduccionId,
    int? ordenProcesoId,
  }) async {
    const path = '/api/finanzas/costos/procesos';

    try {
      final queryParameters = <String, dynamic>{};
      if (ordenProduccionId != null) {
        queryParameters['ordenProduccionId'] = ordenProduccionId;
      }
      if (ordenProcesoId != null) {
        queryParameters['ordenProcesoId'] = ordenProcesoId;
      }

      _talker.dataSource(
        'GET $path con filtros ordenProduccionId=$ordenProduccionId, ordenProcesoId=$ordenProcesoId',
      );
      final response = await _dio.get<List<dynamic>>(
        path,
        queryParameters: queryParameters,
      );
      final items = response.data ?? const [];
      _talker.dataSource(
        'GET $path completado con ${items.length} costos de proceso.',
      );
      return items
          .map(
            (item) =>
                CostoProcesoRecordModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<CostoProcesoRecordModel> getCostoProceso(int ordenProcesoId) async {
    final path = '/api/finanzas/costos/procesos/$ordenProcesoId';

    try {
      _talker.dataSource('GET $path');
      final response = await _dio.get<Map<String, dynamic>>(path);
      _talker.dataSource('GET $path completado.');
      return CostoProcesoRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<CostoProcesoRecordModel> calculateCostoProceso({
    required int ordenProduccionId,
    required int ordenProcesoId,
  }) async {
    const path = '/api/finanzas/costos/procesos/calcular';

    try {
      _talker.dataSource(
        'POST $path para ordenProduccionId=$ordenProduccionId, ordenProcesoId=$ordenProcesoId',
      );
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: {
          'ordenProduccionId': ordenProduccionId,
          'ordenProcesoId': ordenProcesoId,
        },
      );
      _talker.dataSource('POST $path completado.');
      return CostoProcesoRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'POST $path');
    }
  }

  Future<List<CostoOrdenRecordModel>> listCostosOrden({
    int? ordenProduccionId,
    int? periodoCostoId,
    String? estado,
  }) async {
    const path = '/api/finanzas/costos/ordenes';

    try {
      final queryParameters = <String, dynamic>{};
      if (ordenProduccionId != null) {
        queryParameters['ordenProduccionId'] = ordenProduccionId;
      }
      if (periodoCostoId != null) {
        queryParameters['periodoCostoId'] = periodoCostoId;
      }
      if (estado != null && estado.trim().isNotEmpty) {
        queryParameters['estado'] = estado.trim();
      }

      _talker.dataSource(
        'GET $path con filtros ordenProduccionId=$ordenProduccionId, periodoCostoId=$periodoCostoId, estado=${_describeText(estado)}',
      );
      final response = await _dio.get<List<dynamic>>(
        path,
        queryParameters: queryParameters,
      );
      final items = response.data ?? const [];
      _talker.dataSource(
        'GET $path completado con ${items.length} costos de orden.',
      );
      return items
          .map(
            (item) =>
                CostoOrdenRecordModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<CostoOrdenRecordModel> getCostoOrden(int ordenProduccionId) async {
    final path = '/api/finanzas/costos/ordenes/$ordenProduccionId';

    try {
      _talker.dataSource('GET $path');
      final response = await _dio.get<Map<String, dynamic>>(path);
      _talker.dataSource('GET $path completado.');
      return CostoOrdenRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<CostoOrdenRecordModel> calculateCostoOrdenEstimado(
    int ordenProduccionId,
  ) async {
    final path =
        '/api/finanzas/costos/ordenes/$ordenProduccionId/calcular-estimado';

    try {
      _talker.dataSource('POST $path');
      final response = await _dio.post<Map<String, dynamic>>(path);
      _talker.dataSource('POST $path completado.');
      return CostoOrdenRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'POST $path');
    }
  }

  Future<CostoOrdenRecordModel> calculateCostoOrdenReal(
    int ordenProduccionId,
  ) async {
    final path =
        '/api/finanzas/costos/ordenes/$ordenProduccionId/calcular-real';

    try {
      _talker.dataSource('POST $path');
      final response = await _dio.post<Map<String, dynamic>>(path);
      _talker.dataSource('POST $path completado.');
      return CostoOrdenRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'POST $path');
    }
  }

  Future<CostoOrdenRecordModel> closeCostoOrden(int ordenProduccionId) async {
    final path = '/api/finanzas/costos/ordenes/$ordenProduccionId/cerrar';

    try {
      _talker.dataSource('POST $path');
      final response = await _dio.post<Map<String, dynamic>>(path);
      _talker.dataSource('POST $path completado.');
      return CostoOrdenRecordModel.fromJson(response.data!);
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

  String _describeText(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return normalized;
  }
}
