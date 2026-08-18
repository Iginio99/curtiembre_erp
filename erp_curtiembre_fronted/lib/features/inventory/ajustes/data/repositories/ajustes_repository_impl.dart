import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/features/inventory/ajustes/data/datasources/ajustes_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/inventory/ajustes/domain/entities/ajuste_detail.dart';
import 'package:erp_curtiembre_fronted/features/inventory/ajustes/domain/entities/ajuste_record.dart';
import 'package:erp_curtiembre_fronted/features/inventory/ajustes/domain/repositories/ajustes_repository.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/domain/entities/insumo_lookup.dart';
import 'package:talker_flutter/talker_flutter.dart';

class AjustesRepositoryImpl implements AjustesRepository {
  AjustesRepositoryImpl(this._remoteDataSource, this._talker);

  final AjustesRemoteDataSource _remoteDataSource;
  final Talker _talker;

  @override
  Future<List<InsumoLookup>> listActiveInsumos() async {
    _talker.repository(
      'Consultando insumos activos para formularios de ajustes de inventario.',
    );
    final items = await _remoteDataSource.listActiveInsumos();
    _talker.repository(
      'Se obtuvieron ${items.length} insumos activos para ajustes de inventario.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<List<AjusteRecord>> listAjustes({
    String? texto,
    String? tipoAjuste,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    _talker.repository(
      'Consultando ajustes de inventario con filtros texto=${_describeText(texto)}, tipoAjuste=${_describeType(tipoAjuste)}, fechaDesde=${_describeDate(fechaDesde)}, fechaHasta=${_describeDate(fechaHasta)}.',
    );
    final items = await _remoteDataSource.listAjustes(
      texto: texto,
      tipoAjuste: tipoAjuste,
      fechaDesde: fechaDesde,
      fechaHasta: fechaHasta,
    );
    _talker.repository(
      'Se obtuvieron ${items.length} ajustes de inventario para la bandeja.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<AjusteDetail> getAjusteDetail(int id) async {
    _talker.repository('Consultando detalle del ajuste de inventario $id.');
    final detail = await _remoteDataSource.getAjusteDetail(id);
    _talker.repository(
      'Detalle del ajuste de inventario $id obtenido correctamente.',
    );
    return detail.toEntity();
  }

  @override
  Future<AjusteDetail> registerPositive({
    required String motivo,
    String? observacion,
    required List<RegistrarAjusteDetalleInput> detalles,
  }) async {
    _talker.repository(
      'Registrando ajuste positivo con motivo=${_describeText(motivo)} y ${detalles.length} detalles.',
      logLevel: LogLevel.warning,
    );
    final detail = await _remoteDataSource.registerPositive(
      motivo: motivo,
      observacion: observacion,
      detalles: detalles,
    );
    _talker.repository(
      'Ajuste positivo registrado correctamente con id=${detail.id}.',
      logLevel: LogLevel.warning,
    );
    return detail.toEntity();
  }

  @override
  Future<AjusteDetail> registerNegative({
    required String motivo,
    String? observacion,
    required List<RegistrarAjusteDetalleInput> detalles,
  }) async {
    _talker.repository(
      'Registrando ajuste negativo con motivo=${_describeText(motivo)} y ${detalles.length} detalles.',
      logLevel: LogLevel.warning,
    );
    final detail = await _remoteDataSource.registerNegative(
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
      return 'sin-fecha';
    }

    return value.toIso8601String();
  }
}
