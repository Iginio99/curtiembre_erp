import 'package:erp_curtiembre_fronted/features/configuration/formulas/domain/entities/formula_record.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/domain/entities/insumo_lookup.dart';

abstract class FormulasRepository {
  Future<List<FormulaRecord>> listFormulas({
    String? texto,
    int? procesoProductivoId,
    bool? activo,
  });

  Future<FormulaRecord> getFormula(int id);

  Future<FormulaRecord> createFormula({
    required String codigo,
    required String nombre,
    required int procesoProductivoId,
    String? descripcion,
  });

  Future<FormulaRecord> updateFormula({
    required int id,
    required String codigo,
    required String nombre,
    required int procesoProductivoId,
    String? descripcion,
  });

  Future<FormulaRecord> setFormulaActive({
    required int id,
    required bool active,
  });

  Future<List<FormulaVersionRecord>> listVersions(int formulaId);

  Future<FormulaVersionRecord> getVersion(int id);

  Future<FormulaVersionRecord> createVersion({
    required int formulaId,
    required int numeroVersion,
    required DateTime fechaInicioVigencia,
    DateTime? fechaFinVigencia,
    String? observacion,
    int? clonarDesdeVersionId,
  });

  Future<FormulaVersionRecord> updateVersion({
    required int id,
    required DateTime fechaInicioVigencia,
    DateTime? fechaFinVigencia,
    String? observacion,
  });

  Future<FormulaVersionRecord> activateVersion(int id);

  Future<FormulaDetailRecord> createDetail({
    required int versionId,
    required int insumoId,
    required double porcentaje,
    String? observacion,
  });

  Future<FormulaDetailRecord> updateDetail({
    required int id,
    required int insumoId,
    required double porcentaje,
    String? observacion,
    required bool activo,
  });

  Future<FormulaDetailRecord> deleteDetail(int id);

  Future<List<ProcesoProductivoOption>> listActiveProcesses();

  Future<List<InsumoLookup>> listActiveInsumos();
}
