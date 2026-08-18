import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/finance/activos/domain/repositories/activos_repository.dart';
import 'package:erp_curtiembre_fronted/features/finance/activos/presentation/cubit/activos_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';

class ActivosActionResult {
  const ActivosActionResult._({required this.success, required this.message});

  const ActivosActionResult.success(String message)
    : this._(success: true, message: message);

  const ActivosActionResult.failure(String message)
    : this._(success: false, message: message);

  final bool success;
  final String message;
}

class ActivosCubit extends Cubit<ActivosState> {
  ActivosCubit(this._repository, this._talker)
    : super(const ActivosState.loading());

  final ActivosRepository _repository;
  final Talker _talker;

  Future<void> initialize() async {
    _talker.cubit('Inicializando modulo de activos depreciables.');
    emit(const ActivosState.loading());
    await load();
  }

  Future<void> load({String? searchTerm, ActivoActivityFilter? filter}) async {
    final nextSearchTerm = searchTerm ?? state.searchTerm;
    final nextFilter = filter ?? state.filter;
    _talker.cubit(
      'Cargando activos depreciables con busqueda=${_describeText(nextSearchTerm)}, actividad=${_describeActivityFilter(nextFilter)}.',
    );

    emit(
      state.copyWith(
        status: ActivosStatus.loading,
        searchTerm: nextSearchTerm,
        filter: nextFilter,
        clearError: true,
      ),
    );

    try {
      await _reloadActivos(searchTerm: nextSearchTerm, filter: nextFilter);
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar la lista de activos depreciables: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(
        state.copyWith(
          status: ActivosStatus.error,
          errorMessage: exception.message,
        ),
      );
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al cargar la lista de activos depreciables.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          status: ActivosStatus.error,
          errorMessage: 'No pudimos cargar los activos. Intenta nuevamente.',
        ),
      );
    }
  }

  Future<void> selectActivo(int activoId) async {
    if (state.selectedActivoId == activoId &&
        state.selectedActivo?.id == activoId) {
      _talker.cubit(
        'Se ignoro la seleccion del activo $activoId porque ya estaba cargado.',
        logLevel: LogLevel.debug,
      );
      return;
    }

    _talker.cubit(
      'Seleccionando activo depreciable $activoId para ver detalle.',
    );
    emit(state.copyWith(selectedActivoId: activoId, clearDetailError: true));
    await _loadActivoDetail(activoId);
  }

  Future<void> retryDetail() async {
    final activoId = state.selectedActivoId;
    if (activoId == null) {
      _talker.cubit(
        'Se intento reintentar detalle sin un activo seleccionado.',
        logLevel: LogLevel.warning,
      );
      return;
    }
    _talker.cubit(
      'Reintentando carga de detalle para el activo depreciable $activoId.',
    );
    await _loadActivoDetail(activoId);
  }

  Future<ActivosActionResult> createActivo({
    required String codigo,
    required String nombre,
    required double valorCompra,
    required DateTime fechaCompra,
    required int vidaUtilMeses,
    required double valorResidual,
    required bool activo,
  }) async {
    _talker.cubit(
      'Creando activo depreciable con codigo=${_describeText(codigo)}, nombre=${_describeText(nombre)}, valorCompra=$valorCompra, vidaUtilMeses=$vidaUtilMeses, valorResidual=$valorResidual, activo=$activo.',
    );
    emit(state.copyWith(isSubmittingAction: true));
    try {
      final item = await _repository.createActivo(
        codigo: codigo,
        nombre: nombre,
        valorCompra: valorCompra,
        fechaCompra: fechaCompra,
        vidaUtilMeses: vidaUtilMeses,
        valorResidual: valorResidual,
        activo: activo,
      );

      await _reloadActivos(
        searchTerm: state.searchTerm,
        filter: state.filter,
        preferredActivoId: item.id,
      );

      emit(state.copyWith(isSubmittingAction: false));
      _talker.cubit(
        'Activo depreciable creado correctamente con id=${item.id}.',
      );
      return const ActivosActionResult.success(
        'Activo registrado correctamente.',
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo crear el activo depreciable: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return ActivosActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al crear el activo depreciable.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const ActivosActionResult.failure(
        'No pudimos registrar el activo. Intenta nuevamente.',
      );
    }
  }

  Future<ActivosActionResult> updateSelectedActivo({
    required String codigo,
    required String nombre,
    required double valorCompra,
    required DateTime fechaCompra,
    required int vidaUtilMeses,
    required double valorResidual,
    required bool activo,
  }) async {
    final activoId = state.selectedActivoId;
    if (activoId == null) {
      _talker.cubit(
        'Se intento editar un activo depreciable sin seleccion previa.',
        logLevel: LogLevel.warning,
      );
      return const ActivosActionResult.failure(
        'Selecciona un activo para editar.',
      );
    }

    _talker.cubit(
      'Actualizando activo depreciable $activoId con codigo=${_describeText(codigo)}, nombre=${_describeText(nombre)}, valorCompra=$valorCompra, vidaUtilMeses=$vidaUtilMeses, valorResidual=$valorResidual, activo=$activo.',
      logLevel: LogLevel.warning,
    );
    emit(state.copyWith(isSubmittingAction: true));
    try {
      await _repository.updateActivo(
        id: activoId,
        codigo: codigo,
        nombre: nombre,
        valorCompra: valorCompra,
        fechaCompra: fechaCompra,
        vidaUtilMeses: vidaUtilMeses,
        valorResidual: valorResidual,
        activo: activo,
      );

      await _reloadActivos(
        searchTerm: state.searchTerm,
        filter: state.filter,
        preferredActivoId: activoId,
      );

      emit(state.copyWith(isSubmittingAction: false));
      _talker.cubit(
        'Activo depreciable $activoId actualizado correctamente.',
        logLevel: LogLevel.warning,
      );
      return const ActivosActionResult.success(
        'Activo actualizado correctamente.',
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo actualizar el activo depreciable $activoId: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return ActivosActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al actualizar el activo depreciable $activoId.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const ActivosActionResult.failure(
        'No pudimos actualizar el activo. Intenta nuevamente.',
      );
    }
  }

  Future<void> _loadActivoDetail(int activoId) async {
    _talker.cubit('Cargando detalle del activo depreciable $activoId.');
    emit(
      state.copyWith(
        isDetailLoading: true,
        clearSelectedActivo: true,
        clearDetailError: true,
      ),
    );

    try {
      final item = await _repository.getActivo(activoId);
      _talker.cubit(
        'Detalle del activo depreciable $activoId cargado correctamente.',
        logLevel: LogLevel.debug,
      );
      emit(
        state.copyWith(
          isDetailLoading: false,
          selectedActivo: item,
          clearDetailError: true,
        ),
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar el detalle del activo depreciable $activoId: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(
        state.copyWith(
          isDetailLoading: false,
          detailErrorMessage: exception.message,
        ),
      );
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al cargar el detalle del activo depreciable $activoId.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          isDetailLoading: false,
          detailErrorMessage: 'No pudimos cargar el detalle del activo.',
        ),
      );
    }
  }

  Future<void> _reloadActivos({
    required String searchTerm,
    required ActivoActivityFilter filter,
    int? preferredActivoId,
  }) async {
    _talker.cubit(
      'Recargando activos depreciables con busqueda=${_describeText(searchTerm)}, actividad=${_describeActivityFilter(filter)}, preferido=${preferredActivoId ?? state.selectedActivoId ?? 'ninguno'}.',
      logLevel: LogLevel.debug,
    );
    final items = await _repository.listActivos(
      texto: searchTerm,
      activo: _mapFilter(filter),
    );

    final currentSelectedId = preferredActivoId ?? state.selectedActivoId;
    final selectedId = items.any((item) => item.id == currentSelectedId)
        ? currentSelectedId
        : items.isNotEmpty
        ? items.first.id
        : null;
    _talker.cubit(
      'Recarga de activos depreciables completada con ${items.length} resultados. Seleccion actual=${selectedId ?? 'ninguna'}.',
      logLevel: LogLevel.debug,
    );

    emit(
      state.copyWith(
        status: ActivosStatus.success,
        items: items,
        selectedActivoId: selectedId,
        searchTerm: searchTerm,
        filter: filter,
        clearError: true,
      ),
    );

    if (selectedId == null) {
      emit(
        state.copyWith(
          isDetailLoading: false,
          clearSelectedActivo: true,
          clearDetailError: true,
        ),
      );
      _talker.cubit(
        'No hay activo depreciable seleccionado despues de la recarga.',
        logLevel: LogLevel.debug,
      );
      return;
    }

    await _loadActivoDetail(selectedId);
  }

  bool? _mapFilter(ActivoActivityFilter filter) {
    return switch (filter) {
      ActivoActivityFilter.active => true,
      ActivoActivityFilter.inactive => false,
      ActivoActivityFilter.all => null,
    };
  }

  String _describeText(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return '${normalized.length} caracteres';
  }

  String _describeActivityFilter(ActivoActivityFilter value) {
    return switch (value) {
      ActivoActivityFilter.active => 'activos',
      ActivoActivityFilter.inactive => 'inactivos',
      ActivoActivityFilter.all => 'todos',
    };
  }
}
