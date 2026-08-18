import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/features/inventory/insumos/data/datasources/insumos_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/inventory/insumos/domain/entities/insumo_record.dart';
import 'package:erp_curtiembre_fronted/features/inventory/insumos/domain/entities/unidad_medida_option.dart';
import 'package:erp_curtiembre_fronted/features/inventory/insumos/domain/repositories/insumos_repository.dart';
import 'package:talker_flutter/talker_flutter.dart';

class InsumosRepositoryImpl implements InsumosRepository {
  InsumosRepositoryImpl(this._remoteDataSource, this._talker);

  final InsumosRemoteDataSource _remoteDataSource;
  final Talker _talker;

  @override
  Future<List<InsumoRecord>> listInsumos({
    String? texto,
    String? tipoBien,
    int? unidadMedidaId,
    bool? activo,
    bool? stockBajo,
  }) async {
    _talker.repository(
      'Consultando insumos con filtros texto=${_describeText(texto)}, tipoBien=${_describeType(tipoBien)}, unidadMedidaId=$unidadMedidaId, activo=${_describeBool(activo)}, stockBajo=${_describeBool(stockBajo)}.',
    );
    final items = await _remoteDataSource.listInsumos(
      texto: texto,
      tipoBien: tipoBien,
      unidadMedidaId: unidadMedidaId,
      activo: activo,
      stockBajo: stockBajo,
    );
    _talker.repository(
      'Se obtuvieron ${items.length} insumos para la bandeja.',
    );

    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<InsumoRecord> getInsumo(int id) async {
    _talker.repository('Consultando detalle del insumo $id.');
    final insumo = await _remoteDataSource.getInsumo(id);
    _talker.repository('Detalle del insumo $id obtenido correctamente.');
    return insumo.toEntity();
  }

  @override
  Future<InsumoRecord> createInsumo({
    required String codigo,
    required String nombre,
    required String tipoBien,
    String? presentacion,
    required int unidadMedidaId,
    required double stockMinimo,
    required bool requiereLote,
  }) async {
    _talker.repository(
      'Creando insumo codigo=${_describeText(codigo)}, nombre=${_describeText(nombre)}, tipoBien=$tipoBien.',
    );
    final insumo = await _remoteDataSource.createInsumo(
      codigo: codigo,
      nombre: nombre,
      tipoBien: tipoBien,
      presentacion: presentacion,
      unidadMedidaId: unidadMedidaId,
      stockMinimo: stockMinimo,
      requiereLote: requiereLote,
    );
    _talker.repository('Insumo creado correctamente con id=${insumo.id}.');

    return insumo.toEntity();
  }

  @override
  Future<InsumoRecord> updateInsumo({
    required int id,
    required String codigo,
    required String nombre,
    required String tipoBien,
    String? presentacion,
    required int unidadMedidaId,
    required double stockMinimo,
    required bool requiereLote,
  }) async {
    _talker.repository(
      'Actualizando insumo $id con codigo=${_describeText(codigo)}, nombre=${_describeText(nombre)}, tipoBien=$tipoBien.',
    );
    final insumo = await _remoteDataSource.updateInsumo(
      id: id,
      codigo: codigo,
      nombre: nombre,
      tipoBien: tipoBien,
      presentacion: presentacion,
      unidadMedidaId: unidadMedidaId,
      stockMinimo: stockMinimo,
      requiereLote: requiereLote,
    );
    _talker.repository('Insumo $id actualizado correctamente.');

    return insumo.toEntity();
  }

  @override
  Future<InsumoRecord> setInsumoActive({
    required int id,
    required bool active,
  }) async {
    _talker.repository(
      active ? 'Activando insumo $id.' : 'Inactivando insumo $id.',
      logLevel: LogLevel.warning,
    );
    final insumo = await _remoteDataSource.setInsumoActive(
      id: id,
      active: active,
    );
    _talker.repository(
      active
          ? 'Insumo $id activado correctamente.'
          : 'Insumo $id inactivado correctamente.',
      logLevel: LogLevel.warning,
    );

    return insumo.toEntity();
  }

  @override
  Future<List<UnidadMedidaOption>> listActiveUnits() async {
    _talker.repository(
      'Consultando unidades de medida activas para formularios de insumos.',
    );
    final items = await _remoteDataSource.listActiveUnits();
    _talker.repository(
      'Se obtuvieron ${items.length} unidades de medida activas para insumos.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
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

  String _describeBool(bool? value) {
    if (value == null) {
      return 'sin-filtro';
    }

    return value.toString();
  }
}
