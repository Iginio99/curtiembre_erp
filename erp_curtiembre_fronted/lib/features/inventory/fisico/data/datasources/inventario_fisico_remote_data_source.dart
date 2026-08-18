import 'package:dio/dio.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/inventory/fisico/data/models/inventario_fisico_detail_model.dart';
import 'package:erp_curtiembre_fronted/features/inventory/fisico/data/models/inventario_fisico_record_model.dart';
import 'package:erp_curtiembre_fronted/features/inventory/fisico/domain/repositories/inventario_fisico_repository.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/data/models/insumo_lookup_model.dart';
import 'package:talker_flutter/talker_flutter.dart';

class InventarioFisicoRemoteDataSource {
  InventarioFisicoRemoteDataSource(this._dio, this._talker);

  final Dio _dio;
  final Talker _talker;

  Future<List<InsumoLookupModel>> listActiveInsumos() async {
    const path = '/api/inventario/catalogos/insumos/activos';

    try {
      _talker.dataSource('GET $path');
      final response = await _dio.get<List<dynamic>>(path);
      final items = response.data ?? const [];
      _talker.dataSource(
        'GET $path completado con ${items.length} insumos activos.',
      );
      return items
          .map(
            (item) => InsumoLookupModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<List<InventarioFisicoRecordModel>> listInventariosFisicos({
    int? periodoAnio,
    int? periodoMes,
    String? estado,
  }) async {
    const path = '/api/inventario/fisico';

    try {
      final queryParameters = <String, Object>{};
      if (periodoAnio != null) {
        queryParameters['periodoAnio'] = periodoAnio;
      }
      if (periodoMes != null) {
        queryParameters['periodoMes'] = periodoMes;
      }
      if (estado != null && estado.trim().isNotEmpty) {
        queryParameters['estado'] = estado;
      }

      _talker.dataSource(
        'GET $path con filtros periodoAnio=$periodoAnio, periodoMes=$periodoMes, estado=${_describeState(estado)}',
      );
      final response = await _dio.get<List<dynamic>>(
        path,
        queryParameters: queryParameters,
      );
      final items = response.data ?? const [];
      _talker.dataSource(
        'GET $path completado con ${items.length} inventarios fisicos.',
      );
      return items
          .map(
            (item) => InventarioFisicoRecordModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(growable: false);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<InventarioFisicoDetailModel> getInventarioFisicoDetail(int id) async {
    final path = '/api/inventario/fisico/$id';

    try {
      _talker.dataSource('GET $path');
      final response = await _dio.get<Map<String, dynamic>>(path);
      _talker.dataSource('GET $path completado.');
      return InventarioFisicoDetailModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<InventarioFisicoDetailModel> createInventarioFisico({
    required int periodoAnio,
    required int periodoMes,
    String? observacion,
  }) async {
    const path = '/api/inventario/fisico';

    try {
      _talker.dataSource(
        'POST $path con periodoAnio=$periodoAnio, periodoMes=$periodoMes, observacion=${_describeText(observacion)}',
      );
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: {
          'periodoAnio': periodoAnio,
          'periodoMes': periodoMes,
          'observacion': observacion,
        },
      );
      _talker.dataSource('POST $path completado.');
      return InventarioFisicoDetailModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'POST $path');
    }
  }

  Future<InventarioFisicoDetailModel> registerCounts({
    required int inventarioFisicoId,
    required List<RegistrarConteoInventarioFisicoDetalleInput> detalles,
  }) async {
    final path = '/api/inventario/fisico/$inventarioFisicoId/detalle';

    try {
      _talker.dataSource(
        'POST $path con ${detalles.length} detalles de conteo.',
      );
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: {
          'detalles': detalles
              .map(
                (item) => {
                  'insumoId': item.insumoId,
                  'stockContado': item.stockContado,
                  'observacion': item.observacion,
                },
              )
              .toList(growable: false),
        },
      );
      _talker.dataSource(
        'POST $path completado con ${detalles.length} detalles.',
      );
      return InventarioFisicoDetailModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'POST $path');
    }
  }

  Future<InventarioFisicoDetailModel> closeInventarioFisico({
    required int inventarioFisicoId,
    String? observacion,
  }) async {
    final path = '/api/inventario/fisico/$inventarioFisicoId/cerrar';

    try {
      _talker.dataSource(
        'POST $path con observacion=${_describeText(observacion)}',
      );
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: {'observacion': observacion},
      );
      _talker.dataSource('POST $path completado.');
      return InventarioFisicoDetailModel.fromJson(response.data!);
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

  String _describeState(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return normalized;
  }
}
