import 'package:dio/dio.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/data/models/insumo_lookup_model.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/data/models/consumo_planificado_record_model.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/data/models/consumo_real_record_model.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/data/models/control_calidad_record_model.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/data/models/desviacion_consumo_record_model.dart';
import 'package:erp_curtiembre_fronted/features/production/clientes/data/models/cliente_option_model.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/data/models/lote_option_model.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/data/models/merma_proceso_record_model.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/data/models/orden_proceso_record_model.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/data/models/orden_produccion_record_model.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/data/models/producto_terminado_record_model.dart';
import 'package:talker_flutter/talker_flutter.dart';

class OrdenesProduccionRemoteDataSource {
  OrdenesProduccionRemoteDataSource(this._dio, this._talker);

  final Dio _dio;
  final Talker _talker;

  Future<List<OrdenProduccionRecordModel>> listOrdenes({
    String? texto,
    int? clienteId,
    int? loteId,
    String? estado,
  }) async {
    const path = '/api/produccion/ordenes';

    try {
      final queryParameters = <String, dynamic>{};
      if (texto != null && texto.trim().isNotEmpty) {
        queryParameters['texto'] = texto.trim();
      }
      if (clienteId != null) {
        queryParameters['clienteId'] = clienteId;
      }
      if (loteId != null) {
        queryParameters['loteId'] = loteId;
      }
      if (estado != null && estado.trim().isNotEmpty) {
        queryParameters['estado'] = estado.trim();
      }

      _talker.dataSource(
        'GET $path con filtros texto=${_describeText(texto)}, clienteId=$clienteId, loteId=$loteId, estado=${_describeState(estado)}',
      );
      final response = await _dio.get<List<dynamic>>(
        path,
        queryParameters: queryParameters,
      );
      final items = response.data ?? const [];
      _talker.dataSource('GET $path completado con ${items.length} ordenes.');
      return items
          .map(
            (item) => OrdenProduccionRecordModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(growable: false);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<OrdenProduccionRecordModel> getOrden(int id) async {
    final path = '/api/produccion/ordenes/$id';

    try {
      _talker.dataSource('GET $path');
      final response = await _dio.get<Map<String, dynamic>>(path);
      _talker.dataSource('GET $path completado.');
      return OrdenProduccionRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<List<OrdenProcesoRecordModel>> listProcesos(int ordenId) async {
    final path = '/api/produccion/ordenes/$ordenId/procesos';

    try {
      _talker.dataSource('GET $path');
      final response = await _dio.get<List<dynamic>>(path);
      final items = response.data ?? const [];
      _talker.dataSource('GET $path completado con ${items.length} procesos.');
      return items
          .map(
            (item) =>
                OrdenProcesoRecordModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<List<ClienteOptionModel>> listActiveClientes() async {
    const path = '/api/produccion/catalogos/clientes/activos';

    try {
      _talker.dataSource('GET $path');
      final response = await _dio.get<List<dynamic>>(path);
      final items = response.data ?? const [];
      _talker.dataSource(
        'GET $path completado con ${items.length} clientes activos.',
      );
      return items
          .map(
            (item) => ClienteOptionModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

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

  Future<void> generarConsumoPlanificado(int ordenId) async {
    final path =
        '/api/produccion/ordenes/$ordenId/consumo-planificado/calcular';

    try {
      _talker.dataSource('POST $path');
      await _dio.post<void>(path);
      _talker.dataSource('POST $path completado.');
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'POST $path');
    }
  }

  Future<List<ConsumoPlanificadoRecordModel>> listConsumoPlanificado(
    int ordenId,
  ) async {
    final path = '/api/produccion/ordenes/$ordenId/consumo-planificado';

    try {
      _talker.dataSource('GET $path');
      final response = await _dio.get<List<dynamic>>(path);
      final items = response.data ?? const [];
      _talker.dataSource(
        'GET $path completado con ${items.length} consumos planificados.',
      );
      return items
          .map(
            (item) => ConsumoPlanificadoRecordModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(growable: false);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<void> solicitarConsumo({
    required int ordenId,
    required int ordenProcesoId,
    String? motivo,
    String? observacion,
    required List<Map<String, dynamic>> detalles,
  }) async {
    final path =
        '/api/produccion/ordenes/$ordenId/procesos/$ordenProcesoId/solicitudes-insumos';

    try {
      _talker.dataSource(
        'POST $path con detalles=${detalles.length}, observacion=${_describeText(observacion)}',
      );
      await _dio.post<void>(
        path,
        data: {'observacion': observacion, 'detalles': detalles},
      );
      _talker.dataSource(
        'POST $path completado con ${detalles.length} detalles.',
      );
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'POST $path');
    }
  }

  Future<List<ConsumoRealRecordModel>> listConsumoReal(int ordenId) async {
    final path = '/api/produccion/ordenes/$ordenId/consumo-real';

    try {
      _talker.dataSource('GET $path');
      final response = await _dio.get<List<dynamic>>(path);
      final items = response.data ?? const [];
      _talker.dataSource(
        'GET $path completado con ${items.length} consumos reales.',
      );
      return items
          .map(
            (item) =>
                ConsumoRealRecordModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<List<DesviacionConsumoRecordModel>> listDesviaciones(
    int ordenId,
  ) async {
    final path = '/api/produccion/ordenes/$ordenId/desviaciones';

    try {
      _talker.dataSource('GET $path');
      final response = await _dio.get<List<dynamic>>(path);
      final items = response.data ?? const [];
      _talker.dataSource(
        'GET $path completado con ${items.length} desviaciones.',
      );
      return items
          .map(
            (item) => DesviacionConsumoRecordModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(growable: false);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<MermaProcesoRecordModel> registerMerma({
    required int procesoId,
    required double cantidadPerdida,
    String? motivo,
    String? observacion,
  }) async {
    final path = '/api/produccion/procesos/$procesoId/mermas';

    try {
      _talker.dataSource(
        'POST $path con cantidadPerdida=$cantidadPerdida, motivo=${_describeText(motivo)}, observacion=${_describeText(observacion)}',
      );
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: {
          'cantidadPerdida': cantidadPerdida,
          'motivo': motivo,
          'observacion': observacion,
        },
      );
      _talker.dataSource('POST $path completado.');
      return MermaProcesoRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'POST $path');
    }
  }

  Future<List<MermaProcesoRecordModel>> listMermas({
    int? ordenProduccionId,
    int? ordenProcesoId,
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

      _talker.dataSource(
        'GET $path con filtros ordenProduccionId=$ordenProduccionId, ordenProcesoId=$ordenProcesoId',
      );
      final response = await _dio.get<List<dynamic>>(
        path,
        queryParameters: queryParameters,
      );
      final items = response.data ?? const [];
      _talker.dataSource('GET $path completado con ${items.length} mermas.');
      return items
          .map(
            (item) =>
                MermaProcesoRecordModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<ControlCalidadRecordModel> registerCalidadFinal({
    required int ordenId,
    required int calidadProductoId,
    required String resultado,
    String? observacion,
  }) async {
    final path = '/api/produccion/ordenes/$ordenId/calidad-final';

    try {
      _talker.dataSource(
        'POST $path con calidadProductoId=$calidadProductoId, resultado=$resultado, observacion=${_describeText(observacion)}',
      );
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: {
          'calidadProductoId': calidadProductoId,
          'resultado': resultado,
          'observacion': observacion,
        },
      );
      _talker.dataSource('POST $path completado.');
      return ControlCalidadRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'POST $path');
    }
  }

  Future<ProductoTerminadoRecordModel?> getProductoTerminadoByOrder(
    int ordenId,
  ) async {
    final path = '/api/produccion/ordenes/$ordenId/producto-terminado';

    try {
      _talker.dataSource('GET $path');
      final response = await _dio.get<Map<String, dynamic>>(path);
      _talker.dataSource('GET $path completado.');
      return ProductoTerminadoRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      if (exception.response?.statusCode == 404) {
        _talker.dataSource(
          'GET $path respondio 404; no existe producto terminado.',
        );
        return null;
      }
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<ProductoTerminadoRecordModel> finalizeOrden({
    required int ordenId,
    required double cantidadLados,
    String? observacion,
  }) async {
    final path = '/api/produccion/ordenes/$ordenId/finalizar';

    try {
      _talker.dataSource(
        'POST $path con cantidadLados=$cantidadLados, observacion=${_describeText(observacion)}',
      );
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: {'cantidadLados': cantidadLados, 'observacion': observacion},
      );
      _talker.dataSource('POST $path completado.');
      return ProductoTerminadoRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'POST $path');
    }
  }

  Future<List<ProductoTerminadoRecordModel>> listProductosTerminados() async {
    const path = '/api/produccion/productos-terminados';

    try {
      _talker.dataSource('GET $path');
      final response = await _dio.get<List<dynamic>>(path);
      final items = response.data ?? const [];
      _talker.dataSource(
        'GET $path completado con ${items.length} productos terminados.',
      );
      return items
          .map(
            (item) => ProductoTerminadoRecordModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(growable: false);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<List<LoteOptionModel>> listLotesDisponibles() async {
    const path = '/api/produccion/lotes';

    try {
      _talker.dataSource('GET $path para consultar lotes con saldo disponible');
      final response = await _dio.get<List<dynamic>>(path);
      final items = response.data ?? const [];
      final availableItems = items
          .map((item) => LoteOptionModel.fromJson(item as Map<String, dynamic>))
          .where(
            (item) =>
                item.cantidadPielesDisponible > 0 &&
                item.estado != 'ANULADO' &&
                item.estado != 'AGOTADO',
          )
          .toList(growable: false);
      _talker.dataSource(
        'GET $path completado con ${availableItems.length} lotes con saldo disponible.',
      );
      return availableItems;
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<OrdenProduccionRecordModel> createOrden({
    required int loteId,
    required int clienteId,
    required double cantidadPieles,
    DateTime? fechaInicioPlanificada,
    required DateTime fechaFinEstimada,
    int? responsableUsuarioId,
    String? observacion,
  }) async {
    const path = '/api/produccion/ordenes';

    try {
      _talker.dataSource(
        'POST $path para loteId=$loteId, clienteId=$clienteId, cantidadPieles=$cantidadPieles, responsableUsuarioId=$responsableUsuarioId, observacion=${_describeText(observacion)}',
      );
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: {
          'loteId': loteId,
          'clienteId': clienteId,
          'cantidadPieles': cantidadPieles,
          'fechaInicioPlanificada': fechaInicioPlanificada?.toIso8601String(),
          'fechaFinEstimada': fechaFinEstimada.toIso8601String(),
          'responsableUsuarioId': responsableUsuarioId,
          'observacion': observacion,
        },
      );
      _talker.dataSource('POST $path completado para loteId=$loteId.');
      return OrdenProduccionRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'POST $path');
    }
  }

  Future<OrdenProduccionRecordModel> startOrden({
    required int id,
    required double pesoBaseKg,
    required DateTime fechaFinEstimada,
    int? responsableUsuarioId,
    String? observacion,
  }) async {
    final path = '/api/produccion/ordenes/$id/iniciar';

    try {
      _talker.dataSource(
        'POST $path con responsableUsuarioId=$responsableUsuarioId, observacion=${_describeText(observacion)}',
      );
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: {
          'responsableUsuarioId': responsableUsuarioId,
          'pesoBaseKg': pesoBaseKg,
          'fechaFinEstimada': fechaFinEstimada.toIso8601String(),
          'observacion': observacion,
        },
      );
      _talker.dataSource('POST $path completado.');
      return OrdenProduccionRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'POST $path');
    }
  }

  Future<OrdenProduccionRecordModel> cancelOrden({
    required int id,
    required String motivo,
  }) async {
    final path = '/api/produccion/ordenes/$id/anular';

    try {
      _talker.dataSource('POST $path con motivo=${_describeText(motivo)}');
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: {'motivo': motivo},
      );
      _talker.dataSource('POST $path completado.');
      return OrdenProduccionRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'POST $path');
    }
  }

  Future<OrdenProcesoRecordModel> startProceso({
    required int id,
    required double pesoBaseKg,
    required DateTime fechaFinEstimada,
    int? responsableUsuarioId,
    String? observacion,
  }) async {
    final path = '/api/produccion/procesos/$id/iniciar';

    try {
      _talker.dataSource(
        'POST $path con responsableUsuarioId=$responsableUsuarioId, observacion=${_describeText(observacion)}',
      );
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: {
          'responsableUsuarioId': responsableUsuarioId,
          'pesoBaseKg': pesoBaseKg,
          'fechaFinEstimada': fechaFinEstimada.toIso8601String(),
          'observacion': observacion,
        },
      );
      _talker.dataSource('POST $path completado.');
      return OrdenProcesoRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'POST $path');
    }
  }

  Future<OrdenProcesoRecordModel> finishProceso({
    required int id,
    String? observacion,
  }) async {
    final path = '/api/produccion/procesos/$id/finalizar';

    try {
      _talker.dataSource(
        'POST $path con observacion=${_describeText(observacion)}',
      );
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: {'observacion': observacion},
      );
      _talker.dataSource('POST $path completado.');
      return OrdenProcesoRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'POST $path');
    }
  }

  Future<OrdenProcesoRecordModel> updateObservacionProceso({
    required int id,
    String? observacion,
  }) async {
    final path = '/api/produccion/procesos/$id/observacion';

    try {
      _talker.dataSource(
        'PUT $path con observacion=${_describeText(observacion)}',
      );
      final response = await _dio.put<Map<String, dynamic>>(
        path,
        data: {'observacion': observacion},
      );
      _talker.dataSource('PUT $path completado.');
      return OrdenProcesoRecordModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'PUT $path');
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

  String _describeState(String? estado) {
    final normalized = estado?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return normalized;
  }
}
