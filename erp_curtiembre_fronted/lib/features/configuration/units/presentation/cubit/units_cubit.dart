import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/configuration/units/domain/repositories/units_repository.dart';
import 'package:erp_curtiembre_fronted/features/configuration/units/presentation/cubit/units_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UnitsActionResult {
  const UnitsActionResult._({
    required this.success,
    required this.message,
  });

  const UnitsActionResult.success(String message)
      : this._(
          success: true,
          message: message,
        );

  const UnitsActionResult.failure(String message)
      : this._(
          success: false,
          message: message,
        );

  final bool success;
  final String message;
}

class UnitsCubit extends Cubit<UnitsState> {
  UnitsCubit(this._unitsRepository) : super(const UnitsState.loading());

  final UnitsRepository _unitsRepository;

  Future<void> initialize() async {
    emit(const UnitsState.loading());
    await load();
  }

  Future<void> load({
    String? searchTerm,
    UnitActivityFilter? activityFilter,
    UnitDecimalFilter? decimalFilter,
  }) async {
    final nextSearchTerm = searchTerm ?? state.searchTerm;
    final nextActivityFilter = activityFilter ?? state.activityFilter;
    final nextDecimalFilter = decimalFilter ?? state.decimalFilter;

    emit(
      state.copyWith(
        status: UnitsStatus.loading,
        searchTerm: nextSearchTerm,
        activityFilter: nextActivityFilter,
        decimalFilter: nextDecimalFilter,
        clearError: true,
      ),
    );

    try {
      await _reloadUnits(
        searchTerm: nextSearchTerm,
        activityFilter: nextActivityFilter,
        decimalFilter: nextDecimalFilter,
      );
    } on ApiException catch (exception) {
      emit(
        state.copyWith(
          status: UnitsStatus.error,
          errorMessage: exception.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: UnitsStatus.error,
          errorMessage: 'No pudimos cargar las unidades de medida.',
        ),
      );
    }
  }

  Future<void> selectUnit(int unitId) async {
    if (state.selectedUnitId == unitId && state.selectedUnit?.id == unitId) {
      return;
    }

    emit(
      state.copyWith(
        selectedUnitId: unitId,
        clearDetailError: true,
      ),
    );

    await _loadUnitDetail(unitId);
  }

  Future<void> retryDetail() async {
    final unitId = state.selectedUnitId;
    if (unitId == null) {
      return;
    }

    await _loadUnitDetail(unitId);
  }

  Future<UnitsActionResult> createUnit({
    required String codigo,
    required String nombre,
    required bool permiteDecimales,
  }) async {
    emit(state.copyWith(isSubmittingAction: true));

    try {
      final unit = await _unitsRepository.createUnit(
        codigo: codigo,
        nombre: nombre,
        permiteDecimales: permiteDecimales,
      );

      await _reloadUnits(
        searchTerm: state.searchTerm,
        activityFilter: state.activityFilter,
        decimalFilter: state.decimalFilter,
        preferredUnitId: unit.id,
      );

      emit(state.copyWith(isSubmittingAction: false));
      return const UnitsActionResult.success('Unidad creada correctamente.');
    } on ApiException catch (exception) {
      emit(state.copyWith(isSubmittingAction: false));
      return UnitsActionResult.failure(exception.message);
    } catch (_) {
      emit(state.copyWith(isSubmittingAction: false));
      return const UnitsActionResult.failure(
        'No pudimos crear la unidad de medida.',
      );
    }
  }

  Future<UnitsActionResult> updateSelectedUnit({
    required String codigo,
    required String nombre,
    required bool permiteDecimales,
  }) async {
    final unitId = state.selectedUnitId;
    if (unitId == null) {
      return const UnitsActionResult.failure(
        'Selecciona una unidad para editar.',
      );
    }

    emit(state.copyWith(isSubmittingAction: true));

    try {
      await _unitsRepository.updateUnit(
        id: unitId,
        codigo: codigo,
        nombre: nombre,
        permiteDecimales: permiteDecimales,
      );

      await _reloadUnits(
        searchTerm: state.searchTerm,
        activityFilter: state.activityFilter,
        decimalFilter: state.decimalFilter,
        preferredUnitId: unitId,
      );

      emit(state.copyWith(isSubmittingAction: false));
      return const UnitsActionResult.success('Unidad actualizada correctamente.');
    } on ApiException catch (exception) {
      emit(state.copyWith(isSubmittingAction: false));
      return UnitsActionResult.failure(exception.message);
    } catch (_) {
      emit(state.copyWith(isSubmittingAction: false));
      return const UnitsActionResult.failure(
        'No pudimos actualizar la unidad de medida.',
      );
    }
  }

