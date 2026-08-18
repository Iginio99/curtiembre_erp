import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/finance/periodos/domain/repositories/periodos_repository.dart';
import 'package:erp_curtiembre_fronted/features/finance/periodos/presentation/cubit/periodos_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';

class PeriodosActionResult {
  const PeriodosActionResult._({required this.success, required this.message});

  const PeriodosActionResult.success(String message)
    : this._(success: true, message: message);

  const PeriodosActionResult.failure(String message)
    : this._(success: false, message: message);

  final bool success;
  final String message;
}

class PeriodosCubit extends Cubit<PeriodosState> {
  PeriodosCubit(this._repository, this._talker)
    : super(const PeriodosState.loading());

  final PeriodosRepository _repository;
  final Talker _talker;

  Future<void> initialize() async {
    _talker.cubit('Inicializando modulo de periodos de costo.');
    emit(const PeriodosState.loading());
    await load();
  }

  Future<void> load({
    int? anioFilter,
    int? mesFilter,
    String? estadoFilter,
  }) async {
    final nextAnioFilter = anioFilter ?? state.anioFilter;
    final nextMesFilter = mesFilter ?? state.mesFilter;
    final nextEstadoFilter = estadoFilter ?? state.estadoFilter;
    _talker.cubit(
      'Cargando periodos de costo con anio=$nextAnioFilter, mes=$nextMesFilter y estado=${_describeState(nextEstadoFilter)}.',
    );

    emit(
      state.copyWith(
        status: PeriodosStatus.loading,
        anioFilter: nextAnioFilter,
        mesFilter: nextMesFilter,
        estadoFilter: nextEstadoFilter,
        clearError: true,
      ),
    );

    try {
      await _reloadPeriodos(
        anioFilter: nextAnioFilter,
        mesFilter: nextMesFilter,
        estadoFilter: nextEstadoFilter,
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar la lista de periodos de costo: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(
        state.copyWith(
          status: PeriodosStatus.error,
          errorMessage: exception.message,
        ),
      );
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al cargar la lista de periodos de costo.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          status: PeriodosStatus.error,
          errorMessage:
              'No pudimos cargar los periodos de costo. Intenta nuevamente.',
        ),
      );
    }
  }

  Future<void> selectPeriodo(int periodoId) async {
    if (state.selectedPeriodoId == periodoId &&
        state.selectedPeriodo?.id == periodoId) {
      _talker.cubit(
        'Se ignoro la seleccion del periodo $periodoId porque ya estaba cargado.',
        logLevel: LogLevel.debug,
      );
      return;
    }

    _talker.cubit(
      'Seleccionando periodo de costo $periodoId para ver detalle.',
    );
    emit(state.copyWith(selectedPeriodoId: periodoId, clearDetailError: true));
    await _loadPeriodoDetail(periodoId);
  }

  Future<void> retryDetail() async {
    final periodoId = state.selectedPeriodoId;
    if (periodoId == null) {
      _talker.cubit(
        'Se intento reintentar detalle sin un periodo seleccionado.',
        logLevel: LogLevel.warning,
      );
      return;
    }
    _talker.cubit(
      'Reintentando carga de detalle para el periodo de costo $periodoId.',
    );
    await _loadPeriodoDetail(periodoId);
  }

  Future<PeriodosActionResult> createPeriodo({
    required int anio,
    required int mes,
    String? observacion,
  }) async {
    _talker.cubit(
      'Creando periodo de costo con anio=$anio, mes=$mes y observacion=${_describeText(observacion)}.',
      logLevel: LogLevel.warning,
    );
    emit(state.copyWith(isSubmittingAction: true));

    try {
      final periodo = await _repository.createPeriodo(
        anio: anio,
        mes: mes,
        observacion: observacion,
      );

      await _reloadPeriodos(
        anioFilter: state.anioFilter,
        mesFilter: state.mesFilter,
        estadoFilter: state.estadoFilter,
        preferredPeriodoId: periodo.id,
      );

      emit(state.copyWith(isSubmittingAction: false));
      _talker.cubit(
        'Periodo de costo creado correctamente con id=${periodo.id}.',
        logLevel: LogLevel.warning,
      );
      return const PeriodosActionResult.success(
        'Periodo creado correctamente.',
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo crear el periodo de costo: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return PeriodosActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al crear el periodo de costo.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const PeriodosActionResult.failure(
        'No pudimos crear el periodo. Intenta nuevamente.',
      );
    }
  }

  Future<PeriodosActionResult> closeSelectedPeriodo({
    String? observacion,
  }) async {
    final periodoId = state.selectedPeriodoId;
    if (periodoId == null) {
      _talker.cubit(
        'Se intento cerrar un periodo sin seleccion previa.',
        logLevel: LogLevel.warning,
      );
      return const PeriodosActionResult.failure(
        'Selecciona un periodo para continuar.',
      );
    }

    _talker.cubit(
      'Cerrando periodo de costo $periodoId con observacion=${_describeText(observacion)}.',
      logLevel: LogLevel.warning,
    );
    emit(state.copyWith(isSubmittingAction: true));

    try {
      await _repository.closePeriodo(id: periodoId, observacion: observacion);

      await _reloadPeriodos(
        anioFilter: state.anioFilter,
        mesFilter: state.mesFilter,
        estadoFilter: state.estadoFilter,
        preferredPeriodoId: periodoId,
      );

      emit(state.copyWith(isSubmittingAction: false));
      _talker.cubit(
        'Periodo de costo $periodoId cerrado correctamente.',
        logLevel: LogLevel.warning,
      );
      return const PeriodosActionResult.success(
        'Periodo cerrado correctamente.',
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cerrar el periodo de costo $periodoId: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return PeriodosActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al cerrar el periodo de costo $periodoId.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const PeriodosActionResult.failure(
        'No pudimos cerrar el periodo. Intenta nuevamente.',
      );
    }
  }

  Future<void> _loadPeriodoDetail(int periodoId) async {
    _talker.cubit('Cargando detalle del periodo de costo $periodoId.');
    emit(
      state.copyWith(
        isDetailLoading: true,
        clearSelectedPeriodo: true,
        clearDetailError: true,
      ),
    );

    try {
      final periodo = await _repository.getPeriodo(periodoId);
      _talker.cubit(
        'Detalle del periodo de costo $periodoId cargado correctamente.',
        logLevel: LogLevel.debug,
      );
      emit(
        state.copyWith(
          isDetailLoading: false,
          selectedPeriodo: periodo,
          clearDetailError: true,
        ),
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar el detalle del periodo de costo $periodoId: ${exception.message}',
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
        'Fallo inesperado al cargar el detalle del periodo de costo $periodoId.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          isDetailLoading: false,
          detailErrorMessage: 'No pudimos cargar el detalle del periodo.',
        ),
      );
    }
  }

  Future<void> _reloadPeriodos({
    required int? anioFilter,
    required int? mesFilter,
    required String? estadoFilter,
    int? preferredPeriodoId,
  }) async {
    _talker.cubit(
      'Recargando periodos de costo con anio=$anioFilter, mes=$mesFilter, estado=${_describeState(estadoFilter)}, preferido=${preferredPeriodoId ?? state.selectedPeriodoId ?? 'ninguno'}.',
      logLevel: LogLevel.debug,
    );
    final items = await _repository.listPeriodos(
      anio: anioFilter,
      mes: mesFilter,
      estado: estadoFilter,
    );

    final currentSelectedId = preferredPeriodoId ?? state.selectedPeriodoId;
    final selectedPeriodoId = items.any((item) => item.id == currentSelectedId)
        ? currentSelectedId
        : items.isNotEmpty
        ? items.first.id
        : null;
    _talker.cubit(
      'Recarga de periodos de costo completada con ${items.length} resultados. Seleccion actual=${selectedPeriodoId ?? 'ninguna'}.',
      logLevel: LogLevel.debug,
    );

    emit(
      state.copyWith(
        status: PeriodosStatus.success,
        items: items,
        selectedPeriodoId: selectedPeriodoId,
        anioFilter: anioFilter,
        mesFilter: mesFilter,
        estadoFilter: estadoFilter,
        clearError: true,
      ),
    );

    if (selectedPeriodoId == null) {
      emit(
        state.copyWith(
          isDetailLoading: false,
          clearSelectedPeriodo: true,
          clearDetailError: true,
        ),
      );
      _talker.cubit(
        'No hay periodo de costo seleccionado despues de la recarga.',
        logLevel: LogLevel.debug,
      );
      return;
    }

    await _loadPeriodoDetail(selectedPeriodoId);
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
}
