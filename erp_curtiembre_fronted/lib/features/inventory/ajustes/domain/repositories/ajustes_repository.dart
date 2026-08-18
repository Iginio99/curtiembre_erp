import 'package:erp_curtiembre_fronted/features/inventory/ajustes/domain/entities/ajuste_detail.dart';
import 'package:erp_curtiembre_fronted/features/inventory/ajustes/domain/entities/ajuste_record.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/domain/entities/insumo_lookup.dart';

abstract class AjustesRepository {
  Future<List<InsumoLookup>> listActiveInsumos();

  Future<List<AjusteRecord>> listAjustes({
    String? texto,
    String? tipoAjuste,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  });

  Future<AjusteDetail> getAjusteDetail(int id);

  Future<AjusteDetail> registerPositive({
    required String motivo,
    String? observacion,
    required List<RegistrarAjusteDetalleInput> detalles,
  });

  Future<AjusteDetail> registerNegative({
    required String motivo,
    String? observacion,
    required List<RegistrarAjusteDetalleInput> detalles,
  });
}

class RegistrarAjusteDetalleInput {
  const RegistrarAjusteDetalleInput({
    required this.insumoId,
    required this.cantidad,
    this.costoUnitario,
  });

  final int insumoId;
  final double cantidad;
  final double? costoUnitario;
}
