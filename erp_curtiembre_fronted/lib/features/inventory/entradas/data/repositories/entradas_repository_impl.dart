import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/features/inventory/compras/domain/entities/orden_compra_detail.dart';
import 'package:erp_curtiembre_fronted/features/inventory/compras/domain/entities/orden_compra_record.dart';
import 'package:erp_curtiembre_fronted/features/inventory/entradas/data/datasources/entradas_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/inventory/entradas/domain/entities/entrada_inventario_detail.dart';
import 'package:erp_curtiembre_fronted/features/inventory/entradas/domain/repositories/entradas_repository.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/domain/entities/insumo_lookup.dart';
import 'package:talker_flutter/talker_flutter.dart';

class EntradasRepositoryImpl implements EntradasRepository {
  EntradasRepositoryImpl(this._remoteDataSource, this._talker);

  final EntradasRemoteDataSource _remoteDataSource;
  final Talker _talker;

  @override
  Future<List<InsumoLookup>> listActiveInsumos() async {
    _talker.repository(
      'Consultando insumos activos para formularios de entradas de inventario.',
    );
    final items = await _remoteDataSource.listActiveInsumos();
    _talker.repository(
      'Se obtuvieron ${items.length} insumos activos para entradas de inventario.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<List<OrdenCompraRecord>> listReceivableOrders() async {
    _talker.repository(
      'Consultando ordenes de compra recepcionables para entradas de inventario.',
    );
    final items = await _remoteDataSource.listReceivableOrders();
    _talker.repository(
      'Se obtuvieron ${items.length} ordenes recepcionables para entradas.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<OrdenCompraDetail> getOrderDetail(int id) async {
    _talker.repository(
      'Consultando detalle de la orden de compra $id para recepcion.',
    );
    final detail = await _remoteDataSource.getOrderDetail(id);
    _talker.repository(
      'Detalle de la orden de compra $id obtenido correctamente para recepcion.',
    );
    return detail.toEntity();
  }

  @override
  Future<EntradaInventarioDetail> getEntryDetail(int id) async {
    _talker.repository('Consultando detalle de la entrada de inventario $id.');
    final detail = await _remoteDataSource.getEntryDetail(id);
    _talker.repository(
      'Detalle de la entrada de inventario $id obtenido correctamente.',
    );
    return detail.toEntity();
  }

  @override
  Future<EntradaInventarioDetail> registerStockInitial({
    String? documentoSoporte,
    String? observacion,
    required List<RegistrarStockInicialDetalleInput> detalles,
  }) async {
    _talker.repository(
      'Registrando stock inicial con documentoSoporte=${_describeText(documentoSoporte)} y ${detalles.length} detalles.',
      logLevel: LogLevel.warning,
    );
    final detail = await _remoteDataSource.registerStockInitial(
      documentoSoporte: documentoSoporte,
      observacion: observacion,
      detalles: detalles,
    );
    _talker.repository(
      'Stock inicial registrado correctamente con id=${detail.id}.',
      logLevel: LogLevel.warning,
    );
    return detail.toEntity();
  }

  @override
  Future<EntradaInventarioDetail> registerPurchaseEntry({
    required int ordenCompraId,
    required String documentoSoporte,
    String? observacion,
    required List<RegistrarEntradaCompraDetalleInput> detalles,
  }) async {
    _talker.repository(
      'Registrando entrada desde compra para ordenCompraId=$ordenCompraId con ${detalles.length} detalles.',
      logLevel: LogLevel.warning,
    );
    final detail = await _remoteDataSource.registerPurchaseEntry(
      ordenCompraId: ordenCompraId,
      documentoSoporte: documentoSoporte,
      observacion: observacion,
      detalles: detalles,
    );
    _talker.repository(
      'Entrada desde compra registrada correctamente con id=${detail.id}.',
      logLevel: LogLevel.warning,
    );
    return detail.toEntity();
  }

  String _describeText(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return '${normalized.length} caracteres';
  }
}
