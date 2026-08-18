import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/configuration/skin_types/domain/repositories/skin_types_repository.dart';
import 'package:erp_curtiembre_fronted/features/configuration/skin_types/presentation/cubit/skin_types_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SkinTypesActionResult {
  const SkinTypesActionResult._({
    required this.success,
    required this.message,
  });

  const SkinTypesActionResult.success(String message)
      : this._(
          success: true,
          message: message,
        );

  const SkinTypesActionResult.failure(String message)
      : this._(
          success: false,
          message: message,
        );

  final bool success;
  final String message;
}

class SkinTypesCubit extends Cubit<SkinTypesState> {
  SkinTypesCubit(this._repository) : super(const SkinTypesState.loading());

  final SkinTypesRepository _repository;

  Future<void> initialize() async {
    emit(const SkinTypesState.loading());
    await load();
  }

  Future<void> load({
    String? searchTerm,
    SkinTypeActivityFilter? filter,
  }) async {
    final nextSearchTerm = searchTerm ?? state.searchTerm;
    final nextFilter = filter ?? state.filter;

    emit(
      state.copyWith(
        status: SkinTypesStatus.loading,
        searchTerm: nextSearchTerm,
        filter: nextFilter,
        clearError: true,
      ),
    );

    try {
      await _reloadSkinTypes(
        searchTerm: nextSearchTerm,
        filter: nextFilter,
      );
    } on ApiException catch (exception) {
      emit(
        state.copyWith(
          status: SkinTypesStatus.error,
          errorMessage: exception.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: SkinTypesStatus.error,
          errorMessage: 'No pudimos cargar los tipos de piel.',
        ),
      );
    }
  }

  Future<void> selectSkinType(int itemId) async {
    if (state.selectedSkinTypeId == itemId && state.selectedSkinType?.id == itemId) {
      return;
    }

    emit(
      state.copyWith(
        selectedSkinTypeId: itemId,
        clearDetailError: true,
      ),
    );

    await _loadSkinTypeDetail(itemId);
  }

  Future<void> retryDetail() async {
    final itemId = state.selectedSkinTypeId;
    if (itemId == null) {
      return;
    }

    await _loadSkinTypeDetail(itemId);
  }

  Future<SkinTypesActionResult> createSkinType({
    required String codigo,
    required String nombre,
    String? descripcion,
  }) async {
    emit(state.copyWith(isSubmittingAction: true));

    try {
      final item = await _repository.createSkinType(
        codigo: codigo,
        nombre: nombre,
        descripcion: descripcion,
      );

      await _reloadSkinTypes(
        searchTerm: state.searchTerm,
        filter: state.filter,
        preferredItemId: item.id,
      );

      emit(state.copyWith(isSubmittingAction: false));
      return const SkinTypesActionResult.success('Tipo de piel creado correctamente.');
    } on ApiException catch (exception) {
      emit(state.copyWith(isSubmittingAction: false));
      return SkinTypesActionResult.failure(exception.message);
    } catch (_) {
      emit(state.copyWith(isSubmittingAction: false));
      return const SkinTypesActionResult.failure(
        'No pudimos crear el tipo de piel.',
      );
    }
  }

  Future<SkinTypesActionResult> updateSelectedSkinType({
    required String codigo,
    required String nombre,
    String? descripcion,
  }) async {
    final itemId = state.selectedSkinTypeId;
    if (itemId == null) {
      return const SkinTypesActionResult.failure(
        'Selecciona un tipo de piel para editar.',
      );
    }

    emit(state.copyWith(isSubmittingAction: true));

    try {
      await _repository.updateSkinType(
        id: itemId,
        codigo: codigo,
        nombre: nombre,
        descripcion: descripcion,
      );

      await _reloadSkinTypes(
        searchTerm: state.searchTerm,
        filter: state.filter,
        preferredItemId: itemId,
      );

      emit(state.copyWith(isSubmittingAction: false));
      return const SkinTypesActionResult.success('Tipo de piel actualizado correctamente.');
    } on ApiException catch (exception) {
      emit(state.copyWith(isSubmittingAction: false));
      return SkinTypesActionResult.failure(exception.message);
    } catch (_) {
      emit(state.copyWith(isSubmittingAction: false));
      return const SkinTypesActionResult.failure(
        'No pudimos actualizar el tipo de piel.',
      );
    }
  }

  Future<SkinTypesActionResult> setSelectedSkinTypeActive(bool active) async {
    final itemId = state.selectedSkinTypeId;
    if (itemId == null) {
      return const SkinTypesActionResult.failure(
        'Selecciona un tipo de piel para continuar.',
      );
    }

    emit(state.copyWith(isSubmittingAction: true));

    try {
      await _repository.setSkinTypeActive(
        id: itemId,
        active: active,
      );

      await _reloadSkinTypes(
        searchTerm: state.searchTerm,
        filter: state.filter,
        preferredItemId: itemId,
      );

      emit(state.copyWith(isSubmittingAction: false));
      return SkinTypesActionResult.success(
        active
            ? 'Tipo de piel activado correctamente.'
            : 'Tipo de piel inactivado correctamente.',
      );
    } on ApiException catch (exception) {
      emit(state.copyWith(isSubmittingAction: false));
      return SkinTypesActionResult.failure(exception.message);
    } catch (_) {
      emit(state.copyWith(isSubmittingAction: false));
      return SkinTypesActionResult.failure(
        active
            ? 'No pudimos activar el tipo de piel.'
            : 'No pudimos inactivar el tipo de piel.',
      );
    }
  }

  Future<void> _loadSkinTypeDetail(int itemId) async {
    emit(
      state.copyWith(
        isDetailLoading: true,
        clearSelectedSkinType: true,
        clearDetailError: true,
      ),
    );

    try {
      final item = await _repository.getSkinType(itemId);
      emit(
        state.copyWith(
          isDetailLoading: false,
          selectedSkinType: item,
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
          detailErrorMessage: 'No pudimos cargar el detalle del tipo de piel.',
        ),
      );
    }
  }

  Future<void> _reloadSkinTypes({
    required String searchTerm,
    required SkinTypeActivityFilter filter,
    int? preferredItemId,
  }) async {
    final items = await _repository.listSkinTypes(
      texto: searchTerm,
      activo: _mapFilter(filter),
    );

    final currentSelectedId = preferredItemId ?? state.selectedSkinTypeId;
    final selectedItemId = items.any((item) => item.id == currentSelectedId)
        ? currentSelectedId
        : items.isNotEmpty
            ? items.first.id
            : null;

    emit(
      state.copyWith(
        status: SkinTypesStatus.success,
        items: items,
        selectedSkinTypeId: selectedItemId,
        searchTerm: searchTerm,
        filter: filter,
        clearError: true,
      ),
    );

    if (selectedItemId == null) {
      emit(
        state.copyWith(
          isDetailLoading: false,
          clearSelectedSkinType: true,
          clearDetailError: true,
        ),
      );
      return;
    }

    await _loadSkinTypeDetail(selectedItemId);
  }

  bool? _mapFilter(SkinTypeActivityFilter filter) {
    return switch (filter) {
      SkinTypeActivityFilter.active => true,
      SkinTypeActivityFilter.inactive => false,
      SkinTypeActivityFilter.all => null,
    };
  }
}
