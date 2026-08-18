import 'package:equatable/equatable.dart';
import 'package:erp_curtiembre_fronted/features/production/clientes/domain/entities/cliente_option.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/orden_proceso_record.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/orden_produccion_record.dart';
import 'package:erp_curtiembre_fronted/features/production/reportes/domain/entities/consumo_proceso_reporte_item.dart';
import 'package:erp_curtiembre_fronted/features/production/reportes/domain/entities/costo_orden_reporte_item.dart';
import 'package:erp_curtiembre_fronted/features/production/reportes/domain/entities/costo_proceso_reporte_item.dart';
import 'package:erp_curtiembre_fronted/features/production/reportes/domain/entities/merma_reporte_item.dart';
import 'package:erp_curtiembre_fronted/features/production/reportes/domain/entities/orden_activa_reporte_item.dart';
import 'package:erp_curtiembre_fronted/features/production/reportes/domain/entities/orden_cliente_reporte_item.dart';
import 'package:erp_curtiembre_fronted/features/production/reportes/domain/entities/tiempo_proceso_reporte_item.dart';

enum ProduccionReportesStatus { loading, success, error }

enum ProduccionReportesTab {
  ordenesActivas,
  ordenesCliente,
  consumoProceso,
  merma,
  tiemposProceso,
  costosOrden,
}

class ProduccionReportesState extends Equatable {
  static const Object _sentinel = Object();

  const ProduccionReportesState({
    required this.status,
    this.clienteOptions = const [],
    this.ordenOptions = const [],
    this.processOptionsByOrderId = const {},
    this.ordenesActivas = const [],
    this.ordenesCliente = const [],
    this.consumoProceso = const [],
    this.mermas = const [],
    this.tiemposProceso = const [],
    this.costosOrden = const [],
    this.costosProceso = const [],
    this.loadingOrdenesActivas = false,
    this.loadingOrdenesCliente = false,
    this.loadingConsumoProceso = false,
    this.loadingMerma = false,
    this.loadingTiemposProceso = false,
    this.loadingCostosOrden = false,
    this.baseErrorMessage,
    this.ordenesActivasErrorMessage,
    this.ordenesClienteErrorMessage,
    this.consumoProcesoErrorMessage,
    this.mermaErrorMessage,
    this.tiemposProcesoErrorMessage,
    this.costosOrdenErrorMessage,
    this.ordenesClienteClienteId,
    this.ordenesClienteEstado,
    this.ordenesClienteFechaDesde,
    this.ordenesClienteFechaHasta,
    this.consumoOrdenProduccionId,
    this.consumoOrdenProcesoId,
    this.mermaOrdenProduccionId,
    this.mermaOrdenProcesoId,
    this.mermaFechaDesde,
    this.mermaFechaHasta,
    this.tiemposOrdenProduccionId,
    this.tiemposOrdenProcesoId,
    this.tiemposEstado,
    this.costosOrdenProduccionId,
  });

  const ProduccionReportesState.loading()
    : this(status: ProduccionReportesStatus.loading);

  final ProduccionReportesStatus status;
  final List<ClienteOption> clienteOptions;
  final List<OrdenProduccionRecord> ordenOptions;
  final Map<int, List<OrdenProcesoRecord>> processOptionsByOrderId;
  final List<OrdenActivaReporteItem> ordenesActivas;
  final List<OrdenClienteReporteItem> ordenesCliente;
  final List<ConsumoProcesoReporteItem> consumoProceso;
  final List<MermaReporteItem> mermas;
  final List<TiempoProcesoReporteItem> tiemposProceso;
  final List<CostoOrdenReporteItem> costosOrden;
  final List<CostoProcesoReporteItem> costosProceso;
  final bool loadingOrdenesActivas;
  final bool loadingOrdenesCliente;
  final bool loadingConsumoProceso;
  final bool loadingMerma;
  final bool loadingTiemposProceso;
  final bool loadingCostosOrden;
  final String? baseErrorMessage;
  final String? ordenesActivasErrorMessage;
  final String? ordenesClienteErrorMessage;
  final String? consumoProcesoErrorMessage;
  final String? mermaErrorMessage;
  final String? tiemposProcesoErrorMessage;
  final String? costosOrdenErrorMessage;
  final int? ordenesClienteClienteId;
  final String? ordenesClienteEstado;
  final DateTime? ordenesClienteFechaDesde;
  final DateTime? ordenesClienteFechaHasta;
  final int? consumoOrdenProduccionId;
  final int? consumoOrdenProcesoId;
  final int? mermaOrdenProduccionId;
  final int? mermaOrdenProcesoId;
  final DateTime? mermaFechaDesde;
  final DateTime? mermaFechaHasta;
  final int? tiemposOrdenProduccionId;
  final int? tiemposOrdenProcesoId;
  final String? tiemposEstado;
  final int? costosOrdenProduccionId;

