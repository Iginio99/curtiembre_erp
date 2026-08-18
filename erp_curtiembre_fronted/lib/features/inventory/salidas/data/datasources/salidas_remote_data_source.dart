import 'package:dio/dio.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/inventory/salidas/data/models/salida_detail_model.dart';
import 'package:erp_curtiembre_fronted/features/inventory/salidas/data/models/salida_record_model.dart';
import 'package:erp_curtiembre_fronted/features/inventory/salidas/domain/repositories/salidas_repository.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/data/models/insumo_lookup_model.dart';
import 'package:talker_flutter/talker_flutter.dart';

class SalidasRemoteDataSource {
  SalidasRemoteDataSource(this._dio, this._talker);

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

  Future<List<SalidaRecordModel>> listSalidas({
    String? texto,
    String? tipoSalida,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    const path = '/api/inventario/salidas';

    try {
      _talker.dataSource(
        'GET $path con filtros texto=${_describeText(texto)}, tipoSalida=${_describeType(tipoSalida)}, fechaDesde=${_describeDate(fechaDesde)}, fechaHasta=${_describeDate(fechaHasta)}',
      );
      final response = await _dio.get<List<dynamic>>(
        path,
        queryParameters: {
          if (texto != null && texto.trim().isNotEmpty) 'texto': texto.trim(),
          if (tipoSalida != null && tipoSalida.trim().isNotEmpty)
            'tipoSalida': tipoSalida,
          if (fechaDesde != null) 'fechaDesde': fechaDesde.toIso8601String(),
          if (fechaHasta != null) 'fechaHasta': fechaHasta.toIso8601String(),
        },
      );
      final items = response.data ?? const [];
      _talker.dataSource('GET $path completado con ${items.length} salidas.');
      return items
          .map(
            (item) => SalidaRecordModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<SalidaDetailModel> getSalidaDetail(int id) async {
    final path = '/api/inventario/salidas/$id';

    try {
      _talker.dataSource('GET $path');
      final response = await _dio.get<Map<String, dynamic>>(path);
      _talker.dataSource('GET $path completado.');
      return SalidaDetailModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<SalidaDetailModel> registerGeneral({
    required String motivo,
    String? observacion,
    required List<RegistrarSalidaDetalleInput> detalles,
  }) async {
    return _postSalida(
      '/api/inventario/salidas/general',
      motivo: motivo,
      observacion: observacion,
      detalles: detalles,
    );
  }

  Future<SalidaDetailModel> registerSupplierReturn({
    required String motivo,
    String? observacion,
    required List<RegistrarSalidaDetalleInput> detalles,
  }) async {
    return _postSalida(
      '/api/inventario/salidas/devolucion-proveedor',
      motivo: motivo,
      observacion: observacion,
      detalles: detalles,
    );
  }

  Future<SalidaDetailModel> registerNegativeAdjustment({
    required String motivo,
    String? observacion,
    required List<RegistrarSalidaDetalleInput> detalles,
  }) async {
    return _postSalida(
      '/api/inventario/salidas/ajuste-negativo',
      motivo: motivo,
      observacion: observacion,
      detalles: detalles,
    );
  }

  Future<SalidaDetailModel> _postSalida(
    String path, {
    required String motivo,
    String? observacion,
    required List<RegistrarSalidaDetalleInput> detalles,
  }) async {
    try {
      _talker.dataSource(
        'POST $path con motivo=${_describeText(motivo)}, observacion=${_describeText(observacion)}, detalles=${detalles.length}',
      );
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: {
          'motivo': motivo,
          'observacion': observacion,
          'detalles': detalles
              .map(
                (item) => {
                  'insumoId': item.insumoId,
                  'cantidad': item.cantidad,
                  'observacion': item.observacion,
                },
              )
              .toList(growable: false),
        },
      );
      _talker.dataSource('POST $path completado.');
      return SalidaDetailModel.fromJson(response.data!);
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

  String _describeDate(DateTime? value) {
    if (value == null) {
      return 'sin-filtro';
    }

    return value.toIso8601String();
  }
}
