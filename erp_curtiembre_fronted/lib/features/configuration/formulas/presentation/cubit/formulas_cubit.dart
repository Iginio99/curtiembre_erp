import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/configuration/formulas/domain/entities/formula_record.dart';
import 'package:erp_curtiembre_fronted/features/configuration/formulas/domain/repositories/formulas_repository.dart';
import 'package:erp_curtiembre_fronted/features/configuration/formulas/presentation/cubit/formulas_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FormulasActionResult {
  const FormulasActionResult._({
    required this.success,
    required this.message,
  });

  const FormulasActionResult.success(String message)
      : this._(success: true, message: message);

  const FormulasActionResult.failure(String message)
      : this._(success: false, message: message);

  final bool success;
  final String message;
}

class FormulasCubit extends Cubit<FormulasState> {
  FormulasCubit(this._repository) : super(const FormulasState.loading());

  final FormulasRepository _repository;

  Future<void> initialize() async {
    emit(const FormulasState.loading());

    try {
      final processOptions = await _repository.listActiveProcesses();
      final insumoOptions = await _repository.listActiveInsumos();
      emit(
        state.copyWith(
          processOptions: processOptions,
          insumoOptions: insumoOptions,
        ),
      );
      await load();
    } on ApiException catch (exception) {
      emit(
        state.copyWith(
          status: FormulasStatus.error,
          errorMessage: exception.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: FormulasStatus.error,
          errorMessage: 'No pudimos cargar la configuracion de formulas.',
        ),
      );
    }
  }

  Future<void> load({
    String? searchTerm,
    FormulaActivityFilter? activityFilter,
    Object? processFilterId = _sentinel,
  }) async {
    final nextSearchTerm = searchTerm ?? state.searchTerm;
    final nextActivityFilter = activityFilter ?? state.activityFilter;
    final nextProcessFilterId = identical(processFilterId, _sentinel)
        ? state.processFilterId
        : processFilterId as int?;

    emit(
      state.copyWith(
        status: FormulasStatus.loading,
        searchTerm: nextSearchTerm,
        activityFilter: nextActivityFilter,
        processFilterId: nextProcessFilterId,
        clearError: true,
      ),
    );

    try {
      await _reloadFormulas(
        searchTerm: nextSearchTerm,
        activityFilter: nextActivityFilter,
        processFilterId: nextProcessFilterId,
      );
    } on ApiException catch (exception) {
      emit(
        state.copyWith(
          status: FormulasStatus.error,
          errorMessage: exception.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: FormulasStatus.error,
          errorMessage: 'No pudimos cargar las formulas. Intenta nuevamente.',
        ),
      );
    }
  }

  Future<void> selectFormula(int formulaId) async {
    if (state.selectedFormulaId == formulaId && state.selectedFormula?.id == formulaId) {
      return;
    }

    emit(
      state.copyWith(
        selectedFormulaId: formulaId,
        clearFormulaDetailError: true,
        clearVersionDetailError: true,
      ),
    );

    await _reloadSelectedFormulaContext(formulaId: formulaId);
  }

  Future<void> selectVersion(int versionId) async {
    if (state.selectedVersionId == versionId && state.selectedVersion?.id == versionId) {
      return;
    }

    emit(
      state.copyWith(
        selectedVersionId: versionId,
        isVersionDetailLoading: true,
        clearVersionDetailError: true,
        clearSelectedVersion: true,
      ),
    );

    try {
      final version = await _repository.getVersion(versionId);
      emit(
        state.copyWith(
          isVersionDetailLoading: false,
          selectedVersion: version,
          clearVersionDetailError: true,
        ),
      );
    } on ApiException catch (exception) {
      emit(
        state.copyWith(
          isVersionDetailLoading: false,
          versionDetailErrorMessage: exception.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isVersionDetailLoading: false,
          versionDetailErrorMessage: 'No pudimos cargar el detalle de la version.',
        ),
      );
    }
  }

  Future<void> retryFormulaDetail() async {
    final formulaId = state.selectedFormulaId;
    if (formulaId == null) {
      return;
    }
    await _reloadSelectedFormulaContext(formulaId: formulaId);
  }

  Future<void> retryVersionDetail() async {
    final versionId = state.selectedVersionId;
    if (versionId == null) {
      return;
    }
    await selectVersion(versionId);
  }

