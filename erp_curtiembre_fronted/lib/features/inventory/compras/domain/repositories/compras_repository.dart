import 'package:erp_curtiembre_fronted/features/inventory/compras/domain/entities/orden_compra_detail.dart';
import 'package:erp_curtiembre_fronted/features/inventory/compras/domain/entities/orden_compra_record.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/domain/entities/insumo_lookup.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/domain/entities/proveedor_lookup.dart';

abstract class ComprasRepository {
  Future<List<ProveedorLookup>> listActiveSuppliers();

  Future<List<InsumoLookup>> listActiveInsumos();

  Future<List<OrdenCompraRecord>> listOrders({
    String? texto,
    int? proveedorId,
    String? estado,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  });

  Future<OrdenCompraDetail> getOrderDetail(int id);

  Future<OrdenCompraDetail> createOrder({
    required int proveedorId,
    required DateTime fechaEmision,
    String? observacion,
    required List<CreateOrdenCompraDetalleInput> detalles,
  });

  Future<String> approveOrder(int id);
  Future<String> rejectOrder(int id, String motivo);
  Future<String> cancelOrder(int id, String motivo);
}

class CreateOrdenCompraDetalleInput {
  const CreateOrdenCompraDetalleInput({
    required this.insumoId,
    required this.cantidadSolicitada,
    this.costoUnitarioEstimado,
    this.observacion,
  });

  final int insumoId;
  final double cantidadSolicitada;
  final double? costoUnitarioEstimado;
  final String? observacion;
}