  Future<UnitsActionResult> setSelectedUnitActive(bool active) async {
    final unitId = state.selectedUnitId;
    if (unitId == null) {
      return const UnitsActionResult.failure(
        'Selecciona una unidad para continuar.',
      );
    }

    emit(state.copyWith(isSubmittingAction: true));

    try {
      await _unitsRepository.setUnitActive(
        id: unitId,
        active: active,
      );

      await _reloadUnits(
        searchTerm: state.searchTerm,
        activityFilter: state.activityFilter,
        decimalFilter: state.decimalFilter,
        preferredUnitId: unitId,
      );

      emit(state.copyWith(isSubmittingAction: false));
      return UnitsActionResult.success(
        active
            ? 'Unidad activada correctamente.'
            : 'Unidad inactivada correctamente.',
      );
    } on ApiException catch (exception) {
      emit(state.copyWith(isSubmittingAction: false));
      return UnitsActionResult.failure(exception.message);
    } catch (_) {
      emit(state.copyWith(isSubmittingAction: false));
      return UnitsActionResult.failure(
        active
            ? 'No pudimos activar la unidad de medida.'
            : 'No pudimos inactivar la unidad de medida.',
      );
    }
  }

  Future<void> _loadUnitDetail(int unitId) async {
    emit(
      state.copyWith(
        isDetailLoading: true,
        clearSelectedUnit: true,
        clearDetailError: true,
      ),
    );

    try {
      final unit = await _unitsRepository.getUnit(unitId);
      emit(
        state.copyWith(
          isDetailLoading: false,
          selectedUnit: unit,
          clearDetailError: true,
        ),
      );
    } on ApiException catch (exception) {
      emit(
        state.copyWith(
          isDetailLoading: false,
          detailErrorMessage: exception.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isDetailLoading: false,
          detailErrorMessage: 'No pudimos cargar el detalle de la unidad.',
        ),
      );
    }
  }

  Future<void> _reloadUnits({
    required String searchTerm,
    required UnitActivityFilter activityFilter,
    required UnitDecimalFilter decimalFilter,
    int? preferredUnitId,
  }) async {
    final items = await _unitsRepository.listUnits(
      texto: searchTerm,
      activo: _mapActivityFilter(activityFilter),
      permiteDecimales: _mapDecimalFilter(decimalFilter),
    );

    final currentSelectedId = preferredUnitId ?? state.selectedUnitId;
    final selectedUnitId = items.any((item) => item.id == currentSelectedId)
        ? currentSelectedId
        : items.isNotEmpty
            ? items.first.id
            : null;

    emit(
      state.copyWith(
        status: UnitsStatus.success,
        items: items,
        selectedUnitId: selectedUnitId,
        searchTerm: searchTerm,
        activityFilter: activityFilter,
        decimalFilter: decimalFilter,
        clearError: true,
      ),
    );

    if (selectedUnitId == null) {
      emit(
        state.copyWith(
          isDetailLoading: false,
          clearSelectedUnit: true,
          clearDetailError: true,
        ),
      );
      return;
    }

    await _loadUnitDetail(selectedUnitId);
  }

  bool? _mapActivityFilter(UnitActivityFilter filter) {
    return switch (filter) {
      UnitActivityFilter.active => true,
      UnitActivityFilter.inactive => false,
      UnitActivityFilter.all => null,
    };
  }

  bool? _mapDecimalFilter(UnitDecimalFilter filter) {
    return switch (filter) {
      UnitDecimalFilter.all => null,
      UnitDecimalFilter.decimals => true,
      UnitDecimalFilter.integers => false,
    };
  }
}
