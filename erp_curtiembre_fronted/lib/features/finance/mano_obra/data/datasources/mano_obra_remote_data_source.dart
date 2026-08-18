import 'package:dio/dio.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/finance/mano_obra/data/models/mano_obra_directa_record_model.dart';
import 'package:talker_flutter/talker_flutter.dart';

class ManoObraRemoteDataSource {
  ManoObraRemoteDataSource(this._dio, this._talker);

  final Dio _dio;
  final Talker _talker;

  Future<List<ManoObraDirectaRecordModel>> listManoObra({
    int? ordenProduccionId,
    int? ordenProcesoId,
  }) async {
    const path = '/api/finanzas/mano-obra';

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
        'GET $path completado con ${items.length} registros de mano de obra.',
      );
      return items
          .map(
            (item) => ManoObraDirectaRecordModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(growable: false);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<ManoObraDirectaRecordModel> getManoObra(int id) async {
    final path = '/api/finanzas/mano-obra/$id';

    try {
      _talker.dataSource('GET $path');
      final response = await _dio.get<Map<String, dynamic>>(path);
      _talker.dataSource('GET $path completado.');
      return ManoObraDirectaRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<ManoObraDirectaRecordModel> createManoObra({
    required int ordenProduccionId,
    required int ordenProcesoId,
    required double monto,
    String? descripcion,
  }) async {
    const path = '/api/finanzas/mano-obra';

    try {
      _talker.dataSource(
        'POST $path para ordenProduccionId=$ordenProduccionId, ordenProcesoId=$ordenProcesoId, monto=$monto, descripcion=${_describeText(descripcion)}',
      );
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: {
          'ordenProduccionId': ordenProduccionId,
          'ordenProcesoId': ordenProcesoId,
          'monto': monto,
          'descripcion': descripcion,
        },
      );
      _talker.dataSource('POST $path completado.');
      return ManoObraDirectaRecordModel.fromJson(response.data!);
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
