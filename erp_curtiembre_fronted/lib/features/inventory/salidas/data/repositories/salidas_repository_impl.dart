import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/features/inventory/salidas/data/datasources/salidas_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/inventory/salidas/domain/entities/salida_detail.dart';
import 'package:erp_curtiembre_fronted/features/inventory/salidas/domain/entities/salida_record.dart';
import 'package:erp_curtiembre_fronted/features/inventory/salidas/domain/repositories/salidas_repository.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/domain/entities/insumo_lookup.dart';
import 'package:talker_flutter/talker_flutter.dart';

class SalidasRepositoryImpl implements SalidasRepository {
  SalidasRepositoryImpl(this._remoteDataSource, this._talker);

  final SalidasRemoteDataSource _remoteDataSource;
  final Talker _talker;

  @override
  Future<List<InsumoLookup>> listActiveInsumos() async {
    _talker.repository(
      'Consultando insumos activos para formularios de salidas.',
    );
    final items = await _remoteDataSource.listActiveInsumos();
    _talker.repository(
      'Se obtuvieron ${items.length} insumos activos para salidas.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<List<SalidaRecord>> listSalidas({
    String? texto,
    String? tipoSalida,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    _talker.repository(
      'Consultando salidas con filtros texto=${_describeText(texto)}, tipoSalida=${_describeType(tipoSalida)}, fechaDesde=${_describeDate(fechaDesde)}, fechaHasta=${_describeDate(fechaHasta)}.',
    );
    final items = await _remoteDataSource.listSalidas(
      texto: texto,
      tipoSalida: tipoSalida,
      fechaDesde: fechaDesde,
      fechaHasta: fechaHasta,
    );
    _talker.repository(
      'Se obtuvieron ${items.length} salidas para la bandeja.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<SalidaDetail> getSalidaDetail(int id) async {
    _talker.repository('Consultando detalle de la salida $id.');
    final detail = await _remoteDataSource.getSalidaDetail(id);
    _talker.repository('Detalle de la salida $id obtenido correctamente.');
    return detail.toEntity();
  }

  @override
  Future<SalidaDetail> registerGeneral({
    required String motivo,
    String? observacion,
    required List<RegistrarSalidaDetalleInput> detalles,
  }) async {
    _talker.repository(
      'Registrando salida general con motivo=${_describeText(motivo)}, observacion=${_describeText(observacion)}, detalles=${detalles.length}.',
      logLevel: LogLevel.warning,
    );
    final detail = await _remoteDataSource.registerGeneral(
      motivo: motivo,
      observacion: observacion,
      detalles: detalles,
    );
    _talker.repository(
      'Salida general registrada correctamente con id=${detail.id}.',
      logLevel: LogLevel.warning,
    );
    return detail.toEntity();
  }

  @override
  Future<SalidaDetail> registerSupplierReturn({
    required String motivo,
    String? observacion,
    required List<RegistrarSalidaDetalleInput> detalles,
  }) async {
    _talker.repository(
      'Registrando devolucion a proveedor con motivo=${_describeText(motivo)}, observacion=${_describeText(observacion)}, detalles=${detalles.length}.',
      logLevel: LogLevel.warning,
    );
    final detail = await _remoteDataSource.registerSupplierReturn(
      motivo: motivo,
      observacion: observacion,
      detalles: detalles,
    );
    _talker.repository(
      'Devolucion a proveedor registrada correctamente con id=${detail.id}.',
      logLevel: LogLevel.warning,
    );
    return detail.toEntity();
  }

  @override
  Future<SalidaDetail> registerNegativeAdjustment({
    required String motivo,
    String? observacion,
    required List<RegistrarSalidaDetalleInput> detalles,
  }) async {
    _talker.repository(
      'Registrando ajuste negativo con motivo=${_describeText(motivo)}, observacion=${_describeText(observacion)}, detalles=${detalles.length}.',
      logLevel: LogLevel.warning,
    );
    final detail = await _remoteDataSource.registerNegativeAdjustment(
      motivo: motivo,
      observacion: observacion,
      detalles: detalles,
    );
    _talker.repository(
      'Ajuste negativo registrado correctamente con id=${detail.id}.',
      logLevel: LogLevel.warning,
    );
    return detail.toEntity();
  }

  String _describeText(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return '${normalized.length} caracteres';
  }

  String _describeType(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return normalized;
  }

  String _describeDate(DateTime? value) {
    if (value == null) {
      return 'sin-filtro';
    }

    return value.toIso8601String();
  }
}
