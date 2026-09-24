import 'dart:async';

import 'package:erp_curtiembre_fronted/core/di/service_locator.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_breakpoints.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_state.dart';
import 'package:erp_curtiembre_fronted/features/security/presentation/cubit/security_access_cubit.dart';
import 'package:erp_curtiembre_fronted/features/users/domain/entities/user_detail.dart';
import 'package:erp_curtiembre_fronted/features/users/domain/entities/user_list_item.dart';
import 'package:erp_curtiembre_fronted/features/users/presentation/cubit/users_cubit.dart';
import 'package:erp_curtiembre_fronted/features/users/presentation/cubit/users_state.dart';
import 'package:erp_curtiembre_fronted/features/users/presentation/widgets/user_password_reset_dialog.dart';
import 'package:erp_curtiembre_fronted/features/users/presentation/widgets/user_state_change_dialog.dart';
import 'package:erp_curtiembre_fronted/features/users/presentation/widgets/user_upsert_dialog.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/buttons/app_button.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/feedback/app_message_card.dart';
import 'package:erp_curtiembre_fronted/shared/navigation/app_access_routes.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/layout/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:talker_flutter/talker_flutter.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final _searchController = TextEditingController();
  final Talker _talker = getIt<Talker>();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _talker.ui('Se abrio la pantalla de usuarios.');
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _searchAsYouType(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      context.read<UsersCubit>().load(searchTerm: value.trim());
    });
  }

  Future<void> _openCreateUserDialog(UsersState state) async {
    _talker.ui('Se abrio el dialogo para crear usuario.');
    final payload = await showDialog<UserUpsertFormData>(
      context: context,
      builder: (dialogContext) => UserUpsertDialog(
        title: 'Nuevo usuario',
        submitLabel: 'Crear usuario',
        roles: state.roles,
        areas: state.areas,
        isSubmitting: state.isSubmittingAction,
      ),
    );

    if (payload == null || !mounted) {
      _talker.ui(
        'Se cerro el dialogo de creacion de usuario sin confirmar.',
        logLevel: LogLevel.debug,
      );
      return;
    }
    _talker.ui(
      'Se confirmo la creacion de usuario con userName=${payload.userName}.',
    );

    final result = await context.read<UsersCubit>().createUser(
      dni: payload.dni,
      nombres: payload.nombres,
      apellidos: payload.apellidos,
      userName: payload.userName,
      rolId: payload.rolId,
      areaId: payload.areaId,
      passwordTemporal: payload.passwordTemporal,
    );

    if (!mounted) {
      return;
    }

    await _handleActionResult(result, successTitle: 'Usuario creado');
  }

  Future<void> _openEditUserDialog(UsersState state, UserDetail detail) async {
    _talker.ui(
      'Se abrio el dialogo para editar el usuario ${detail.usuarioId}.',
    );
    final payload = await showDialog<UserUpsertFormData>(
      context: context,
      builder: (dialogContext) => UserUpsertDialog(
        title: 'Editar usuario',
        submitLabel: 'Guardar cambios',
        roles: state.roles,
        areas: state.areas,
        isSubmitting: state.isSubmittingAction,
        initialUser: detail,
      ),
    );

    if (payload == null || !mounted) {
      _talker.ui(
        'Se cerro la edicion del usuario ${detail.usuarioId} sin confirmar.',
        logLevel: LogLevel.debug,
      );
      return;
    }
    _talker.ui(
      'Se confirmo la edicion del usuario ${detail.usuarioId} con userName=${payload.userName}.',
    );

    final result = await context.read<UsersCubit>().updateSelectedUser(
      dni: payload.dni,
      nombres: payload.nombres,
      apellidos: payload.apellidos,
      userName: payload.userName,
      rolId: payload.rolId,
      areaId: payload.areaId,
    );

    if (!mounted) {
      return;
    }

    await _handleActionResult(
      result,
      successTitle: 'Usuario actualizado',
      useDialogForSuccess: false,
    );
  }

  Future<void> _openResetPasswordDialog(UserDetail detail) async {
    _talker.ui(
      'Se abrio el dialogo de reseteo de password para el usuario ${detail.usuarioId}.',
      logLevel: LogLevel.warning,
    );
    final resultDialog = await showDialog<UserPasswordResetDialogResult>(
      context: context,
      builder: (dialogContext) => UserPasswordResetDialog(
        userName: detail.userName,
        isSubmitting: false,
      ),
    );

    if (!mounted) {
      return;
    }

    if (resultDialog == null) {
      _talker.ui(
        'Se cerro el dialogo de reseteo de password para el usuario ${detail.usuarioId} sin confirmar.',
        logLevel: LogLevel.debug,
      );
      return;
    }
    _talker.ui(
      'Se confirmo el reseteo de password para el usuario ${detail.usuarioId}.',
      logLevel: LogLevel.warning,
    );

    final result = await context.read<UsersCubit>().resetPassword(
      usuarioId: detail.usuarioId,
      passwordTemporal: resultDialog.passwordTemporal,
    );

    if (!mounted) {
      return;
    }

    await _handleActionResult(
      result,
      successTitle: 'Password reseteado',
      useDialogForSuccess: true,
    );
  }

  Future<void> _openStateChangeDialog({
    required UserDetail detail,
    required bool activate,
  }) async {
    _talker.ui(
      activate
          ? 'Se abrio el dialogo para reactivar al usuario ${detail.usuarioId}.'
          : 'Se abrio el dialogo para desactivar al usuario ${detail.usuarioId}.',
      logLevel: LogLevel.warning,
    );
    final resultDialog = await showDialog<UserStateChangeDialogResult>(
      context: context,
      builder: (dialogContext) => UserStateChangeDialog(
        userName: detail.userName,
        activate: activate,
        isSubmitting: false,
      ),
    );

    if (!mounted) {
      return;
    }

    if (resultDialog == null) {
      _talker.ui(
        activate
            ? 'Se cerro la reactivacion del usuario ${detail.usuarioId} sin confirmar.'
            : 'Se cerro la desactivacion del usuario ${detail.usuarioId} sin confirmar.',
        logLevel: LogLevel.debug,
      );
      return;
    }
    _talker.ui(
      activate
          ? 'Se confirmo la reactivacion del usuario ${detail.usuarioId}.'
          : 'Se confirmo la desactivacion del usuario ${detail.usuarioId}.',
      logLevel: LogLevel.warning,
    );

    final result = await context.read<UsersCubit>().setUserActive(
      usuarioId: detail.usuarioId,
      active: activate,
      motivo: resultDialog.motivo,
    );

    if (!mounted) {
      return;
    }

    await _handleActionResult(
      result,
      successTitle: activate ? 'Usuario reactivado' : 'Usuario desactivado',
      useDialogForSuccess: false,
    );
  }

  Future<void> _handleActionResult(
    UsersActionResult result, {
    required String successTitle,
    bool useDialogForSuccess = true,
  }) async {
    if (!result.success) {
      _talker.ui(
        'La accion en usuarios fallo: ${result.message}',
        logLevel: LogLevel.error,
      );
      _showSnackBar(result.message, isError: true);
      return;
    }
    _talker.ui('Accion en usuarios completada: $successTitle.');

    if (useDialogForSuccess) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(successTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(result.message),
              if (result.passwordTemporal != null) ...[
                const Gap(AppSpacing.lg),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Theme.of(dialogContext).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SelectableText(
                    result.passwordTemporal!,
                    style: Theme.of(dialogContext).textTheme.titleMedium
                        ?.copyWith(
                          color: Theme.of(
                            dialogContext,
                          ).colorScheme.onPrimaryContainer,
                        ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
      return;
    }

    _showSnackBar(result.message);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    _talker.ui(
      isError
          ? 'Se mostro un mensaje de error en usuarios.'
          : 'Se mostro un mensaje informativo en usuarios.',
      logLevel: isError ? LogLevel.error : LogLevel.debug,
    );
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? const Color(0xFF8A2F22) : null,
      ),
    );
  }

  String _describeSearchTerm(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return 'vacio';
    }

    return '${normalized.length} caracteres';
  }

  @override
  Widget build(BuildContext context) {
    final session = context.select((AuthCubit cubit) => cubit.state.session);
    final isSigningOut = context.select(
      (AuthCubit cubit) => cubit.state.status == AuthStatus.signingOut,
    );
    final permissionCodes = context.select(
      (SecurityAccessCubit cubit) =>
          cubit.state.snapshot?.userPermissionCodes.toSet() ?? const <String>{},
    );

    if (session == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return AppShell(
      title: 'Usuarios',
      currentPath: '/seguridad/usuarios',
      breadcrumbs: const ['Inicio', 'Seguridad', 'Usuarios'],
      userName: session.nombreCompleto,
      roleName: session.rolNombre,
      accessibleRoutes: AppAccessRoutes.forPermissions(permissionCodes),
      onSignOut: isSigningOut
          ? () {}
          : () => context.read<AuthCubit>().signOut(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1440),
                child: BlocBuilder<UsersCubit, UsersState>(
                  builder: (context, state) {
                    final isWide =
                        MediaQuery.sizeOf(context).width >=
                        AppBreakpoints.tablet;
                    final compactHeight = constraints.maxHeight < 860;

                    if (_searchController.text != state.searchTerm) {
                      _searchController.value = TextEditingValue(
                        text: state.searchTerm,
                        selection: TextSelection.collapsed(
                          offset: state.searchTerm.length,
                        ),
                      );
                    }

                    final listPanel = _UsersListPanel(
                      state: state,
                      onRetry: () => context.read<UsersCubit>().initialize(),
                      onSelectUser: (usuarioId) {
                        _talker.ui(
                          'Se selecciono el usuario $usuarioId desde el listado.',
                          logLevel: LogLevel.debug,
                        );
                        context.read<UsersCubit>().selectUser(usuarioId);
                      },
                    );

                    final detailPanel = _UserDetailPanel(
                      state: state,
                      onRetry: () => context.read<UsersCubit>().retryDetail(),
                      onEditUser: state.selectedUserDetail == null
                          ? null
                          : () => _openEditUserDialog(
                              state,
                              state.selectedUserDetail!,
                            ),
                      onResetPassword: state.selectedUserDetail == null
                          ? null
                          : () => _openResetPasswordDialog(
                              state.selectedUserDetail!,
                            ),
                      onToggleState: state.selectedUserDetail == null
                          ? null
                          : () => _openStateChangeDialog(
                              detail: state.selectedUserDetail!,
                              activate: !state.selectedUserDetail!.activo,
                            ),
                    );

                    final headerAndFilters = <Widget>[
                      Text(
                        'Administra usuarios, roles, estados de acceso y credenciales del sistema.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Gap(AppSpacing.xl),
                      _UsersFiltersCard(
                        controller: _searchController,
                        selectedFilter: state.filter,
                        isSubmittingAction: state.isSubmittingAction,
                        onSearchChanged: _searchAsYouType,
                        onCreateUser: () => _openCreateUserDialog(state),
                        onFilterChanged: (filter) {
                          _talker.ui(
                            'Se cambio el filtro de usuarios a $filter.',
                            logLevel: LogLevel.debug,
                          );
                          context.read<UsersCubit>().load(filter: filter);
                        },
                      ),
                      const Gap(AppSpacing.xl),
                    ];

                    if (compactHeight) {
                      if (isWide) {
                        return SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...headerAndFilters,
                              SizedBox(
                                height: 620,
                                child: Row(
                                  children: [
                                    Expanded(flex: 9, child: listPanel),
                                    const Gap(AppSpacing.xl),
                                    Expanded(flex: 8, child: detailPanel),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...headerAndFilters,
                            SizedBox(height: 520, child: listPanel),
                            const Gap(AppSpacing.xl),
                            SizedBox(height: 560, child: detailPanel),
                          ],
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...headerAndFilters,
                        Expanded(
                          child: isWide
                              ? Row(
                                  children: [
                                    Expanded(flex: 9, child: listPanel),
                                    const Gap(AppSpacing.xl),
                                    Expanded(flex: 8, child: detailPanel),
                                  ],
                                )
                              : Column(
                                  children: [
                                    Expanded(child: listPanel),
                                    const Gap(AppSpacing.xl),
                                    Expanded(child: detailPanel),
                                  ],
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _UsersFiltersCard extends StatelessWidget {
  const _UsersFiltersCard({
    required this.controller,
    required this.selectedFilter,
    required this.isSubmittingAction,
    required this.onSearchChanged,
    required this.onCreateUser,
    required this.onFilterChanged,
  });

  final TextEditingController controller;
  final UserActivityFilter selectedFilter;
  final bool isSubmittingAction;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onCreateUser;
  final ValueChanged<UserActivityFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 900;
          final search = TextField(
            controller: controller,
            onChanged: onSearchChanged,
            decoration: const InputDecoration(
              hintText: 'Buscar usuario, DNI, rol o area...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          );
          final filters = SegmentedButton<UserActivityFilter>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment<UserActivityFilter>(
                value: UserActivityFilter.active,
                label: Text('Activos'),
              ),
              ButtonSegment<UserActivityFilter>(
                value: UserActivityFilter.inactive,
                label: Text('Inactivos'),
              ),
              ButtonSegment<UserActivityFilter>(
                value: UserActivityFilter.all,
                label: Text('Todos'),
              ),
            ],
            selected: {selectedFilter},
            onSelectionChanged: (selection) {
              final filter = selection.firstOrNull;
              if (filter != null) onFilterChanged(filter);
            },
          );
          final createButton = AppButton.secondary(
            label: 'Nuevo usuario',
            icon: Icons.person_add_alt_1_rounded,
            isLoading: isSubmittingAction,
            onPressed: onCreateUser,
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                search,
                const Gap(AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [filters, createButton],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: search),
              const Gap(AppSpacing.md),
              filters,
              const Gap(AppSpacing.md),
              createButton,
            ],
          );
        },
      ),
    );
  }
}

class _UsersListPanel extends StatelessWidget {
  const _UsersListPanel({
    required this.state,
    required this.onRetry,
    required this.onSelectUser,
  });

  final UsersState state;
  final VoidCallback onRetry;
  final ValueChanged<int> onSelectUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Listado de usuarios', style: theme.textTheme.titleLarge),
            const Gap(AppSpacing.xs),
            Text(
              '${state.items.length} resultado(s) para la vista actual.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Gap(AppSpacing.lg),
            Expanded(
              child: switch (state.status) {
                UsersStatus.loading => const Center(
                  child: CircularProgressIndicator(),
                ),
                UsersStatus.error => _CenteredMessage(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppMessageCard.error(
                        title: 'No pudimos cargar la lista',
                        message:
                            state.errorMessage ??
                            'Intenta nuevamente para consultar los usuarios.',
                      ),
                      const Gap(AppSpacing.lg),
                      AppButton.secondary(
                        label: 'Reintentar',
                        icon: Icons.refresh_rounded,
                        onPressed: onRetry,
                      ),
                    ],
                  ),
                ),
                UsersStatus.success =>
                  state.items.isEmpty
                      ? const _CenteredMessage(
                          child: AppMessageCard.info(
                            title: 'Sin resultados',
                            message:
                                'No encontramos usuarios con los filtros actuales.',
                          ),
                        )
                      : ListView.separated(
                          itemCount: state.items.length,
                          separatorBuilder: (_, _) => const Gap(AppSpacing.md),
                          itemBuilder: (context, index) {
                            final item = state.items[index];
                            return _UserListTileCard(
                              item: item,
                              isSelected:
                                  item.usuarioId == state.selectedUserId,
                              onTap: () => onSelectUser(item.usuarioId),
                            );
                          },
                        ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _UserDetailPanel extends StatelessWidget {
  const _UserDetailPanel({
    required this.state,
    required this.onRetry,
    required this.onEditUser,
    required this.onResetPassword,
    required this.onToggleState,
  });

  final UsersState state;
  final VoidCallback onRetry;
  final VoidCallback? onEditUser;
  final VoidCallback? onResetPassword;
  final VoidCallback? onToggleState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detail = state.selectedUserDetail;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Detalle del usuario', style: theme.textTheme.titleLarge),
            const Gap(AppSpacing.xs),
            Text(
              'Revisa identidad, rol, estado de acceso y trazabilidad reciente.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Gap(AppSpacing.lg),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (state.isDetailLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.detailErrorMessage != null) {
                    return _CenteredMessage(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppMessageCard.error(
                            title: 'No pudimos cargar el detalle',
                            message: state.detailErrorMessage!,
                          ),
                          const Gap(AppSpacing.lg),
                          AppButton.secondary(
                            label: 'Reintentar detalle',
                            icon: Icons.refresh_rounded,
                            onPressed: onRetry,
                          ),
                        ],
                      ),
                    );
                  }

                  if (detail == null) {
                    return const _CenteredMessage(
                      child: AppMessageCard.info(
                        title: 'Selecciona un usuario',
                        message:
                            'Escoge un registro del listado para revisar su informacion.',
                      ),
                    );
                  }

                  return ScrollConfiguration(
                    behavior: ScrollConfiguration.of(
                      context,
                    ).copyWith(scrollbars: false),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: AppSpacing.md,
                            runSpacing: AppSpacing.md,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                detail.nombreCompleto,
                                style: theme.textTheme.headlineSmall,
                              ),
                              _StatusBadge(
                                label: detail.activo ? 'Activo' : 'Inactivo',
                                icon: detail.activo
                                    ? Icons.verified_user_outlined
                                    : Icons.person_off_outlined,
                                background: detail.activo
                                    ? theme.colorScheme.primaryContainer
                                    : theme.colorScheme.surfaceContainerHighest,
                                foreground: detail.activo
                                    ? theme.colorScheme.onPrimaryContainer
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                              if (detail.debeCambiarPassword)
                                _StatusBadge(
                                  label: 'Cambio de clave pendiente',
                                  icon: Icons.password_outlined,
                                  background: const Color(0xFFF9E8BF),
                                  foreground: const Color(0xFF7A5512),
                                ),
                            ],
                          ),
                          const Gap(AppSpacing.xs),
                          Text(
                            '@${detail.userName}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const Gap(AppSpacing.lg),
                          Wrap(
                            spacing: AppSpacing.md,
                            runSpacing: AppSpacing.md,
                            children: [
                              AppButton.secondary(
                                label: 'Editar usuario',
                                icon: Icons.edit_outlined,
                                isLoading: state.isSubmittingAction,
                                onPressed: onEditUser,
                              ),
                              AppButton.secondary(
                                label: 'Resetear contrasena',
                                icon: Icons.password_outlined,
                                isLoading: state.isSubmittingAction,
                                onPressed: onResetPassword,
                              ),
                              AppButton.secondary(
                                label: detail.activo
                                    ? 'Desactivar usuario'
                                    : 'Reactivar usuario',
                                icon: detail.activo
                                    ? Icons.person_off_outlined
                                    : Icons.person_add_alt_1_outlined,
                                isLoading: state.isSubmittingAction,
                                onPressed: onToggleState,
                              ),
                            ],
                          ),
                          const Gap(AppSpacing.xl),
                          Wrap(
                            spacing: AppSpacing.lg,
                            runSpacing: AppSpacing.lg,
                            children: [
                              _DetailCard(
                                title: 'Identidad',
                                lines: [
                                  'DNI: ${detail.dni}',
                                  'Area: ${detail.areaNombre ?? 'Sin area'}',
                                  'Usuario ID: ${detail.usuarioId}',
                                ],
                              ),
                              _DetailCard(
                                title: 'Acceso',
                                lines: [
                                  'Rol: ${detail.rolNombre}',
                                  'Codigo de rol: ${detail.rolCodigo}',
                                  'Intentos fallidos: ${detail.intentosFallidos}',
                                ],
                              ),
                              _DetailCard(
                                title: 'Trazabilidad',
                                lines: [
                                  'Creado: ${_formatDateTime(detail.creadoEn)}',
                                  'Ultimo login: ${_formatOptionalDate(detail.ultimoLoginEn)}',
                                  'Bloqueado hasta: ${_formatOptionalDate(detail.bloqueadoHasta)}',
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserListTileCard extends StatelessWidget {
  const _UserListTileCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final UserListItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.68)
                : theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.42)
                  : theme.colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(item.nombreCompleto, style: theme.textTheme.titleMedium),
                  _MiniPill(
                    label: item.activo ? 'Activo' : 'Inactivo',
                    background: item.activo
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    foreground: item.activo
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  if (item.debeCambiarPassword)
                    const _MiniPill(
                      label: 'Cambio de clave',
                      background: Color(0xFFF9E8BF),
                      foreground: Color(0xFF7A5512),
                    ),
                ],
              ),
              const Gap(AppSpacing.sm),
              Text(
                '@${item.userName}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const Gap(AppSpacing.md),
              Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.sm,
                children: [
                  _InlineInfo(label: 'DNI', value: item.dni),
                  _InlineInfo(label: 'Rol', value: item.rolNombre),
                  _InlineInfo(
                    label: 'Area',
                    value: item.areaNombre ?? 'Sin area',
                  ),
                ],
              ),
              const Gap(AppSpacing.md),
              Text(
                'Ultimo acceso: ${_formatOptionalDate(item.ultimoLoginEn)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 260,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const Gap(AppSpacing.md),
          for (final line in lines) ...[
            Text(line, style: theme.textTheme.bodyMedium),
            const Gap(AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const Gap(AppSpacing.sm),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: foreground),
      ),
    );
  }
}

class _InlineInfo extends StatelessWidget {
  const _InlineInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RichText(
      text: TextSpan(
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
        children: [
          TextSpan(
            text: '$label: ',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: child,
      ),
    );
  }
}

String _formatOptionalDate(DateTime? value) {
  if (value == null) {
    return 'Sin registro';
  }

  return _formatDateTime(value);
}

String _formatDateTime(DateTime value) {
  return DateFormat('dd/MM/yyyy hh:mm a').format(value.toLocal());
}
