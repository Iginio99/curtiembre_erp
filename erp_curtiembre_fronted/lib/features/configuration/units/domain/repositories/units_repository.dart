import 'package:erp_curtiembre_fronted/features/configuration/units/domain/entities/unit_record.dart';

abstract interface class UnitsRepository {
  Future<List<UnitRecord>> listUnits({
    String? texto,
    bool? activo,
    bool? permiteDecimales,
  });

  Future<UnitRecord> getUnit(int id);

  Future<UnitRecord> createUnit({
    required String codigo,
    required String nombre,
    required bool permiteDecimales,
  });

  Future<UnitRecord> updateUnit({
    required int id,
    required String codigo,
    required String nombre,
    required bool permiteDecimales,
  });

  Future<UnitRecord> setUnitActive({
    required int id,
    required bool active,
  });
}
