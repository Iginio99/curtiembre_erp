import 'package:dio/dio.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/finance/periodos/data/models/periodo_costo_record_model.dart';
import 'package:talker_flutter/talker_flutter.dart';

class PeriodosRemoteDataSource {
  PeriodosRemoteDataSource(this._dio, this._talker);

  final Dio _dio;
  final Talker _talker;

  Future<List<PeriodoCostoRecordModel>> listPeriodos({
    int? anio,
    int? mes,
    String? estado,
  }) async {
    const path = '/api/finanzas/periodos';

    try {
      final queryParameters = <String, dynamic>{};
      if (anio != null) {
        queryParameters['anio'] = anio;
      }
      if (mes != null) {
        queryParameters['mes'] = mes;
      }
      if (estado != null && estado.trim().isNotEmpty) {
        queryParameters['estado'] = estado.trim();
      }

      _talker.dataSource(
        'GET $path con filtros anio=$anio, mes=$mes, estado=${_describeText(estado)}',
      );
      final response = await _dio.get<List<dynamic>>(
        path,
        queryParameters: queryParameters,
      );
      final items = response.data ?? const [];
      _talker.dataSource('GET $path completado con ${items.length} periodos.');
      return items
          .map(
            (item) =>
                PeriodoCostoRecordModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<PeriodoCostoRecordModel> getPeriodo(int id) async {
    final path = '/api/finanzas/periodos/$id';

    try {
      _talker.dataSource('GET $path');
      final response = await _dio.get<Map<String, dynamic>>(path);
      _talker.dataSource('GET $path completado.');
      return PeriodoCostoRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<PeriodoCostoRecordModel> createPeriodo({
    required int anio,
    required int mes,
    String? observacion,
  }) async {
    const path = '/api/finanzas/periodos';

    try {
      _talker.dataSource(
        'POST $path para anio=$anio, mes=$mes, observacion=${_describeText(observacion)}',
      );
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: {'anio': anio, 'mes': mes, 'observacion': observacion},
      );
      _talker.dataSource('POST $path completado.');
      return PeriodoCostoRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'POST $path');
    }
  }

  Future<PeriodoCostoRecordModel> closePeriodo({
    required int id,
    String? observacion,
  }) async {
    final path = '/api/finanzas/periodos/$id/cerrar';

    try {
      _talker.dataSource(
        'POST $path con observacion=${_describeText(observacion)}',
      );
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: {'observacion': observacion},
      );
      _talker.dataSource('POST $path completado.');
      return PeriodoCostoRecordModel.fromJson(response.data!);
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

    return '${normalized.length} caracteres';
  }
}