  Future<FormulasActionResult> createFormula({
    required String codigo,
    required String nombre,
    required int procesoProductivoId,
    String? descripcion,
  }) async {
    emit(state.copyWith(isSubmittingAction: true));
    try {
      final formula = await _repository.createFormula(
        codigo: codigo,
        nombre: nombre,
        procesoProductivoId: procesoProductivoId,
        descripcion: descripcion,
      );

      await _reloadFormulas(
        searchTerm: state.searchTerm,
        activityFilter: state.activityFilter,
        processFilterId: state.processFilterId,
        preferredFormulaId: formula.id,
      );

      emit(state.copyWith(isSubmittingAction: false));
      return const FormulasActionResult.success('Formula creada correctamente.');
    } on ApiException catch (exception) {
      emit(state.copyWith(isSubmittingAction: false));
      return FormulasActionResult.failure(exception.message);
    } catch (_) {
      emit(state.copyWith(isSubmittingAction: false));
      return const FormulasActionResult.failure(
        'No pudimos crear la formula. Intenta nuevamente.',
      );
    }
  }

  Future<FormulasActionResult> updateSelectedFormula({
    required String codigo,
    required String nombre,
    required int procesoProductivoId,
    String? descripcion,
  }) async {
    final formulaId = state.selectedFormulaId;
    if (formulaId == null) {
      return const FormulasActionResult.failure('Selecciona una formula para editar.');
    }

    emit(state.copyWith(isSubmittingAction: true));
    try {
      await _repository.updateFormula(
        id: formulaId,
        codigo: codigo,
        nombre: nombre,
        procesoProductivoId: procesoProductivoId,
        descripcion: descripcion,
      );

      await _reloadFormulas(
        searchTerm: state.searchTerm,
        activityFilter: state.activityFilter,
        processFilterId: state.processFilterId,
        preferredFormulaId: formulaId,
      );

      emit(state.copyWith(isSubmittingAction: false));
      return const FormulasActionResult.success('Formula actualizada correctamente.');
    } on ApiException catch (exception) {
      emit(state.copyWith(isSubmittingAction: false));
      return FormulasActionResult.failure(exception.message);
    } catch (_) {
      emit(state.copyWith(isSubmittingAction: false));
      return const FormulasActionResult.failure(
        'No pudimos actualizar la formula. Intenta nuevamente.',
      );
    }
  }

  Future<FormulasActionResult> setSelectedFormulaActive(bool active) async {
    final formulaId = state.selectedFormulaId;
    if (formulaId == null) {
      return const FormulasActionResult.failure('Selecciona una formula para continuar.');
    }

    emit(state.copyWith(isSubmittingAction: true));
    try {
      await _repository.setFormulaActive(id: formulaId, active: active);

      await _reloadFormulas(
        searchTerm: state.searchTerm,
        activityFilter: state.activityFilter,
        processFilterId: state.processFilterId,
        preferredFormulaId: formulaId,
      );

      emit(state.copyWith(isSubmittingAction: false));
      return FormulasActionResult.success(
        active ? 'Formula activada correctamente.' : 'Formula inactivada correctamente.',
      );
    } on ApiException catch (exception) {
      emit(state.copyWith(isSubmittingAction: false));
      return FormulasActionResult.failure(exception.message);
    } catch (_) {
      emit(state.copyWith(isSubmittingAction: false));
      return FormulasActionResult.failure(
        active ? 'No pudimos activar la formula.' : 'No pudimos inactivar la formula.',
      );
    }
  }

  Future<FormulasActionResult> createVersion({
    required int numeroVersion,
    required DateTime fechaInicioVigencia,
    DateTime? fechaFinVigencia,
    String? observacion,
    int? clonarDesdeVersionId,
  }) async {
    final formulaId = state.selectedFormulaId;
    if (formulaId == null) {
      return const FormulasActionResult.failure('Selecciona una formula primero.');
    }

    emit(state.copyWith(isSubmittingAction: true));
    try {
      final version = await _repository.createVersion(
        formulaId: formulaId,
        numeroVersion: numeroVersion,
        fechaInicioVigencia: fechaInicioVigencia,
        fechaFinVigencia: fechaFinVigencia,
        observacion: observacion,
        clonarDesdeVersionId: clonarDesdeVersionId,
      );

      await _reloadSelectedFormulaContext(
        formulaId: formulaId,
        preferredVersionId: version.id,
      );

      emit(state.copyWith(isSubmittingAction: false));
      return const FormulasActionResult.success('Version creada correctamente.');
    } on ApiException catch (exception) {
      emit(state.copyWith(isSubmittingAction: false));
      return FormulasActionResult.failure(exception.message);
    } catch (_) {
      emit(state.copyWith(isSubmittingAction: false));
      return const FormulasActionResult.failure(
        'No pudimos crear la version. Intenta nuevamente.',
      );
    }
  }

