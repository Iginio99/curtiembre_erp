import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/features/production/reportes/data/datasources/produccion_reportes_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/production/reportes/domain/entities/consumo_proceso_reporte_item.dart';
import 'package:erp_curtiembre_fronted/features/production/reportes/domain/entities/costo_orden_reporte_item.dart';
import 'package:erp_curtiembre_fronted/features/production/reportes/domain/entities/costo_proceso_reporte_item.dart';
import 'package:erp_curtiembre_fronted/features/production/reportes/domain/entities/merma_reporte_item.dart';
import 'package:erp_curtiembre_fronted/features/production/reportes/domain/entities/orden_activa_reporte_item.dart';
import 'package:erp_curtiembre_fronted/features/production/reportes/domain/entities/orden_cliente_reporte_item.dart';
import 'package:erp_curtiembre_fronted/features/production/reportes/domain/entities/tiempo_proceso_reporte_item.dart';
import 'package:erp_curtiembre_fronted/features/production/reportes/domain/repositories/produccion_reportes_repository.dart';
import 'package:talker_flutter/talker_flutter.dart';

class ProduccionReportesRepositoryImpl implements ProduccionReportesRepository {
  ProduccionReportesRepositoryImpl(this._remoteDataSource, this._talker);

  final ProduccionReportesRemoteDataSource _remoteDataSource;
  final Talker _talker;

  @override
  Future<List<OrdenActivaReporteItem>> listOrdenesActivas() async {
    _talker.repository('Consultando reporte de ordenes activas.');
    final items = await _remoteDataSource.listOrdenesActivas();
    _talker.repository(
      'Se obtuvieron ${items.length} registros para el reporte de ordenes activas.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<List<OrdenClienteReporteItem>> listOrdenesPorCliente({
    int? clienteId,
    String? estado,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    _talker.repository(
      'Consultando reporte de ordenes por cliente con filtros clienteId=$clienteId, estado=${_describeState(estado)}, fechaDesde=${_describeDate(fechaDesde)}, fechaHasta=${_describeDate(fechaHasta)}.',
    );
    final items = await _remoteDataSource.listOrdenesPorCliente(
      clienteId: clienteId,
      estado: estado,
      fechaDesde: fechaDesde,
      fechaHasta: fechaHasta,
    );
    _talker.repository(
      'Se obtuvieron ${items.length} registros para el reporte de ordenes por cliente.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<List<ConsumoProcesoReporteItem>> listConsumoPorProceso({
    int? ordenProduccionId,
    int? ordenProcesoId,
  }) async {
    _talker.repository(
      'Consultando reporte de consumo por proceso con filtros ordenProduccionId=$ordenProduccionId, ordenProcesoId=$ordenProcesoId.',
    );
    final items = await _remoteDataSource.listConsumoPorProceso(
      ordenProduccionId: ordenProduccionId,
      ordenProcesoId: ordenProcesoId,
    );
    _talker.repository(
      'Se obtuvieron ${items.length} registros para el reporte de consumo por proceso.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<List<MermaReporteItem>> listMerma({
    int? ordenProduccionId,
    int? ordenProcesoId,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    _talker.repository(
      'Consultando reporte de merma con filtros ordenProduccionId=$ordenProduccionId, ordenProcesoId=$ordenProcesoId, fechaDesde=${_describeDate(fechaDesde)}, fechaHasta=${_describeDate(fechaHasta)}.',
    );
    final items = await _remoteDataSource.listMerma(
      ordenProduccionId: ordenProduccionId,
      ordenProcesoId: ordenProcesoId,
      fechaDesde: fechaDesde,
      fechaHasta: fechaHasta,
    );
    _talker.repository(
      'Se obtuvieron ${items.length} registros para el reporte de merma.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<List<TiempoProcesoReporteItem>> listTiemposProceso({
    int? ordenProduccionId,
    int? ordenProcesoId,
    String? estado,
  }) async {
    _talker.repository(
      'Consultando reporte de tiempos de proceso con filtros ordenProduccionId=$ordenProduccionId, ordenProcesoId=$ordenProcesoId, estado=${_describeState(estado)}.',
    );
    final items = await _remoteDataSource.listTiemposProceso(
      ordenProduccionId: ordenProduccionId,
      ordenProcesoId: ordenProcesoId,
      estado: estado,
    );
    _talker.repository(
      'Se obtuvieron ${items.length} registros para el reporte de tiempos de proceso.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<List<CostoOrdenReporteItem>> listCostosPorOrden({
    int? ordenProduccionId,
  }) async {
    _talker.repository(
      'Consultando costos reales por orden con ordenProduccionId=$ordenProduccionId.',
    );
    final items = await _remoteDataSource.listCostosPorOrden(
      ordenProduccionId: ordenProduccionId,
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<List<CostoProcesoReporteItem>> listCostosPorProceso({
    int? ordenProduccionId,
  }) async {
    final items = await _remoteDataSource.listCostosPorProceso(
      ordenProduccionId: ordenProduccionId,
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  String _describeState(String? estado) {
    final normalized = estado?.trim();
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
