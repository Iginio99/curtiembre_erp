import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/finance/activos/domain/repositories/activos_repository.dart';
import 'package:erp_curtiembre_fronted/features/finance/depreciaciones/domain/repositories/depreciaciones_repository.dart';
import 'package:erp_curtiembre_fronted/features/finance/depreciaciones/presentation/cubit/depreciaciones_state.dart';
import 'package:erp_curtiembre_fronted/features/finance/periodos/domain/repositories/periodos_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';

class DepreciacionesActionResult {
  const DepreciacionesActionResult._({
    required this.success,
    required this.message,
  });

  const DepreciacionesActionResult.success(String message)
    : this._(success: true, message: message);

  const DepreciacionesActionResult.failure(String message)
    : this._(success: false, message: message);

  final bool success;
  final String message;
}

class DepreciacionesCubit extends Cubit<DepreciacionesState> {
  DepreciacionesCubit(
    this._repository,
    this._periodosRepository,
    this._activosRepository,
    this._talker,
  ) : super(const DepreciacionesState.loading());

  final DepreciacionesRepository _repository;
  final PeriodosRepository _periodosRepository;
  final ActivosRepository _activosRepository;
  final Talker _talker;

  Future<void> initialize() async {
    _talker.cubit('Inicializando modulo de depreciaciones.');
    emit(const DepreciacionesState.loading());

    try {
      final periodosFuture = _periodosRepository.listPeriodos();
      final activosFuture = _activosRepository.listActivos();
      final periodos = await periodosFuture;
      final activos = await activosFuture;
      _talker.cubit(
        'Base de depreciaciones preparada con ${periodos.length} periodos y ${activos.length} activos.',
        logLevel: LogLevel.debug,
      );

      emit(state.copyWith(periodoOptions: periodos, activoOptions: activos));

      await load();
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo preparar la base de depreciaciones: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(
        state.copyWith(
          status: DepreciacionesStatus.error,
          errorMessage: exception.message,
        ),
      );
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al preparar la base de depreciaciones.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          status: DepreciacionesStatus.error,
          errorMessage: 'No pudimos preparar la base de depreciaciones.',
        ),
      );
    }
  }

  Future<void> load({
    int? periodoCostoIdFilter,
    int? activoDepreciableIdFilter,
  }) async {
    final nextPeriodoId = periodoCostoIdFilter ?? state.periodoCostoIdFilter;
    final nextActivoId =
        activoDepreciableIdFilter ?? state.activoDepreciableIdFilter;
    _talker.cubit(
      'Cargando depreciaciones con periodoCostoId=$nextPeriodoId y activoDepreciableId=$nextActivoId.',
    );

    emit(
      state.copyWith(
        status: DepreciacionesStatus.loading,
        periodoCostoIdFilter: nextPeriodoId,
        activoDepreciableIdFilter: nextActivoId,
        clearError: true,
      ),
    );

    try {
      await _reloadDepreciaciones(
        periodoCostoIdFilter: nextPeriodoId,
        activoDepreciableIdFilter: nextActivoId,
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar la lista de depreciaciones: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(
        state.copyWith(
          status: DepreciacionesStatus.error,
          errorMessage: exception.message,
        ),
      );
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al cargar la lista de depreciaciones.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          status: DepreciacionesStatus.error,
          errorMessage:
              'No pudimos cargar las depreciaciones. Intenta nuevamente.',
        ),
      );
    }
  }

  Future<void> selectDepreciacion(int depreciacionId) async {
    if (state.selectedDepreciacionId == depreciacionId &&
        state.selectedDepreciacion?.id == depreciacionId) {
      _talker.cubit(
        'Se ignoro la seleccion de la depreciacion $depreciacionId porque ya estaba cargada.',
        logLevel: LogLevel.debug,
      );
      return;
    }

    _talker.cubit(
      'Seleccionando depreciacion $depreciacionId para ver detalle.',
    );
    emit(
      state.copyWith(
        selectedDepreciacionId: depreciacionId,
        clearDetailError: true,
      ),
    );
    await _loadDepreciacionDetail(depreciacionId);
  }

  Future<void> retryDetail() async {
    final depreciacionId = state.selectedDepreciacionId;
    if (depreciacionId == null) {
      _talker.cubit(
        'Se intento reintentar detalle sin una depreciacion seleccionada.',
        logLevel: LogLevel.warning,
      );
      return;
    }
    _talker.cubit(
      'Reintentando carga de detalle para la depreciacion $depreciacionId.',
    );
    await _loadDepreciacionDetail(depreciacionId);
  }

  Future<DepreciacionesActionResult> calculateForPeriod(int periodoId) async {
    _talker.cubit(
      'Calculando depreciaciones para el periodo $periodoId.',
      logLevel: LogLevel.warning,
    );
    emit(state.copyWith(isSubmittingAction: true));

    try {
      await _repository.calculateForPeriod(periodoId);
      await _reloadDepreciaciones(
        periodoCostoIdFilter: state.periodoCostoIdFilter,
        activoDepreciableIdFilter: state.activoDepreciableIdFilter,
      );
      emit(state.copyWith(isSubmittingAction: false));
      _talker.cubit(
        'Depreciaciones calculadas correctamente para el periodo $periodoId.',
        logLevel: LogLevel.warning,
      );
      return const DepreciacionesActionResult.success(
        'Depreciacion calculada correctamente para el periodo seleccionado.',
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo calcular la depreciacion para el periodo $periodoId: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return DepreciacionesActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al calcular la depreciacion para el periodo $periodoId.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const DepreciacionesActionResult.failure(
        'No pudimos calcular la depreciacion. Intenta nuevamente.',
      );
    }
  }

  Future<void> _loadDepreciacionDetail(int depreciacionId) async {
    _talker.cubit('Cargando detalle de la depreciacion $depreciacionId.');
    emit(
      state.copyWith(
        isDetailLoading: true,
        clearSelectedDepreciacion: true,
        clearDetailError: true,
      ),
    );

    try {
      final item = await _repository.getDepreciacion(depreciacionId);
      _talker.cubit(
        'Detalle de la depreciacion $depreciacionId cargado correctamente.',
        logLevel: LogLevel.debug,
      );
      emit(
        state.copyWith(
          isDetailLoading: false,
          selectedDepreciacion: item,
          clearDetailError: true,
        ),
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar el detalle de la depreciacion $depreciacionId: ${exception.message}',
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
        'Fallo inesperado al cargar el detalle de la depreciacion $depreciacionId.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          isDetailLoading: false,
          detailErrorMessage: 'No pudimos cargar el detalle de depreciacion.',
        ),
      );
    }
  }

  Future<void> _reloadDepreciaciones({
    required int? periodoCostoIdFilter,
    required int? activoDepreciableIdFilter,
    int? preferredDepreciacionId,
  }) async {
    _talker.cubit(
      'Recargando depreciaciones con periodoCostoId=$periodoCostoIdFilter, activoDepreciableId=$activoDepreciableIdFilter, preferida=${preferredDepreciacionId ?? state.selectedDepreciacionId ?? 'ninguna'}.',
      logLevel: LogLevel.debug,
    );
    final items = await _repository.listDepreciaciones(
      periodoCostoId: periodoCostoIdFilter,
      activoDepreciableId: activoDepreciableIdFilter,
    );

    final currentSelectedId =
        preferredDepreciacionId ?? state.selectedDepreciacionId;
    final selectedId = items.any((item) => item.id == currentSelectedId)
        ? currentSelectedId
        : items.isNotEmpty
        ? items.first.id
        : null;
    _talker.cubit(
      'Recarga de depreciaciones completada con ${items.length} resultados. Seleccion actual=${selectedId ?? 'ninguna'}.',
      logLevel: LogLevel.debug,
    );

    emit(
      state.copyWith(
        status: DepreciacionesStatus.success,
        items: items,
        selectedDepreciacionId: selectedId,
        periodoCostoIdFilter: periodoCostoIdFilter,
        activoDepreciableIdFilter: activoDepreciableIdFilter,
        clearError: true,
      ),
    );

    if (selectedId == null) {
      emit(
        state.copyWith(
          isDetailLoading: false,
          clearSelectedDepreciacion: true,
          clearDetailError: true,
        ),
      );
      _talker.cubit(
        'No hay depreciacion seleccionada despues de la recarga.',
        logLevel: LogLevel.debug,
      );
      return;
    }

    await _loadDepreciacionDetail(selectedId);
  }
}
