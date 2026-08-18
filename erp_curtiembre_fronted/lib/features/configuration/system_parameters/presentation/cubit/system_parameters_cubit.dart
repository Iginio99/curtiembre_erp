import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/configuration/system_parameters/domain/entities/system_parameter_record.dart';
import 'package:erp_curtiembre_fronted/features/configuration/system_parameters/domain/repositories/system_parameters_repository.dart';
import 'package:erp_curtiembre_fronted/features/configuration/system_parameters/presentation/cubit/system_parameters_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SystemParametersCubit extends Cubit<SystemParametersState> {
  SystemParametersCubit(this._repository) : super(const SystemParametersState.loading());

  final SystemParametersRepository _repository;

  Future<void> initialize() async {
    emit(const SystemParametersState.loading());
    await load();
  }

  Future<void> load({
    String? searchTerm,
    SystemParameterEditabilityFilter? editabilityFilter,
    String? typeFilter,
  }) async {
    final nextSearchTerm = searchTerm ?? state.searchTerm;
    final nextEditabilityFilter = editabilityFilter ?? state.editabilityFilter;
    final nextTypeFilter = typeFilter ?? state.typeFilter;

    emit(
      state.copyWith(
        status: SystemParametersStatus.loading,
        searchTerm: nextSearchTerm,
        editabilityFilter: nextEditabilityFilter,
        typeFilter: nextTypeFilter,
        clearError: true,
      ),
    );

    try {
      final items = await _repository.listSystemParameters();
      _emitFilteredState(
        allItems: items,
        searchTerm: nextSearchTerm,
        editabilityFilter: nextEditabilityFilter,
        typeFilter: nextTypeFilter,
      );
    } on ApiException catch (exception) {
      emit(
        state.copyWith(
          status: SystemParametersStatus.error,
          errorMessage: exception.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: SystemParametersStatus.error,
          errorMessage: 'No pudimos cargar los parametros del sistema.',
        ),
      );
    }
  }

  void selectParameter(int parameterId) {
    if (state.selectedParameterId == parameterId) {
      return;
    }

    final selected = state.visibleItems
        .cast<SystemParameterRecord?>()
        .firstWhere(
          (item) => item?.id == parameterId,
          orElse: () => null,
        );

    emit(
      state.copyWith(
        selectedParameterId: parameterId,
        selectedParameter: selected,
      ),
    );
  }

  void applyFilters({
    String? searchTerm,
    SystemParameterEditabilityFilter? editabilityFilter,
    String? typeFilter,
  }) {
    final nextSearchTerm = searchTerm ?? state.searchTerm;
    final nextEditabilityFilter = editabilityFilter ?? state.editabilityFilter;
    final nextTypeFilter = typeFilter ?? state.typeFilter;

    _emitFilteredState(
      allItems: state.allItems,
      searchTerm: nextSearchTerm,
      editabilityFilter: nextEditabilityFilter,
      typeFilter: nextTypeFilter,
    );
  }

  void _emitFilteredState({
    required List<SystemParameterRecord> allItems,
    required String searchTerm,
    required SystemParameterEditabilityFilter editabilityFilter,
    required String typeFilter,
  }) {
    final normalizedSearch = searchTerm.trim().toLowerCase();
    final normalizedType = typeFilter.trim().toLowerCase();

    final visibleItems = allItems.where((item) {
      final matchesSearch = normalizedSearch.isEmpty ||
          item.clave.toLowerCase().contains(normalizedSearch) ||
          item.valor.toLowerCase().contains(normalizedSearch) ||
          (item.descripcion?.toLowerCase().contains(normalizedSearch) ?? false);

      final matchesEditability = switch (editabilityFilter) {
        SystemParameterEditabilityFilter.all => true,
        SystemParameterEditabilityFilter.editable => item.editable,
        SystemParameterEditabilityFilter.readOnly => !item.editable,
      };

      final matchesType = normalizedType.isEmpty ||
          item.tipoDato.toLowerCase() == normalizedType;

      return matchesSearch && matchesEditability && matchesType;
    }).toList(growable: false);

    final currentSelectedId = state.selectedParameterId;
    final selected = visibleItems.firstWhere(
      (item) => item.id == currentSelectedId,
      orElse: () => visibleItems.isNotEmpty ? visibleItems.first : const _EmptyParameter(),
    );

    emit(
      state.copyWith(
        status: SystemParametersStatus.success,
        allItems: allItems,
        visibleItems: visibleItems,
        selectedParameterId: visibleItems.isEmpty ? null : selected.id,
        selectedParameter: visibleItems.isEmpty ? null : selected,
        searchTerm: searchTerm,
        editabilityFilter: editabilityFilter,
        typeFilter: typeFilter,
        clearError: true,
      ),
    );
  }
}

class _EmptyParameter extends SystemParameterRecord {
  const _EmptyParameter()
      : super(
          id: -1,
          clave: '',
          valor: '',
          descripcion: null,
          tipoDato: '',
          editable: false,
          actualizadoEn: null,
        );
}
