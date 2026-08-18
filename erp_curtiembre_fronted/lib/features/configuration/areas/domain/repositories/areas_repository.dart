import 'package:erp_curtiembre_fronted/features/configuration/areas/domain/entities/area_record.dart';

abstract interface class AreasRepository {
  Future<List<AreaRecord>> listAreas({
    String? texto,
    bool? activo,
  });

  Future<AreaRecord> getArea(int id);

  Future<AreaRecord> createArea({
    required String codigo,
    required String nombre,
    String? descripcion,
  });

  Future<AreaRecord> updateArea({
    required int id,
    required String codigo,
    required String nombre,
    String? descripcion,
  });

  Future<AreaRecord> setAreaActive({
    required int id,
    required bool active,
  });
}
