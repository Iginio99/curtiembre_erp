import 'package:dio/dio.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/finance/depreciaciones/data/models/depreciacion_periodo_record_model.dart';
import 'package:talker_flutter/talker_flutter.dart';

class DepreciacionesRemoteDataSource {
  DepreciacionesRemoteDataSource(this._dio, this._talker);

  final Dio _dio;
  final Talker _talker;

  Future<List<DepreciacionPeriodoRecordModel>> listDepreciaciones({
    int? periodoCostoId,
    int? activoDepreciableId,
  }) async {
    const path = '/api/finanzas/depreciaciones';

    try {
      final queryParameters = <String, dynamic>{};
      if (periodoCostoId != null) {
        queryParameters['periodoCostoId'] = periodoCostoId;
      }
      if (activoDepreciableId != null) {
        queryParameters['activoDepreciableId'] = activoDepreciableId;
      }

      _talker.dataSource(
        'GET $path con filtros periodoCostoId=$periodoCostoId, activoDepreciableId=$activoDepreciableId',
      );
      final response = await _dio.get<List<dynamic>>(
        path,
        queryParameters: queryParameters,
      );
      final items = response.data ?? const [];
      _talker.dataSource(
        'GET $path completado con ${items.length} depreciaciones.',
      );
      return items
          .map(
            (item) => DepreciacionPeriodoRecordModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(growable: false);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<DepreciacionPeriodoRecordModel> getDepreciacion(int id) async {
    final path = '/api/finanzas/depreciaciones/$id';

    try {
      _talker.dataSource('GET $path');
      final response = await _dio.get<Map<String, dynamic>>(path);
      _talker.dataSource('GET $path completado.');
      return DepreciacionPeriodoRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<void> calculateForPeriod(int periodoId) async {
    final path = '/api/finanzas/periodos/$periodoId/calcular-depreciacion';

    try {
      _talker.dataSource('POST $path');
      await _dio.post<void>(path);
      _talker.dataSource('POST $path completado.');
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
