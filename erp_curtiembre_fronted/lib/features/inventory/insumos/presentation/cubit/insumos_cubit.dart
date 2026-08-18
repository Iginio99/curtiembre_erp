import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/inventory/insumos/domain/repositories/insumos_repository.dart';
import 'package:erp_curtiembre_fronted/features/inventory/insumos/presentation/cubit/insumos_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';

class InsumosActionResult {
  const InsumosActionResult._({required this.success, required this.message});

  const InsumosActionResult.success(String message)
    : this._(success: true, message: message);

  const InsumosActionResult.failure(String message)
    : this._(success: false, message: message);

  final bool success;
  final String message;
}

class InsumosCubit extends Cubit<InsumosState> {
  static const Object _sentinel = Object();

  InsumosCubit(this._repository, this._talker)
    : super(const InsumosState.loading());

  final InsumosRepository _repository;
  final Talker _talker;

  Future<void> initialize() async {
    _talker.cubit('Inicializando modulo de insumos.');
    emit(const InsumosState.loading());

    try {
      final unitOptions = await _repository.listActiveUnits();
      _talker.cubit(
        'Catalogo base de insumos cargado con ${unitOptions.length} unidades de medida activas.',
        logLevel: LogLevel.debug,
      );
      emit(state.copyWith(unitOptions: unitOptions));
      await load();
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar la base de insumos: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(
        state.copyWith(
          status: InsumosStatus.error,
          errorMessage: exception.message,
        ),
      );
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al cargar la base de insumos.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          status: InsumosStatus.error,
          errorMessage: 'No pudimos cargar la base de insumos.',
        ),
      );
    }
  }

  Future<void> load({
    String? searchTerm,
    InsumoActivityFilter? activityFilter,
    bool? stockBajoOnly,
    Object? tipoBienFilter = _sentinel,
  }) async {
    final nextSearchTerm = searchTerm ?? state.searchTerm;
    final nextActivityFilter = activityFilter ?? state.activityFilter;
    final nextStockBajoOnly = stockBajoOnly ?? state.stockBajoOnly;
    final nextTipoBienFilter = identical(tipoBienFilter, _sentinel)
        ? state.tipoBienFilter
        : tipoBienFilter as String?;
    _talker.cubit(
      'Cargando insumos con busqueda=${_describeText(nextSearchTerm)}, actividad=${_describeActivityFilter(nextActivityFilter)}, stockBajo=$nextStockBajoOnly, tipoBien=${_describeState(nextTipoBienFilter)}.',
    );

    emit(
      state.copyWith(
        status: InsumosStatus.loading,
        searchTerm: nextSearchTerm,
        activityFilter: nextActivityFilter,
        stockBajoOnly: nextStockBajoOnly,
        tipoBienFilter: nextTipoBienFilter,
        clearError: true,
      ),
    );

    try {
      await _reloadInsumos(
        searchTerm: nextSearchTerm,
        activityFilter: nextActivityFilter,
        stockBajoOnly: nextStockBajoOnly,
        tipoBienFilter: nextTipoBienFilter,
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar la lista de insumos: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(
        state.copyWith(
          status: InsumosStatus.error,
          errorMessage: exception.message,
        ),
      );
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al cargar la lista de insumos.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          status: InsumosStatus.error,
          errorMessage: 'No pudimos cargar los insumos. Intenta nuevamente.',
        ),
      );
    }
  }

  Future<void> selectInsumo(int insumoId) async {
    if (state.selectedInsumoId == insumoId &&
        state.selectedInsumo?.id == insumoId) {
      _talker.cubit(
        'Se ignoro la seleccion del insumo $insumoId porque ya estaba cargado.',
        logLevel: LogLevel.debug,
      );
      return;
    }

    _talker.cubit('Seleccionando insumo $insumoId para ver detalle.');
    emit(state.copyWith(selectedInsumoId: insumoId, clearDetailError: true));

    await _loadInsumoDetail(insumoId);
  }

  Future<void> retryDetail() async {
    final insumoId = state.selectedInsumoId;
    if (insumoId == null) {
      _talker.cubit(
        'Se intento reintentar detalle sin un insumo seleccionado.',
        logLevel: LogLevel.warning,
      );
      return;
    }

    _talker.cubit('Reintentando carga de detalle para el insumo $insumoId.');
    await _loadInsumoDetail(insumoId);
  }

  Future<InsumosActionResult> createInsumo({
    required String codigo,
    required String nombre,
    required String tipoBien,
    String? presentacion,
    required int unidadMedidaId,
    required double stockMinimo,
    required bool requiereLote,
  }) async {
    _talker.cubit(
      'Creando insumo codigo=$codigo, nombre=${_describeText(nombre)}, tipoBien=${_describeState(tipoBien)}, requiereLote=$requiereLote.',
    );
    emit(state.copyWith(isSubmittingAction: true));

    try {
      final insumo = await _repository.createInsumo(
        codigo: codigo,
        nombre: nombre,
        tipoBien: tipoBien,
        presentacion: presentacion,
        unidadMedidaId: unidadMedidaId,
        stockMinimo: stockMinimo,
        requiereLote: requiereLote,
      );

      await _reloadInsumos(
        searchTerm: state.searchTerm,
        activityFilter: state.activityFilter,
        stockBajoOnly: state.stockBajoOnly,
        tipoBienFilter: state.tipoBienFilter,
        preferredInsumoId: insumo.id,
      );

      emit(state.copyWith(isSubmittingAction: false));
      _talker.cubit('Insumo creado correctamente con id=${insumo.id}.');
      return const InsumosActionResult.success('Insumo creado correctamente.');
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo crear el insumo codigo=$codigo: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return InsumosActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al crear el insumo codigo=$codigo.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const InsumosActionResult.failure(
        'No pudimos crear el insumo. Intenta nuevamente.',
      );
    }
  }

  Future<InsumosActionResult> updateSelectedInsumo({
    required String codigo,
    required String nombre,
    required String tipoBien,
    String? presentacion,
    required int unidadMedidaId,
    required double stockMinimo,
    required bool requiereLote,
  }) async {
    final insumoId = state.selectedInsumoId;
    if (insumoId == null) {
      _talker.cubit(
        'Se intento editar un insumo sin seleccion previa.',
        logLevel: LogLevel.warning,
      );
      return const InsumosActionResult.failure(
        'Selecciona un insumo para editar.',
      );
    }

    _talker.cubit(
      'Actualizando insumo $insumoId con codigo=$codigo, nombre=${_describeText(nombre)}, tipoBien=${_describeState(tipoBien)}.',
      logLevel: LogLevel.warning,
    );
    emit(state.copyWith(isSubmittingAction: true));

    try {
      await _repository.updateInsumo(
        id: insumoId,
        codigo: codigo,
        nombre: nombre,
        tipoBien: tipoBien,
        presentacion: presentacion,
        unidadMedidaId: unidadMedidaId,
        stockMinimo: stockMinimo,
        requiereLote: requiereLote,
      );

      await _reloadInsumos(
        searchTerm: state.searchTerm,
        activityFilter: state.activityFilter,
        stockBajoOnly: state.stockBajoOnly,
        tipoBienFilter: state.tipoBienFilter,
        preferredInsumoId: insumoId,
      );

      emit(state.copyWith(isSubmittingAction: false));
      _talker.cubit(
        'Insumo $insumoId actualizado correctamente.',
        logLevel: LogLevel.warning,
      );
      return const InsumosActionResult.success(
        'Insumo actualizado correctamente.',
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo actualizar el insumo $insumoId: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return InsumosActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al actualizar el insumo $insumoId.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const InsumosActionResult.failure(
        'No pudimos actualizar el insumo. Intenta nuevamente.',
      );
    }
  }

  Future<InsumosActionResult> setSelectedInsumoActive(bool active) async {
    final insumoId = state.selectedInsumoId;
    if (insumoId == null) {
      _talker.cubit(
        'Se intento cambiar el estado de un insumo sin seleccion previa.',
        logLevel: LogLevel.warning,
      );
      return const InsumosActionResult.failure(
        'Selecciona un insumo para continuar.',
      );
    }

    _talker.cubit(
      '${active ? 'Activando' : 'Inactivando'} insumo $insumoId.',
      logLevel: LogLevel.warning,
    );
    emit(state.copyWith(isSubmittingAction: true));

    try {
      await _repository.setInsumoActive(id: insumoId, active: active);

      await _reloadInsumos(
        searchTerm: state.searchTerm,
        activityFilter: state.activityFilter,
        stockBajoOnly: state.stockBajoOnly,
        tipoBienFilter: state.tipoBienFilter,
        preferredInsumoId: insumoId,
      );

      emit(state.copyWith(isSubmittingAction: false));
      _talker.cubit(
        'Insumo $insumoId ${active ? 'activado' : 'inactivado'} correctamente.',
        logLevel: LogLevel.warning,
      );
      return InsumosActionResult.success(
        active
            ? 'Insumo activado correctamente.'
            : 'Insumo inactivado correctamente.',
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo ${active ? 'activar' : 'inactivar'} el insumo $insumoId: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return InsumosActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al ${active ? 'activar' : 'inactivar'} el insumo $insumoId.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return InsumosActionResult.failure(
        active
            ? 'No pudimos activar el insumo.'
            : 'No pudimos inactivar el insumo.',
      );
    }
  }

  Future<void> _loadInsumoDetail(int insumoId) async {
    _talker.cubit('Cargando detalle del insumo $insumoId.');
    emit(
      state.copyWith(
        isDetailLoading: true,
        clearSelectedInsumo: true,
        clearDetailError: true,
      ),
    );

    try {
      final insumo = await _repository.getInsumo(insumoId);
      _talker.cubit(
        'Detalle del insumo $insumoId cargado correctamente.',
        logLevel: LogLevel.debug,
      );
      emit(
        state.copyWith(
          isDetailLoading: false,
          selectedInsumo: insumo,
          clearDetailError: true,
        ),
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar el detalle del insumo $insumoId: ${exception.message}',
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
        'Fallo inesperado al cargar el detalle del insumo $insumoId.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          isDetailLoading: false,
          detailErrorMessage: 'No pudimos cargar el detalle del insumo.',
        ),
      );
    }
  }

  Future<void> _reloadInsumos({
    required String searchTerm,
    required InsumoActivityFilter activityFilter,
    required bool stockBajoOnly,
    required String? tipoBienFilter,
    int? preferredInsumoId,
  }) async {
    _talker.cubit(
      'Recargando insumos con busqueda=${_describeText(searchTerm)}, actividad=${_describeActivityFilter(activityFilter)}, stockBajo=$stockBajoOnly, tipoBien=${_describeState(tipoBienFilter)}, preferido=${preferredInsumoId ?? state.selectedInsumoId ?? 'ninguno'}.',
      logLevel: LogLevel.debug,
    );
    final items = await _repository.listInsumos(
      texto: searchTerm,
      tipoBien: tipoBienFilter,
      activo: _mapActivityFilter(activityFilter),
      stockBajo: stockBajoOnly ? true : null,
    );

    final currentSelectedId = preferredInsumoId ?? state.selectedInsumoId;
    final selectedInsumoId = items.any((item) => item.id == currentSelectedId)
        ? currentSelectedId
        : items.isNotEmpty
        ? items.first.id
        : null;
    _talker.cubit(
      'Recarga de insumos completada con ${items.length} resultados. Seleccion actual=${selectedInsumoId ?? 'ninguna'}.',
      logLevel: LogLevel.debug,
    );

    emit(
      state.copyWith(
        status: InsumosStatus.success,
        items: items,
        selectedInsumoId: selectedInsumoId,
        searchTerm: searchTerm,
        activityFilter: activityFilter,
        stockBajoOnly: stockBajoOnly,
        tipoBienFilter: tipoBienFilter,
        clearError: true,
      ),
    );

    if (selectedInsumoId == null) {
      emit(
        state.copyWith(
          isDetailLoading: false,
          clearSelectedInsumo: true,
          clearDetailError: true,
        ),
      );
      _talker.cubit(
        'No hay insumo seleccionado despues de la recarga.',
        logLevel: LogLevel.debug,
      );
      return;
    }

    await _loadInsumoDetail(selectedInsumoId);
  }

  bool? _mapActivityFilter(InsumoActivityFilter filter) {
    return switch (filter) {
      InsumoActivityFilter.active => true,
      InsumoActivityFilter.inactive => false,
      InsumoActivityFilter.all => null,
    };
  }

  String _describeText(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return '${normalized.length} caracteres';
  }

  String _describeState(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return normalized;
  }

  String _describeActivityFilter(InsumoActivityFilter value) {
    return switch (value) {
      InsumoActivityFilter.active => 'activos',
      InsumoActivityFilter.inactive => 'inactivos',
      InsumoActivityFilter.all => 'todos',
    };
  }
}