  ProduccionReportesState copyWith({
    ProduccionReportesStatus? status,
    List<ClienteOption>? clienteOptions,
    List<OrdenProduccionRecord>? ordenOptions,
    Map<int, List<OrdenProcesoRecord>>? processOptionsByOrderId,
    List<OrdenActivaReporteItem>? ordenesActivas,
    List<OrdenClienteReporteItem>? ordenesCliente,
    List<ConsumoProcesoReporteItem>? consumoProceso,
    List<MermaReporteItem>? mermas,
    List<TiempoProcesoReporteItem>? tiemposProceso,
    List<CostoOrdenReporteItem>? costosOrden,
    List<CostoProcesoReporteItem>? costosProceso,
    bool? loadingOrdenesActivas,
    bool? loadingOrdenesCliente,
    bool? loadingConsumoProceso,
    bool? loadingMerma,
    bool? loadingTiemposProceso,
    bool? loadingCostosOrden,
    String? baseErrorMessage,
    String? ordenesActivasErrorMessage,
    String? ordenesClienteErrorMessage,
    String? consumoProcesoErrorMessage,
    String? mermaErrorMessage,
    String? tiemposProcesoErrorMessage,
    String? costosOrdenErrorMessage,
    Object? ordenesClienteClienteId = _sentinel,
    Object? ordenesClienteEstado = _sentinel,
    Object? ordenesClienteFechaDesde = _sentinel,
    Object? ordenesClienteFechaHasta = _sentinel,
    Object? consumoOrdenProduccionId = _sentinel,
    Object? consumoOrdenProcesoId = _sentinel,
    Object? mermaOrdenProduccionId = _sentinel,
    Object? mermaOrdenProcesoId = _sentinel,
    Object? mermaFechaDesde = _sentinel,
    Object? mermaFechaHasta = _sentinel,
    Object? tiemposOrdenProduccionId = _sentinel,
    Object? tiemposOrdenProcesoId = _sentinel,
    Object? tiemposEstado = _sentinel,
    Object? costosOrdenProduccionId = _sentinel,
    bool clearBaseError = false,
    bool clearOrdenesActivasError = false,
    bool clearOrdenesClienteError = false,
    bool clearConsumoProcesoError = false,
    bool clearMermaError = false,
    bool clearTiemposProcesoError = false,
    bool clearCostosOrdenError = false,
  }) {
    return ProduccionReportesState(
      status: status ?? this.status,
      clienteOptions: clienteOptions ?? this.clienteOptions,
      ordenOptions: ordenOptions ?? this.ordenOptions,
      processOptionsByOrderId:
          processOptionsByOrderId ?? this.processOptionsByOrderId,
      ordenesActivas: ordenesActivas ?? this.ordenesActivas,
      ordenesCliente: ordenesCliente ?? this.ordenesCliente,
      consumoProceso: consumoProceso ?? this.consumoProceso,
      mermas: mermas ?? this.mermas,
      tiemposProceso: tiemposProceso ?? this.tiemposProceso,
      costosOrden: costosOrden ?? this.costosOrden,
      costosProceso: costosProceso ?? this.costosProceso,
      loadingOrdenesActivas:
          loadingOrdenesActivas ?? this.loadingOrdenesActivas,
      loadingOrdenesCliente:
          loadingOrdenesCliente ?? this.loadingOrdenesCliente,
      loadingConsumoProceso:
          loadingConsumoProceso ?? this.loadingConsumoProceso,
      loadingMerma: loadingMerma ?? this.loadingMerma,
      loadingTiemposProceso:
          loadingTiemposProceso ?? this.loadingTiemposProceso,
      loadingCostosOrden: loadingCostosOrden ?? this.loadingCostosOrden,
      baseErrorMessage: clearBaseError
          ? null
          : baseErrorMessage ?? this.baseErrorMessage,
      ordenesActivasErrorMessage: clearOrdenesActivasError
          ? null
          : ordenesActivasErrorMessage ?? this.ordenesActivasErrorMessage,
      ordenesClienteErrorMessage: clearOrdenesClienteError
          ? null
          : ordenesClienteErrorMessage ?? this.ordenesClienteErrorMessage,
      consumoProcesoErrorMessage: clearConsumoProcesoError
          ? null
          : consumoProcesoErrorMessage ?? this.consumoProcesoErrorMessage,
      mermaErrorMessage: clearMermaError
          ? null
          : mermaErrorMessage ?? this.mermaErrorMessage,
      tiemposProcesoErrorMessage: clearTiemposProcesoError
          ? null
          : tiemposProcesoErrorMessage ?? this.tiemposProcesoErrorMessage,
      costosOrdenErrorMessage: clearCostosOrdenError
          ? null
          : costosOrdenErrorMessage ?? this.costosOrdenErrorMessage,
      ordenesClienteClienteId: identical(ordenesClienteClienteId, _sentinel)
          ? this.ordenesClienteClienteId
          : ordenesClienteClienteId as int?,
      ordenesClienteEstado: identical(ordenesClienteEstado, _sentinel)
          ? this.ordenesClienteEstado
          : ordenesClienteEstado as String?,
      ordenesClienteFechaDesde: identical(ordenesClienteFechaDesde, _sentinel)
          ? this.ordenesClienteFechaDesde
          : ordenesClienteFechaDesde as DateTime?,
      ordenesClienteFechaHasta: identical(ordenesClienteFechaHasta, _sentinel)
          ? this.ordenesClienteFechaHasta
          : ordenesClienteFechaHasta as DateTime?,
      consumoOrdenProduccionId: identical(consumoOrdenProduccionId, _sentinel)
          ? this.consumoOrdenProduccionId
          : consumoOrdenProduccionId as int?,
      consumoOrdenProcesoId: identical(consumoOrdenProcesoId, _sentinel)
          ? this.consumoOrdenProcesoId
          : consumoOrdenProcesoId as int?,
      mermaOrdenProduccionId: identical(mermaOrdenProduccionId, _sentinel)
          ? this.mermaOrdenProduccionId
          : mermaOrdenProduccionId as int?,
      mermaOrdenProcesoId: identical(mermaOrdenProcesoId, _sentinel)
          ? this.mermaOrdenProcesoId
          : mermaOrdenProcesoId as int?,
      mermaFechaDesde: identical(mermaFechaDesde, _sentinel)
          ? this.mermaFechaDesde
          : mermaFechaDesde as DateTime?,
      mermaFechaHasta: identical(mermaFechaHasta, _sentinel)
          ? this.mermaFechaHasta
          : mermaFechaHasta as DateTime?,
      tiemposOrdenProduccionId: identical(tiemposOrdenProduccionId, _sentinel)
          ? this.tiemposOrdenProduccionId
          : tiemposOrdenProduccionId as int?,
      tiemposOrdenProcesoId: identical(tiemposOrdenProcesoId, _sentinel)
          ? this.tiemposOrdenProcesoId
          : tiemposOrdenProcesoId as int?,
      tiemposEstado: identical(tiemposEstado, _sentinel)
          ? this.tiemposEstado
          : tiemposEstado as String?,
      costosOrdenProduccionId: identical(costosOrdenProduccionId, _sentinel)
          ? this.costosOrdenProduccionId
          : costosOrdenProduccionId as int?,
    );
  }

  @override
  List<Object?> get props => [
    status,
    clienteOptions,
    ordenOptions,
    processOptionsByOrderId,
    ordenesActivas,
    ordenesCliente,
    consumoProceso,
    mermas,
    tiemposProceso,
    costosOrden,
    costosProceso,
    loadingOrdenesActivas,
    loadingOrdenesCliente,
    loadingConsumoProceso,
    loadingMerma,
    loadingTiemposProceso,
    loadingCostosOrden,
    baseErrorMessage,
    ordenesActivasErrorMessage,
    ordenesClienteErrorMessage,
    consumoProcesoErrorMessage,
    mermaErrorMessage,
    tiemposProcesoErrorMessage,
    costosOrdenErrorMessage,
    ordenesClienteClienteId,
    ordenesClienteEstado,
    ordenesClienteFechaDesde,
    ordenesClienteFechaHasta,
    consumoOrdenProduccionId,
    consumoOrdenProcesoId,
    mermaOrdenProduccionId,
    mermaOrdenProcesoId,
    mermaFechaDesde,
    mermaFechaHasta,
    tiemposOrdenProduccionId,
    tiemposOrdenProcesoId,
    tiemposEstado,
    costosOrdenProduccionId,
  ];
}
