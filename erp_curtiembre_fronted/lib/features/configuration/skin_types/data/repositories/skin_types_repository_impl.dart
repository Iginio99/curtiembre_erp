import 'package:erp_curtiembre_fronted/features/configuration/skin_types/data/datasources/skin_types_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/configuration/skin_types/domain/entities/skin_type_record.dart';
import 'package:erp_curtiembre_fronted/features/configuration/skin_types/domain/repositories/skin_types_repository.dart';

class SkinTypesRepositoryImpl implements SkinTypesRepository {
  SkinTypesRepositoryImpl(this._remoteDataSource);

  final SkinTypesRemoteDataSource _remoteDataSource;

  @override
  Future<List<SkinTypeRecord>> listSkinTypes({
    String? texto,
    bool? activo,
  }) async {
    final items = await _remoteDataSource.listSkinTypes(
      texto: texto,
      activo: activo,
    );

    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<SkinTypeRecord> getSkinType(int id) async {
    final item = await _remoteDataSource.getSkinType(id);
    return item.toEntity();
  }

  @override
  Future<SkinTypeRecord> createSkinType({
    required String codigo,
    required String nombre,
    String? descripcion,
  }) async {
    final item = await _remoteDataSource.createSkinType(
      codigo: codigo,
      nombre: nombre,
      descripcion: descripcion,
    );
    return item.toEntity();
  }

  @override
  Future<SkinTypeRecord> updateSkinType({
    required int id,
    required String codigo,
    required String nombre,
    String? descripcion,
  }) async {
    final item = await _remoteDataSource.updateSkinType(
      id: id,
      codigo: codigo,
      nombre: nombre,
      descripcion: descripcion,
    );
    return item.toEntity();
  }

  @override
  Future<SkinTypeRecord> setSkinTypeActive({
    required int id,
    required bool active,
  }) async {
    final item = await _remoteDataSource.setSkinTypeActive(
      id: id,
      active: active,
    );
    return item.toEntity();
  }
}
