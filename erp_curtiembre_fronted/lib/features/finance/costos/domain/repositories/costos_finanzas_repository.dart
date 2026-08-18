import 'package:erp_curtiembre_fronted/features/finance/costos/domain/entities/costo_orden_record.dart';
import 'package:erp_curtiembre_fronted/features/finance/costos/domain/entities/costo_proceso_record.dart';

abstract class CostosFinanzasRepository {
  Future<List<CostoProcesoRecord>> listCostosProceso({
    int? ordenProduccionId,
    int? ordenProcesoId,
  });

  Future<CostoProcesoRecord> getCostoProceso(int ordenProcesoId);

  Future<CostoProcesoRecord> calculateCostoProceso({
    required int ordenProduccionId,
    required int ordenProcesoId,
  });

  Future<List<CostoOrdenRecord>> listCostosOrden({
    int? ordenProduccionId,
    int? periodoCostoId,
    String? estado,
  });

  Future<CostoOrdenRecord> getCostoOrden(int ordenProduccionId);

  Future<CostoOrdenRecord> calculateCostoOrdenEstimado(int ordenProduccionId);

  Future<CostoOrdenRecord> calculateCostoOrdenReal(int ordenProduccionId);

  Future<CostoOrdenRecord> closeCostoOrden(int ordenProduccionId);
}

