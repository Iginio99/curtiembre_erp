import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/configuration/areas/domain/repositories/areas_repository.dart';
import 'package:erp_curtiembre_fronted/features/configuration/areas/presentation/cubit/areas_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AreasActionResult {
  const AreasActionResult._({
    required this.success,
    required this.message,
  });

  const AreasActionResult.success(String message)
      : this._(
          success: true,
          message: message,
        );

  const AreasActionResult.failure(String message)
      : this._(
          success: false,
          message: message,
        );

  final bool success;
  final String message;
}

class AreasCubit extends Cubit<AreasState> {
  AreasCubit(this._areasRepository) : super(const AreasState.loading());

  final AreasRepository _areasRepository;

  Future<void> initialize() async {
    emit(const AreasState.loading());
    await load();
  }

  Future<void> load({
    String? searchTerm,
    AreaActivityFilter? filter,
  }) async {
    final nextSearchTerm = searchTerm ?? state.searchTerm;
    final nextFilter = filter ?? state.filter;

    emit(
      state.copyWith(
        status: AreasStatus.loading,
        searchTerm: nextSearchTerm,
        filter: nextFilter,
        clearError: true,
      ),
    );

    try {
      await _reloadAreas(
        searchTerm: nextSearchTerm,
        filter: nextFilter,
      );
    } on ApiException catch (exception) {
      emit(
        state.copyWith(
          status: AreasStatus.error,
          errorMessage: exception.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AreasStatus.error,
          errorMessage: 'No pudimos cargar las areas. Intenta nuevamente.',
        ),
      );
    }
  }

  Future<void> selectArea(int areaId) async {
    if (state.selectedAreaId == areaId && state.selectedArea?.id == areaId) {
      return;
    }

    emit(
      state.copyWith(
        selectedAreaId: areaId,
        clearDetailError: true,
      ),
    );

    await _loadAreaDetail(areaId);
  }

  Future<void> retryDetail() async {
    final areaId = state.selectedAreaId;
    if (areaId == null) {
      return;
    }

    await _loadAreaDetail(areaId);
  }

  Future<AreasActionResult> createArea({
    required String codigo,
    required String nombre,
    String? descripcion,
  }) async {
    emit(state.copyWith(isSubmittingAction: true));

    try {
      final area = await _areasRepository.createArea(
        codigo: codigo,
        nombre: nombre,
        descripcion: descripcion,
      );

      await _reloadAreas(
        searchTerm: state.searchTerm,
        filter: state.filter,
        preferredAreaId: area.id,
      );

      emit(state.copyWith(isSubmittingAction: false));
      return const AreasActionResult.success('Area creada correctamente.');
    } on ApiException catch (exception) {
      emit(state.copyWith(isSubmittingAction: false));
      return AreasActionResult.failure(exception.message);
    } catch (_) {
      emit(state.copyWith(isSubmittingAction: false));
      return const AreasActionResult.failure(
        'No pudimos crear el area. Intenta nuevamente.',
      );
    }
  }

  Future<AreasActionResult> updateSelectedArea({
    required String codigo,
    required String nombre,
    String? descripcion,
  }) async {
    final areaId = state.selectedAreaId;
    if (areaId == null) {
      return const AreasActionResult.failure('Selecciona un area para editar.');
    }

    emit(state.copyWith(isSubmittingAction: true));

    try {
      await _areasRepository.updateArea(
        id: areaId,
        codigo: codigo,
        nombre: nombre,
        descripcion: descripcion,
      );

      await _reloadAreas(
        searchTerm: state.searchTerm,
        filter: state.filter,
        preferredAreaId: areaId,
      );

      emit(state.copyWith(isSubmittingAction: false));
      return const AreasActionResult.success('Area actualizada correctamente.');
    } on ApiException catch (exception) {
      emit(state.copyWith(isSubmittingAction: false));
      return AreasActionResult.failure(exception.message);
    } catch (_) {
      emit(state.copyWith(isSubmittingAction: false));
      return const AreasActionResult.failure(
        'No pudimos actualizar el area. Intenta nuevamente.',
      );
    }
  }

  Future<AreasActionResult> setSelectedAreaActive(bool active) async {
    final areaId = state.selectedAreaId;
    if (areaId == null) {
      return const AreasActionResult.failure('Selecciona un area para continuar.');
    }

    emit(state.copyWith(isSubmittingAction: true));

    try {
      await _areasRepository.setAreaActive(
        id: areaId,
        active: active,
      );

      await _reloadAreas(
        searchTerm: state.searchTerm,
        filter: state.filter,
        preferredAreaId: areaId,
      );

      emit(state.copyWith(isSubmittingAction: false));
      return AreasActionResult.success(
        active ? 'Area activada correctamente.' : 'Area inactivada correctamente.',
      );
    } on ApiException catch (exception) {
      emit(state.copyWith(isSubmittingAction: false));
      return AreasActionResult.failure(exception.message);
    } catch (_) {
      emit(state.copyWith(isSubmittingAction: false));
      return AreasActionResult.failure(
        active ? 'No pudimos activar el area.' : 'No pudimos inactivar el area.',
      );
    }
  }

  Future<void> _loadAreaDetail(int areaId) async {
    emit(
      state.copyWith(
        isDetailLoading: true,
        clearSelectedArea: true,
        clearDetailError: true,
      ),
    );

    try {
      final area = await _areasRepository.getArea(areaId);
      emit(
        state.copyWith(
          isDetailLoading: false,
          selectedArea: area,
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
          detailErrorMessage: 'No pudimos cargar el detalle del area.',
        ),
      );
    }
  }

  Future<void> _reloadAreas({
    required String searchTerm,
    required AreaActivityFilter filter,
    int? preferredAreaId,
  }) async {
    final items = await _areasRepository.listAreas(
      texto: searchTerm,
      activo: _mapFilter(filter),
    );

    final currentSelectedId = preferredAreaId ?? state.selectedAreaId;
    final selectedAreaId = items.any((item) => item.id == currentSelectedId)
        ? currentSelectedId
        : items.isNotEmpty
            ? items.first.id
            : null;

    emit(
      state.copyWith(
        status: AreasStatus.success,
        items: items,
        selectedAreaId: selectedAreaId,
        searchTerm: searchTerm,
        filter: filter,
        clearError: true,
      ),
    );

    if (selectedAreaId == null) {
      emit(
        state.copyWith(
          isDetailLoading: false,
          clearSelectedArea: true,
          clearDetailError: true,
        ),
      );
      return;
    }

    await _loadAreaDetail(selectedAreaId);
  }

  bool? _mapFilter(AreaActivityFilter filter) {
    return switch (filter) {
      AreaActivityFilter.active => true,
      AreaActivityFilter.inactive => false,
      AreaActivityFilter.all => null,
    };
  }
}
