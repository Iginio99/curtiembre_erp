import 'package:dio/dio.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/inventory/kardex/data/models/kardex_record_model.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/data/models/insumo_lookup_model.dart';
import 'package:talker_flutter/talker_flutter.dart';

class KardexRemoteDataSource {
  KardexRemoteDataSource(this._dio, this._talker);

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

  Future<List<KardexRecordModel>> listKardex({
    int? insumoId,
    String? tipoMovimiento,
    String? documentoTipo,
    int? usuarioResponsableId,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    const path = '/api/inventario/kardex';

    try {
      final queryParameters = <String, dynamic>{};
      if (insumoId != null) {
        queryParameters['insumoId'] = insumoId;
      }
      if (tipoMovimiento != null && tipoMovimiento.trim().isNotEmpty) {
        queryParameters['tipoMovimiento'] = tipoMovimiento;
      }
      if (documentoTipo != null && documentoTipo.trim().isNotEmpty) {
        queryParameters['documentoTipo'] = documentoTipo;
      }
      if (usuarioResponsableId != null) {
        queryParameters['usuarioResponsableId'] = usuarioResponsableId;
      }
      if (fechaDesde != null) {
        queryParameters['fechaDesde'] = fechaDesde.toIso8601String();
      }
      if (fechaHasta != null) {
        queryParameters['fechaHasta'] = fechaHasta.toIso8601String();
      }

      _talker.dataSource(
        'GET $path con filtros insumoId=$insumoId, tipoMovimiento=${_describeState(tipoMovimiento)}, documentoTipo=${_describeState(documentoTipo)}, usuarioResponsableId=$usuarioResponsableId, fechaDesde=${_describeDate(fechaDesde)}, fechaHasta=${_describeDate(fechaHasta)}',
      );
      final response = await _dio.get<List<dynamic>>(
        path,
        queryParameters: queryParameters,
      );
      final items = response.data ?? const [];
      _talker.dataSource(
        'GET $path completado con ${items.length} movimientos.',
      );
      return items
          .map(
            (item) => KardexRecordModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<List<KardexRecordModel>> listKardexByInsumo(
    int insumoId, {
    String? tipoMovimiento,
    String? documentoTipo,
    int? usuarioResponsableId,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    final path = '/api/inventario/kardex/$insumoId';

    try {
      final queryParameters = <String, dynamic>{};
      if (tipoMovimiento != null && tipoMovimiento.trim().isNotEmpty) {
        queryParameters['tipoMovimiento'] = tipoMovimiento;
      }
      if (documentoTipo != null && documentoTipo.trim().isNotEmpty) {
        queryParameters['documentoTipo'] = documentoTipo;
      }
      if (usuarioResponsableId != null) {
        queryParameters['usuarioResponsableId'] = usuarioResponsableId;
      }
      if (fechaDesde != null) {
        queryParameters['fechaDesde'] = fechaDesde.toIso8601String();
      }
      if (fechaHasta != null) {
        queryParameters['fechaHasta'] = fechaHasta.toIso8601String();
      }

      _talker.dataSource(
        'GET $path con filtros tipoMovimiento=${_describeState(tipoMovimiento)}, documentoTipo=${_describeState(documentoTipo)}, usuarioResponsableId=$usuarioResponsableId, fechaDesde=${_describeDate(fechaDesde)}, fechaHasta=${_describeDate(fechaHasta)}',
      );
      final response = await _dio.get<List<dynamic>>(
        path,
        queryParameters: queryParameters,
      );
      final items = response.data ?? const [];
      _talker.dataSource(
        'GET $path completado con ${items.length} movimientos.',
      );
      return items
          .map(
            (item) => KardexRecordModel.fromJson(item as Map<String, dynamic>),
          )
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

  String _describeState(String? value) {
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
