import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/features/production/clientes/domain/entities/cliente_option.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/domain/entities/insumo_lookup.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/consumo_planificado_record.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/consumo_real_record.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/control_calidad_record.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/desviacion_consumo_record.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/data/datasources/ordenes_produccion_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/lote_option.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/merma_proceso_record.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/orden_proceso_record.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/orden_produccion_record.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/producto_terminado_record.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/personal_empresa_option.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/repositories/ordenes_produccion_repository.dart';
import 'package:talker_flutter/talker_flutter.dart';

class OrdenesProduccionRepositoryImpl implements OrdenesProduccionRepository {
  OrdenesProduccionRepositoryImpl(this._remoteDataSource, this._talker);

  final OrdenesProduccionRemoteDataSource _remoteDataSource;
  final Talker _talker;

  @override
  Future<List<PersonalEmpresaOption>> listPersonal() =>
      _remoteDataSource.listPersonal();

  @override
  Future<PersonalEmpresaOption> createPersonal({
    required String nombre,
    required String cargo,
  }) => _remoteDataSource.createPersonal(nombre: nombre, cargo: cargo);

  @override
  Future<List<OrdenProduccionRecord>> listOrdenes({
    String? texto,
    int? clienteId,
    int? loteId,
    String? estado,
  }) async {
    _talker.repository(
      'Consultando ordenes de produccion con filtros texto=${_describeText(texto)}, clienteId=$clienteId, loteId=$loteId, estado=${_describeState(estado)}.',
    );
    final items = await _remoteDataSource.listOrdenes(
      texto: texto,
      clienteId: clienteId,
      loteId: loteId,
      estado: estado,
    );
    _talker.repository(
      'Se obtuvieron ${items.length} ordenes para la bandeja de produccion.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<OrdenProduccionRecord> getOrden(int id) async {
    _talker.repository('Consultando detalle de la orden de produccion $id.');
    final item = await _remoteDataSource.getOrden(id);
    _talker.repository(
      'Detalle de la orden de produccion $id obtenido correctamente.',
    );
    return item.toEntity();
  }

  @override
  Future<List<OrdenProcesoRecord>> listProcesos(int ordenId) async {
    _talker.repository(
      'Consultando procesos de la orden de produccion $ordenId.',
    );
    final items = await _remoteDataSource.listProcesos(ordenId);
    _talker.repository(
      'Se obtuvieron ${items.length} procesos para la orden de produccion $ordenId.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<List<ClienteOption>> listActiveClientes() async {
    _talker.repository(
      'Consultando clientes activos para formularios de ordenes de produccion.',
    );
    final items = await _remoteDataSource.listActiveClientes();
    _talker.repository(
      'Se obtuvieron ${items.length} clientes activos para formularios de ordenes.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<List<LoteOption>> listLotesDisponibles() async {
    _talker.repository(
      'Consultando lotes disponibles para crear ordenes de produccion.',
    );
    final items = await _remoteDataSource.listLotesDisponibles();
    _talker.repository(
      'Se obtuvieron ${items.length} lotes disponibles para ordenes.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<List<InsumoLookup>> listActiveInsumos() async {
    _talker.repository(
      'Consultando insumos activos para consumo de ordenes de produccion.',
    );
    final items = await _remoteDataSource.listActiveInsumos();
    _talker.repository(
      'Se obtuvieron ${items.length} insumos activos para ordenes.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<List<ConsumoPlanificadoRecord>> listConsumoPlanificado(
    int ordenId,
  ) async {
    _talker.repository(
      'Consultando consumo planificado de la orden de produccion $ordenId.',
    );
    final items = await _remoteDataSource.listConsumoPlanificado(ordenId);
    _talker.repository(
      'Se obtuvieron ${items.length} consumos planificados para la orden $ordenId.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<List<ConsumoRealRecord>> listConsumoReal(int ordenId) async {
    _talker.repository(
      'Consultando consumo real de la orden de produccion $ordenId.',
    );
    final items = await _remoteDataSource.listConsumoReal(ordenId);
    _talker.repository(
      'Se obtuvieron ${items.length} consumos reales para la orden $ordenId.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<List<DesviacionConsumoRecord>> listDesviaciones(int ordenId) async {
    _talker.repository(
      'Consultando desviaciones de consumo para la orden de produccion $ordenId.',
    );
    final items = await _remoteDataSource.listDesviaciones(ordenId);
    _talker.repository(
      'Se obtuvieron ${items.length} desviaciones para la orden $ordenId.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<List<MermaProcesoRecord>> listMermas({
    int? ordenProduccionId,
    int? ordenProcesoId,
  }) async {
    _talker.repository(
      'Consultando mermas con filtros ordenProduccionId=$ordenProduccionId, ordenProcesoId=$ordenProcesoId.',
    );
    final items = await _remoteDataSource.listMermas(
      ordenProduccionId: ordenProduccionId,
      ordenProcesoId: ordenProcesoId,
    );
    _talker.repository(
      'Se obtuvieron ${items.length} registros de merma para el reporte de produccion.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<MermaProcesoRecord> registerMerma({
    required int procesoId,
    required RegistrarMermaProcesoInput input,
  }) async {
    _talker.repository(
      'Registrando merma para procesoId=$procesoId con cantidadPerdida=${input.cantidadPerdida}.',
    );
    final item = await _remoteDataSource.registerMerma(
      procesoId: procesoId,
      cantidadPerdida: input.cantidadPerdida,
      motivo: input.motivo,
      observacion: input.observacion,
    );
    _talker.repository(
      'Merma registrada correctamente para procesoId=$procesoId.',
    );
    return item.toEntity();
  }

  @override
  Future<ControlCalidadRecord> registerCalidadFinal({
    required int ordenId,
    required RegistrarCalidadFinalInput input,
  }) async {
    _talker.repository(
      'Registrando control de calidad final para ordenId=$ordenId con resultado=${input.resultado}.',
    );
    final item = await _remoteDataSource.registerCalidadFinal(
      ordenId: ordenId,
      calidadProductoId: input.calidadProductoId,
      cantidadLadosA: input.cantidadLadosA,
      cantidadLadosB: input.cantidadLadosB,
      cantidadLadosC: input.cantidadLadosC,
      cantidadLadosMerma: input.cantidadLadosMerma,
      resultado: input.resultado,
      observacion: input.observacion,
    );
    _talker.repository(
      'Control de calidad final registrado correctamente para ordenId=$ordenId.',
    );
    return item.toEntity();
  }

  @override
  Future<ProductoTerminadoRecord?> getProductoTerminadoByOrder(
    int ordenId,
  ) async {
    _talker.repository('Consultando producto terminado de la orden $ordenId.');
    final item = await _remoteDataSource.getProductoTerminadoByOrder(ordenId);
    if (item == null) {
      _talker.repository(
        'La orden $ordenId todavia no tiene producto terminado registrado.',
      );
      return null;
    }

    _talker.repository(
      'Producto terminado de la orden $ordenId obtenido correctamente.',
    );
    return item.toEntity();
  }

  @override
  Future<ProductoTerminadoRecord> finalizeOrden({
    required int ordenId,
    required FinalizarOrdenProduccionInput input,
  }) async {
    _talker.repository(
      'Finalizando orden de produccion $ordenId con cantidadLados=${input.cantidadLados}.',
    );
    final item = await _remoteDataSource.finalizeOrden(
      ordenId: ordenId,
      cantidadLados: input.cantidadLados,
      observacion: input.observacion,
    );
    _talker.repository(
      'Orden de produccion $ordenId finalizada correctamente.',
    );
    return item.toEntity();
  }

  @override
  Future<List<ProductoTerminadoRecord>> listProductosTerminados() async {
    _talker.repository('Consultando productos terminados de produccion.');
    final items = await _remoteDataSource.listProductosTerminados();
    _talker.repository(
      'Se obtuvieron ${items.length} productos terminados para la bandeja.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<void> generarConsumoPlanificado(int ordenId) async {
    _talker.repository(
      'Generando consumo planificado para la orden de produccion $ordenId.',
    );
    await _remoteDataSource.generarConsumoPlanificado(ordenId);
    _talker.repository(
      'Consumo planificado generado correctamente para la orden $ordenId.',
    );
  }

  @override
  Future<void> solicitarConsumo({
    required int ordenId,
    required int ordenProcesoId,
    String? motivo,
    String? observacion,
    required List<SolicitarConsumoProduccionDetalleInput> detalles,
  }) async {
    _talker.repository(
      'Solicitando consumo para ordenId=$ordenId, ordenProcesoId=$ordenProcesoId con ${detalles.length} detalles.',
    );
    await _remoteDataSource.solicitarConsumo(
      ordenId: ordenId,
      ordenProcesoId: ordenProcesoId,
      motivo: motivo,
      observacion: observacion,
      detalles: detalles
          .map(
            (item) => {
              'insumoId': item.insumoId,
              'cantidad': item.cantidad,
              'observacion': item.observacion,
            },
          )
          .toList(growable: false),
    );
    _talker.repository(
      'Solicitud de consumo registrada correctamente para ordenId=$ordenId y ordenProcesoId=$ordenProcesoId.',
    );
  }

  @override
  Future<OrdenProduccionRecord> createOrden({
    required int loteId,
    required int clienteId,
    required double cantidadPieles,
    DateTime? fechaInicioPlanificada,
    required DateTime fechaFinEstimada,
    required String responsableNombre,
    required String responsableCargo,
    String? observacion,
  }) async {
    _talker.repository(
      'Creando orden de produccion para loteId=$loteId, clienteId=$clienteId y cantidadPieles=$cantidadPieles.',
    );
    final item = await _remoteDataSource.createOrden(
      loteId: loteId,
      clienteId: clienteId,
      cantidadPieles: cantidadPieles,
      fechaInicioPlanificada: fechaInicioPlanificada,
      fechaFinEstimada: fechaFinEstimada,
      responsableNombre: responsableNombre,
      responsableCargo: responsableCargo,
      observacion: observacion,
    );
    _talker.repository(
      'Orden de produccion creada correctamente con id=${item.id}.',
    );
    return item.toEntity();
  }

  @override
  Future<OrdenProduccionRecord> startOrden({
    required int id,
    required double pesoBaseKg,
    required DateTime fechaFinEstimada,
    required String responsableNombre,
    required String responsableCargo,
    String? observacion,
  }) async {
    _talker.repository('Iniciando orden de produccion $id.');
    final item = await _remoteDataSource.startOrden(
      id: id,
      pesoBaseKg: pesoBaseKg,
      fechaFinEstimada: fechaFinEstimada,
      responsableNombre: responsableNombre,
      responsableCargo: responsableCargo,
      observacion: observacion,
    );
    _talker.repository('Orden de produccion $id iniciada correctamente.');
    return item.toEntity();
  }

  @override
  Future<OrdenProduccionRecord> cancelOrden({
    required int id,
    required String motivo,
  }) async {
    _talker.repository(
      'Anulando orden de produccion $id con motivo=${_describeText(motivo)}.',
      logLevel: LogLevel.warning,
    );
    final item = await _remoteDataSource.cancelOrden(id: id, motivo: motivo);
    _talker.repository(
      'Orden de produccion $id anulada correctamente.',
      logLevel: LogLevel.warning,
    );
    return item.toEntity();
  }

  @override
  Future<OrdenProcesoRecord> startProceso({
    required int id,
    required double pesoBaseKg,
    required DateTime fechaFinEstimada,
    required String responsableNombre,
    required String responsableCargo,
    String? observacion,
  }) async {
    _talker.repository('Iniciando proceso de produccion $id.');
    final item = await _remoteDataSource.startProceso(
      id: id,
      pesoBaseKg: pesoBaseKg,
      fechaFinEstimada: fechaFinEstimada,
      responsableNombre: responsableNombre,
      responsableCargo: responsableCargo,
      observacion: observacion,
    );
    _talker.repository('Proceso de produccion $id iniciado correctamente.');
    return item.toEntity();
  }

  @override
  Future<OrdenProcesoRecord> finishProceso({
    required int id,
    String? observacion,
  }) async {
    _talker.repository('Finalizando proceso de produccion $id.');
    final item = await _remoteDataSource.finishProceso(
      id: id,
      observacion: observacion,
    );
    _talker.repository('Proceso de produccion $id finalizado correctamente.');
    return item.toEntity();
  }

  @override
  Future<OrdenProcesoRecord> updateObservacionProceso({
    required int id,
    String? observacion,
  }) async {
    _talker.repository(
      'Actualizando observacion del proceso de produccion $id.',
    );
    final item = await _remoteDataSource.updateObservacionProceso(
      id: id,
      observacion: observacion,
    );
    _talker.repository(
      'Observacion del proceso de produccion $id actualizada.',
    );
    return item.toEntity();
  }

  String _describeText(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return '${normalized.length} caracteres';
  }

  String _describeState(String? estado) {
    final normalized = estado?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return normalized;
  }
}
