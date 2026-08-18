import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/features/production/clientes/data/datasources/clientes_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/production/clientes/domain/entities/cliente_option.dart';
import 'package:erp_curtiembre_fronted/features/production/clientes/domain/entities/cliente_record.dart';
import 'package:erp_curtiembre_fronted/features/production/clientes/domain/repositories/clientes_repository.dart';
import 'package:talker_flutter/talker_flutter.dart';

class ClientesRepositoryImpl implements ClientesRepository {
  ClientesRepositoryImpl(this._remoteDataSource, this._talker);

  final ClientesRemoteDataSource _remoteDataSource;
  final Talker _talker;

  @override
  Future<List<ClienteRecord>> listClientes({
    String? texto,
    bool? activo,
  }) async {
    _talker.repository(
      'Consultando clientes con filtros texto=${_describeText(texto)}, activo=$activo.',
    );
    final items = await _remoteDataSource.listClientes(
      texto: texto,
      activo: activo,
    );
    _talker.repository(
      'Se obtuvieron ${items.length} clientes para la bandeja de produccion.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<ClienteRecord> getCliente(int id) async {
    _talker.repository('Consultando detalle del cliente $id.');
    final item = await _remoteDataSource.getCliente(id);
    _talker.repository('Detalle del cliente $id obtenido correctamente.');
    return item.toEntity();
  }

  @override
  Future<List<ClienteOption>> listActiveClientes() async {
    _talker.repository(
      'Consultando clientes activos para catalogos de produccion.',
    );
    final items = await _remoteDataSource.listActiveClientes();
    _talker.repository(
      'Se obtuvieron ${items.length} clientes activos para catalogos de produccion.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<ClienteRecord> createCliente({
    required String rucDocumento,
    required String razonSocial,
    String? direccion,
    String? celular,
    String? correo,
    String? contacto,
  }) async {
    _talker.repository(
      'Iniciando creacion de cliente razonSocial=$razonSocial, rucDocumento=${_describeIdentifier(rucDocumento)}.',
    );
    final item = await _remoteDataSource.createCliente(
      rucDocumento: rucDocumento,
      razonSocial: razonSocial,
      direccion: direccion,
      celular: celular,
      correo: correo,
      contacto: contacto,
    );
    _talker.repository(
      'Cliente creado correctamente con razonSocial=$razonSocial.',
    );
    return item.toEntity();
  }

  @override
  Future<ClienteRecord> updateCliente({
    required int id,
    required String rucDocumento,
    required String razonSocial,
    String? direccion,
    String? celular,
    String? correo,
    String? contacto,
  }) async {
    _talker.repository(
      'Iniciando actualizacion del cliente $id con razonSocial=$razonSocial, rucDocumento=${_describeIdentifier(rucDocumento)}.',
    );
    final item = await _remoteDataSource.updateCliente(
      id: id,
      rucDocumento: rucDocumento,
      razonSocial: razonSocial,
      direccion: direccion,
      celular: celular,
      correo: correo,
      contacto: contacto,
    );
    _talker.repository('Cliente $id actualizado correctamente.');
    return item.toEntity();
  }

  @override
  Future<ClienteRecord> setClienteActive({
    required int id,
    required bool active,
  }) async {
    _talker.repository(
      active
          ? 'Se solicitara activacion del cliente $id.'
          : 'Se solicitara inactivacion del cliente $id.',
      logLevel: LogLevel.warning,
    );
    final item = await _remoteDataSource.setClienteActive(
      id: id,
      active: active,
    );
    _talker.repository(
      active
          ? 'Cliente $id activado correctamente.'
          : 'Cliente $id inactivado correctamente.',
      logLevel: LogLevel.warning,
    );
    return item.toEntity();
  }

  String _describeText(String? texto) {
    final normalized = texto?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return '${normalized.length} caracteres';
  }

  String _describeIdentifier(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return 'vacio';
    }

    return '${normalized.length} caracteres';
  }
}
