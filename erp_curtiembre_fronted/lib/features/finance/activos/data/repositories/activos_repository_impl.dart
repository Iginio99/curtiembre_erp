import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/features/finance/activos/data/datasources/activos_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/finance/activos/domain/entities/activo_depreciable_record.dart';
import 'package:erp_curtiembre_fronted/features/finance/activos/domain/repositories/activos_repository.dart';
import 'package:talker_flutter/talker_flutter.dart';

class ActivosRepositoryImpl implements ActivosRepository {
  ActivosRepositoryImpl(this._remoteDataSource, this._talker);

  final ActivosRemoteDataSource _remoteDataSource;
  final Talker _talker;

  @override
  Future<List<ActivoDepreciableRecord>> listActivos({
    String? texto,
    bool? activo,
  }) async {
    _talker.repository(
      'Consultando activos depreciables con filtros texto=${_describeText(texto)}, activo=${_describeBool(activo)}.',
    );
    final items = await _remoteDataSource.listActivos(
      texto: texto,
      activo: activo,
    );
    _talker.repository(
      'Se obtuvieron ${items.length} activos depreciables para la bandeja.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<ActivoDepreciableRecord> getActivo(int id) async {
    _talker.repository('Consultando detalle del activo depreciable $id.');
    final item = await _remoteDataSource.getActivo(id);
    _talker.repository(
      'Detalle del activo depreciable $id obtenido correctamente.',
    );
    return item.toEntity();
  }

  @override
  Future<ActivoDepreciableRecord> createActivo({
    required String codigo,
    required String nombre,
    required double valorCompra,
    required DateTime fechaCompra,
    required int vidaUtilMeses,
    required double valorResidual,
    required bool activo,
  }) async {
    _talker.repository(
      'Creando activo depreciable con codigo=${_describeText(codigo)}, nombre=${_describeText(nombre)}, valorCompra=$valorCompra, vidaUtilMeses=$vidaUtilMeses, valorResidual=$valorResidual, activo=$activo.',
    );
    final item = await _remoteDataSource.createActivo(
      codigo: codigo,
      nombre: nombre,
      valorCompra: valorCompra,
      fechaCompra: fechaCompra,
      vidaUtilMeses: vidaUtilMeses,
      valorResidual: valorResidual,
      activo: activo,
    );
    _talker.repository(
      'Activo depreciable creado correctamente con id=${item.id}.',
    );
    return item.toEntity();
  }

  @override
  Future<ActivoDepreciableRecord> updateActivo({
    required int id,
    required String codigo,
    required String nombre,
    required double valorCompra,
    required DateTime fechaCompra,
    required int vidaUtilMeses,
    required double valorResidual,
    required bool activo,
  }) async {
    _talker.repository(
      'Actualizando activo depreciable $id con codigo=${_describeText(codigo)}, nombre=${_describeText(nombre)}, valorCompra=$valorCompra, vidaUtilMeses=$vidaUtilMeses, valorResidual=$valorResidual, activo=$activo.',
      logLevel: LogLevel.warning,
    );
    final item = await _remoteDataSource.updateActivo(
      id: id,
      codigo: codigo,
      nombre: nombre,
      valorCompra: valorCompra,
      fechaCompra: fechaCompra,
      vidaUtilMeses: vidaUtilMeses,
      valorResidual: valorResidual,
      activo: activo,
    );
    _talker.repository(
      'Activo depreciable $id actualizado correctamente.',
      logLevel: LogLevel.warning,
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

  String _describeBool(bool? value) {
    if (value == null) {
      return 'sin-filtro';
    }

    return value.toString();
  }
}
