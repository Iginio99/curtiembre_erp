import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/orden_proceso_record.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/repositories/ordenes_produccion_repository.dart';
import 'package:erp_curtiembre_fronted/features/production/reportes/domain/repositories/produccion_reportes_repository.dart';
import 'package:erp_curtiembre_fronted/features/production/reportes/presentation/cubit/produccion_reportes_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';

class ProduccionReportesCubit extends Cubit<ProduccionReportesState> {
  static const Object _sentinel = Object();

  ProduccionReportesCubit(
    this._reportesRepository,
    this._ordenesRepository,
    this._talker,
  ) : super(const ProduccionReportesState.loading());

  final ProduccionReportesRepository _reportesRepository;
  final OrdenesProduccionRepository _ordenesRepository;
  final Talker _talker;

  Future<void> initialize() async {
    _talker.cubit('Inicializando modulo de reportes de produccion.');
    emit(const ProduccionReportesState.loading());

    try {
      final clienteOptionsFuture = _ordenesRepository.listActiveClientes();
      final ordenOptionsFuture = _ordenesRepository.listOrdenes();
      final clienteOptions = await clienteOptionsFuture;
      final ordenOptions = await ordenOptionsFuture;
      _talker.cubit(
        'Base de reportes cargada con clientes=${clienteOptions.length} y ordenes=${ordenOptions.length}.',
        logLevel: LogLevel.debug,
      );

      emit(
        state.copyWith(
          status: ProduccionReportesStatus.success,
          clienteOptions: clienteOptions,
          ordenOptions: ordenOptions,
          clearBaseError: true,
        ),
      );

      await ensureTabLoaded(ProduccionReportesTab.ordenesActivas);
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo preparar la base de reportes de produccion: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(
        state.copyWith(
          status: ProduccionReportesStatus.error,
          baseErrorMessage: exception.message,
        ),
      );
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al preparar la base de reportes de produccion.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          status: ProduccionReportesStatus.error,
          baseErrorMessage:
              'No pudimos cargar la base de reportes de produccion.',
        ),
      );
    }
  }

  List<OrdenProcesoRecord> processOptionsForOrder(int? orderId) {
    if (orderId == null) {
      return const [];
    }
    return state.processOptionsByOrderId[orderId] ?? const [];
  }

  Future<void> ensureTabLoaded(ProduccionReportesTab tab) async {
    _talker.cubit(
      'Verificando si la pestaña ${_tabLabel(tab)} requiere carga inicial.',
      logLevel: LogLevel.debug,
    );
    switch (tab) {
      case ProduccionReportesTab.ordenesActivas:
        if (state.ordenesActivas.isEmpty && !state.loadingOrdenesActivas) {
          await loadOrdenesActivas();
        }
      case ProduccionReportesTab.ordenesCliente:
        if (state.ordenesCliente.isEmpty && !state.loadingOrdenesCliente) {
          await loadOrdenesCliente();
        }
      case ProduccionReportesTab.consumoProceso:
        if (state.consumoProceso.isEmpty && !state.loadingConsumoProceso) {
          await loadConsumoProceso();
        }
      case ProduccionReportesTab.merma:
        if (state.mermas.isEmpty && !state.loadingMerma) {
          await loadMerma();
        }
      case ProduccionReportesTab.tiemposProceso:
        if (state.tiemposProceso.isEmpty && !state.loadingTiemposProceso) {
          await loadTiemposProceso();
        }
      case ProduccionReportesTab.costosOrden:
        if (state.costosOrden.isEmpty && !state.loadingCostosOrden) {
          await loadCostosOrden();
        }
    }
  }

  Future<void> loadOrdenesActivas() async {
    _talker.cubit('Cargando reporte de ordenes activas.');
    emit(
      state.copyWith(
        loadingOrdenesActivas: true,
        clearOrdenesActivasError: true,
      ),
    );

    try {
      final items = await _reportesRepository.listOrdenesActivas();
      _talker.cubit(
        'Reporte de ordenes activas cargado con ${items.length} registros.',
      );
      emit(state.copyWith(loadingOrdenesActivas: false, ordenesActivas: items));
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar el reporte de ordenes activas: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(
        state.copyWith(
          loadingOrdenesActivas: false,
          ordenesActivasErrorMessage: exception.message,
        ),
      );
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al cargar el reporte de ordenes activas.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          loadingOrdenesActivas: false,
          ordenesActivasErrorMessage: 'No pudimos cargar las ordenes activas.',
        ),
      );
    }
  }

  Future<void> loadOrdenesCliente({
    Object? clienteId = _sentinel,
    Object? estado = _sentinel,
    Object? fechaDesde = _sentinel,
    Object? fechaHasta = _sentinel,
  }) async {
    final nextClienteId = identical(clienteId, _sentinel)
        ? state.ordenesClienteClienteId
        : clienteId as int?;
    final nextEstado = identical(estado, _sentinel)
        ? state.ordenesClienteEstado
        : estado as String?;
    final nextFechaDesde = identical(fechaDesde, _sentinel)
        ? state.ordenesClienteFechaDesde
        : fechaDesde as DateTime?;
    final nextFechaHasta = identical(fechaHasta, _sentinel)
        ? state.ordenesClienteFechaHasta
        : fechaHasta as DateTime?;
    _talker.cubit(
      'Cargando reporte de ordenes por cliente con filtros clienteId=$nextClienteId, estado=${_describeState(nextEstado)}, fechaDesde=${_describeDate(nextFechaDesde)}, fechaHasta=${_describeDate(nextFechaHasta)}.',
    );

    emit(
      state.copyWith(
        loadingOrdenesCliente: true,
        ordenesClienteClienteId: nextClienteId,
        ordenesClienteEstado: nextEstado,
        ordenesClienteFechaDesde: nextFechaDesde,
        ordenesClienteFechaHasta: nextFechaHasta,
        clearOrdenesClienteError: true,
      ),
    );

    try {
      final items = await _reportesRepository.listOrdenesPorCliente(
        clienteId: nextClienteId,
        estado: nextEstado,
        fechaDesde: nextFechaDesde,
        fechaHasta: nextFechaHasta,
      );
      _talker.cubit(
        'Reporte de ordenes por cliente cargado con ${items.length} registros.',
      );
      emit(state.copyWith(loadingOrdenesCliente: false, ordenesCliente: items));
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar el reporte por cliente: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(
        state.copyWith(
          loadingOrdenesCliente: false,
          ordenesClienteErrorMessage: exception.message,
        ),
      );
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al cargar el reporte por cliente.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          loadingOrdenesCliente: false,
          ordenesClienteErrorMessage:
              'No pudimos cargar el reporte por cliente.',
        ),
      );
    }
  }

  Future<void> loadConsumoProceso({
    Object? ordenProduccionId = _sentinel,
    Object? ordenProcesoId = _sentinel,
  }) async {
    final nextOrderId = identical(ordenProduccionId, _sentinel)
        ? state.consumoOrdenProduccionId
        : ordenProduccionId as int?;
    final nextProcessId = identical(ordenProcesoId, _sentinel)
        ? state.consumoOrdenProcesoId
        : ordenProcesoId as int?;
    final normalizedProcessId = nextOrderId == null ? null : nextProcessId;
    _talker.cubit(
      'Cargando reporte de consumo por proceso con filtros ordenProduccionId=$nextOrderId, ordenProcesoId=$normalizedProcessId.',
    );

    emit(
      state.copyWith(
        loadingConsumoProceso: true,
        consumoOrdenProduccionId: nextOrderId,
        consumoOrdenProcesoId: normalizedProcessId,
        clearConsumoProcesoError: true,
      ),
    );

    try {
      await _ensureProcessOptionsForOrder(nextOrderId);
      final items = await _reportesRepository.listConsumoPorProceso(
        ordenProduccionId: nextOrderId,
        ordenProcesoId: normalizedProcessId,
      );
      _talker.cubit(
        'Reporte de consumo por proceso cargado con ${items.length} registros.',
      );
      emit(state.copyWith(loadingConsumoProceso: false, consumoProceso: items));
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar el reporte de consumo por proceso: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(
        state.copyWith(
          loadingConsumoProceso: false,
          consumoProcesoErrorMessage: exception.message,
        ),
      );
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al cargar el reporte de consumo por proceso.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          loadingConsumoProceso: false,
          consumoProcesoErrorMessage:
              'No pudimos cargar el consumo por proceso.',
        ),
      );
    }
  }

  Future<void> loadMerma({
    Object? ordenProduccionId = _sentinel,
    Object? ordenProcesoId = _sentinel,
    Object? fechaDesde = _sentinel,
    Object? fechaHasta = _sentinel,
  }) async {
    final nextOrderId = identical(ordenProduccionId, _sentinel)
        ? state.mermaOrdenProduccionId
        : ordenProduccionId as int?;
    final nextProcessId = identical(ordenProcesoId, _sentinel)
        ? state.mermaOrdenProcesoId
        : ordenProcesoId as int?;
    final normalizedProcessId = nextOrderId == null ? null : nextProcessId;
    final nextFechaDesde = identical(fechaDesde, _sentinel)
        ? state.mermaFechaDesde
        : fechaDesde as DateTime?;
    final nextFechaHasta = identical(fechaHasta, _sentinel)
        ? state.mermaFechaHasta
        : fechaHasta as DateTime?;
    _talker.cubit(
      'Cargando reporte de merma con filtros ordenProduccionId=$nextOrderId, ordenProcesoId=$normalizedProcessId, fechaDesde=${_describeDate(nextFechaDesde)}, fechaHasta=${_describeDate(nextFechaHasta)}.',
    );

    emit(
      state.copyWith(
        loadingMerma: true,
        mermaOrdenProduccionId: nextOrderId,
        mermaOrdenProcesoId: normalizedProcessId,
        mermaFechaDesde: nextFechaDesde,
        mermaFechaHasta: nextFechaHasta,
        clearMermaError: true,
      ),
    );

    try {
      await _ensureProcessOptionsForOrder(nextOrderId);
      final items = await _reportesRepository.listMerma(
        ordenProduccionId: nextOrderId,
        ordenProcesoId: normalizedProcessId,
        fechaDesde: nextFechaDesde,
        fechaHasta: nextFechaHasta,
      );
      _talker.cubit('Reporte de merma cargado con ${items.length} registros.');
      emit(state.copyWith(loadingMerma: false, mermas: items));
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar el reporte de merma: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(
        state.copyWith(
          loadingMerma: false,
          mermaErrorMessage: exception.message,
        ),
      );
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al cargar el reporte de merma.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          loadingMerma: false,
          mermaErrorMessage: 'No pudimos cargar el reporte de merma.',
        ),
      );
    }
  }

  Future<void> loadTiemposProceso({
    Object? ordenProduccionId = _sentinel,
    Object? ordenProcesoId = _sentinel,
    Object? estado = _sentinel,
  }) async {
    final nextOrderId = identical(ordenProduccionId, _sentinel)
        ? state.tiemposOrdenProduccionId
        : ordenProduccionId as int?;
    final nextProcessId = identical(ordenProcesoId, _sentinel)
        ? state.tiemposOrdenProcesoId
        : ordenProcesoId as int?;
    final normalizedProcessId = nextOrderId == null ? null : nextProcessId;
    final nextEstado = identical(estado, _sentinel)
        ? state.tiemposEstado
        : estado as String?;
    _talker.cubit(
      'Cargando reporte de tiempos de proceso con filtros ordenProduccionId=$nextOrderId, ordenProcesoId=$normalizedProcessId, estado=${_describeState(nextEstado)}.',
    );

    emit(
      state.copyWith(
        loadingTiemposProceso: true,
        tiemposOrdenProduccionId: nextOrderId,
        tiemposOrdenProcesoId: normalizedProcessId,
        tiemposEstado: nextEstado,
        clearTiemposProcesoError: true,
      ),
    );

    try {
      await _ensureProcessOptionsForOrder(nextOrderId);
      final items = await _reportesRepository.listTiemposProceso(
        ordenProduccionId: nextOrderId,
        ordenProcesoId: normalizedProcessId,
        estado: nextEstado,
      );
      _talker.cubit(
        'Reporte de tiempos de proceso cargado con ${items.length} registros.',
      );
      emit(state.copyWith(loadingTiemposProceso: false, tiemposProceso: items));
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar el reporte de tiempos de proceso: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(
        state.copyWith(
          loadingTiemposProceso: false,
          tiemposProcesoErrorMessage: exception.message,
        ),
      );
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al cargar el reporte de tiempos de proceso.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          loadingTiemposProceso: false,
          tiemposProcesoErrorMessage:
              'No pudimos cargar los tiempos de proceso.',
        ),
      );
    }
  }

  Future<void> _ensureProcessOptionsForOrder(int? orderId) async {
    if (orderId == null || state.processOptionsByOrderId.containsKey(orderId)) {
      if (orderId != null) {
        _talker.cubit(
          'Los procesos de la orden $orderId ya estaban disponibles en cache.',
          logLevel: LogLevel.debug,
        );
      }
      return;
    }

    _talker.cubit(
      'Cargando procesos auxiliares para la orden $orderId.',
      logLevel: LogLevel.debug,
    );
    final processes = await _ordenesRepository.listProcesos(orderId);
    final nextMap = Map<int, List<OrdenProcesoRecord>>.from(
      state.processOptionsByOrderId,
    );
    nextMap[orderId] = processes;
    _talker.cubit(
      'Se cargaron ${processes.length} procesos auxiliares para la orden $orderId.',
      logLevel: LogLevel.debug,
    );
    emit(state.copyWith(processOptionsByOrderId: nextMap));
  }

  Future<void> loadCostosOrden({Object? ordenProduccionId = _sentinel}) async {
    final nextOrderId = identical(ordenProduccionId, _sentinel)
        ? state.costosOrdenProduccionId
        : ordenProduccionId as int?;
    emit(
      state.copyWith(
        loadingCostosOrden: true,
        costosOrdenProduccionId: nextOrderId,
        clearCostosOrdenError: true,
      ),
    );
    try {
      final costosOrdenFuture = _reportesRepository.listCostosPorOrden(
        ordenProduccionId: nextOrderId,
      );
      final costosProcesoFuture = _reportesRepository.listCostosPorProceso(
        ordenProduccionId: nextOrderId,
      );
      final costosOrden = await costosOrdenFuture;
      final costosProceso = await costosProcesoFuture;
      emit(
        state.copyWith(
          loadingCostosOrden: false,
          costosOrden: costosOrden,
          costosProceso: costosProceso,
        ),
      );
    } on ApiException catch (exception) {
      emit(
        state.copyWith(
          loadingCostosOrden: false,
          costosOrdenErrorMessage: exception.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          loadingCostosOrden: false,
          costosOrdenErrorMessage: 'No pudimos cargar los costos por orden.',
        ),
      );
    }
  }

  String _tabLabel(ProduccionReportesTab tab) {
    return switch (tab) {
      ProduccionReportesTab.ordenesActivas => 'ordenes-activas',
      ProduccionReportesTab.ordenesCliente => 'ordenes-cliente',
      ProduccionReportesTab.consumoProceso => 'consumo-proceso',
      ProduccionReportesTab.merma => 'merma',
      ProduccionReportesTab.tiemposProceso => 'tiempos-proceso',
      ProduccionReportesTab.costosOrden => 'costos-orden',
    };
  }

  String _describeState(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return normalized;
  }

  String _describeDate(DateTime? value) {
    if (value == null) {
      return 'sin-fecha';
    }

    return value.toIso8601String();
  }
}
