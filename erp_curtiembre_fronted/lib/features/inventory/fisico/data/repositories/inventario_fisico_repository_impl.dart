import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/features/inventory/fisico/data/datasources/inventario_fisico_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/inventory/fisico/domain/entities/inventario_fisico_detail.dart';
import 'package:erp_curtiembre_fronted/features/inventory/fisico/domain/entities/inventario_fisico_record.dart';
import 'package:erp_curtiembre_fronted/features/inventory/fisico/domain/repositories/inventario_fisico_repository.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/domain/entities/insumo_lookup.dart';
import 'package:talker_flutter/talker_flutter.dart';

class InventarioFisicoRepositoryImpl implements InventarioFisicoRepository {
  InventarioFisicoRepositoryImpl(this._remoteDataSource, this._talker);

  final InventarioFisicoRemoteDataSource _remoteDataSource;
  final Talker _talker;

  @override
  Future<List<InsumoLookup>> listActiveInsumos() async {
    _talker.repository('Consultando insumos activos para inventario fisico.');
    final items = await _remoteDataSource.listActiveInsumos();
    _talker.repository(
      'Se obtuvieron ${items.length} insumos activos para inventario fisico.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<List<InventarioFisicoRecord>> listInventariosFisicos({
    int? periodoAnio,
    int? periodoMes,
    String? estado,
  }) async {
    _talker.repository(
      'Consultando inventarios fisicos con filtros periodoAnio=$periodoAnio, periodoMes=$periodoMes, estado=${_describeState(estado)}.',
    );
    final items = await _remoteDataSource.listInventariosFisicos(
      periodoAnio: periodoAnio,
      periodoMes: periodoMes,
      estado: estado,
    );
    _talker.repository(
      'Se obtuvieron ${items.length} inventarios fisicos para la bandeja.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<InventarioFisicoDetail> getInventarioFisicoDetail(int id) async {
    _talker.repository('Consultando detalle del inventario fisico $id.');
    final detail = await _remoteDataSource.getInventarioFisicoDetail(id);
    _talker.repository(
      'Detalle del inventario fisico $id obtenido correctamente.',
    );
    return detail.toEntity();
  }

  @override
  Future<InventarioFisicoDetail> createInventarioFisico({
    required int periodoAnio,
    required int periodoMes,
    String? observacion,
  }) async {
    _talker.repository(
      'Creando inventario fisico para periodo=$periodoMes/$periodoAnio.',
    );
    final detail = await _remoteDataSource.createInventarioFisico(
      periodoAnio: periodoAnio,
      periodoMes: periodoMes,
      observacion: observacion,
    );
    _talker.repository(
      'Inventario fisico creado correctamente con id=${detail.id}.',
    );
    return detail.toEntity();
  }

  @override
  Future<InventarioFisicoDetail> registerCounts({
    required int inventarioFisicoId,
    required List<RegistrarConteoInventarioFisicoDetalleInput> detalles,
  }) async {
    _talker.repository(
      'Registrando conteos para inventario fisico $inventarioFisicoId con ${detalles.length} detalles.',
      logLevel: LogLevel.warning,
    );
    final detail = await _remoteDataSource.registerCounts(
      inventarioFisicoId: inventarioFisicoId,
      detalles: detalles,
    );
    _talker.repository(
      'Conteos registrados correctamente para inventario fisico $inventarioFisicoId.',
      logLevel: LogLevel.warning,
    );
    return detail.toEntity();
  }

  @override
  Future<InventarioFisicoDetail> closeInventarioFisico({
    required int inventarioFisicoId,
    String? observacion,
  }) async {
    _talker.repository(
      'Cerrando inventario fisico $inventarioFisicoId con observacion=${_describeText(observacion)}.',
      logLevel: LogLevel.warning,
    );
    final detail = await _remoteDataSource.closeInventarioFisico(
      inventarioFisicoId: inventarioFisicoId,
      observacion: observacion,
    );
    _talker.repository(
      'Inventario fisico $inventarioFisicoId cerrado correctamente.',
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

  String _describeState(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return normalized;
  }
}
