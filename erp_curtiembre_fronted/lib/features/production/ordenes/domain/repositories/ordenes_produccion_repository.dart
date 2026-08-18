import 'package:erp_curtiembre_fronted/features/production/clientes/domain/entities/cliente_option.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/domain/entities/insumo_lookup.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/consumo_planificado_record.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/consumo_real_record.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/control_calidad_record.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/desviacion_consumo_record.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/lote_option.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/merma_proceso_record.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/orden_proceso_record.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/orden_produccion_record.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/producto_terminado_record.dart';

class SolicitarConsumoProduccionDetalleInput {
  const SolicitarConsumoProduccionDetalleInput({
    required this.insumoId,
    required this.cantidad,
    this.observacion,
  });

  final int insumoId;
  final double cantidad;
  final String? observacion;
}

class RegistrarMermaProcesoInput {
  const RegistrarMermaProcesoInput({
    required this.cantidadPerdida,
    this.motivo,
    this.observacion,
  });

  final double cantidadPerdida;
  final String? motivo;
  final String? observacion;
}

class RegistrarCalidadFinalInput {
  const RegistrarCalidadFinalInput({
    required this.calidadProductoId,
    required this.resultado,
    this.observacion,
  });

  final int calidadProductoId;
  final String resultado;
  final String? observacion;
}

class FinalizarOrdenProduccionInput {
  const FinalizarOrdenProduccionInput({
    required this.cantidadLados,
    this.observacion,
  });

  final double cantidadLados;
  final String? observacion;
}

abstract class OrdenesProduccionRepository {
  Future<List<OrdenProduccionRecord>> listOrdenes({
    String? texto,
    int? clienteId,
    int? loteId,
    String? estado,
  });

  Future<OrdenProduccionRecord> getOrden(int id);

  Future<List<OrdenProcesoRecord>> listProcesos(int ordenId);

  Future<List<ClienteOption>> listActiveClientes();

  Future<List<LoteOption>> listLotesDisponibles();

  Future<List<InsumoLookup>> listActiveInsumos();

  Future<List<ConsumoPlanificadoRecord>> listConsumoPlanificado(int ordenId);

  Future<List<ConsumoRealRecord>> listConsumoReal(int ordenId);

  Future<List<DesviacionConsumoRecord>> listDesviaciones(int ordenId);

  Future<List<MermaProcesoRecord>> listMermas({
    int? ordenProduccionId,
    int? ordenProcesoId,
  });

  Future<MermaProcesoRecord> registerMerma({
    required int procesoId,
    required RegistrarMermaProcesoInput input,
  });

  Future<ControlCalidadRecord> registerCalidadFinal({
    required int ordenId,
    required RegistrarCalidadFinalInput input,
  });

  Future<ProductoTerminadoRecord?> getProductoTerminadoByOrder(int ordenId);

  Future<ProductoTerminadoRecord> finalizeOrden({
    required int ordenId,
    required FinalizarOrdenProduccionInput input,
  });

  Future<List<ProductoTerminadoRecord>> listProductosTerminados();

  Future<void> generarConsumoPlanificado(int ordenId);

  Future<void> solicitarConsumo({
    required int ordenId,
    required int ordenProcesoId,
    String? motivo,
    String? observacion,
    required List<SolicitarConsumoProduccionDetalleInput> detalles,
  });

  Future<OrdenProduccionRecord> createOrden({
    required int loteId,
    required int clienteId,
    required double cantidadPieles,
    DateTime? fechaInicioPlanificada,
    required DateTime fechaFinEstimada,
    int? responsableUsuarioId,
    String? observacion,
  });

  Future<OrdenProduccionRecord> startOrden({
    required int id,
    required double pesoBaseKg,
    required DateTime fechaFinEstimada,
    int? responsableUsuarioId,
    String? observacion,
  });

  Future<OrdenProduccionRecord> cancelOrden({
    required int id,
    required String motivo,
  });

  Future<OrdenProcesoRecord> startProceso({
    required int id,
    required double pesoBaseKg,
    required DateTime fechaFinEstimada,
    int? responsableUsuarioId,
    String? observacion,
  });

  Future<OrdenProcesoRecord> finishProceso({
    required int id,
    String? observacion,
  });

  Future<OrdenProcesoRecord> updateObservacionProceso({
    required int id,
    String? observacion,
  });
}
