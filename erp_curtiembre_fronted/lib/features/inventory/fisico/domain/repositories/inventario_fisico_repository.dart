import 'package:erp_curtiembre_fronted/features/inventory/fisico/domain/entities/inventario_fisico_detail.dart';
import 'package:erp_curtiembre_fronted/features/inventory/fisico/domain/entities/inventario_fisico_record.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/domain/entities/insumo_lookup.dart';

abstract class InventarioFisicoRepository {
  Future<List<InsumoLookup>> listActiveInsumos();

  Future<List<InventarioFisicoRecord>> listInventariosFisicos({
    int? periodoAnio,
    int? periodoMes,
    String? estado,
  });

  Future<InventarioFisicoDetail> getInventarioFisicoDetail(int id);

  Future<InventarioFisicoDetail> createInventarioFisico({
    required int periodoAnio,
    required int periodoMes,
    String? observacion,
  });

  Future<InventarioFisicoDetail> registerCounts({
    required int inventarioFisicoId,
    required List<RegistrarConteoInventarioFisicoDetalleInput> detalles,
  });

  Future<InventarioFisicoDetail> closeInventarioFisico({
    required int inventarioFisicoId,
    String? observacion,
  });
}

class RegistrarConteoInventarioFisicoDetalleInput {
  const RegistrarConteoInventarioFisicoDetalleInput({
    required this.insumoId,
    required this.stockContado,
    this.observacion,
  });

  final int insumoId;
  final double stockContado;
  final String? observacion;
}
