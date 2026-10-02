import 'dart:async';
import 'dart:math' as math;

import 'package:erp_curtiembre_fronted/core/di/service_locator.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';

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

import 'package:erp_curtiembre_fronted/shared/navigation/app_access_routes.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/layout/app_shell.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:talker_flutter/talker_flutter.dart';

// ============================================================
// PALETA DEL MODULO
// ============================================================

const Color _accent = Color(0xFFE8590C);
const Color _accentSoft = Color(0xFFFFEADF);

const Color _green = Color(0xFF138653);
const Color _greenSoft = Color(0xFFE0F6EC);

const Color _amber = Color(0xFF93620B);
const Color _amberSoft = Color(0xFFFFEBC5);

// ============================================================
// PAGINA PRINCIPAL
// ============================================================

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final TextEditingController _searchController = TextEditingController();

  final Talker _talker = getIt<Talker>();

  Timer? _searchDebounce;

  String? _selectedRole;
  String? _selectedArea;

  int _page = 0;

  static const int _pageSize = 6;

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

  // ==========================================================
  // BUSQUEDA INCREMENTAL
  // ==========================================================

  void _searchAsYouType(String value) {
    _searchDebounce?.cancel();

    setState(() {
      _page = 0;
    });

    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;

      final term = value.trim();

      final cubit = context.read<UsersCubit>();

      if (term == cubit.state.searchTerm) {
        return;
      }

      cubit.load(searchTerm: term);
    });
  }

  void _applySearch() {
    _searchDebounce?.cancel();

    if (!mounted) return;

    setState(() {
      _page = 0;
    });

    context.read<UsersCubit>().load(searchTerm: _searchController.text.trim());
  }

  void _clearSearch() {
    _searchController.clear();
    _searchAsYouType('');
  }

  // ==========================================================
  // CREAR USUARIO
  // ==========================================================

  Future<void> _openCreateUserDialog(UsersState state) async {
    if (state.isSubmittingAction) return;

    _talker.ui('Se abrio el formulario de nuevo usuario.');

    final payload = await showDialog<UserUpsertFormData>(
      context: context,
      builder: (_) => UserUpsertDialog(
        title: 'Nuevo usuario',
        submitLabel: 'Crear usuario',
        roles: state.roles,
        areas: state.areas,
        isSubmitting: state.isSubmittingAction,
      ),
    );

    if (payload == null || !mounted) return;

    final result = await context.read<UsersCubit>().createUser(
      dni: payload.dni,
      nombres: payload.nombres,
      apellidos: payload.apellidos,
      userName: payload.userName,
      rolId: payload.rolId,
      areaId: payload.areaId,
      passwordTemporal: payload.passwordTemporal,
    );

    if (!mounted) return;

    await _handleActionResult(result, successTitle: 'Usuario creado');
  }

  // ==========================================================
  // EDITAR USUARIO
  // ==========================================================

  Future<void> _openEditUserDialog(UsersState state, UserDetail detail) async {
    if (state.isSubmittingAction) return;

    _talker.ui('Se abrio la edicion del usuario ${detail.usuarioId}.');

    final payload = await showDialog<UserUpsertFormData>(
      context: context,
      builder: (_) => UserUpsertDialog(
        title: 'Editar usuario',
        submitLabel: 'Guardar cambios',
        roles: state.roles,
        areas: state.areas,
        isSubmitting: state.isSubmittingAction,
        initialUser: detail,
      ),
    );

    if (payload == null || !mounted) return;

    final result = await context.read<UsersCubit>().updateSelectedUser(
      dni: payload.dni,
      nombres: payload.nombres,
      apellidos: payload.apellidos,
      userName: payload.userName,
      rolId: payload.rolId,
      areaId: payload.areaId,
    );

    if (!mounted) return;

    await _handleActionResult(
      result,
      successTitle: 'Usuario actualizado',
      useDialogForSuccess: false,
    );
  }

  // ==========================================================
  // RESETEAR CONTRASEÑA
  // ==========================================================

  Future<void> _openResetPasswordDialog(UserDetail detail) async {
    if (context.read<UsersCubit>().state.isSubmittingAction) {
      return;
    }

    _talker.ui(
      'Se solicito resetear la contraseña del usuario '
      '${detail.usuarioId}.',
      logLevel: LogLevel.warning,
    );

    final resultDialog = await showDialog<UserPasswordResetDialogResult>(
      context: context,
      builder: (_) => UserPasswordResetDialog(
        userName: detail.userName,
        isSubmitting: false,
      ),
    );

    if (resultDialog == null || !mounted) return;

    final result = await context.read<UsersCubit>().resetPassword(
      usuarioId: detail.usuarioId,
      passwordTemporal: resultDialog.passwordTemporal,
    );

    if (!mounted) return;

    await _handleActionResult(
      result,
      successTitle: 'Contraseña restablecida',
      useDialogForSuccess: true,
    );
  }

  // ==========================================================
  // ACTIVAR / DESACTIVAR
  // ==========================================================

  Future<void> _openStateChangeDialog({
    required UserDetail detail,
    required bool activate,
  }) async {
    if (context.read<UsersCubit>().state.isSubmittingAction) {
      return;
    }

    _talker.ui(
      'Se solicito cambiar el estado del usuario '
      '${detail.usuarioId}.',
      logLevel: LogLevel.warning,
    );

    final resultDialog = await showDialog<UserStateChangeDialogResult>(
      context: context,
      builder: (_) => UserStateChangeDialog(
        userName: detail.userName,
        activate: activate,
        isSubmitting: false,
      ),
    );

    if (resultDialog == null || !mounted) return;

    final result = await context.read<UsersCubit>().setUserActive(
      usuarioId: detail.usuarioId,
      active: activate,
      motivo: resultDialog.motivo,
    );

    if (!mounted) return;

    await _handleActionResult(
      result,
      successTitle: activate ? 'Usuario reactivado' : 'Usuario desactivado',
      useDialogForSuccess: false,
    );
  }

  // ==========================================================
  // RESULTADO DE OPERACIONES
  // ==========================================================

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

    if (!useDialogForSuccess) {
      _showSnackBar(result.message);
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final colors = Theme.of(dialogContext).colorScheme;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: _green),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  successTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(result.message),

              if (result.passwordTemporal != null) ...[
                const Gap(14),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contraseña temporal',
                        style: TextStyle(
                          color: colors.onPrimaryContainer,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        result.passwordTemporal!,
                        style: TextStyle(
                          color: colors.onPrimaryContainer,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
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

  // ==========================================================
  // SELECCIONAR USUARIO
  // ==========================================================

  void _selectUser(int usuarioId, {required bool openMobileDetail}) {
    _talker.ui(
      'Se selecciono el usuario $usuarioId.',
      logLevel: LogLevel.debug,
    );

    context.read<UsersCubit>().selectUser(usuarioId);

    if (!openMobileDetail) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) {
        return BlocProvider.value(
          value: context.read<UsersCubit>(),
          child: _MobileUserDetailSheet(
            onEditUser: () {
              final state = context.read<UsersCubit>().state;
              final detail = state.selectedUserDetail;

              if (detail == null) return;

              Navigator.of(context).pop();

              _openEditUserDialog(state, detail);
            },
            onResetPassword: () {
              final detail = context
                  .read<UsersCubit>()
                  .state
                  .selectedUserDetail;

              if (detail == null) return;

              Navigator.of(context).pop();

              _openResetPasswordDialog(detail);
            },
            onToggleState: () {
              final detail = context
                  .read<UsersCubit>()
                  .state
                  .selectedUserDetail;

              if (detail == null) return;

              Navigator.of(context).pop();

              _openStateChangeDialog(detail: detail, activate: !detail.activo);
            },
          ),
        );
      },
    );
  }

  // ==========================================================
  // VISTA PRINCIPAL
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final session = context.select((AuthCubit cubit) => cubit.state.session);

    final signingOut = context.select(
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
      onSignOut: signingOut ? () {} : () => context.read<AuthCubit>().signOut(),
      child: BlocBuilder<UsersCubit, UsersState>(
        builder: (context, state) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;

              final sideBySide = constraints.maxWidth >= 1050;

              // Se obtienen los roles y áreas reales del
              // listado recibido, sin alterar el backend.

              final roleOptions =
                  state.items
                      .map((item) => item.rolNombre.trim())
                      .where((value) => value.isNotEmpty)
                      .toSet()
                      .toList()
                    ..sort();

              final areaOptions =
                  state.items
                      .map((item) => item.areaNombre?.trim() ?? 'Sin área')
                      .toSet()
                      .toList()
                    ..sort();

              final filteredItems = state.items
                  .where((item) {
                    final roleMatches =
                        _selectedRole == null ||
                        item.rolNombre == _selectedRole;

                    final areaMatches =
                        _selectedArea == null ||
                        (item.areaNombre?.trim() ?? 'Sin área') ==
                            _selectedArea;

                    return roleMatches && areaMatches;
                  })
                  .toList(growable: false);

              final total = filteredItems.length;

              final totalPages = math.max(1, (total / _pageSize).ceil());

              final currentPage = _page.clamp(0, totalPages - 1).toInt();

              final start = currentPage * _pageSize;

              final end = math.min(start + _pageSize, total);

              final visibleItems = filteredItems.sublist(start, end);

              // ------------------------------------------
              // LISTADO
              // ------------------------------------------

              final listPanel = _UsersListPanel(
                state: state,
                items: visibleItems,
                total: total,
                start: start,
                end: end,
                currentPage: currentPage,
                totalPages: totalPages,
                compact: compact,
                onRetry: () => context.read<UsersCubit>().initialize(),
                onRefresh: () => context.read<UsersCubit>().load(),
                onSelectUser: (id) =>
                    _selectUser(id, openMobileDetail: compact),
                onPageChanged: (value) {
                  setState(() {
                    _page = value;
                  });
                },
              );

              // ------------------------------------------
              // DETALLE
              // ------------------------------------------

              final selectedDetail = state.selectedUserDetail;

              final busy = state.isSubmittingAction;

              final detailPanel = _UserDetailPanel(
                state: state,
                onRetry: () => context.read<UsersCubit>().retryDetail(),
                onEditUser: selectedDetail == null || busy
                    ? null
                    : () => _openEditUserDialog(state, selectedDetail),
                onResetPassword: selectedDetail == null || busy
                    ? null
                    : () => _openResetPasswordDialog(selectedDetail),
                onToggleState: selectedDetail == null || busy
                    ? null
                    : () => _openStateChangeDialog(
                        detail: selectedDetail,
                        activate: !selectedDetail.activo,
                      ),
              );

              return Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 12 : 18,
                  14,
                  compact ? 12 : 18,
                  16,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ==================================
                        // FILTROS
                        // ==================================
                        _UsersFiltersCard(
                          controller: _searchController,
                          selectedFilter: state.filter,
                          selectedRole: _selectedRole,
                          selectedArea: _selectedArea,
                          roles: roleOptions,
                          areas: areaOptions,
                          isLoading: state.status == UsersStatus.loading,
                          isSubmittingAction: state.isSubmittingAction,
                          onSearchChanged: _searchAsYouType,
                          onSearch: _applySearch,
                          onClearSearch: _clearSearch,
                          onCreateUser: () => _openCreateUserDialog(state),
                          onFilterChanged: (filter) {
                            setState(() => _page = 0);

                            context.read<UsersCubit>().load(filter: filter);
                          },
                          onRoleChanged: (value) {
                            setState(() {
                              _selectedRole = value;
                              _page = 0;
                            });
                          },
                          onAreaChanged: (value) {
                            setState(() {
                              _selectedArea = value;
                              _page = 0;
                            });
                          },
                        ),

                        const SizedBox(height: 14),

                        // ==================================
                        // LISTA + DETALLE
                        // ==================================
                        Expanded(
                          child: sideBySide
                              ? Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(flex: 10, child: listPanel),
                                    const SizedBox(width: 14),
                                    Expanded(flex: 10, child: detailPanel),
                                  ],
                                )
                              : compact
                              ? listPanel
                              : SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      SizedBox(height: 500, child: listPanel),
                                      const SizedBox(height: 14),
                                      SizedBox(height: 620, child: detailPanel),
                                    ],
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ============================================================
// FILTROS SUPERIORES
// ============================================================

class _UsersFiltersCard extends StatelessWidget {
  const _UsersFiltersCard({
    required this.controller,
    required this.selectedFilter,
    required this.selectedRole,
    required this.selectedArea,
    required this.roles,
    required this.areas,
    required this.isLoading,
    required this.isSubmittingAction,
    required this.onSearchChanged,
    required this.onSearch,
    required this.onClearSearch,
    required this.onCreateUser,
    required this.onFilterChanged,
    required this.onRoleChanged,
    required this.onAreaChanged,
  });

  final TextEditingController controller;

  final UserActivityFilter selectedFilter;

  final String? selectedRole;
  final String? selectedArea;

  final List<String> roles;
  final List<String> areas;

  final bool isLoading;
  final bool isSubmittingAction;

  final ValueChanged<String> onSearchChanged;

  final VoidCallback onSearch;
  final VoidCallback onClearSearch;
  final VoidCallback onCreateUser;

  final ValueChanged<UserActivityFilter> onFilterChanged;
  final ValueChanged<String?> onRoleChanged;
  final ValueChanged<String?> onAreaChanged;

  @override
  Widget build(BuildContext context) {
    // --------------------------------------------------------
    // BUSCADOR
    // --------------------------------------------------------

    final search = TextField(
      controller: controller,
      onChanged: onSearchChanged,
      onSubmitted: (_) => onSearch(),
      textInputAction: TextInputAction.search,
      decoration:
          _inputDecoration(
            context,
            hint: 'Buscar por nombre, usuario, DNI, rol o área...',
            icon: Icons.search_rounded,
          ).copyWith(
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (controller.text.isNotEmpty)
                  IconButton(
                    tooltip: 'Limpiar búsqueda',
                    onPressed: onClearSearch,
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),

                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  IconButton(
                    tooltip: 'Aplicar búsqueda',
                    onPressed: onSearch,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 19),
                  ),
              ],
            ),
          ),
    );

    // --------------------------------------------------------
    // ESTADO
    // --------------------------------------------------------

    final statusFilter = DropdownMenu<UserActivityFilter>(
      key: ValueKey('user-status-${selectedFilter.name}'),
      width: 180,
      menuHeight: 220,
      label: const Text('Estado'),
      initialSelection: selectedFilter,
      inputDecorationTheme: _dropdownDecoration(context),
      dropdownMenuEntries: const [
        DropdownMenuEntry(value: UserActivityFilter.all, label: 'Todos'),
        DropdownMenuEntry(value: UserActivityFilter.active, label: 'Activos'),
        DropdownMenuEntry(
          value: UserActivityFilter.inactive,
          label: 'Inactivos',
        ),
      ],
      onSelected: (value) {
        if (value != null) {
          onFilterChanged(value);
        }
      },
    );

    // --------------------------------------------------------
    // ROL BUSCABLE
    // --------------------------------------------------------

    final roleFilter = DropdownMenu<String>(
      key: ValueKey('user-role-${selectedRole ?? '__all__'}'),
      width: 190,
      menuHeight: 260,
      enableFilter: true,
      enableSearch: true,
      requestFocusOnTap: true,
      label: const Text('Rol'),
      initialSelection: selectedRole ?? '__all_roles__',
      inputDecorationTheme: _dropdownDecoration(context),
      dropdownMenuEntries: [
        const DropdownMenuEntry(value: '__all_roles__', label: 'Todos'),
        for (final role in roles) DropdownMenuEntry(value: role, label: role),
      ],
      onSelected: (value) {
        if (value == null) return;

        onRoleChanged(value == '__all_roles__' ? null : value);
      },
    );

    // --------------------------------------------------------
    // AREA BUSCABLE
    // --------------------------------------------------------

    final areaFilter = DropdownMenu<String>(
      key: ValueKey('user-area-${selectedArea ?? '__all__'}'),
      width: 190,
      menuHeight: 260,
      enableFilter: true,
      enableSearch: true,
      requestFocusOnTap: true,
      label: const Text('Área'),
      initialSelection: selectedArea ?? '__all_areas__',
      inputDecorationTheme: _dropdownDecoration(context),
      dropdownMenuEntries: [
        const DropdownMenuEntry(value: '__all_areas__', label: 'Todos'),
        for (final area in areas) DropdownMenuEntry(value: area, label: area),
      ],
      onSelected: (value) {
        if (value == null) return;

        onAreaChanged(value == '__all_areas__' ? null : value);
      },
    );

    // --------------------------------------------------------
    // NUEVO USUARIO
    // --------------------------------------------------------

    final createButton = FilledButton.icon(
      onPressed: isSubmittingAction ? null : onCreateUser,
      icon: const Icon(Icons.person_add_alt_1_rounded, size: 19),
      label: const Text('Nuevo usuario'),
      style: FilledButton.styleFrom(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
    );

    return _Surface(
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 1170) {
            return Row(
              children: [
                Expanded(child: search),
                const SizedBox(width: 10),
                statusFilter,
                const SizedBox(width: 10),
                roleFilter,
                const SizedBox(width: 10),
                areaFilter,
                const SizedBox(width: 10),
                createButton,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              search,
              const SizedBox(height: 11),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [statusFilter, roleFilter, areaFilter, createButton],
              ),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================
// LISTADO DE USUARIOS
// ============================================================

class _UsersListPanel extends StatelessWidget {
  const _UsersListPanel({
    required this.state,
    required this.items,
    required this.total,
    required this.start,
    required this.end,
    required this.currentPage,
    required this.totalPages,
    required this.compact,
    required this.onRetry,
    required this.onRefresh,
    required this.onSelectUser,
    required this.onPageChanged,
  });

  final UsersState state;
  final List<UserListItem> items;

  final int total;
  final int start;
  final int end;

  final int currentPage;
  final int totalPages;

  final bool compact;

  final VoidCallback onRetry;
  final VoidCallback onRefresh;

  final ValueChanged<int> onSelectUser;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return _Surface(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --------------------------------------------------
          // CABECERA
          // --------------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 16, 14, 13),
            child: Row(
              children: [
                const _SectionIcon(Icons.people_alt_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Listado de usuarios',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$total resultado(s) para la vista actual.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.outlined(
                  tooltip: 'Actualizar usuarios',
                  visualDensity: VisualDensity.compact,
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_rounded, size: 19),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: colors.outlineVariant),

          // --------------------------------------------------
          // RESULTADOS
          // --------------------------------------------------
          Expanded(
            child: switch (state.status) {
              UsersStatus.loading => const Center(
                child: CircularProgressIndicator(),
              ),

              UsersStatus.error => _EmptyMessage(
                icon: Icons.error_outline_rounded,
                title: 'No pudimos cargar la lista',
                description:
                    state.errorMessage ??
                    'Intenta nuevamente para consultar los usuarios.',
                onRetry: onRetry,
              ),

              UsersStatus.success =>
                total == 0
                    ? const _EmptyMessage(
                        icon: Icons.search_off_rounded,
                        title: 'Sin resultados',
                        description:
                            'No encontramos usuarios con los filtros actuales.',
                      )
                    : ListView.separated(
                        padding: EdgeInsets.all(compact ? 10 : 13),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 9),
                        itemBuilder: (context, index) {
                          final item = items[index];

                          return _UserListTileCard(
                            item: item,
                            isSelected: item.usuarioId == state.selectedUserId,
                            onTap: () => onSelectUser(item.usuarioId),
                          );
                        },
                      ),
            },
          ),

          Divider(height: 1, color: colors.outlineVariant),

          // --------------------------------------------------
          // PAGINACION
          // --------------------------------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    total == 0
                        ? '0 usuarios'
                        : 'Mostrando ${start + 1}–$end de $total usuarios',
                    style: TextStyle(
                      fontSize: 10.7,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),

                IconButton.outlined(
                  tooltip: 'Página anterior',
                  visualDensity: VisualDensity.compact,
                  onPressed: currentPage == 0
                      ? null
                      : () => onPageChanged(currentPage - 1),
                  icon: const Icon(Icons.chevron_left_rounded, size: 18),
                ),

                const SizedBox(width: 5),

                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${currentPage + 1}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                const SizedBox(width: 5),

                IconButton.outlined(
                  tooltip: 'Página siguiente',
                  visualDensity: VisualDensity.compact,
                  onPressed: currentPage + 1 >= totalPages
                      ? null
                      : () => onPageChanged(currentPage + 1),
                  icon: const Icon(Icons.chevron_right_rounded, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TARJETA DE USUARIO
// ============================================================

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
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: isSelected
                ? _accent.withValues(alpha: 0.075)
                : colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? _accent.withValues(alpha: 0.65)
                  : colors.outlineVariant,
              width: isSelected ? 1.2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _UserAvatar(
                name: item.nombreCompleto,
                size: 46,
                selected: isSelected,
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // NOMBRE Y ESTADO
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          item.nombreCompleto,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        _StatusPill(active: item.activo),

                        if (item.debeCambiarPassword)
                          const _SmallPill(
                            label: 'Cambio de clave',
                            background: _amberSoft,
                            foreground: _amber,
                            icon: Icons.key_outlined,
                          ),

                        if (item.rolNombre.toLowerCase().contains(
                          'administrador',
                        ))
                          _SmallPill(
                            label: item.rolNombre,
                            background: colors.surfaceContainerHigh,
                            foreground: colors.onSurface,
                            icon: Icons.admin_panel_settings_outlined,
                          ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    Text(
                      '@${item.userName}',
                      style: const TextStyle(
                        color: _accent,
                        fontSize: 12.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 11),

                    // IDENTIDAD Y ACCESO
                    Wrap(
                      spacing: 13,
                      runSpacing: 7,
                      children: [
                        _InlineInfo(
                          icon: Icons.badge_outlined,
                          value: 'DNI: ${item.dni}',
                        ),
                        _InlineInfo(
                          icon: Icons.business_outlined,
                          value: 'Área: ${item.areaNombre ?? 'Sin área'}',
                        ),
                        _InlineInfo(
                          icon: Icons.access_time_rounded,
                          value:
                              'Último acceso: ${_formatOptionalDate(item.ultimoLoginEn)}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 6),

              Icon(
                Icons.chevron_right_rounded,
                size: 21,
                color: isSelected ? _accent : colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// PANEL DE DETALLE
// ============================================================

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
    final colors = Theme.of(context).colorScheme;

    final detail = state.selectedUserDetail;

    return _Surface(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --------------------------------------------------
          // CABECERA
          // --------------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 12, 13),
            child: Row(
              children: [
                const _SectionIcon(Icons.person_outline_rounded),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detalle del usuario',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Identidad, rol, acceso y trazabilidad.',
                        style: TextStyle(
                          fontSize: 11.3,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: colors.outlineVariant),

          // --------------------------------------------------
          // CONTENIDO
          // --------------------------------------------------
          Expanded(
            child: Builder(
              builder: (context) {
                if (state.isDetailLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.detailErrorMessage != null) {
                  return _EmptyMessage(
                    icon: Icons.error_outline,
                    title: 'No pudimos cargar el detalle',
                    description: state.detailErrorMessage!,
                    onRetry: onRetry,
                  );
                }

                if (detail == null) {
                  return const _EmptyMessage(
                    icon: Icons.person_search_outlined,
                    title: 'Selecciona un usuario',
                    description:
                        'Escoge un registro del listado para consultar su información.',
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildUserContent(context, detail),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserContent(BuildContext context, UserDetail detail) {
    final colors = Theme.of(context).colorScheme;

    final busy = state.isSubmittingAction;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ====================================================
        // PERFIL SUPERIOR
        // ====================================================
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _UserAvatar(name: detail.nombreCompleto, size: 59, selected: true),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 9,
                    runSpacing: 5,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        detail.nombreCompleto,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      _StatusPill(active: detail.activo),
                    ],
                  ),

                  const SizedBox(height: 5),

                  Text(
                    '@${detail.userName}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: _accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  if (detail.debeCambiarPassword) ...[
                    const SizedBox(height: 8),
                    const _SmallPill(
                      label: 'Cambio de contraseña pendiente',
                      background: _amberSoft,
                      foreground: _amber,
                      icon: Icons.key_outlined,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 17),

        // ====================================================
        // ACCIONES
        // ====================================================
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: busy ? null : onEditUser,
              icon: const Icon(Icons.edit_outlined, size: 17),
              label: const Text('Editar usuario'),
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),

            OutlinedButton.icon(
              onPressed: busy ? null : onResetPassword,
              icon: const Icon(Icons.key_outlined, size: 17),
              label: const Text('Resetear contraseña'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.onSurface,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),

            OutlinedButton.icon(
              onPressed: busy ? null : onToggleState,
              icon: Icon(
                detail.activo
                    ? Icons.lock_outline_rounded
                    : Icons.lock_open_outlined,
                size: 17,
              ),
              label: Text(
                detail.activo ? 'Desactivar usuario' : 'Reactivar usuario',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.onSurface,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 19),

        // ====================================================
        // CUATRO BLOQUES DE INFORMACION
        // ====================================================
        LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth >= 500;

            final cards = [
              _UserInfoCard(
                icon: Icons.badge_outlined,
                title: 'Información de identidad',
                items: [
                  _InfoLine(label: 'DNI', value: detail.dni),
                  _InfoLine(label: 'Usuario ID', value: '${detail.usuarioId}'),
                  _InfoLine(
                    label: 'Usuario',
                    value: '@${detail.userName}',
                    highlight: true,
                  ),
                ],
              ),

              _UserInfoCard(
                icon: Icons.shield_outlined,
                title: 'Rol y permisos',
                items: [
                  _InfoLine(label: 'Rol', value: detail.rolNombre),
                  _InfoLine(label: 'Código de rol', value: detail.rolCodigo),
                  _InfoLine(
                    label: 'Área',
                    value: detail.areaNombre ?? 'Sin área',
                  ),
                ],
              ),

              _UserInfoCard(
                icon: Icons.power_settings_new_rounded,
                title: 'Estado de acceso',
                items: [
                  _InfoLine(
                    label: 'Estado',
                    value: detail.activo ? 'Activo' : 'Inactivo',
                    highlight: detail.activo,
                  ),
                  _InfoLine(
                    label: 'Intentos fallidos',
                    value: '${detail.intentosFallidos}',
                  ),
                  _InfoLine(
                    label: 'Bloqueado hasta',
                    value: _formatOptionalDate(detail.bloqueadoHasta),
                  ),
                  _InfoLine(
                    label: 'Cambio de clave',
                    value: detail.debeCambiarPassword
                        ? 'Pendiente'
                        : 'No pendiente',
                  ),
                ],
              ),

              _UserInfoCard(
                icon: Icons.history_rounded,
                title: 'Trazabilidad',
                items: [
                  _InfoLine(
                    label: 'Creado',
                    value: _formatDateTime(detail.creadoEn),
                  ),
                  _InfoLine(
                    label: 'Último login',
                    value: _formatOptionalDate(detail.ultimoLoginEn),
                  ),
                ],
              ),
            ];

            if (!twoColumns) {
              return Column(
                children: [
                  for (int i = 0; i < cards.length; i++) ...[
                    cards[i],
                    if (i < cards.length - 1) const SizedBox(height: 10),
                  ],
                ],
              );
            }

            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: cards[0]),
                    const SizedBox(width: 10),
                    Expanded(child: cards[1]),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: cards[2]),
                    const SizedBox(width: 10),
                    Expanded(child: cards[3]),
                  ],
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 14),

        // ====================================================
        // SEGURIDAD
        // ====================================================
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            children: [
              const Icon(Icons.security_rounded, color: _accent, size: 21),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Administración de acceso',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Los cambios de contraseña y estado requieren confirmación.',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// TARJETAS DE INFORMACION
// ============================================================

class _UserInfoCard extends StatelessWidget {
  const _UserInfoCard({
    required this.icon,
    required this.title,
    required this.items,
  });

  final IconData icon;
  final String title;
  final List<_InfoLine> items;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SectionIcon(icon, size: 30),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          for (int i = 0; i < items.length; i++) ...[
            items[i],
            if (i < items.length - 1) const SizedBox(height: 11),
          ],
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Text(
            label,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 10.8,
              height: 1.4,
            ),
          ),
        ),

        const SizedBox(width: 7),

        Expanded(
          flex: 6,
          child: Text(
            value,
            style: TextStyle(
              color: highlight ? _accent : colors.onSurface,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// DETALLE MOVIL
// ============================================================

class _MobileUserDetailSheet extends StatelessWidget {
  const _MobileUserDetailSheet({
    required this.onEditUser,
    required this.onResetPassword,
    required this.onToggleState,
  });

  final VoidCallback onEditUser;
  final VoidCallback onResetPassword;
  final VoidCallback onToggleState;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return FractionallySizedBox(
      heightFactor: 0.90,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: colors.outlineVariant,
                borderRadius: BorderRadius.circular(99),
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Detalle del usuario',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ),

                IconButton(
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Expanded(
              child: BlocBuilder<UsersCubit, UsersState>(
                builder: (context, state) {
                  return _UserDetailPanel(
                    state: state,
                    onRetry: () => context.read<UsersCubit>().retryDetail(),
                    onEditUser:
                        state.selectedUserDetail == null ||
                            state.isSubmittingAction
                        ? null
                        : onEditUser,
                    onResetPassword:
                        state.selectedUserDetail == null ||
                            state.isSubmittingAction
                        ? null
                        : onResetPassword,
                    onToggleState:
                        state.selectedUserDetail == null ||
                            state.isSubmittingAction
                        ? null
                        : onToggleState,
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

// ============================================================
// AVATAR
// ============================================================

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({
    required this.name,
    required this.size,
    this.selected = false,
  });

  final String name;
  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    final background = selected
        ? const Color(0xFFFFDDC7)
        : Theme.of(context).colorScheme.surfaceContainerHigh;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size * 0.35,
          fontWeight: FontWeight.w800,
          color: selected ? _accent : Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

// ============================================================
// INDICADORES DE ESTADO
// ============================================================

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final background = active ? _greenSoft : colors.surfaceContainerHighest;

    final foreground = active ? _green : colors.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: foreground,
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(width: 5),

          Text(
            active ? 'Activo' : 'Inactivo',
            style: TextStyle(
              fontSize: 10.5,
              color: foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallPill extends StatelessWidget {
  const _SmallPill({
    required this.label,
    required this.background,
    required this.foreground,
    required this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: foreground),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// COMPONENTES GENERALES
// ============================================================

class _Surface extends StatelessWidget {
  const _Surface({required this.child, required this.padding});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      clipBehavior: Clip.antiAlias,
      padding: padding,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: child,
    );
  }
}

class _SectionIcon extends StatelessWidget {
  const _SectionIcon(this.icon, {this.size = 34});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? _accent.withValues(alpha: 0.18)
            : _accentSoft,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, size: size * 0.54, color: _accent),
    );
  }
}

class _InlineInfo extends StatelessWidget {
  const _InlineInfo({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(value, style: TextStyle(fontSize: 10.5, color: color)),
      ],
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({
    required this.icon,
    required this.title,
    required this.description,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 37, color: colors.onSurfaceVariant),

            const SizedBox(height: 12),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),

            const SizedBox(height: 6),

            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: colors.onSurfaceVariant),
            ),

            if (onRetry != null) ...[
              const SizedBox(height: 13),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// DECORACION DE FILTROS
// ============================================================

InputDecoration _inputDecoration(
  BuildContext context, {
  required String hint,
  IconData? icon,
}) {
  final colors = Theme.of(context).colorScheme;

  return InputDecoration(
    isDense: true,
    hintText: hint,
    prefixIcon: icon == null
        ? null
        : Icon(icon, size: 19, color: colors.onSurfaceVariant),
    filled: true,
    fillColor: colors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: BorderSide(color: colors.outlineVariant),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: _accent, width: 1.5),
    ),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
  );
}

InputDecorationTheme _dropdownDecoration(BuildContext context) {
  final colors = Theme.of(context).colorScheme;

  return InputDecorationTheme(
    isDense: true,
    filled: true,
    fillColor: colors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 13),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: BorderSide(color: colors.outlineVariant),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: _accent, width: 1.4),
    ),
  );
}

// ============================================================
// FORMATO DE FECHAS
// ============================================================

String _formatOptionalDate(DateTime? value) {
  if (value == null) {
    return 'Sin registro';
  }

  return _formatDateTime(value);
}

String _formatDateTime(DateTime value) {
  return DateFormat('dd/MM/yyyy hh:mm a').format(value.toLocal());
}
