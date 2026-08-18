import 'package:erp_curtiembre_fronted/features/configuration/areas/data/datasources/areas_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/configuration/areas/domain/entities/area_record.dart';
import 'package:erp_curtiembre_fronted/features/configuration/areas/domain/repositories/areas_repository.dart';

class AreasRepositoryImpl implements AreasRepository {
  AreasRepositoryImpl(this._remoteDataSource);

  final AreasRemoteDataSource _remoteDataSource;

  @override
  Future<List<AreaRecord>> listAreas({
    String? texto,
    bool? activo,
  }) async {
    final items = await _remoteDataSource.listAreas(
      texto: texto,
      activo: activo,
    );

    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<AreaRecord> getArea(int id) async {
    final area = await _remoteDataSource.getArea(id);
    return area.toEntity();
  }

  @override
  Future<AreaRecord> createArea({
    required String codigo,
    required String nombre,
    String? descripcion,
  }) async {
    final area = await _remoteDataSource.createArea(
      codigo: codigo,
      nombre: nombre,
      descripcion: descripcion,
    );
    return area.toEntity();
  }

  @override
  Future<AreaRecord> updateArea({
    required int id,
    required String codigo,
    required String nombre,
    String? descripcion,
  }) async {
    final area = await _remoteDataSource.updateArea(
      id: id,
      codigo: codigo,
      nombre: nombre,
      descripcion: descripcion,
    );
    return area.toEntity();
  }

  @override
  Future<AreaRecord> setAreaActive({
    required int id,
    required bool active,
  }) async {
    final area = await _remoteDataSource.setAreaActive(
      id: id,
      active: active,
    );
    return area.toEntity();
  }
}
