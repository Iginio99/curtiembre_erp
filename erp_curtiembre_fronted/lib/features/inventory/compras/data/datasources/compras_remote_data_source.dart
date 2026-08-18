import 'package:dio/dio.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/inventory/compras/data/models/orden_compra_detail_model.dart';
import 'package:erp_curtiembre_fronted/features/inventory/compras/data/models/orden_compra_record_model.dart';
import 'package:erp_curtiembre_fronted/features/inventory/compras/domain/repositories/compras_repository.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/data/models/insumo_lookup_model.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/data/models/proveedor_lookup_model.dart';
import 'package:talker_flutter/talker_flutter.dart';

class ComprasRemoteDataSource {
  ComprasRemoteDataSource(this._dio, this._talker);

  final Dio _dio;
  final Talker _talker;

  Future<List<ProveedorLookupModel>> listActiveSuppliers() async {
    const path = '/api/inventario/catalogos/proveedores/activos';

    try {
      _talker.dataSource('GET $path');
      final response = await _dio.get<List<dynamic>>(path);
      final items = response.data ?? const [];
      _talker.dataSource(
        'GET $path completado con ${items.length} proveedores activos.',
      );
      return items
          .map(
            (item) =>
                ProveedorLookupModel.fromJson(item as Map<String, dynamic>),
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

  Future<List<OrdenCompraRecordModel>> listOrders({
    String? texto,
    int? proveedorId,
    String? estado,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    const path = '/api/inventario/compras';

    try {
      final queryParameters = <String, Object>{};
      if (texto != null && texto.trim().isNotEmpty) {
        queryParameters['texto'] = texto.trim();
      }
      if (proveedorId != null) {
        queryParameters['proveedorId'] = proveedorId;
      }
      if (estado != null && estado.trim().isNotEmpty) {
        queryParameters['estado'] = estado;
      }
      if (fechaDesde != null) {
        queryParameters['fechaDesde'] = fechaDesde.toIso8601String();
      }
      if (fechaHasta != null) {
        queryParameters['fechaHasta'] = fechaHasta.toIso8601String();
      }

      _talker.dataSource(
        'GET $path con filtros texto=${_describeText(texto)}, proveedorId=$proveedorId, estado=${_describeState(estado)}, fechaDesde=${_describeDate(fechaDesde)}, fechaHasta=${_describeDate(fechaHasta)}',
      );
      final response = await _dio.get<List<dynamic>>(
        path,
        queryParameters: queryParameters,
      );
      final items = response.data ?? const [];
      _talker.dataSource(
        'GET $path completado con ${items.length} ordenes de compra.',
      );
      return items
          .map(
            (item) =>
                OrdenCompraRecordModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<OrdenCompraDetailModel> getOrderDetail(int id) async {
    final path = '/api/inventario/compras/$id';

    try {
      _talker.dataSource('GET $path');
      final response = await _dio.get<Map<String, dynamic>>(path);
      _talker.dataSource('GET $path completado.');
      return OrdenCompraDetailModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<OrdenCompraDetailModel> createOrder({
    required int proveedorId,
    required DateTime fechaEmision,
    String? observacion,
    required List<CreateOrdenCompraDetalleInput> detalles,
  }) async {
    const path = '/api/inventario/compras';

    try {
      _talker.dataSource(
        'POST $path para proveedorId=$proveedorId, observacion=${_describeText(observacion)}, detalles=${detalles.length}',
      );
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: {
          'proveedorId': proveedorId,
          'fechaEmision': fechaEmision.toIso8601String(),
          'observacion': observacion,
          'detalles': detalles
              .map(
                (item) => {
                  'insumoId': item.insumoId,
                  'cantidadSolicitada': item.cantidadSolicitada,
                  'costoUnitarioEstimado': item.costoUnitarioEstimado,
                  'observacion': item.observacion,
                },
              )
              .toList(growable: false),
        },
      );

      _talker.dataSource(
        'POST $path completado con ${detalles.length} detalles.',
      );
      return OrdenCompraDetailModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'POST $path');
    }
  }

  Future<String> approveOrder(int id) async =>
      _postMessage('/api/inventario/compras/$id/aprobar');

  Future<String> rejectOrder(int id, String motivo) async => _postMessage(
    '/api/inventario/compras/$id/rechazar',
    data: {'motivo': motivo},
  );

  Future<String> cancelOrder(int id, String motivo) async => _postMessage(
    '/api/inventario/compras/$id/anular',
    data: {'motivo': motivo},
  );

  Future<String> _postMessage(String path, {Map<String, dynamic>? data}) async {
    try {
      _talker.dataSource(
        'POST $path con payload=${data == null ? 'sin-payload' : data.keys.join(',')}',
      );
      final response = await _dio.post<Map<String, dynamic>>(path, data: data);

      _talker.dataSource('POST $path completado.');
      return response.data?['message'] as String? ??
          'Operacion completada correctamente.';
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

  String _describeDate(DateTime? value) {
    if (value == null) {
      return 'sin-fecha';
    }

    return value.toIso8601String();
  }
}
