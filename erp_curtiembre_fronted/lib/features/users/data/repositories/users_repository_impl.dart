import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/features/security/domain/entities/security_role.dart';
import 'package:erp_curtiembre_fronted/features/users/data/datasources/users_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/users/domain/entities/user_area_option.dart';
import 'package:erp_curtiembre_fronted/features/users/domain/entities/user_detail.dart';
import 'package:erp_curtiembre_fronted/features/users/domain/entities/user_list_item.dart';
import 'package:erp_curtiembre_fronted/features/users/domain/entities/user_mutation_result.dart';
import 'package:erp_curtiembre_fronted/features/users/domain/repositories/users_repository.dart';
import 'package:talker_flutter/talker_flutter.dart';

class UsersRepositoryImpl implements UsersRepository {
  UsersRepositoryImpl(this._remoteDataSource, this._talker);

  final UsersRemoteDataSource _remoteDataSource;
  final Talker _talker;

  @override
  Future<List<SecurityRole>> listRoles() async {
    _talker.repository('Consultando roles para administracion de usuarios.');
    final items = await _remoteDataSource.listRoles();
    _talker.repository(
      'Se obtuvieron ${items.length} roles para administracion de usuarios.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<List<UserAreaOption>> listActiveAreas() async {
    _talker.repository(
      'Consultando areas activas para formulario de usuarios.',
    );
    final items = await _remoteDataSource.listActiveAreas();
    _talker.repository(
      'Se obtuvieron ${items.length} areas activas para formulario de usuarios.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<List<UserListItem>> listUsers({String? texto, bool? activo}) async {
    _talker.repository(
      'Consultando usuarios con filtros texto=${_describeText(texto)}, activo=$activo.',
    );
    final items = await _remoteDataSource.listUsers(
      texto: texto,
      activo: activo,
    );
    _talker.repository(
      'Se obtuvieron ${items.length} usuarios para la bandeja de seguridad.',
    );

    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<UserDetail> getUserDetail(int usuarioId) async {
    _talker.repository('Consultando detalle del usuario $usuarioId.');
    final detail = await _remoteDataSource.getUserDetail(usuarioId);
    _talker.repository(
      'Detalle del usuario $usuarioId obtenido correctamente.',
    );
    return detail.toEntity();
  }

  @override
  Future<UserMutationResult> createUser({
    required String dni,
    required String nombres,
    required String apellidos,
    required String userName,
    required int rolId,
    required int areaId,
    String? passwordTemporal,
  }) async {
    _talker.repository(
      'Iniciando creacion de usuario userName=$userName, rolId=$rolId, areaId=$areaId.',
    );
    final result = await _remoteDataSource.createUser(
      dni: dni,
      nombres: nombres,
      apellidos: apellidos,
      userName: userName,
      rolId: rolId,
      areaId: areaId,
      passwordTemporal: passwordTemporal,
    );
    _talker.repository('Usuario creado correctamente con userName=$userName.');

    return result.toEntity();
  }

  @override
  Future<UserMutationResult> updateUser({
    required int usuarioId,
    required String dni,
    required String nombres,
    required String apellidos,
    required String userName,
    required int rolId,
    required int areaId,
  }) async {
    _talker.repository(
      'Iniciando actualizacion del usuario $usuarioId con userName=$userName, rolId=$rolId, areaId=$areaId.',
    );
    final result = await _remoteDataSource.updateUser(
      usuarioId: usuarioId,
      dni: dni,
      nombres: nombres,
      apellidos: apellidos,
      userName: userName,
      rolId: rolId,
      areaId: areaId,
    );
    _talker.repository('Usuario $usuarioId actualizado correctamente.');

    return result.toEntity();
  }

  @override
  Future<String> resetPassword({
    required int usuarioId,
    String? passwordTemporal,
  }) {
    _talker.repository(
      'Se solicitara reseteo de credenciales para el usuario $usuarioId.',
      logLevel: LogLevel.warning,
    );
    return _remoteDataSource.resetPassword(
      usuarioId: usuarioId,
      passwordTemporal: passwordTemporal,
    );
  }

  @override
  Future<String> deactivateUser({required int usuarioId, String? motivo}) {
    _talker.repository(
      'Se solicitara desactivacion del usuario $usuarioId.',
      logLevel: LogLevel.warning,
    );
    return _remoteDataSource.deactivateUser(
      usuarioId: usuarioId,
      motivo: motivo,
    );
  }

  @override
  Future<String> reactivateUser({required int usuarioId, String? motivo}) {
    _talker.repository(
      'Se solicitara reactivacion del usuario $usuarioId.',
      logLevel: LogLevel.warning,
    );
    return _remoteDataSource.reactivateUser(
      usuarioId: usuarioId,
      motivo: motivo,
    );
  }

  String _describeText(String? texto) {
    final normalized = texto?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return '${normalized.length} caracteres';
  }
}
