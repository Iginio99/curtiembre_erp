import 'package:dio/dio.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/inventory/ajustes/data/models/ajuste_detail_model.dart';
import 'package:erp_curtiembre_fronted/features/inventory/ajustes/data/models/ajuste_record_model.dart';
import 'package:erp_curtiembre_fronted/features/inventory/ajustes/domain/repositories/ajustes_repository.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/data/models/insumo_lookup_model.dart';
import 'package:talker_flutter/talker_flutter.dart';

class AjustesRemoteDataSource {
  AjustesRemoteDataSource(this._dio, this._talker);

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

  Future<List<AjusteRecordModel>> listAjustes({
    String? texto,
    String? tipoAjuste,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    const path = '/api/inventario/ajustes';

    try {
      _talker.dataSource(
        'GET $path con filtros texto=${_describeText(texto)}, tipoAjuste=${_describeType(tipoAjuste)}, fechaDesde=${_describeDate(fechaDesde)}, fechaHasta=${_describeDate(fechaHasta)}',
      );
      final response = await _dio.get<List<dynamic>>(
        path,
        queryParameters: {
          if (texto != null && texto.trim().isNotEmpty) 'texto': texto.trim(),
          if (tipoAjuste != null && tipoAjuste.trim().isNotEmpty)
            'tipoAjuste': tipoAjuste,
          if (fechaDesde != null) 'fechaDesde': fechaDesde.toIso8601String(),
          if (fechaHasta != null) 'fechaHasta': fechaHasta.toIso8601String(),
        },
      );
      final items = response.data ?? const [];
      _talker.dataSource('GET $path completado con ${items.length} ajustes.');
      return items
          .map(
            (item) => AjusteRecordModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<AjusteDetailModel> getAjusteDetail(int id) async {
    final path = '/api/inventario/ajustes/$id';

    try {
      _talker.dataSource('GET $path');
      final response = await _dio.get<Map<String, dynamic>>(path);
      _talker.dataSource('GET $path completado.');
      return AjusteDetailModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<AjusteDetailModel> registerPositive({
    required String motivo,
    String? observacion,
    required List<RegistrarAjusteDetalleInput> detalles,
  }) async {
    return _postAjuste(
      '/api/inventario/ajustes/positivo',
      motivo: motivo,
      observacion: observacion,
      detalles: detalles,
    );
  }

  Future<AjusteDetailModel> registerNegative({
    required String motivo,
    String? observacion,
    required List<RegistrarAjusteDetalleInput> detalles,
  }) async {
    return _postAjuste(
      '/api/inventario/ajustes/negativo',
      motivo: motivo,
      observacion: observacion,
      detalles: detalles,
    );
  }

  Future<AjusteDetailModel> _postAjuste(
    String path, {
    required String motivo,
    String? observacion,
    required List<RegistrarAjusteDetalleInput> detalles,
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
                  'costoUnitario': item.costoUnitario,
                },
              )
              .toList(growable: false),
        },
      );
      _talker.dataSource(
        'POST $path completado con ${detalles.length} detalles.',
      );
      return AjusteDetailModel.fromJson(response.data!);
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
      return 'sin-fecha';
    }

    return value.toIso8601String();
  }
}
