import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/finance/costos/domain/repositories/costos_finanzas_repository.dart';
import 'package:erp_curtiembre_fronted/features/finance/costos/presentation/cubit/costos_orden_state.dart';
import 'package:erp_curtiembre_fronted/features/finance/periodos/domain/repositories/periodos_repository.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/repositories/ordenes_produccion_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';

class CostosOrdenActionResult {
  const CostosOrdenActionResult._({
    required this.success,
    required this.message,
  });

  const CostosOrdenActionResult.success(String message)
    : this._(success: true, message: message);

  const CostosOrdenActionResult.failure(String message)
    : this._(success: false, message: message);

  final bool success;
  final String message;
}

class CostosOrdenCubit extends Cubit<CostosOrdenState> {
  CostosOrdenCubit(
    this._repository,
    this._ordenesRepository,
    this._periodosRepository,
    this._talker,
  ) : super(const CostosOrdenState.loading());

  final CostosFinanzasRepository _repository;
  final OrdenesProduccionRepository _ordenesRepository;
  final PeriodosRepository _periodosRepository;
  final Talker _talker;

  static const List<String> availableStates = ['ESTIMADO', 'REAL', 'CERRADO'];

  Future<void> initialize() async {
    _talker.cubit('Inicializando modulo de costos por orden.');
    emit(const CostosOrdenState.loading());

    try {
      final ordenes = await _ordenesRepository.listOrdenes();
      final periodos = await _periodosRepository.listPeriodos();
      _talker.cubit(
        'Base de costos por orden preparada con ${ordenes.length} ordenes y ${periodos.length} periodos.',
        logLevel: LogLevel.debug,
      );
      emit(state.copyWith(ordenOptions: ordenes, periodoOptions: periodos));
      await load();
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo preparar la base de costos por orden: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(
        state.copyWith(
          status: CostosOrdenStatus.error,
          errorMessage: exception.message,
        ),
      );
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al preparar la base de costos por orden.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          status: CostosOrdenStatus.error,
          errorMessage: 'No pudimos preparar la base de costos por orden.',
        ),
      );
    }
  }

  Future<void> load({
    int? ordenProduccionIdFilter,
    int? periodoCostoIdFilter,
    String? estadoFilter,
  }) async {
    final nextOrderId =
        ordenProduccionIdFilter ?? state.ordenProduccionIdFilter;
    final nextPeriodId = periodoCostoIdFilter ?? state.periodoCostoIdFilter;
    final nextStatus = estadoFilter ?? state.estadoFilter;
    _talker.cubit(
      'Cargando costos por orden con ordenProduccionId=$nextOrderId, periodoCostoId=$nextPeriodId y estado=${_describeState(nextStatus)}.',
    );

    emit(
      state.copyWith(
        status: CostosOrdenStatus.loading,
        ordenProduccionIdFilter: nextOrderId,
        periodoCostoIdFilter: nextPeriodId,
        estadoFilter: nextStatus,
        clearError: true,
      ),
    );

    try {
      await _reloadCostosOrden(
        ordenProduccionIdFilter: nextOrderId,
        periodoCostoIdFilter: nextPeriodId,
        estadoFilter: nextStatus,
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar la lista de costos por orden: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(
        state.copyWith(
          status: CostosOrdenStatus.error,
          errorMessage: exception.message,
        ),
      );
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al cargar la lista de costos por orden.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          status: CostosOrdenStatus.error,
          errorMessage:
              'No pudimos cargar los costos por orden. Intenta nuevamente.',
        ),
      );
    }
  }

  Future<void> selectCostoOrden(int costoOrdenId) async {
    if (state.selectedCostoOrdenId == costoOrdenId &&
        state.selectedCostoOrden?.id == costoOrdenId) {
      _talker.cubit(
        'Se ignoro la seleccion del costo por orden $costoOrdenId porque ya estaba cargado.',
        logLevel: LogLevel.debug,
      );
      return;
    }

    _talker.cubit(
      'Seleccionando costo por orden $costoOrdenId para ver detalle.',
    );
    emit(
      state.copyWith(
        selectedCostoOrdenId: costoOrdenId,
        clearDetailError: true,
      ),
    );
    await _loadCostoOrdenDetail(costoOrdenId);
  }

  Future<void> retryDetail() async {
    final costoOrdenId = state.selectedCostoOrdenId;
    if (costoOrdenId == null) {
      _talker.cubit(
        'Se intento reintentar detalle sin un costo por orden seleccionado.',
        logLevel: LogLevel.warning,
      );
      return;
    }
    _talker.cubit(
      'Reintentando carga de detalle para el costo por orden $costoOrdenId.',
    );
    await _loadCostoOrdenDetail(costoOrdenId);
  }

  Future<CostosOrdenActionResult> calculateEstimatedCurrent() async {
    final ordenId =
        state.ordenProduccionIdFilter ??
        state.selectedCostoOrden?.ordenProduccionId;
    if (ordenId == null) {
      _talker.cubit(
        'Se intento calcular costo estimado sin una orden seleccionada.',
        logLevel: LogLevel.warning,
      );
      return const CostosOrdenActionResult.failure(
        'Selecciona una orden antes de calcular el costo estimado.',
      );
    }

    _talker.cubit(
      'Calculando costo estimado para la orden $ordenId.',
      logLevel: LogLevel.warning,
    );
    emit(state.copyWith(isSubmittingAction: true));
    try {
      final item = await _repository.calculateCostoOrdenEstimado(ordenId);
      await _reloadCostosOrden(
        ordenProduccionIdFilter: ordenId,
        periodoCostoIdFilter: state.periodoCostoIdFilter,
        estadoFilter: null,
        preferredCostoOrdenId: item.id,
      );
      emit(state.copyWith(isSubmittingAction: false));
      _talker.cubit(
        'Costo estimado calculado correctamente con id=${item.id}.',
        logLevel: LogLevel.warning,
      );
      return const CostosOrdenActionResult.success(
        'Costo estimado calculado correctamente.',
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo calcular el costo estimado: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return CostosOrdenActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al calcular el costo estimado.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const CostosOrdenActionResult.failure(
        'No pudimos calcular el costo estimado. Intenta nuevamente.',
      );
    }
  }

  Future<CostosOrdenActionResult> calculateRealCurrent() async {
    final ordenId =
        state.ordenProduccionIdFilter ??
        state.selectedCostoOrden?.ordenProduccionId;
    if (ordenId == null) {
      _talker.cubit(
        'Se intento calcular costo real sin una orden seleccionada.',
        logLevel: LogLevel.warning,
      );
      return const CostosOrdenActionResult.failure(
        'Selecciona una orden antes de calcular el costo real.',
      );
    }

    _talker.cubit(
      'Calculando costo real para la orden $ordenId.',
      logLevel: LogLevel.warning,
    );
    emit(state.copyWith(isSubmittingAction: true));
    try {
      final item = await _repository.calculateCostoOrdenReal(ordenId);
      await _reloadCostosOrden(
        ordenProduccionIdFilter: ordenId,
        periodoCostoIdFilter: state.periodoCostoIdFilter,
        estadoFilter: null,
        preferredCostoOrdenId: item.id,
      );
      emit(state.copyWith(isSubmittingAction: false));
      _talker.cubit(
        'Costo real calculado correctamente con id=${item.id}.',
        logLevel: LogLevel.warning,
      );
      return const CostosOrdenActionResult.success(
        'Costo real calculado correctamente.',
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo calcular el costo real: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return CostosOrdenActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al calcular el costo real.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const CostosOrdenActionResult.failure(
        'No pudimos calcular el costo real. Intenta nuevamente.',
      );
    }
  }

  Future<CostosOrdenActionResult> closeCurrent() async {
    final ordenId = state.selectedCostoOrden?.ordenProduccionId;
    if (ordenId == null) {
      _talker.cubit(
        'Se intento cerrar un costo por orden sin seleccion previa.',
        logLevel: LogLevel.warning,
      );
      return const CostosOrdenActionResult.failure(
        'Selecciona un costo de orden para cerrarlo.',
      );
    }

    _talker.cubit(
      'Cerrando costo por orden para la orden $ordenId.',
      logLevel: LogLevel.warning,
    );
    emit(state.copyWith(isSubmittingAction: true));
    try {
      final item = await _repository.closeCostoOrden(ordenId);
      await _reloadCostosOrden(
        ordenProduccionIdFilter: state.ordenProduccionIdFilter,
        periodoCostoIdFilter: state.periodoCostoIdFilter,
        estadoFilter: state.estadoFilter,
        preferredCostoOrdenId: item.id,
      );
      emit(state.copyWith(isSubmittingAction: false));
      _talker.cubit(
        'Costo por orden cerrado correctamente con id=${item.id}.',
        logLevel: LogLevel.warning,
      );
      return const CostosOrdenActionResult.success(
        'Costo de orden cerrado correctamente.',
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cerrar el costo por orden: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return CostosOrdenActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al cerrar el costo por orden.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const CostosOrdenActionResult.failure(
        'No pudimos cerrar el costo de orden. Intenta nuevamente.',
      );
    }
  }

  Future<void> _loadCostoOrdenDetail(int costoOrdenId) async {
    _talker.cubit('Cargando detalle del costo por orden $costoOrdenId.');
    emit(
      state.copyWith(
        isDetailLoading: true,
        clearSelectedCostoOrden: true,
        clearDetailError: true,
      ),
    );

    try {
      final item = await _repository.getCostoOrden(costoOrdenId);
      _talker.cubit(
        'Detalle del costo por orden $costoOrdenId cargado correctamente.',
        logLevel: LogLevel.debug,
      );
      emit(
        state.copyWith(
          isDetailLoading: false,
          selectedCostoOrden: item,
          clearDetailError: true,
        ),
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar el detalle del costo por orden $costoOrdenId: ${exception.message}',
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
        'Fallo inesperado al cargar el detalle del costo por orden $costoOrdenId.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          isDetailLoading: false,
          detailErrorMessage:
              'No pudimos cargar el detalle del costo de orden.',
        ),
      );
    }
  }

  Future<void> _reloadCostosOrden({
    required int? ordenProduccionIdFilter,
    required int? periodoCostoIdFilter,
    required String? estadoFilter,
    int? preferredCostoOrdenId,
  }) async {
    _talker.cubit(
      'Recargando costos por orden con ordenProduccionId=$ordenProduccionIdFilter, periodoCostoId=$periodoCostoIdFilter, estado=${_describeState(estadoFilter)}, preferido=${preferredCostoOrdenId ?? state.selectedCostoOrdenId ?? 'ninguno'}.',
      logLevel: LogLevel.debug,
    );
    final items = await _repository.listCostosOrden(
      ordenProduccionId: ordenProduccionIdFilter,
      periodoCostoId: periodoCostoIdFilter,
      estado: estadoFilter,
    );

    final currentSelectedId =
        preferredCostoOrdenId ?? state.selectedCostoOrdenId;
    final selectedId = items.any((item) => item.id == currentSelectedId)
        ? currentSelectedId
        : items.isNotEmpty
        ? items.first.id
        : null;
    _talker.cubit(
      'Recarga de costos por orden completada con ${items.length} resultados. Seleccion actual=${selectedId ?? 'ninguna'}.',
      logLevel: LogLevel.debug,
    );

    emit(
      state.copyWith(
        status: CostosOrdenStatus.success,
        items: items,
        selectedCostoOrdenId: selectedId,
        ordenProduccionIdFilter: ordenProduccionIdFilter,
        periodoCostoIdFilter: periodoCostoIdFilter,
        estadoFilter: estadoFilter,
        clearError: true,
      ),
    );

    if (selectedId == null) {
      emit(
        state.copyWith(
          isDetailLoading: false,
          clearSelectedCostoOrden: true,
          clearDetailError: true,
        ),
      );
      _talker.cubit(
        'No hay costo por orden seleccionado despues de la recarga.',
        logLevel: LogLevel.debug,
      );
      return;
    }

    await _loadCostoOrdenDetail(selectedId);
  }

  String _describeState(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return normalized;
  }
}
