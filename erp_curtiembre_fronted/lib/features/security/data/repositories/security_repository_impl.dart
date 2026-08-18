import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/features/security/data/datasources/security_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/security/data/models/security_permission_model.dart';
import 'package:erp_curtiembre_fronted/features/security/data/models/security_role_model.dart';
import 'package:erp_curtiembre_fronted/features/security/domain/entities/permission_check_result.dart';
import 'package:erp_curtiembre_fronted/features/security/domain/entities/security_access_snapshot.dart';
import 'package:erp_curtiembre_fronted/features/security/domain/repositories/security_repository.dart';
import 'package:talker_flutter/talker_flutter.dart';

class SecurityRepositoryImpl implements SecurityRepository {
  SecurityRepositoryImpl(this._remoteDataSource, this._talker);

  final SecurityRemoteDataSource _remoteDataSource;
  final Talker _talker;

  @override
  Future<SecurityAccessSnapshot> loadAccessSnapshot({
    required int usuarioId,
  }) async {
    _talker.repository(
      'Cargando snapshot de acceso para el usuario $usuarioId.',
    );
    final userPermissionCodes = await _remoteDataSource
        .getCurrentUserPermissions();
    var roles = const <SecurityRoleModel>[];
    var permissions = const <SecurityPermissionModel>[];

    if (userPermissionCodes.contains('USUARIOS_ADMIN')) {
      _talker.repository(
        'El usuario $usuarioId tiene USUARIOS_ADMIN. Se cargaran roles y permisos.',
      );
      final results = await Future.wait([
        _remoteDataSource.listRoles(),
        _remoteDataSource.listPermissions(),
      ]);

      roles = results[0] as List<SecurityRoleModel>;
      permissions = results[1] as List<SecurityPermissionModel>;
    } else {
      _talker.repository(
        'El usuario $usuarioId no tiene USUARIOS_ADMIN. Se omitira la carga de catalogos administrativos.',
        logLevel: LogLevel.debug,
      );
    }

    _talker.repository(
      'Snapshot de acceso listo para el usuario $usuarioId con ${userPermissionCodes.length} permisos de usuario, ${roles.length} roles y ${permissions.length} permisos catalogados.',
    );
    return SecurityAccessSnapshot(
      roles: roles.map((item) => item.toEntity()).toList(growable: false),
      permissions: permissions
          .map((item) => item.toEntity())
          .toList(growable: false),
      userPermissionCodes: userPermissionCodes,
    );
  }

  @override
  Future<PermissionCheckResult> checkPermission({
    required int usuarioId,
    required String permissionCode,
  }) async {
    _talker.repository(
      'Validando permiso $permissionCode para el usuario $usuarioId.',
      logLevel: LogLevel.warning,
    );
    final result = await _remoteDataSource.checkPermission(
      usuarioId: usuarioId,
      permissionCode: permissionCode,
    );
    _talker.repository(
      'Validacion de permiso $permissionCode para el usuario $usuarioId completada.',
      logLevel: LogLevel.warning,
    );

    return result.toEntity();
  }
}
