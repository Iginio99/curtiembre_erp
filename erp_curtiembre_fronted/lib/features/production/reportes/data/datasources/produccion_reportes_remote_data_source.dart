import 'package:dio/dio.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/production/reportes/data/models/consumo_proceso_reporte_item_model.dart';
import 'package:erp_curtiembre_fronted/features/production/reportes/data/models/costo_orden_reporte_item_model.dart';
import 'package:erp_curtiembre_fronted/features/production/reportes/data/models/costo_proceso_reporte_item_model.dart';
import 'package:erp_curtiembre_fronted/features/production/reportes/data/models/merma_reporte_item_model.dart';
import 'package:erp_curtiembre_fronted/features/production/reportes/data/models/orden_activa_reporte_item_model.dart';
import 'package:erp_curtiembre_fronted/features/production/reportes/data/models/orden_cliente_reporte_item_model.dart';
import 'package:erp_curtiembre_fronted/features/production/reportes/data/models/tiempo_proceso_reporte_item_model.dart';
import 'package:talker_flutter/talker_flutter.dart';

class ProduccionReportesRemoteDataSource {
  ProduccionReportesRemoteDataSource(this._dio, this._talker);

  final Dio _dio;
  final Talker _talker;

  Future<List<OrdenActivaReporteItemModel>> listOrdenesActivas() async {
    const path = '/api/produccion/reportes/ordenes-activas';

    try {
      _talker.dataSource('GET $path');
      final response = await _dio.get<List<dynamic>>(path);
      final items = response.data ?? const [];
      _talker.dataSource(
        'GET $path completado con ${items.length} ordenes activas.',
      );
      return items
          .map(
            (item) => OrdenActivaReporteItemModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(growable: false);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<List<OrdenClienteReporteItemModel>> listOrdenesPorCliente({
    int? clienteId,
    String? estado,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    const path = '/api/produccion/reportes/ordenes-cliente';

    try {
      final queryParameters = <String, dynamic>{};
      if (clienteId != null) {
        queryParameters['clienteId'] = clienteId;
      }
      if (estado != null && estado.trim().isNotEmpty) {
        queryParameters['estado'] = estado.trim();
      }
      if (fechaDesde != null) {
        queryParameters['fechaDesde'] = fechaDesde.toIso8601String();
      }
      if (fechaHasta != null) {
        queryParameters['fechaHasta'] = fechaHasta.toIso8601String();
      }

      _talker.dataSource(
        'GET $path con filtros clienteId=$clienteId, estado=${_describeState(estado)}, fechaDesde=${_describeDate(fechaDesde)}, fechaHasta=${_describeDate(fechaHasta)}',
      );
      final response = await _dio.get<List<dynamic>>(
        path,
        queryParameters: queryParameters,
      );
      final items = response.data ?? const [];
      _talker.dataSource('GET $path completado con ${items.length} registros.');
      return items
          .map(
            (item) => OrdenClienteReporteItemModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(growable: false);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<List<ConsumoProcesoReporteItemModel>> listConsumoPorProceso({
    int? ordenProduccionId,
    int? ordenProcesoId,
  }) async {
    const path = '/api/produccion/reportes/consumo-proceso';

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
      _talker.dataSource('GET $path completado con ${items.length} registros.');
      return items
          .map(
            (item) => ConsumoProcesoReporteItemModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(growable: false);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<List<CostoOrdenReporteItemModel>> listCostosPorOrden({
    int? ordenProduccionId,
  }) async {
    const path = '/api/produccion/reportes/costos-orden';
    try {
      final response = await _dio.get<List<dynamic>>(
        path,
        queryParameters: ordenProduccionId == null
            ? null
            : {'ordenProduccionId': ordenProduccionId},
      );
      return (response.data ?? const [])
          .map(
            (item) => CostoOrdenReporteItemModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(growable: false);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<List<CostoProcesoReporteItemModel>> listCostosPorProceso({
    int? ordenProduccionId,
  }) async {
    const path = '/api/produccion/reportes/costos-proceso';
    try {
      final response = await _dio.get<List<dynamic>>(
        path,
        queryParameters: ordenProduccionId == null
            ? null
            : {'ordenProduccionId': ordenProduccionId},
      );
      return (response.data ?? const [])
          .map(
            (item) => CostoProcesoReporteItemModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(growable: false);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<List<MermaReporteItemModel>> listMerma({
    int? ordenProduccionId,
    int? ordenProcesoId,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    const path = '/api/produccion/reportes/merma';

    try {
      final queryParameters = <String, dynamic>{};
      if (ordenProduccionId != null) {
        queryParameters['ordenProduccionId'] = ordenProduccionId;
      }
      if (ordenProcesoId != null) {
        queryParameters['ordenProcesoId'] = ordenProcesoId;
      }
      if (fechaDesde != null) {
        queryParameters['fechaDesde'] = fechaDesde.toIso8601String();
      }
      if (fechaHasta != null) {
        queryParameters['fechaHasta'] = fechaHasta.toIso8601String();
      }

      _talker.dataSource(
        'GET $path con filtros ordenProduccionId=$ordenProduccionId, ordenProcesoId=$ordenProcesoId, fechaDesde=${_describeDate(fechaDesde)}, fechaHasta=${_describeDate(fechaHasta)}',
      );
      final response = await _dio.get<List<dynamic>>(
        path,
        queryParameters: queryParameters,
      );
      final items = response.data ?? const [];
      _talker.dataSource(
        'GET $path completado con ${items.length} registros de merma.',
      );
      return items
          .map(
            (item) =>
                MermaReporteItemModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<List<TiempoProcesoReporteItemModel>> listTiemposProceso({
    int? ordenProduccionId,
    int? ordenProcesoId,
    String? estado,
  }) async {
    const path = '/api/produccion/reportes/tiempos-proceso';

    try {
      final queryParameters = <String, dynamic>{};
      if (ordenProduccionId != null) {
        queryParameters['ordenProduccionId'] = ordenProduccionId;
      }
      if (ordenProcesoId != null) {
        queryParameters['ordenProcesoId'] = ordenProcesoId;
      }
      if (estado != null && estado.trim().isNotEmpty) {
        queryParameters['estado'] = estado.trim();
      }

      _talker.dataSource(
        'GET $path con filtros ordenProduccionId=$ordenProduccionId, ordenProcesoId=$ordenProcesoId, estado=${_describeState(estado)}',
      );
      final response = await _dio.get<List<dynamic>>(
        path,
        queryParameters: queryParameters,
      );
      final items = response.data ?? const [];
      _talker.dataSource(
        'GET $path completado con ${items.length} registros de tiempos de proceso.',
      );
      return items
          .map(
            (item) => TiempoProcesoReporteItemModel.fromJson(
              item as Map<String, dynamic>,
            ),
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

  String _describeState(String? estado) {
    final normalized = estado?.trim();
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
