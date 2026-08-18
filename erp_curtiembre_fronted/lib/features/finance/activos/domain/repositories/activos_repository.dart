import 'package:erp_curtiembre_fronted/features/finance/activos/domain/entities/activo_depreciable_record.dart';

abstract class ActivosRepository {
  Future<List<ActivoDepreciableRecord>> listActivos({
    String? texto,
    bool? activo,
  });

  Future<ActivoDepreciableRecord> getActivo(int id);

  Future<ActivoDepreciableRecord> createActivo({
    required String codigo,
    required String nombre,
    required double valorCompra,
    required DateTime fechaCompra,
    required int vidaUtilMeses,
    required double valorResidual,
    required bool activo,
  });

  Future<ActivoDepreciableRecord> updateActivo({
    required int id,
    required String codigo,
    required String nombre,
    required double valorCompra,
    required DateTime fechaCompra,
    required int vidaUtilMeses,
    required double valorResidual,
    required bool activo,
  });
}
