import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/security/domain/repositories/security_repository.dart';
import 'package:erp_curtiembre_fronted/features/security/presentation/cubit/security_access_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';

class SecurityAccessCubit extends Cubit<SecurityAccessState> {
  static const String usuariosAdminPermissionCode = 'USUARIOS_ADMIN';

  SecurityAccessCubit(this._securityRepository, this._talker)
    : super(const SecurityAccessState.loading());

  final SecurityRepository _securityRepository;
  final Talker _talker;

  void clear() => emit(const SecurityAccessState.loading());

  Future<void> load({required int usuarioId}) async {
    _talker.cubit('Cargando acceso de seguridad para el usuario $usuarioId.');
    emit(const SecurityAccessState.loading());

    try {
      final snapshot = await _securityRepository.loadAccessSnapshot(
        usuarioId: usuarioId,
      );
      _talker.cubit(
        'Snapshot de seguridad cargado para el usuario $usuarioId con ${snapshot.userPermissionCodes.length} permisos de usuario.',
        logLevel: LogLevel.debug,
      );

      final usuariosAdminResult = await _securityRepository.checkPermission(
        usuarioId: usuarioId,
        permissionCode: usuariosAdminPermissionCode,
      );
      _talker.cubit(
        'Validacion de $usuariosAdminPermissionCode para el usuario $usuarioId: ${usuariosAdminResult.allowed}.',
        logLevel: LogLevel.debug,
      );

      emit(
        state.copyWith(
          status: SecurityAccessStatus.success,
          snapshot: snapshot,
          checkedPermissions: {
            usuariosAdminPermissionCode: usuariosAdminResult.allowed,
          },
          clearError: true,
        ),
      );
      _talker.cubit(
        'Acceso de seguridad cargado correctamente para el usuario $usuarioId.',
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar acceso de seguridad para el usuario $usuarioId: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(
        state.copyWith(
          status: SecurityAccessStatus.error,
          errorMessage: exception.message,
        ),
      );
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al cargar acceso de seguridad para el usuario $usuarioId.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          status: SecurityAccessStatus.error,
          errorMessage:
              'No pudimos cargar roles y permisos. Intenta nuevamente.',
        ),
      );
    }
  }
}
