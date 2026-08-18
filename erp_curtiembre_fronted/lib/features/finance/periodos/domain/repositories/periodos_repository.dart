import 'package:erp_curtiembre_fronted/features/finance/periodos/domain/entities/periodo_costo_record.dart';

abstract class PeriodosRepository {
  Future<List<PeriodoCostoRecord>> listPeriodos({
    int? anio,
    int? mes,
    String? estado,
  });

  Future<PeriodoCostoRecord> getPeriodo(int id);

  Future<PeriodoCostoRecord> createPeriodo({
    required int anio,
    required int mes,
    String? observacion,
  });

  Future<PeriodoCostoRecord> closePeriodo({
    required int id,
    String? observacion,
  });
}