  Future<FormulasActionResult> updateSelectedVersion({
    required DateTime fechaInicioVigencia,
    DateTime? fechaFinVigencia,
    String? observacion,
  }) async {
    final versionId = state.selectedVersionId;
    if (versionId == null) {
      return const FormulasActionResult.failure('Selecciona una version para editar.');
    }

    emit(state.copyWith(isSubmittingAction: true));
    try {
      await _repository.updateVersion(
        id: versionId,
        fechaInicioVigencia: fechaInicioVigencia,
        fechaFinVigencia: fechaFinVigencia,
        observacion: observacion,
      );

      await _reloadSelectedFormulaContext(
        formulaId: state.selectedFormulaId!,
        preferredVersionId: versionId,
      );

      emit(state.copyWith(isSubmittingAction: false));
      return const FormulasActionResult.success('Version actualizada correctamente.');
    } on ApiException catch (exception) {
      emit(state.copyWith(isSubmittingAction: false));
      return FormulasActionResult.failure(exception.message);
    } catch (_) {
      emit(state.copyWith(isSubmittingAction: false));
      return const FormulasActionResult.failure(
        'No pudimos actualizar la version. Intenta nuevamente.',
      );
    }
  }

  Future<FormulasActionResult> activateSelectedVersion() async {
    final versionId = state.selectedVersionId;
    final formulaId = state.selectedFormulaId;
    if (versionId == null || formulaId == null) {
      return const FormulasActionResult.failure('Selecciona una version para activarla.');
    }

    emit(state.copyWith(isSubmittingAction: true));
    try {
      await _repository.activateVersion(versionId);
      await _reloadFormulas(
        searchTerm: state.searchTerm,
        activityFilter: state.activityFilter,
        processFilterId: state.processFilterId,
        preferredFormulaId: formulaId,
        preferredVersionId: versionId,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const FormulasActionResult.success('Version vigente actualizada correctamente.');
    } on ApiException catch (exception) {
      emit(state.copyWith(isSubmittingAction: false));
      return FormulasActionResult.failure(exception.message);
    } catch (_) {
      emit(state.copyWith(isSubmittingAction: false));
      return const FormulasActionResult.failure(
        'No pudimos activar la version. Intenta nuevamente.',
      );
    }
  }

  Future<FormulasActionResult> createDetail({
    required int insumoId,
    required double porcentaje,
    String? observacion,
  }) async {
    final versionId = state.selectedVersionId;
    final formulaId = state.selectedFormulaId;
    if (versionId == null || formulaId == null) {
      return const FormulasActionResult.failure('Selecciona una version para agregar detalle.');
    }

    emit(state.copyWith(isSubmittingAction: true));
    try {
      await _repository.createDetail(
        versionId: versionId,
        insumoId: insumoId,
        porcentaje: porcentaje,
        observacion: observacion,
      );
      await _reloadSelectedFormulaContext(
        formulaId: formulaId,
        preferredVersionId: versionId,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const FormulasActionResult.success('Detalle agregado correctamente.');
    } on ApiException catch (exception) {
      emit(state.copyWith(isSubmittingAction: false));
      return FormulasActionResult.failure(exception.message);
    } catch (_) {
      emit(state.copyWith(isSubmittingAction: false));
      return const FormulasActionResult.failure(
        'No pudimos agregar el detalle. Intenta nuevamente.',
      );
    }
  }

  Future<FormulasActionResult> updateDetail({
    required int id,
    required int insumoId,
    required double porcentaje,
    String? observacion,
    required bool activo,
  }) async {
    final versionId = state.selectedVersionId;
    final formulaId = state.selectedFormulaId;
    if (versionId == null || formulaId == null) {
      return const FormulasActionResult.failure('Selecciona una version para editar detalle.');
    }

    emit(state.copyWith(isSubmittingAction: true));
    try {
      await _repository.updateDetail(
        id: id,
        insumoId: insumoId,
        porcentaje: porcentaje,
        observacion: observacion,
        activo: activo,
      );
      await _reloadSelectedFormulaContext(
        formulaId: formulaId,
        preferredVersionId: versionId,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const FormulasActionResult.success('Detalle actualizado correctamente.');
    } on ApiException catch (exception) {
      emit(state.copyWith(isSubmittingAction: false));
      return FormulasActionResult.failure(exception.message);
    } catch (_) {
      emit(state.copyWith(isSubmittingAction: false));
      return const FormulasActionResult.failure(
        'No pudimos actualizar el detalle. Intenta nuevamente.',
      );
    }
  }

  Future<FormulasActionResult> deleteDetail(int id) async {
    final versionId = state.selectedVersionId;
    final formulaId = state.selectedFormulaId;
    if (versionId == null || formulaId == null) {
      return const FormulasActionResult.failure('Selecciona una version para inactivar detalle.');
    }

    emit(state.copyWith(isSubmittingAction: true));
    try {
      await _repository.deleteDetail(id);
      await _reloadSelectedFormulaContext(
        formulaId: formulaId,
        preferredVersionId: versionId,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const FormulasActionResult.success('Detalle inactivado correctamente.');
    } on ApiException catch (exception) {
      emit(state.copyWith(isSubmittingAction: false));
      return FormulasActionResult.failure(exception.message);
    } catch (_) {
      emit(state.copyWith(isSubmittingAction: false));
      return const FormulasActionResult.failure(
        'No pudimos inactivar el detalle. Intenta nuevamente.',
      );
    }
  }

  Future<void> _reloadFormulas({
    required String searchTerm,
    required FormulaActivityFilter activityFilter,
    required int? processFilterId,
    int? preferredFormulaId,
    int? preferredVersionId,
  }) async {
    final items = await _repository.listFormulas(
      texto: searchTerm,
      procesoProductivoId: processFilterId,
      activo: _mapActivityFilter(activityFilter),
    );

    final currentSelectedId = preferredFormulaId ?? state.selectedFormulaId;
    final selectedFormulaId = items.any((item) => item.id == currentSelectedId)
        ? currentSelectedId
        : items.isNotEmpty
            ? items.first.id
            : null;

    emit(
      state.copyWith(
        status: FormulasStatus.success,
        items: items,
        selectedFormulaId: selectedFormulaId,
        searchTerm: searchTerm,
        activityFilter: activityFilter,
        processFilterId: processFilterId,
        clearError: true,
      ),
    );

    if (selectedFormulaId == null) {
      emit(
        state.copyWith(
          versions: const [],
          isFormulaDetailLoading: false,
          isVersionDetailLoading: false,
          clearSelectedFormula: true,
          clearSelectedVersion: true,
          clearFormulaDetailError: true,
          clearVersionDetailError: true,
        ),
      );
      return;
    }

    await _reloadSelectedFormulaContext(
      formulaId: selectedFormulaId,
      preferredVersionId: preferredVersionId,
    );
  }

  Future<void> _reloadSelectedFormulaContext({
    required int formulaId,
    int? preferredVersionId,
  }) async {
    emit(
      state.copyWith(
        isFormulaDetailLoading: true,
        isVersionDetailLoading: true,
        clearSelectedFormula: true,
        clearSelectedVersion: true,
        clearFormulaDetailError: true,
        clearVersionDetailError: true,
      ),
    );

    try {
      final formula = await _repository.getFormula(formulaId);
      final versions = await _repository.listVersions(formulaId);
      final selectedVersionId = _resolveVersionId(
        versions: versions,
        preferredVersionId: preferredVersionId,
        fallbackVersionId: formula.versionVigente?.id ?? state.selectedVersionId,
      );

      emit(
        state.copyWith(
          isFormulaDetailLoading: false,
          selectedFormula: formula,
          versions: versions,
          selectedVersionId: selectedVersionId,
          clearFormulaDetailError: true,
          isVersionDetailLoading: selectedVersionId != null,
        ),
      );

      if (selectedVersionId == null) {
        emit(
          state.copyWith(
            isVersionDetailLoading: false,
            clearSelectedVersion: true,
            clearVersionDetailError: true,
          ),
        );
        return;
      }

      final version = await _repository.getVersion(selectedVersionId);
      emit(
        state.copyWith(
          isVersionDetailLoading: false,
          selectedVersion: version,
          clearVersionDetailError: true,
        ),
      );
    } on ApiException catch (exception) {
      emit(
        state.copyWith(
          isFormulaDetailLoading: false,
          isVersionDetailLoading: false,
          formulaDetailErrorMessage: exception.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isFormulaDetailLoading: false,
          isVersionDetailLoading: false,
          formulaDetailErrorMessage: 'No pudimos cargar el detalle de la formula.',
        ),
      );
    }
  }

  int? _resolveVersionId({
    required List<FormulaVersionRecord> versions,
    int? preferredVersionId,
    int? fallbackVersionId,
  }) {
    final candidateIds = [preferredVersionId, fallbackVersionId];
    for (final candidate in candidateIds) {
      if (candidate != null && versions.any((item) => item.id == candidate)) {
        return candidate;
      }
    }

    FormulaVersionRecord? vigente;
    for (final item in versions) {
      if (item.vigente) {
        vigente = item;
        break;
      }
    }

    return vigente?.id ?? (versions.isEmpty ? null : versions.first.id);
  }

  bool? _mapActivityFilter(FormulaActivityFilter filter) {
    return switch (filter) {
      FormulaActivityFilter.active => true,
      FormulaActivityFilter.inactive => false,
      FormulaActivityFilter.all => null,
    };
  }
}

const Object _sentinel = Object();
