import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/finance/costos/domain/repositories/costos_finanzas_repository.dart';
import 'package:erp_curtiembre_fronted/features/finance/costos/presentation/cubit/costos_proceso_state.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/orden_proceso_record.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/repositories/ordenes_produccion_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';

class CostosProcesoActionResult {
  const CostosProcesoActionResult._({
    required this.success,
    required this.message,
  });

  const CostosProcesoActionResult.success(String message)
    : this._(success: true, message: message);

  const CostosProcesoActionResult.failure(String message)
    : this._(success: false, message: message);

  final bool success;
  final String message;
}

class CostosProcesoCubit extends Cubit<CostosProcesoState> {
  CostosProcesoCubit(this._repository, this._ordenesRepository, this._talker)
    : super(const CostosProcesoState.loading());

  final CostosFinanzasRepository _repository;
  final OrdenesProduccionRepository _ordenesRepository;
  final Talker _talker;

  Future<void> initialize() async {
    _talker.cubit('Inicializando modulo de costos por proceso.');
    emit(const CostosProcesoState.loading());

    try {
      final ordenes = await _ordenesRepository.listOrdenes();
      final processOptionsByOrderId = <int, List<OrdenProcesoRecord>>{};
      for (final orden in ordenes) {
        processOptionsByOrderId[orden.id] = await _ordenesRepository
            .listProcesos(orden.id);
      }
      _talker.cubit(
        'Base de costos por proceso preparada con ${ordenes.length} ordenes y ${processOptionsByOrderId.length} mapas de procesos.',
        logLevel: LogLevel.debug,
      );

      emit(
        state.copyWith(
          ordenOptions: ordenes,
          processOptionsByOrderId: processOptionsByOrderId,
        ),
      );
      await load();
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo preparar la base de costos por proceso: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(
        state.copyWith(
          status: CostosProcesoStatus.error,
          errorMessage: exception.message,
        ),
      );
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al preparar la base de costos por proceso.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          status: CostosProcesoStatus.error,
          errorMessage: 'No pudimos preparar la base de costos por proceso.',
        ),
      );
    }
  }

  List<OrdenProcesoRecord> processOptionsForOrder(int? orderId) {
    if (orderId == null) return const [];
    return state.processOptionsByOrderId[orderId] ?? const [];
  }

  Future<void> load({
    int? ordenProduccionIdFilter,
    int? ordenProcesoIdFilter,
  }) async {
    final nextOrderId =
        ordenProduccionIdFilter ?? state.ordenProduccionIdFilter;
    final nextProcessId = ordenProcesoIdFilter ?? state.ordenProcesoIdFilter;
    final normalizedProcessId = nextOrderId == null ? null : nextProcessId;
    _talker.cubit(
      'Cargando costos por proceso con ordenProduccionId=$nextOrderId y ordenProcesoId=$normalizedProcessId.',
    );

    emit(
      state.copyWith(
        status: CostosProcesoStatus.loading,
        ordenProduccionIdFilter: nextOrderId,
        ordenProcesoIdFilter: normalizedProcessId,
        clearError: true,
      ),
    );

    try {
      await _reloadCostosProceso(
        ordenProduccionIdFilter: nextOrderId,
        ordenProcesoIdFilter: normalizedProcessId,
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar la lista de costos por proceso: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(
        state.copyWith(
          status: CostosProcesoStatus.error,
          errorMessage: exception.message,
        ),
      );
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al cargar la lista de costos por proceso.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          status: CostosProcesoStatus.error,
          errorMessage:
              'No pudimos cargar los costos por proceso. Intenta nuevamente.',
        ),
      );
    }
  }

  Future<void> selectCostoProceso(int costoProcesoId) async {
    if (state.selectedCostoProcesoId == costoProcesoId &&
        state.selectedCostoProceso?.id == costoProcesoId) {
      _talker.cubit(
        'Se ignoro la seleccion del costo por proceso $costoProcesoId porque ya estaba cargado.',
        logLevel: LogLevel.debug,
      );
      return;
    }

    _talker.cubit(
      'Seleccionando costo por proceso $costoProcesoId para ver detalle.',
    );
    emit(
      state.copyWith(
        selectedCostoProcesoId: costoProcesoId,
        clearDetailError: true,
      ),
    );
    await _loadCostoProcesoDetail(costoProcesoId);
  }

  Future<void> retryDetail() async {
    final costoProcesoId = state.selectedCostoProcesoId;
    if (costoProcesoId == null) {
      _talker.cubit(
        'Se intento reintentar detalle sin un costo por proceso seleccionado.',
        logLevel: LogLevel.warning,
      );
      return;
    }
    _talker.cubit(
      'Reintentando carga de detalle para el costo por proceso $costoProcesoId.',
    );
    await _loadCostoProcesoDetail(costoProcesoId);
  }

  Future<CostosProcesoActionResult> calculateCurrent() async {
    final ordenId =
        state.ordenProduccionIdFilter ??
        state.selectedCostoProceso?.ordenProduccionId;
    final procesoId =
        state.ordenProcesoIdFilter ??
        state.selectedCostoProceso?.ordenProcesoId;

    if (ordenId == null || procesoId == null) {
      _talker.cubit(
        'Se intento calcular costo por proceso sin orden o proceso seleccionado.',
        logLevel: LogLevel.warning,
      );
      return const CostosProcesoActionResult.failure(
        'Selecciona una orden y un proceso antes de calcular el costo.',
      );
    }

    _talker.cubit(
      'Calculando costo por proceso para ordenProduccionId=$ordenId y ordenProcesoId=$procesoId.',
      logLevel: LogLevel.warning,
    );
    emit(state.copyWith(isSubmittingAction: true));

    try {
      final item = await _repository.calculateCostoProceso(
        ordenProduccionId: ordenId,
        ordenProcesoId: procesoId,
      );

      await _reloadCostosProceso(
        ordenProduccionIdFilter: ordenId,
        ordenProcesoIdFilter: procesoId,
        preferredCostoProcesoId: item.id,
      );

      emit(state.copyWith(isSubmittingAction: false));
      _talker.cubit(
        'Costo por proceso calculado correctamente con id=${item.id}.',
        logLevel: LogLevel.warning,
      );
      return const CostosProcesoActionResult.success(
        'Costo por proceso calculado correctamente.',
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo calcular el costo por proceso: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return CostosProcesoActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al calcular el costo por proceso.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const CostosProcesoActionResult.failure(
        'No pudimos calcular el costo por proceso. Intenta nuevamente.',
      );
    }
  }

  Future<void> _loadCostoProcesoDetail(int costoProcesoId) async {
    _talker.cubit('Cargando detalle del costo por proceso $costoProcesoId.');
    emit(
      state.copyWith(
        isDetailLoading: true,
        clearSelectedCostoProceso: true,
        clearDetailError: true,
      ),
    );

    try {
      final item = await _repository.getCostoProceso(costoProcesoId);
      _talker.cubit(
        'Detalle del costo por proceso $costoProcesoId cargado correctamente.',
        logLevel: LogLevel.debug,
      );
      emit(
        state.copyWith(
          isDetailLoading: false,
          selectedCostoProceso: item,
          clearDetailError: true,
        ),
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar el detalle del costo por proceso $costoProcesoId: ${exception.message}',
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
        'Fallo inesperado al cargar el detalle del costo por proceso $costoProcesoId.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          isDetailLoading: false,
          detailErrorMessage:
              'No pudimos cargar el detalle del costo por proceso.',
        ),
      );
    }
  }

  Future<void> _reloadCostosProceso({
    required int? ordenProduccionIdFilter,
    required int? ordenProcesoIdFilter,
    int? preferredCostoProcesoId,
  }) async {
    _talker.cubit(
      'Recargando costos por proceso con ordenProduccionId=$ordenProduccionIdFilter, ordenProcesoId=$ordenProcesoIdFilter, preferido=${preferredCostoProcesoId ?? state.selectedCostoProcesoId ?? 'ninguno'}.',
      logLevel: LogLevel.debug,
    );
    final items = await _repository.listCostosProceso(
      ordenProduccionId: ordenProduccionIdFilter,
      ordenProcesoId: ordenProcesoIdFilter,
    );

    final currentSelectedId =
        preferredCostoProcesoId ?? state.selectedCostoProcesoId;
    final selectedId = items.any((item) => item.id == currentSelectedId)
        ? currentSelectedId
        : items.isNotEmpty
        ? items.first.id
        : null;
    _talker.cubit(
      'Recarga de costos por proceso completada con ${items.length} resultados. Seleccion actual=${selectedId ?? 'ninguna'}.',
      logLevel: LogLevel.debug,
    );

    emit(
      state.copyWith(
        status: CostosProcesoStatus.success,
        items: items,
        selectedCostoProcesoId: selectedId,
        ordenProduccionIdFilter: ordenProduccionIdFilter,
        ordenProcesoIdFilter: ordenProcesoIdFilter,
        clearError: true,
      ),
    );

    if (selectedId == null) {
      emit(
        state.copyWith(
          isDetailLoading: false,
          clearSelectedCostoProceso: true,
          clearDetailError: true,
        ),
      );
      _talker.cubit(
        'No hay costo por proceso seleccionado despues de la recarga.',
        logLevel: LogLevel.debug,
      );
      return;
    }

    await _loadCostoProcesoDetail(selectedId);
  }
}
