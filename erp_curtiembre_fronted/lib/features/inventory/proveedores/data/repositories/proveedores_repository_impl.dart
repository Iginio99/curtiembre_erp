import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/features/inventory/proveedores/data/datasources/proveedores_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/inventory/proveedores/domain/entities/proveedor_record.dart';
import 'package:erp_curtiembre_fronted/features/inventory/proveedores/domain/repositories/proveedores_repository.dart';
import 'package:talker_flutter/talker_flutter.dart';

class ProveedoresRepositoryImpl implements ProveedoresRepository {
  ProveedoresRepositoryImpl(this._remoteDataSource, this._talker);

  final ProveedoresRemoteDataSource _remoteDataSource;
  final Talker _talker;

  @override
  Future<List<ProveedorRecord>> listProveedores({
    String? texto,
    bool? activo,
  }) async {
    _talker.repository(
      'Consultando proveedores con filtros texto=${_describeText(texto)}, activo=${_describeBool(activo)}.',
    );
    final items = await _remoteDataSource.listProveedores(
      texto: texto,
      activo: activo,
    );
    _talker.repository(
      'Se obtuvieron ${items.length} proveedores para la bandeja.',
    );

    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<ProveedorRecord> getProveedor(int id) async {
    _talker.repository('Consultando detalle del proveedor $id.');
    final proveedor = await _remoteDataSource.getProveedor(id);
    _talker.repository('Detalle del proveedor $id obtenido correctamente.');
    return proveedor.toEntity();
  }

  @override
  Future<ProveedorRecord> createProveedor({
    required String rucDocumento,
    required String razonSocial,
    String? direccion,
    String? telefono,
    String? correo,
    String? contacto,
  }) async {
    _talker.repository(
      'Creando proveedor con ruc=${_describeText(rucDocumento)}, razonSocial=${_describeText(razonSocial)}.',
    );
    final proveedor = await _remoteDataSource.createProveedor(
      rucDocumento: rucDocumento,
      razonSocial: razonSocial,
      direccion: direccion,
      telefono: telefono,
      correo: correo,
      contacto: contacto,
    );
    _talker.repository(
      'Proveedor creado correctamente con id=${proveedor.id}.',
    );

    return proveedor.toEntity();
  }

  @override
  Future<ProveedorRecord> updateProveedor({
    required int id,
    required String rucDocumento,
    required String razonSocial,
    String? direccion,
    String? telefono,
    String? correo,
    String? contacto,
  }) async {
    _talker.repository(
      'Actualizando proveedor $id con ruc=${_describeText(rucDocumento)}, razonSocial=${_describeText(razonSocial)}.',
      logLevel: LogLevel.warning,
    );
    final proveedor = await _remoteDataSource.updateProveedor(
      id: id,
      rucDocumento: rucDocumento,
      razonSocial: razonSocial,
      direccion: direccion,
      telefono: telefono,
      correo: correo,
      contacto: contacto,
    );
    _talker.repository(
      'Proveedor $id actualizado correctamente.',
      logLevel: LogLevel.warning,
    );

    return proveedor.toEntity();
  }

  @override
  Future<ProveedorRecord> setProveedorActive({
    required int id,
    required bool active,
  }) async {
    _talker.repository(
      active ? 'Activando proveedor $id.' : 'Inactivando proveedor $id.',
      logLevel: LogLevel.warning,
    );
    final proveedor = await _remoteDataSource.setProveedorActive(
      id: id,
      active: active,
    );
    _talker.repository(
      active
          ? 'Proveedor $id activado correctamente.'
          : 'Proveedor $id inactivado correctamente.',
      logLevel: LogLevel.warning,
    );

    return proveedor.toEntity();
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
