import 'package:dio/dio.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/inventory/compras/data/models/orden_compra_detail_model.dart';
import 'package:erp_curtiembre_fronted/features/inventory/compras/data/models/orden_compra_record_model.dart';
import 'package:erp_curtiembre_fronted/features/inventory/entradas/data/models/entrada_inventario_detail_model.dart';
import 'package:erp_curtiembre_fronted/features/inventory/entradas/domain/repositories/entradas_repository.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/data/models/insumo_lookup_model.dart';
import 'package:talker_flutter/talker_flutter.dart';

class EntradasRemoteDataSource {
  EntradasRemoteDataSource(this._dio, this._talker);

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

  Future<List<OrdenCompraRecordModel>> listReceivableOrders() async {
    const path = '/api/inventario/compras';

    try {
      _talker.dataSource('GET $path con filtro estado=APROBADA');
      final response = await _dio.get<List<dynamic>>(
        path,
        queryParameters: {'estado': 'APROBADA'},
      );
      final approvedItems = (response.data ?? const []).map(
        (item) => OrdenCompraRecordModel.fromJson(item as Map<String, dynamic>),
      );
      _talker.dataSource(
        'GET $path para APROBADA completado con ${response.data?.length ?? 0} ordenes.',
      );

      _talker.dataSource('GET $path con filtro estado=PARCIALMENTE_RECIBIDA');
      final partialResponse = await _dio.get<List<dynamic>>(
        path,
        queryParameters: {'estado': 'PARCIALMENTE_RECIBIDA'},
      );
      final partialItems = (partialResponse.data ?? const []).map(
        (item) => OrdenCompraRecordModel.fromJson(item as Map<String, dynamic>),
      );
      _talker.dataSource(
        'GET $path para PARCIALMENTE_RECIBIDA completado con ${partialResponse.data?.length ?? 0} ordenes.',
      );

      return [...approvedItems, ...partialItems];
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

  Future<EntradaInventarioDetailModel> getEntryDetail(int id) async {
    final path = '/api/inventario/entradas/$id';

    try {
      _talker.dataSource('GET $path');
      final response = await _dio.get<Map<String, dynamic>>(path);
      _talker.dataSource('GET $path completado.');
      return EntradaInventarioDetailModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'GET $path');
    }
  }

  Future<EntradaInventarioDetailModel> registerStockInitial({
    String? documentoSoporte,
    String? observacion,
    required List<RegistrarStockInicialDetalleInput> detalles,
  }) async {
    const path = '/api/inventario/entradas/stock-inicial';

    try {
      _talker.dataSource(
        'POST $path con documentoSoporte=${_describeText(documentoSoporte)}, observacion=${_describeText(observacion)}, detalles=${detalles.length}',
      );
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: {
          'documentoSoporte': documentoSoporte,
          'observacion': observacion,
          'detalles': detalles
              .map(
                (item) => {
                  'insumoId': item.insumoId,
                  'cantidad': item.cantidad,
                  'costoUnitario': item.costoUnitario,
                  'observacion': item.observacion,
                },
              )
              .toList(growable: false),
        },
      );

      _talker.dataSource(
        'POST $path completado con ${detalles.length} detalles.',
      );
      return EntradaInventarioDetailModel.fromJson(response.data!);
    } on DioException catch (exception) {
      throw _mapAndLogDioException(exception, operation: 'POST $path');
    }
  }

  Future<EntradaInventarioDetailModel> registerPurchaseEntry({
    required int ordenCompraId,
    required String documentoSoporte,
    String? observacion,
    required List<RegistrarEntradaCompraDetalleInput> detalles,
  }) async {
    const path = '/api/inventario/entradas/desde-compra';

    try {
      _talker.dataSource(
        'POST $path para ordenCompraId=$ordenCompraId, documentoSoporte=${_describeText(documentoSoporte)}, observacion=${_describeText(observacion)}, detalles=${detalles.length}',
      );
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: {
          'ordenCompraId': ordenCompraId,
          'documentoSoporte': documentoSoporte,
          'observacion': observacion,
          'detalles': detalles
              .map(
                (item) => {
                  'ordenCompraDetalleId': item.ordenCompraDetalleId,
                  'insumoId': item.insumoId,
                  'cantidad': item.cantidad,
                  'costoUnitario': item.costoUnitario,
                  'observacion': item.observacion,
                },
              )
              .toList(growable: false),
        },
      );

      _talker.dataSource(
        'POST $path completado con ${detalles.length} detalles.',
      );
      return EntradaInventarioDetailModel.fromJson(response.data!);
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
