import 'package:erp_curtiembre_fronted/features/finance/depreciaciones/domain/entities/depreciacion_periodo_record.dart';

abstract class DepreciacionesRepository {
  Future<List<DepreciacionPeriodoRecord>> listDepreciaciones({
    int? periodoCostoId,
    int? activoDepreciableId,
  });

  Future<DepreciacionPeriodoRecord> getDepreciacion(int id);

  Future<void> calculateForPeriod(int periodoId);
}
