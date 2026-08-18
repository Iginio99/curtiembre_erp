import 'package:erp_curtiembre_fronted/features/inventory/kardex/domain/entities/kardex_record.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/domain/entities/insumo_lookup.dart';

abstract class KardexRepository {
  Future<List<InsumoLookup>> listActiveInsumos();

  Future<List<KardexRecord>> listKardex({
    int? insumoId,
    String? tipoMovimiento,
    String? documentoTipo,
    int? usuarioResponsableId,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  });

  Future<List<KardexRecord>> listKardexByInsumo(
    int insumoId, {
    String? tipoMovimiento,
    String? documentoTipo,
    int? usuarioResponsableId,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  });
}
