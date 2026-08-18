import 'package:erp_curtiembre_fronted/features/configuration/formulas/data/datasources/formulas_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/configuration/formulas/domain/entities/formula_record.dart';
import 'package:erp_curtiembre_fronted/features/configuration/formulas/domain/repositories/formulas_repository.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/domain/entities/insumo_lookup.dart';

class FormulasRepositoryImpl implements FormulasRepository {
  FormulasRepositoryImpl(this._remoteDataSource);

  final FormulasRemoteDataSource _remoteDataSource;

  @override
  Future<List<FormulaRecord>> listFormulas({
    String? texto,
    int? procesoProductivoId,
    bool? activo,
  }) async {
    final items = await _remoteDataSource.listFormulas(
      texto: texto,
      procesoProductivoId: procesoProductivoId,
      activo: activo,
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<FormulaRecord> getFormula(int id) async {
    final item = await _remoteDataSource.getFormula(id);
    return item.toEntity();
  }

  @override
  Future<FormulaRecord> createFormula({
    required String codigo,
    required String nombre,
    required int procesoProductivoId,
    String? descripcion,
  }) async {
    final item = await _remoteDataSource.createFormula(
      codigo: codigo,
      nombre: nombre,
      procesoProductivoId: procesoProductivoId,
      descripcion: descripcion,
    );
    return item.toEntity();
  }

  @override
  Future<FormulaRecord> updateFormula({
    required int id,
    required String codigo,
    required String nombre,
    required int procesoProductivoId,
    String? descripcion,
  }) async {
    final item = await _remoteDataSource.updateFormula(
      id: id,
      codigo: codigo,
      nombre: nombre,
      procesoProductivoId: procesoProductivoId,
      descripcion: descripcion,
    );
    return item.toEntity();
  }

  @override
  Future<FormulaRecord> setFormulaActive({
    required int id,
    required bool active,
  }) async {
    final item = await _remoteDataSource.setFormulaActive(id: id, active: active);
    return item.toEntity();
  }

  @override
  Future<List<FormulaVersionRecord>> listVersions(int formulaId) async {
    final items = await _remoteDataSource.listVersions(formulaId);
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<FormulaVersionRecord> getVersion(int id) async {
    final item = await _remoteDataSource.getVersion(id);
    return item.toEntity();
  }

  @override
  Future<FormulaVersionRecord> createVersion({
    required int formulaId,
    required int numeroVersion,
    required DateTime fechaInicioVigencia,
    DateTime? fechaFinVigencia,
    String? observacion,
    int? clonarDesdeVersionId,
  }) async {
    final item = await _remoteDataSource.createVersion(
      formulaId: formulaId,
      numeroVersion: numeroVersion,
      fechaInicioVigencia: fechaInicioVigencia,
      fechaFinVigencia: fechaFinVigencia,
      observacion: observacion,
      clonarDesdeVersionId: clonarDesdeVersionId,
    );
    return item.toEntity();
  }

  @override
  Future<FormulaVersionRecord> updateVersion({
    required int id,
    required DateTime fechaInicioVigencia,
    DateTime? fechaFinVigencia,
    String? observacion,
  }) async {
    final item = await _remoteDataSource.updateVersion(
      id: id,
      fechaInicioVigencia: fechaInicioVigencia,
      fechaFinVigencia: fechaFinVigencia,
      observacion: observacion,
    );
    return item.toEntity();
  }

  @override
  Future<FormulaVersionRecord> activateVersion(int id) async {
    final item = await _remoteDataSource.activateVersion(id);
    return item.toEntity();
  }

  @override
  Future<FormulaDetailRecord> createDetail({
    required int versionId,
    required int insumoId,
    required double porcentaje,
    String? observacion,
  }) async {
    final item = await _remoteDataSource.createDetail(
      versionId: versionId,
      insumoId: insumoId,
      porcentaje: porcentaje,
      observacion: observacion,
    );
    return item.toEntity();
  }

  @override
  Future<FormulaDetailRecord> updateDetail({
    required int id,
    required int insumoId,
    required double porcentaje,
    String? observacion,
    required bool activo,
  }) async {
    final item = await _remoteDataSource.updateDetail(
      id: id,
      insumoId: insumoId,
      porcentaje: porcentaje,
      observacion: observacion,
      activo: activo,
    );
    return item.toEntity();
  }

  @override
  Future<FormulaDetailRecord> deleteDetail(int id) async {
    final item = await _remoteDataSource.deleteDetail(id);
    return item.toEntity();
  }

  @override
  Future<List<ProcesoProductivoOption>> listActiveProcesses() async {
    final items = await _remoteDataSource.listActiveProcesses();
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<List<InsumoLookup>> listActiveInsumos() async {
    final items = await _remoteDataSource.listActiveInsumos();
    return items.map((item) => item.toEntity()).toList(growable: false);
  }
}
