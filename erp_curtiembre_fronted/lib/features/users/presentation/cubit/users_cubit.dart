import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/security/domain/entities/security_role.dart';
import 'package:erp_curtiembre_fronted/features/users/domain/entities/user_area_option.dart';
import 'package:erp_curtiembre_fronted/features/users/domain/repositories/users_repository.dart';
import 'package:erp_curtiembre_fronted/features/users/presentation/cubit/users_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';

class UsersActionResult {
  const UsersActionResult._({
    required this.success,
    required this.message,
    this.passwordTemporal,
  });

  const UsersActionResult.success({
    required String message,
    String? passwordTemporal,
  }) : this._(
         success: true,
         message: message,
         passwordTemporal: passwordTemporal,
       );

  const UsersActionResult.failure(String message)
    : this._(success: false, message: message);

  final bool success;
  final String message;
  final String? passwordTemporal;
}

class UsersCubit extends Cubit<UsersState> {
  UsersCubit(this._usersRepository, this._talker)
    : super(const UsersState.loading());

  final UsersRepository _usersRepository;
  final Talker _talker;

  Future<void> initialize() async {
    _talker.cubit('Inicializando modulo de usuarios.');
    emit(const UsersState.loading());

    try {
      final results = await Future.wait([
        _usersRepository.listRoles(),
        _usersRepository.listActiveAreas(),
      ]);
      final roles = results[0] as List<SecurityRole>;
      final areas = results[1] as List<UserAreaOption>;

      emit(state.copyWith(roles: roles, areas: areas, clearError: true));
      _talker.cubit(
        'Configuracion inicial de usuarios cargada con ${roles.length} roles y ${areas.length} areas.',
      );

      await load();
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo inicializar el modulo de usuarios: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(
        state.copyWith(
          status: UsersStatus.error,
          errorMessage: exception.message,
        ),
      );
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado durante la inicializacion del modulo de usuarios.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          status: UsersStatus.error,
          errorMessage:
              'No pudimos cargar la configuracion de usuarios. Intenta nuevamente.',
        ),
      );
    }
  }

  Future<void> load({String? searchTerm, UserActivityFilter? filter}) async {
    final nextSearchTerm = searchTerm ?? state.searchTerm;
    final nextFilter = filter ?? state.filter;
    _talker.cubit(
      'Cargando usuarios con filtros texto=${_describeSearchTerm(nextSearchTerm)}, filtro=$nextFilter.',
    );

    emit(
      state.copyWith(
        status: UsersStatus.loading,
        searchTerm: nextSearchTerm,
        filter: nextFilter,
        clearError: true,
      ),
    );

    try {
      await _reloadUsers(searchTerm: nextSearchTerm, filter: nextFilter);
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar la lista de usuarios: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(
        state.copyWith(
          status: UsersStatus.error,
          errorMessage: exception.message,
        ),
      );
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al cargar la lista de usuarios.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          status: UsersStatus.error,
          errorMessage:
              'No pudimos cargar la lista de usuarios. Intenta nuevamente.',
        ),
      );
    }
  }

  Future<void> selectUser(int usuarioId) async {
    if (state.selectedUserId == usuarioId &&
        state.selectedUserDetail?.usuarioId == usuarioId) {
      _talker.cubit(
        'Se ignoro la seleccion del usuario $usuarioId porque ya estaba cargado.',
        logLevel: LogLevel.debug,
      );
      return;
    }

    _talker.cubit('Seleccionando usuario $usuarioId para ver detalle.');
    emit(state.copyWith(selectedUserId: usuarioId, clearDetailError: true));

    await _loadUserDetail(usuarioId);
  }

  Future<void> retryDetail() async {
    final usuarioId = state.selectedUserId;
    if (usuarioId == null) {
      _talker.cubit(
        'Se intento reintentar detalle sin un usuario seleccionado.',
        logLevel: LogLevel.warning,
      );
      return;
    }

    _talker.cubit('Reintentando carga de detalle para el usuario $usuarioId.');
    await _loadUserDetail(usuarioId);
  }

  Future<UsersActionResult> createUser({
    required String dni,
    required String nombres,
    required String apellidos,
    required String userName,
    required int rolId,
    required int areaId,
    String? passwordTemporal,
  }) async {
    _talker.cubit(
      'Iniciando flujo de creacion de usuario userName=$userName, rolId=$rolId, areaId=$areaId.',
    );
    emit(state.copyWith(isSubmittingAction: true));

    try {
      final result = await _usersRepository.createUser(
        dni: dni,
        nombres: nombres,
        apellidos: apellidos,
        userName: userName,
        rolId: rolId,
        areaId: areaId,
        passwordTemporal: passwordTemporal,
      );

      await _reloadUsers(
        searchTerm: state.searchTerm,
        filter: state.filter,
        preferredUserId: result.usuario.usuarioId,
      );

      emit(state.copyWith(isSubmittingAction: false));
      _talker.cubit('Usuario creado correctamente con userName=$userName.');
      return UsersActionResult.success(
        message: 'Usuario creado correctamente.',
        passwordTemporal: result.passwordTemporal,
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo crear el usuario userName=$userName: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return UsersActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al crear el usuario userName=$userName.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const UsersActionResult.failure(
        'No pudimos crear el usuario. Intenta nuevamente.',
      );
    }
  }

  Future<UsersActionResult> updateSelectedUser({
    required String dni,
    required String nombres,
    required String apellidos,
    required String userName,
    required int rolId,
    required int areaId,
  }) async {
    final usuarioId = state.selectedUserId;
    if (usuarioId == null) {
      _talker.cubit(
        'Se intento editar un usuario sin seleccion previa.',
        logLevel: LogLevel.warning,
      );
      return const UsersActionResult.failure(
        'Selecciona un usuario para editar.',
      );
    }

    _talker.cubit(
      'Iniciando actualizacion del usuario $usuarioId con userName=$userName, rolId=$rolId, areaId=$areaId.',
    );
    emit(state.copyWith(isSubmittingAction: true));

    try {
      await _usersRepository.updateUser(
        usuarioId: usuarioId,
        dni: dni,
        nombres: nombres,
        apellidos: apellidos,
        userName: userName,
        rolId: rolId,
        areaId: areaId,
      );

      await _reloadUsers(
        searchTerm: state.searchTerm,
        filter: state.filter,
        preferredUserId: usuarioId,
      );

      emit(state.copyWith(isSubmittingAction: false));
      _talker.cubit('Usuario $usuarioId actualizado correctamente.');
      return const UsersActionResult.success(
        message: 'Usuario actualizado correctamente.',
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo actualizar el usuario $usuarioId: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return UsersActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al actualizar el usuario $usuarioId.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const UsersActionResult.failure(
        'No pudimos actualizar el usuario. Intenta nuevamente.',
      );
    }
  }

  Future<UsersActionResult> resetPassword({
    required int usuarioId,
    String? passwordTemporal,
  }) async {
    _talker.cubit(
      'Iniciando reseteo de credenciales para el usuario $usuarioId.',
      logLevel: LogLevel.warning,
    );
    emit(state.copyWith(isSubmittingAction: true));

    try {
      final message = await _usersRepository.resetPassword(
        usuarioId: usuarioId,
        passwordTemporal: passwordTemporal,
      );

      await _reloadUsers(
        searchTerm: state.searchTerm,
        filter: state.filter,
        preferredUserId: usuarioId,
      );

      emit(state.copyWith(isSubmittingAction: false));
      _talker.cubit(
        'Password reseteado correctamente para el usuario $usuarioId.',
        logLevel: LogLevel.warning,
      );
      return UsersActionResult.success(message: message);
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo resetear la contrasena del usuario $usuarioId: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return UsersActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al resetear la contrasena del usuario $usuarioId.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const UsersActionResult.failure(
        'No pudimos resetear la contrasena del usuario.',
      );
    }
  }

  Future<UsersActionResult> setUserActive({
    required int usuarioId,
    required bool active,
    String? motivo,
  }) async {
    _talker.cubit(
      active
          ? 'Iniciando reactivacion del usuario $usuarioId.'
          : 'Iniciando desactivacion del usuario $usuarioId.',
      logLevel: LogLevel.warning,
    );
    emit(state.copyWith(isSubmittingAction: true));

    try {
      final message = active
          ? await _usersRepository.reactivateUser(
              usuarioId: usuarioId,
              motivo: motivo,
            )
          : await _usersRepository.deactivateUser(
              usuarioId: usuarioId,
              motivo: motivo,
            );

      await _reloadUsers(
        searchTerm: state.searchTerm,
        filter: state.filter,
        preferredUserId: usuarioId,
      );

      emit(state.copyWith(isSubmittingAction: false));
      _talker.cubit(
        active
            ? 'Usuario $usuarioId reactivado correctamente.'
            : 'Usuario $usuarioId desactivado correctamente.',
        logLevel: LogLevel.warning,
      );
      return UsersActionResult.success(message: message);
    } on ApiException catch (exception) {
      _talker.cubit(
        active
            ? 'No se pudo reactivar el usuario $usuarioId: ${exception.message}'
            : 'No se pudo desactivar el usuario $usuarioId: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return UsersActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        active
            ? 'Fallo inesperado al reactivar el usuario $usuarioId.'
            : 'Fallo inesperado al desactivar el usuario $usuarioId.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return UsersActionResult.failure(
        active
            ? 'No pudimos reactivar el usuario.'
            : 'No pudimos desactivar el usuario.',
      );
    }
  }

  Future<void> _loadUserDetail(int usuarioId) async {
    _talker.cubit('Cargando detalle del usuario $usuarioId.');
    emit(
      state.copyWith(
        isDetailLoading: true,
        clearSelectedUserDetail: true,
        clearDetailError: true,
      ),
    );

    try {
      final detail = await _usersRepository.getUserDetail(usuarioId);
      _talker.cubit('Detalle del usuario $usuarioId cargado correctamente.');
      emit(
        state.copyWith(
          isDetailLoading: false,
          selectedUserDetail: detail,
          clearDetailError: true,
        ),
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar el detalle del usuario $usuarioId: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(
        state.copyWith(
          isDetailLoading: false,
          detailErrorMessage: exception.message,
        ),
      );
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al cargar el detalle del usuario $usuarioId.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          isDetailLoading: false,
          detailErrorMessage: 'No pudimos cargar el detalle del usuario.',
        ),
      );
    }
  }

  Future<void> _reloadUsers({
    required String searchTerm,
    required UserActivityFilter filter,
    int? preferredUserId,
  }) async {
    _talker.cubit(
      'Recargando usuarios con texto=${_describeSearchTerm(searchTerm)}, filtro=$filter, preferido=${preferredUserId ?? state.selectedUserId}.',
      logLevel: LogLevel.debug,
    );
    final items = await _usersRepository.listUsers(
      texto: searchTerm,
      activo: _mapFilter(filter),
    );

    final currentSelectedId = preferredUserId ?? state.selectedUserId;
    final selectedUserId =
        items.any((item) => item.usuarioId == currentSelectedId)
        ? currentSelectedId
        : items.isNotEmpty
        ? items.first.usuarioId
        : null;
    _talker.cubit(
      'Recarga de usuarios completada con ${items.length} resultados. Seleccion actual=${selectedUserId ?? 'ninguna'}.',
      logLevel: LogLevel.debug,
    );

    emit(
      state.copyWith(
        status: UsersStatus.success,
        items: items,
        selectedUserId: selectedUserId,
        searchTerm: searchTerm,
        filter: filter,
        clearError: true,
      ),
    );

    if (selectedUserId == null) {
      emit(
        state.copyWith(
          isDetailLoading: false,
          clearSelectedUserDetail: true,
          clearDetailError: true,
        ),
      );
      _talker.cubit(
        'No hay usuario seleccionado despues de la recarga.',
        logLevel: LogLevel.debug,
      );
      return;
    }

    await _loadUserDetail(selectedUserId);
  }

  bool? _mapFilter(UserActivityFilter filter) {
    return switch (filter) {
      UserActivityFilter.active => true,
      UserActivityFilter.inactive => false,
      UserActivityFilter.all => null,
    };
  }

  String _describeSearchTerm(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return 'vacio';
    }

    return '${normalized.length} caracteres';
  }
}
