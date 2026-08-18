import 'package:dio/dio.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/production/solicitudes_insumos/data/models/solicitud_insumo_record_model.dart';
import 'package:erp_curtiembre_fronted/features/production/solicitudes_insumos/data/models/solicitud_insumo_detail_model.dart';
import 'package:talker_flutter/talker_flutter.dart';

class SolicitudesInsumosRemoteDataSource {
  SolicitudesInsumosRemoteDataSource(this._dio, this._talker);

  final Dio _dio;
  final Talker _talker;

  Future<List<SolicitudInsumoRecordModel>> list({String? estado}) async {
    const path = '/api/produccion/solicitudes-insumos';
    try {
      final response = await _dio.get<List<dynamic>>(
        path,
        queryParameters: estado == null ? null : {'estado': estado},
      );
      return (response.data ?? const [])
          .map(
            (item) => SolicitudInsumoRecordModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(growable: false);
    } on DioException catch (exception) {
      throw _map(exception, 'GET $path');
    }
  }

  Future<void> deliver({
    required int id,
    String? motivo,
    String? observacion,
  }) async {
    final path = '/api/produccion/solicitudes-insumos/$id/entregar';
    try {
      await _dio.post<void>(
        path,
        data: {'motivo': motivo, 'observacion': observacion},
      );
    } on DioException catch (exception) {
      throw _map(exception, 'POST $path');
    }
  }

  Future<SolicitudInsumoDetailModel> getDetail(int id) async {
    final path = '/api/produccion/solicitudes-insumos/$id';
    try {
      final response = await _dio.get<Map<String, dynamic>>(path);
      return SolicitudInsumoDetailModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _map(exception, 'GET $path');
    }
  }

  ApiException _map(DioException exception, String operation) {
    final error = ApiException.fromDioException(exception);
    _talker.dataSource(
      '$operation fallo: ${error.message}',
      logLevel: LogLevel.error,
      exception: error,
    );
    return error;
  }
}
