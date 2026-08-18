import 'package:erp_curtiembre_fronted/features/configuration/units/data/datasources/units_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/configuration/units/domain/entities/unit_record.dart';
import 'package:erp_curtiembre_fronted/features/configuration/units/domain/repositories/units_repository.dart';

class UnitsRepositoryImpl implements UnitsRepository {
  UnitsRepositoryImpl(this._remoteDataSource);

  final UnitsRemoteDataSource _remoteDataSource;

  @override
  Future<List<UnitRecord>> listUnits({
    String? texto,
    bool? activo,
    bool? permiteDecimales,
  }) async {
    final items = await _remoteDataSource.listUnits(
      texto: texto,
      activo: activo,
      permiteDecimales: permiteDecimales,
    );

    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<UnitRecord> getUnit(int id) async {
    final unit = await _remoteDataSource.getUnit(id);
    return unit.toEntity();
  }

  @override
  Future<UnitRecord> createUnit({
    required String codigo,
    required String nombre,
    required bool permiteDecimales,
  }) async {
    final unit = await _remoteDataSource.createUnit(
      codigo: codigo,
      nombre: nombre,
      permiteDecimales: permiteDecimales,
    );
    return unit.toEntity();
  }

  @override
  Future<UnitRecord> updateUnit({
    required int id,
    required String codigo,
    required String nombre,
    required bool permiteDecimales,
  }) async {
    final unit = await _remoteDataSource.updateUnit(
      id: id,
      codigo: codigo,
      nombre: nombre,
      permiteDecimales: permiteDecimales,
    );
    return unit.toEntity();
  }

  @override
  Future<UnitRecord> setUnitActive({
    required int id,
    required bool active,
  }) async {
    final unit = await _remoteDataSource.setUnitActive(
      id: id,
      active: active,
    );
    return unit.toEntity();
  }
}
