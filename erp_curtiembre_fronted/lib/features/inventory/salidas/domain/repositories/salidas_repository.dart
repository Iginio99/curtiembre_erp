import 'package:erp_curtiembre_fronted/features/inventory/salidas/domain/entities/salida_detail.dart';
import 'package:erp_curtiembre_fronted/features/inventory/salidas/domain/entities/salida_record.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/domain/entities/insumo_lookup.dart';

abstract class SalidasRepository {
  Future<List<InsumoLookup>> listActiveInsumos();

  Future<List<SalidaRecord>> listSalidas({
    String? texto,
    String? tipoSalida,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  });

  Future<SalidaDetail> getSalidaDetail(int id);

  Future<SalidaDetail> registerGeneral({
    required String motivo,
    String? observacion,
    required List<RegistrarSalidaDetalleInput> detalles,
  });

  Future<SalidaDetail> registerSupplierReturn({
    required String motivo,
    String? observacion,
    required List<RegistrarSalidaDetalleInput> detalles,
  });

  Future<SalidaDetail> registerNegativeAdjustment({
    required String motivo,
    String? observacion,
    required List<RegistrarSalidaDetalleInput> detalles,
  });
}

class RegistrarSalidaDetalleInput {
  const RegistrarSalidaDetalleInput({
    required this.insumoId,
    required this.cantidad,
    this.observacion,
  });

  final int insumoId;
  final double cantidad;
  final String? observacion;
}
