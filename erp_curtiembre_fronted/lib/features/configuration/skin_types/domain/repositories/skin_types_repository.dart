import 'package:erp_curtiembre_fronted/features/configuration/skin_types/domain/entities/skin_type_record.dart';

abstract interface class SkinTypesRepository {
  Future<List<SkinTypeRecord>> listSkinTypes({
    String? texto,
    bool? activo,
  });

  Future<SkinTypeRecord> getSkinType(int id);

  Future<SkinTypeRecord> createSkinType({
    required String codigo,
    required String nombre,
    String? descripcion,
  });

  Future<SkinTypeRecord> updateSkinType({
    required int id,
    required String codigo,
    required String nombre,
    String? descripcion,
  });

  Future<SkinTypeRecord> setSkinTypeActive({
    required int id,
    required bool active,
  });
}
