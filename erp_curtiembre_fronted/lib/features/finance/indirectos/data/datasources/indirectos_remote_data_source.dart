import 'package:dio/dio.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/finance/indirectos/data/models/costo_indirecto_record_model.dart';
import 'package:talker_flutter/talker_flutter.dart';

class IndirectosRemoteDataSource {
  IndirectosRemoteDataSource(this._dio, this._talker);

  final Dio _dio;
  final Talker _talker;

  Future<List<CostoIndirectoRecordModel>> listIndirectos({
    int? periodoCostoId,
    String? tipoCosto,
    String? texto,
  }) async {
    const path = '/api/finanzas/indirectos';

    try {
      final queryParameters = <String, dynamic>{};
      if (periodoCostoId != null) {
        queryParameters['periodoCostoId'] = periodoCostoId;
      }
      if (tipoCosto != null && tipoCosto.trim().isNotEmpty) {
        queryParameters['tipoCosto'] = tipoCosto.trim();
      }
      if (texto != null && texto.trim().isNotEmpty) {
        queryParameters['texto'] = texto.trim();
      }

      _talker.dataSource(
        'GET $path con filtros periodoCostoId=$periodoCostoId, tipoCosto=${_describeType(tipoCosto)}, texto=${_describeText(texto)}',
      );
      final response = await _dio.get<List<dynamic>>(
        path,
        queryParameters: queryParameters,
      );
      final items = response.data ?? const [];
      _talker.dataSource(
        'GET $path completado con ${items.length} costos indirectos.',
      );
      return items
          .map(
            (item) => CostoIndirectoRecordModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(growable: false);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<CostoIndirectoRecordModel> getIndirecto(int id) async {
    final path = '/api/finanzas/indirectos/$id';

    try {
      _talker.dataSource('GET $path');
      final response = await _dio.get<Map<String, dynamic>>(path);
      _talker.dataSource('GET $path completado.');
      return CostoIndirectoRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<CostoIndirectoRecordModel> createIndirecto({
    required int periodoCostoId,
    required String tipoCosto,
    String? descripcion,
    required double monto,
  }) async {
    const path = '/api/finanzas/indirectos';

    try {
      _talker.dataSource(
        'POST $path para periodoCostoId=$periodoCostoId, tipoCosto=${_describeType(tipoCosto)}, descripcion=${_describeText(descripcion)}, monto=$monto',
      );
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: {
          'periodoCostoId': periodoCostoId,
          'tipoCosto': tipoCosto,
          'descripcion': descripcion,
          'monto': monto,
        },
      );
      _talker.dataSource('POST $path completado.');
      return CostoIndirectoRecordModel.fromJson(response.data!);
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

  String _describeType(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return normalized;
  }
}
