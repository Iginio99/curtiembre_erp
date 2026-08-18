import 'package:dio/dio.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/alerts/data/models/alert_record_model.dart';

class AlertsRemoteDataSource {
  AlertsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<AlertRecordModel>> listActivas() async {
    try {
      final response = await _dio.get<List<dynamic>>('/api/alertas/activas');
      final items = response.data ?? const [];
      return items
          .map((item) => AlertRecordModel.fromJson(item as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  Future<List<AlertRecordModel>> listAlerts({
    String? estado,
    String? severidad,
    String? tipoAlerta,
    String? moduloOrigen,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/api/alertas',
        queryParameters: {
          if (estado != null && estado.trim().isNotEmpty) 'estado': estado.trim(),
          if (severidad != null && severidad.trim().isNotEmpty) 'severidad': severidad.trim(),
          if (tipoAlerta != null && tipoAlerta.trim().isNotEmpty) 'tipoAlerta': tipoAlerta.trim(),
          if (moduloOrigen != null && moduloOrigen.trim().isNotEmpty)
            'moduloOrigen': moduloOrigen.trim(),
          if (fechaDesde != null) 'fechaDesde': fechaDesde.toIso8601String(),
          if (fechaHasta != null) 'fechaHasta': fechaHasta.toIso8601String(),
        },
      );
      final items = response.data ?? const [];
      return items
          .map((item) => AlertRecordModel.fromJson(item as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  Future<AlertDetailModel> getAlert(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/alertas/$id');
      return AlertDetailModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  Future<AlertsSummaryModel> getSummary() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/alertas/resumen');
      return AlertsSummaryModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  Future<List<AlertHistoryItemModel>> getHistory(int id) async {
    try {
      final response = await _dio.get<List<dynamic>>('/api/alertas/$id/historial');
      final items = response.data ?? const [];
      return items
          .map((item) => AlertHistoryItemModel.fromJson(item as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  Future<AlertDetailModel> markAsRead(int id) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>('/api/alertas/$id/marcar-leida');
      return AlertDetailModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  Future<AlertDetailModel> closeAlert(int id, {String? comentario}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/alertas/$id/cerrar',
        data: comentario == null || comentario.trim().isEmpty
            ? const {}
            : <String, dynamic>{'comentario': comentario.trim()},
      );
      return AlertDetailModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }
}
