import 'package:dio/dio.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/finance/pricing/data/models/finanzas_report_record_models.dart';
import 'package:erp_curtiembre_fronted/features/finance/pricing/data/models/precio_sugerido_record_model.dart';
import 'package:erp_curtiembre_fronted/features/finance/pricing/data/models/rentabilidad_orden_record_model.dart';
import 'package:talker_flutter/talker_flutter.dart';

class FinanzasPricingRemoteDataSource {
  FinanzasPricingRemoteDataSource(this._dio, this._talker);

  final Dio _dio;
  final Talker _talker;

  Future<PrecioSugeridoRecordModel> getPrecioSugerido(
    int ordenProduccionId,
  ) async {
    final path = '/api/finanzas/precios/$ordenProduccionId';

    try {
      _talker.dataSource('GET $path');
      final response = await _dio.get<Map<String, dynamic>>(path);
      _talker.dataSource('GET $path completado.');
      return PrecioSugeridoRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<PrecioSugeridoRecordModel> calculatePrecioSugerido({
    required int ordenProduccionId,
    required double margenPorcentaje,
  }) async {
    final path = '/api/finanzas/precios/$ordenProduccionId/calcular';

    try {
      _talker.dataSource('POST $path con margenPorcentaje=$margenPorcentaje');
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: {'margenPorcentaje': margenPorcentaje},
      );
      _talker.dataSource('POST $path completado.');
      return PrecioSugeridoRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'POST $path');
    }
  }

  Future<RentabilidadOrdenRecordModel> getRentabilidad(
    int ordenProduccionId,
  ) async {
    final path = '/api/finanzas/rentabilidad/$ordenProduccionId';

    try {
      _talker.dataSource('GET $path');
      final response = await _dio.get<Map<String, dynamic>>(path);
      _talker.dataSource('GET $path completado.');
      return RentabilidadOrdenRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<RentabilidadOrdenRecordModel> calculateRentabilidad({
    required int ordenProduccionId,
    required double precioVenta,
  }) async {
    final path = '/api/finanzas/rentabilidad/$ordenProduccionId/calcular';

    try {
      _talker.dataSource('POST $path con precioVenta=$precioVenta');
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: {'precioVenta': precioVenta},
      );
      _talker.dataSource('POST $path completado.');
      return RentabilidadOrdenRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'POST $path');
    }
  }

  Future<List<ReporteCostoOrdenRecordModel>> listReporteCostoOrden() async {
    return _getList(
      '/api/finanzas/reportes/costo-orden',
      ReporteCostoOrdenRecordModel.fromJson,
    );
  }

  Future<List<ReporteCostoProcesoRecordModel>> listReporteCostoProceso() async {
    return _getList(
      '/api/finanzas/reportes/costo-proceso',
      ReporteCostoProcesoRecordModel.fromJson,
    );
  }

  Future<List<ReporteCostoClienteRecordModel>> listReporteCostoCliente() async {
    return _getList(
      '/api/finanzas/reportes/costo-cliente',
      ReporteCostoClienteRecordModel.fromJson,
    );
  }

  Future<List<ReporteIndirectoPeriodoRecordModel>>
  listReporteIndirectosPeriodo() async {
    return _getList(
      '/api/finanzas/reportes/indirectos-periodo',
      ReporteIndirectoPeriodoRecordModel.fromJson,
    );
  }

  Future<List<ReporteRentabilidadRecordModel>> listReporteRentabilidad() async {
    return _getList(
      '/api/finanzas/reportes/rentabilidad',
      ReporteRentabilidadRecordModel.fromJson,
    );
  }

  Future<List<ReportePrecioSugeridoRecordModel>>
  listReportePrecioSugerido() async {
    return _getList(
      '/api/finanzas/reportes/precio-sugerido',
      ReportePrecioSugeridoRecordModel.fromJson,
    );
  }

  Future<List<T>> _getList<T>(
    String path,
    T Function(Map<String, dynamic>) mapper,
  ) async {
    try {
      _talker.dataSource('GET $path');
      final response = await _dio.get<List<dynamic>>(path);
      final items = response.data ?? const [];
      _talker.dataSource('GET $path completado con ${items.length} registros.');
      return items
          .map((item) => mapper(item as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
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
