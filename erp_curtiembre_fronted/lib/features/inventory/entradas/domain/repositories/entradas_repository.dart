import 'package:erp_curtiembre_fronted/features/inventory/compras/domain/entities/orden_compra_detail.dart';
import 'package:erp_curtiembre_fronted/features/inventory/compras/domain/entities/orden_compra_record.dart';
import 'package:erp_curtiembre_fronted/features/inventory/entradas/domain/entities/entrada_inventario_detail.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/domain/entities/insumo_lookup.dart';

abstract class EntradasRepository {
  Future<List<InsumoLookup>> listActiveInsumos();
  Future<List<OrdenCompraRecord>> listReceivableOrders();
  Future<OrdenCompraDetail> getOrderDetail(int id);
  Future<EntradaInventarioDetail> getEntryDetail(int id);

  Future<EntradaInventarioDetail> registerStockInitial({
    String? documentoSoporte,
    String? observacion,
    required List<RegistrarStockInicialDetalleInput> detalles,
  });

  Future<EntradaInventarioDetail> registerPurchaseEntry({
    required int ordenCompraId,
    required String documentoSoporte,
    String? observacion,
    required List<RegistrarEntradaCompraDetalleInput> detalles,
  });
}

class RegistrarStockInicialDetalleInput {
  const RegistrarStockInicialDetalleInput({
    required this.insumoId,
    required this.cantidad,
    required this.costoUnitario,
    this.observacion,
  });

  final int insumoId;
  final double cantidad;
  final double costoUnitario;
  final String? observacion;
}

class RegistrarEntradaCompraDetalleInput {
  const RegistrarEntradaCompraDetalleInput({
    required this.ordenCompraDetalleId,
    required this.insumoId,
    required this.cantidad,
    required this.costoUnitario,
    this.observacion,
  });

  final int ordenCompraDetalleId;
  final int insumoId;
  final double cantidad;
  final double costoUnitario;
  final String? observacion;
}
