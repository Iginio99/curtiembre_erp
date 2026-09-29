import 'package:erp_curtiembre_fronted/core/di/service_locator.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_breakpoints.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';

import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_state.dart';

import 'package:erp_curtiembre_fronted/features/security/presentation/cubit/security_access_cubit.dart';

import 'package:erp_curtiembre_fronted/features/production/clientes/domain/entities/cliente_record.dart';
import 'package:erp_curtiembre_fronted/features/production/clientes/presentation/cubit/clientes_cubit.dart';
import 'package:erp_curtiembre_fronted/features/production/clientes/presentation/cubit/clientes_state.dart';
import 'package:erp_curtiembre_fronted/features/production/clientes/presentation/widgets/cliente_upsert_dialog.dart';

import 'package:erp_curtiembre_fronted/shared/widgets/buttons/app_button.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/feedback/app_message_card.dart';
import 'package:erp_curtiembre_fronted/shared/navigation/app_access_routes.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/layout/app_shell.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:talker_flutter/talker_flutter.dart';

class ClientesPage extends StatefulWidget {
  const ClientesPage({
    super.key,
  });

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  final _searchController = TextEditingController();

  final Talker _talker = getIt<Talker>();

  @override
  void initState() {
    super.initState();

    _talker.ui(
      'Se abrio la pantalla de clientes de produccion.',
    );
  }

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  /*
  ════════════════════════════════════════════════
  BÚSQUEDA
  ════════════════════════════════════════════════
  */

  void _applySearch() {
    FocusScope.of(context).unfocus();

    _talker.ui(
      'Se aplico una busqueda en clientes con texto='
      '${_describeSearchTerm(_searchController.text)}.',
    );

    context.read<ClientesCubit>().load(
          searchTerm: _searchController.text.trim(),
        );
  }

  /*
  ════════════════════════════════════════════════
  NUEVO CLIENTE
  ════════════════════════════════════════════════
  */

  Future<void> _openCreateDialog(
    ClientesState state,
  ) async {
    _talker.ui(
      'Se abrio el dialogo para crear cliente.',
    );

    final payload =
        await showDialog<ClienteUpsertFormData>(
      context: context,
      builder: (_) => ClienteUpsertDialog(
        title: 'Nuevo cliente',
        submitLabel: 'Crear cliente',
        isSubmitting: state.isSubmittingAction,
      ),
    );

    if (payload == null || !mounted) {
      _talker.ui(
        'Se cerro el dialogo de creacion de cliente sin confirmar.',
        logLevel: LogLevel.debug,
      );

      return;
    }

    _talker.ui(
      'Se confirmo la creacion del cliente ${payload.razonSocial}.',
    );

    final result =
        await context.read<ClientesCubit>().createCliente(
              rucDocumento: payload.rucDocumento,
              razonSocial: payload.razonSocial,
              direccion: payload.direccion,
              celular: payload.celular,
              correo: payload.correo,
              contacto: payload.contacto,
            );

    if (!mounted) {
      return;
    }

    _showActionResult(result);
  }

  /*
  ════════════════════════════════════════════════
  EDITAR CLIENTE
  ════════════════════════════════════════════════
  */

  Future<void> _openEditDialog(
    ClientesState state,
    ClienteRecord cliente,
  ) async {
    _talker.ui(
      'Se abrio el dialogo para editar el cliente ${cliente.id}.',
    );

    final payload =
        await showDialog<ClienteUpsertFormData>(
      context: context,
      builder: (_) => ClienteUpsertDialog(
        title: 'Editar cliente',
        submitLabel: 'Guardar cambios',
        isSubmitting: state.isSubmittingAction,
        initialCliente: cliente,
      ),
    );

    if (payload == null || !mounted) {
      _talker.ui(
        'Se cerro la edicion del cliente ${cliente.id} sin confirmar.',
        logLevel: LogLevel.debug,
      );

      return;
    }

    _talker.ui(
      'Se confirmo la edicion del cliente '
      '${cliente.id} con razonSocial=${payload.razonSocial}.',
    );

    final result =
        await context.read<ClientesCubit>().updateSelectedCliente(
              rucDocumento: payload.rucDocumento,
              razonSocial: payload.razonSocial,
              direccion: payload.direccion,
              celular: payload.celular,
              correo: payload.correo,
              contacto: payload.contacto,
            );

    if (!mounted) {
      return;
    }

    _showActionResult(result);
  }

  /*
  ════════════════════════════════════════════════
  ACTIVAR / INACTIVAR
  ════════════════════════════════════════════════
  */

  Future<void> _toggleState(
    ClienteRecord cliente,
  ) async {
    _talker.ui(
      cliente.activo
          ? 'Se solicito inactivar el cliente ${cliente.id}.'
          : 'Se solicito activar el cliente ${cliente.id}.',
      logLevel: LogLevel.warning,
    );

    final result = await context
        .read<ClientesCubit>()
        .setSelectedClienteActive(
          !cliente.activo,
        );

    if (!mounted) {
      return;
    }

    _showActionResult(result);
  }

  /*
  ════════════════════════════════════════════════
  RESULTADO DE ACCIONES
  ════════════════════════════════════════════════
  */

  void _showActionResult(
    ClientesActionResult result,
  ) {
    _talker.ui(
      result.success
          ? 'Accion en clientes completada correctamente.'
          : 'La accion en clientes fallo: ${result.message}',
      logLevel:
          result.success ? LogLevel.debug : LogLevel.error,
    );

    final messenger =
        ScaffoldMessenger.of(context);

    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.message,
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            result.success ? null : const Color(0xFF8A2F22),
      ),
    );
  }

  String _describeSearchTerm(
    String value,
  ) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      return 'vacio';
    }

    return '${normalized.length} caracteres';
  }

  /*
  ════════════════════════════════════════════════
  BUILD
  ════════════════════════════════════════════════
  */

  @override
  Widget build(BuildContext context) {
    final session = context.select(
      (AuthCubit cubit) => cubit.state.session,
    );

    final isSigningOut = context.select(
      (AuthCubit cubit) =>
          cubit.state.status == AuthStatus.signingOut,
    );

    final permissionCodes = context.select(
      (SecurityAccessCubit cubit) =>
          cubit.state.snapshot?.userPermissionCodes
              .toSet() ??
          const <String>{},
    );

    if (session == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return AppShell(
      title: 'Clientes',
      currentPath: '/produccion/clientes',
      breadcrumbs: const [
        'Inicio',
        'Producción',
        'Clientes',
      ],
      userName: session.nombreCompleto,
      roleName: session.rolNombre,
      accessibleRoutes:
          AppAccessRoutes.forPermissions(
        permissionCodes,
      ),
      onSignOut: isSigningOut
          ? () {}
          : () =>
              context.read<AuthCubit>().signOut(),
      child: LayoutBuilder(
        builder: (
          context,
          constraints,
        ) {
          return Padding(
            padding: const EdgeInsets.all(
              AppSpacing.lg,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 1440,
                ),
                child: BlocBuilder<
                    ClientesCubit,
                    ClientesState>(
                  builder: (
                    context,
                    state,
                  ) {
                    /*
                    Desktop desde tablet grande.
                    */

                    final isWide =
                        MediaQuery.sizeOf(context).width >=
                            AppBreakpoints.tablet;

                    final compactHeight =
                        constraints.maxHeight < 860;

                    /*
                    Sincroniza el buscador con Cubit.
                    */

                    if (_searchController.text !=
                        state.searchTerm) {
                      _searchController.value =
                          TextEditingValue(
                        text: state.searchTerm,
                        selection:
                            TextSelection.collapsed(
                          offset:
                              state.searchTerm.length,
                        ),
                      );
                    }

                    /*
                    LISTADO
                    */

                    final listPanel =
                        _ClientesListPanel(
                      state: state,
                      onRetry: () => context
                          .read<ClientesCubit>()
                          .initialize(),
                      onSelectCliente:
                          (clienteId) {
                        _talker.ui(
                          'Se selecciono el cliente '
                          '$clienteId desde el listado.',
                          logLevel:
                              LogLevel.debug,
                        );

                        context
                            .read<ClientesCubit>()
                            .selectCliente(
                              clienteId,
                            );
                      },
                    );

                    /*
                    DETALLE
                    */

                    final detailPanel =
                        _ClienteDetailPanel(
                      state: state,
                      onRetry: () => context
                          .read<ClientesCubit>()
                          .retryDetail(),
                      onEdit:
                          state.selectedCliente == null
                              ? null
                              : () =>
                                  _openEditDialog(
                                    state,
                                    state.selectedCliente!,
                                  ),
                      onToggleState:
                          state.selectedCliente == null
                              ? null
                              : () => _toggleState(
                                    state.selectedCliente!,
                                  ),
                    );

                    /*
                    FILTROS
                    */

                    final filters =
                        _ClientesFiltersCard(
                      controller:
                          _searchController,
                      selectedFilter:
                          state.filter,
                      isLoading:
                          state.status ==
                              ClientesStatus.loading,
                      isSubmittingAction:
                          state.isSubmittingAction,
                      onSearch:
                          _applySearch,
                      onCreateCliente: () =>
                          _openCreateDialog(
                        state,
                      ),
                      onFilterChanged:
                          (filter) {
                        _talker.ui(
                          'Se cambio el filtro '
                          'de clientes a $filter.',
                          logLevel:
                              LogLevel.debug,
                        );

                        context
                            .read<ClientesCubit>()
                            .load(
                              filter:
                                  filter,
                            );
                      },
                    );

                    /*
                    PANTALLA BAJA
                    */

                    if (compactHeight) {
                      if (isWide) {
                        return SingleChildScrollView(
                          child: Column(
                            children: [
                              filters,

                              const Gap(
                                AppSpacing.md,
                              ),

                              SizedBox(
                                height: 610,
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .stretch,
                                  children: [
                                    Expanded(
                                      flex: 9,
                                      child:
                                          listPanel,
                                    ),

                                    const Gap(
                                      AppSpacing
                                          .md,
                                    ),

                                    Expanded(
                                      flex: 8,
                                      child:
                                          detailPanel,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            filters,

                            const Gap(
                              AppSpacing.md,
                            ),

                            SizedBox(
                              height: 520,
                              child:
                                  listPanel,
                            ),

                            const Gap(
                              AppSpacing.md,
                            ),

                            SizedBox(
                              height: 560,
                              child:
                                  detailPanel,
                            ),
                          ],
                        ),
                      );
                    }

                    /*
                    PANTALLA NORMAL
                    */

                    return Column(
                      children: [
                        filters,

                        const Gap(
                          AppSpacing.md,
                        ),

                        Expanded(
                          child: isWide
                              ? Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .stretch,
                                  children: [
                                    Expanded(
                                      flex: 9,
                                      child:
                                          listPanel,
                                    ),

                                    const Gap(
                                      AppSpacing
                                          .md,
                                    ),

                                    Expanded(
                                      flex: 8,
                                      child:
                                          detailPanel,
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    Expanded(
                                      child:
                                          listPanel,
                                    ),

                                    const Gap(
                                      AppSpacing
                                          .md,
                                    ),

                                    Expanded(
                                      child:
                                          detailPanel,
                                    ),
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

/*
══════════════════════════════════════════════════════════════
FILTROS SUPERIORES
══════════════════════════════════════════════════════════════
*/

class _ClientesFiltersCard extends StatelessWidget {
  const _ClientesFiltersCard({
    required this.controller,
    required this.selectedFilter,
    required this.isLoading,
    required this.isSubmittingAction,
    required this.onSearch,
    required this.onCreateCliente,
    required this.onFilterChanged,
  });

  final TextEditingController controller;

  final ClienteActivityFilter selectedFilter;

  final bool isLoading;

  final bool isSubmittingAction;

  final VoidCallback onSearch;

  final VoidCallback onCreateCliente;

  final ValueChanged<ClienteActivityFilter>
      onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context);

    return Container(
      width: double.infinity,

      /*
      Más compacto.
      */
      padding:
          const EdgeInsets.all(
        AppSpacing.md,
      ),

      decoration:
          BoxDecoration(
        color: theme
            .colorScheme
            .surface,

        borderRadius:
            BorderRadius.circular(
          12,
        ),

        border:
            Border.all(
          color: theme
              .colorScheme
              .outlineVariant,
        ),
      ),

      child: LayoutBuilder(
        builder: (
          context,
          constraints,
        ) {
          final search =
              TextField(
            controller:
                controller,

            textInputAction:
                TextInputAction
                    .search,

            onSubmitted: (_) =>
                onSearch(),

            decoration:
                const InputDecoration(
              hintText:
                  'Buscar por RUC, razón social o contacto...',

              prefixIcon:
                  Icon(
                Icons
                    .search_rounded,
                size: 18,
              ),
            ),
          );

          final filters =
              SegmentedButton<
                  ClienteActivityFilter>(
            showSelectedIcon:
                false,

            segments:
                const [
              /*
              Primero Todos.
              */
              ButtonSegment(
                value:
                    ClienteActivityFilter
                        .all,
                label:
                    Text('Todos'),
              ),

              ButtonSegment(
                value:
                    ClienteActivityFilter
                        .active,
                label:
                    Text('Activos'),
              ),

              ButtonSegment(
                value:
                    ClienteActivityFilter
                        .inactive,
                label:
                    Text('Inactivos'),
              ),
            ],

            selected: {
              selectedFilter,
            },

            onSelectionChanged:
                (selection) {
              if (selection
                  .isNotEmpty) {
                onFilterChanged(
                  selection.first,
                );
              }
            },
          );

          final createButton =
              FilledButton.icon(
            onPressed:
                isSubmittingAction
                    ? null
                    : onCreateCliente,

            icon:
                const Icon(
              Icons.add_rounded,
              size: 18,
            ),

            label:
                const Text(
              'Nuevo cliente',
            ),
          );

          /*
          DESKTOP
          */

          if (constraints
                  .maxWidth >=
              850) {
            return Row(
              children: [
                /*
                El buscador toma la mayor parte.
                */

                Expanded(
                  child: search,
                ),

                const Gap(
                  AppSpacing.md,
                ),

                filters,

                const Spacer(),

                createButton,
              ],
            );
          }

          /*
          MOBILE / TABLET
          */

          return Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .stretch,
            children: [
              search,

              const Gap(
                AppSpacing.sm,
              ),

              Wrap(
                spacing:
                    AppSpacing.sm,
                runSpacing:
                    AppSpacing.sm,
                crossAxisAlignment:
                    WrapCrossAlignment
                        .center,
                children: [
                  filters,
                  createButton,
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/*
══════════════════════════════════════════════════════════════
LISTADO
══════════════════════════════════════════════════════════════
*/

class _ClientesListPanel extends StatelessWidget {
  const _ClientesListPanel({
    required this.state,
    required this.onRetry,
    required this.onSelectCliente,
  });

  final ClientesState state;

  final VoidCallback onRetry;

  final ValueChanged<int>
      onSelectCliente;

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context);

    return Container(
      decoration:
          BoxDecoration(
        color: theme
            .colorScheme
            .surface,

        borderRadius:
            BorderRadius.circular(
          12,
        ),

        border:
            Border.all(
          color: theme
              .colorScheme
              .outlineVariant,
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          /*
          HEADER LISTADO
          */

          Padding(
            padding:
                const EdgeInsets
                    .fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),

            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        'Listado de clientes',
                        style: theme
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                          fontWeight:
                              FontWeight
                                  .w700,
                        ),
                      ),

                      const Gap(2),

                      Text(
                        '${state.items.length} '
                        '${state.items.length == 1 ? 'resultado' : 'resultados'}',
                        style: theme
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                          color: theme
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: theme
                .colorScheme
                .outlineVariant,
          ),

          /*
          LISTA
          */

          Expanded(
            child:
                switch (state.status) {
              ClientesStatus.loading =>
                const Center(
                  child:
                      CircularProgressIndicator(),
                ),

              ClientesStatus.error =>
                _CenteredMessage(
                  child: Column(
                    mainAxisSize:
                        MainAxisSize
                            .min,
                    children: [
                      AppMessageCard.error(
                        title:
                            'No pudimos cargar los clientes',
                        message: state
                                .errorMessage ??
                            'Intenta nuevamente para consultar la información comercial.',
                      ),

                      const Gap(
                        AppSpacing
                            .md,
                      ),

                      AppButton.secondary(
                        label:
                            'Reintentar',
                        icon: Icons
                            .refresh_rounded,
                        onPressed:
                            onRetry,
                      ),
                    ],
                  ),
                ),

              ClientesStatus.success =>
                state.items.isEmpty
                    ? const _CenteredMessage(
                        child:
                            AppMessageCard
                                .info(
                          title:
                              'Sin resultados',
                          message:
                              'No encontramos clientes con los filtros actuales.',
                        ),
                      )
                    : ListView.separated(
                        padding:
                            const EdgeInsets
                                .all(
                          AppSpacing
                              .md,
                        ),
                        itemCount:
                            state
                                .items
                                .length,
                        separatorBuilder:
                            (_, _) =>
                                const Gap(
                          AppSpacing
                              .sm,
                        ),
                        itemBuilder:
                            (
                          context,
                          index,
                        ) {
                          final item =
                              state
                                      .items[
                                  index];

                          return _ClienteListTileCard(
                            item:
                                item,
                            isSelected:
                                item.id ==
                                    state
                                        .selectedClienteId,
                            onTap: () =>
                                onSelectCliente(
                              item.id,
                            ),
                          );
                        },
                      ),
            },
          ),
        ],
      ),
    );
  }
}

/*
══════════════════════════════════════════════════════════════
TARJETA CLIENTE
══════════════════════════════════════════════════════════════
*/

class _ClienteListTileCard
    extends StatelessWidget {
  const _ClienteListTileCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final ClienteRecord item;

  final bool isSelected;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context);

    final trimmed =
        item.razonSocial.trim();

    final initial =
        trimmed.isNotEmpty
            ? trimmed[0].toUpperCase()
            : '?';

    return Material(
      color:
          Colors.transparent,

      child: InkWell(
        borderRadius:
            BorderRadius.circular(
          12,
        ),

        onTap: onTap,

        child: Ink(
          padding:
              const EdgeInsets.all(
            AppSpacing.md,
          ),

          decoration:
              BoxDecoration(
            color: isSelected
                ? theme
                    .colorScheme
                    .primaryContainer
                    .withValues(
                      alpha: .32,
                    )
                : theme
                    .colorScheme
                    .surfaceContainerLowest,

            borderRadius:
                BorderRadius.circular(
              12,
            ),

            border:
                Border.all(
              color: isSelected
                  ? theme
                      .colorScheme
                      .primary
                      .withValues(
                        alpha: .55,
                      )
                  : theme
                      .colorScheme
                      .outlineVariant,
              width:
                  isSelected
                      ? 1.2
                      : 1,
            ),
          ),

          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.center,
            children: [
              /*
              AVATAR
              */

              Container(
                width: 44,
                height: 44,

                alignment:
                    Alignment.center,

                decoration:
                    BoxDecoration(
                  color: isSelected
                      ? theme
                          .colorScheme
                          .primaryContainer
                      : theme
                          .colorScheme
                          .surfaceContainerHighest,

                  shape:
                      BoxShape.circle,
                ),

                child: Text(
                  initial,
                  style: theme
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                    fontWeight:
                        FontWeight
                            .w800,

                    color: isSelected
                        ? theme
                            .colorScheme
                            .primary
                        : theme
                            .colorScheme
                            .onSurfaceVariant,
                  ),
                ),
              ),

              const Gap(
                AppSpacing.md,
              ),

              /*
              DATOS
              */

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.razonSocial,

                            maxLines: 1,

                            overflow:
                                TextOverflow
                                    .ellipsis,

                            style: theme
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                              fontWeight:
                                  FontWeight
                                      .w700,
                            ),
                          ),
                        ),

                        const Gap(
                          AppSpacing
                              .sm,
                        ),

                        _MiniPill(
                          label:
                              item.activo
                                  ? 'Activo'
                                  : 'Inactivo',

                          background:
                              item.activo
                                  ? const Color(
                                      0xFFE3F5E5,
                                    )
                                  : theme
                                      .colorScheme
                                      .surfaceContainerHighest,

                          foreground:
                              item.activo
                                  ? const Color(
                                      0xFF2E7D32,
                                    )
                                  : theme
                                      .colorScheme
                                      .onSurfaceVariant,
                        ),
                      ],
                    ),

                    const Gap(3),

                    Text(
                      item.rucDocumento,

                      style: theme
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                        color: theme
                            .colorScheme
                            .primary,

                        fontWeight:
                            FontWeight
                                .w600,
                      ),
                    ),

                    const Gap(3),

                    Text(
                      item.contacto ??
                          item.correo ??
                          'Sin contacto registrado',

                      maxLines: 1,

                      overflow:
                          TextOverflow
                              .ellipsis,

                      style: theme
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                        color: theme
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/*
══════════════════════════════════════════════════════════════
PANEL DETALLE
══════════════════════════════════════════════════════════════
*/

class _ClienteDetailPanel
    extends StatelessWidget {
  const _ClienteDetailPanel({
    required this.state,
    required this.onRetry,
    required this.onEdit,
    required this.onToggleState,
  });

  final ClientesState state;

  final VoidCallback onRetry;

  final VoidCallback? onEdit;

  final VoidCallback? onToggleState;

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context);

    final cliente =
        state.selectedCliente;

    return Container(
      decoration:
          BoxDecoration(
        color: theme
            .colorScheme
            .surface,

        borderRadius:
            BorderRadius.circular(
          12,
        ),

        border:
            Border.all(
          color: theme
              .colorScheme
              .outlineVariant,
        ),
      ),

      child: Builder(
        builder: (
          context,
        ) {
          /*
          LOADING
          */

          if (state
              .isDetailLoading) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          /*
          ERROR
          */

          if (state
                  .detailErrorMessage !=
              null) {
            return _CenteredMessage(
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  AppMessageCard.error(
                    title:
                        'No pudimos cargar el detalle',
                    message: state
                        .detailErrorMessage!,
                  ),

                  const Gap(
                    AppSpacing.md,
                  ),

                  AppButton.secondary(
                    label:
                        'Reintentar detalle',
                    icon: Icons
                        .refresh_rounded,
                    onPressed:
                        onRetry,
                  ),
                ],
              ),
            );
          }

          /*
          SIN SELECCIÓN
          */

          if (cliente == null) {
            return const _CenteredMessage(
              child:
                  AppMessageCard.info(
                title:
                    'Selecciona un cliente',
                message:
                    'Escoge un registro del listado para revisar su información.',
              ),
            );
          }

          /*
          DETALLE
          */

          final trimmed =
              cliente.razonSocial.trim();

          final initial =
              trimmed.isNotEmpty
                  ? trimmed[0]
                      .toUpperCase()
                  : '?';

          return SingleChildScrollView(
            padding:
                const EdgeInsets.all(
              AppSpacing.lg,
            ),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                /*
                ═══════════════════════
                CABECERA
                ═══════════════════════
                */

                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    /*
                    AVATAR
                    */

                    Container(
                      width: 46,
                      height: 46,

                      alignment:
                          Alignment
                              .center,

                      decoration:
                          BoxDecoration(
                        color: theme
                            .colorScheme
                            .primaryContainer,

                        shape:
                            BoxShape.circle,
                      ),

                      child: Text(
                        initial,

                        style: theme
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                          color: theme
                              .colorScheme
                              .primary,

                          fontWeight:
                              FontWeight
                                  .w800,
                        ),
                      ),
                    ),

                    const Gap(
                      AppSpacing.md,
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Wrap(
                            spacing:
                                AppSpacing
                                    .sm,

                            runSpacing:
                                AppSpacing
                                    .xs,

                            crossAxisAlignment:
                                WrapCrossAlignment
                                    .center,

                            children: [
                              Text(
                                cliente
                                    .razonSocial,

                                style: theme
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                  fontWeight:
                                      FontWeight
                                          .w700,
                                ),
                              ),

                              _MiniPill(
                                label: cliente
                                        .activo
                                    ? 'Activo'
                                    : 'Inactivo',

                                background:
                                    cliente
                                            .activo
                                        ? const Color(
                                            0xFFE3F5E5,
                                          )
                                        : theme
                                            .colorScheme
                                            .surfaceContainerHighest,

                                foreground:
                                    cliente
                                            .activo
                                        ? const Color(
                                            0xFF2E7D32,
                                          )
                                        : theme
                                            .colorScheme
                                            .onSurfaceVariant,
                              ),
                            ],
                          ),

                          const Gap(3),

                          Text(
                            cliente
                                .rucDocumento,

                            style: theme
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                              color: theme
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Gap(
                      AppSpacing.sm,
                    ),

                    OutlinedButton.icon(
                      onPressed:
                          state
                                  .isSubmittingAction
                              ? null
                              : onEdit,

                      icon:
                          const Icon(
                        Icons
                            .edit_outlined,
                        size: 17,
                      ),

                      label:
                          const Text(
                        'Editar',
                      ),
                    ),
                  ],
                ),

                const Gap(
                  AppSpacing.lg,
                ),

                Divider(
                  height: 1,
                  color: theme
                      .colorScheme
                      .outlineVariant,
                ),

                const Gap(
                  AppSpacing.md,
                ),

                /*
                ═══════════════════════
                INFORMACIÓN COMERCIAL
                ═══════════════════════
                */

                Text(
                  'Información comercial',

                  style: theme
                      .textTheme
                      .titleSmall
                      ?.copyWith(
                    fontWeight:
                        FontWeight
                            .w700,
                  ),
                ),

                const Gap(
                  AppSpacing.md,
                ),

                _ClienteDetailRow(
                  label:
                      'RUC / documento',
                  value: cliente
                      .rucDocumento,
                ),

                _ClienteDetailRow(
                  label:
                      'Contacto',
                  value:
                      cliente.contacto ??
                          'Sin contacto',
                ),

                _ClienteDetailRow(
                  label:
                      'Celular',
                  value:
                      cliente.celular ??
                          'Sin celular',
                ),

                _ClienteDetailRow(
                  label:
                      'Correo',
                  value:
                      cliente.correo ??
                          'Sin correo',
                ),

                _ClienteDetailRow(
                  label:
                      'Dirección',
                  value:
                      cliente.direccion ??
                          'Sin dirección',
                ),

                const Gap(
                  AppSpacing.md,
                ),

                Divider(
                  height: 1,
                  color: theme
                      .colorScheme
                      .outlineVariant,
                ),

                const Gap(
                  AppSpacing.md,
                ),

                /*
                ═══════════════════════
                TRAZABILIDAD
                ═══════════════════════
                */

                Text(
                  'Trazabilidad',

                  style: theme
                      .textTheme
                      .titleSmall
                      ?.copyWith(
                    fontWeight:
                        FontWeight
                            .w700,
                  ),
                ),

                const Gap(
                  AppSpacing.md,
                ),

                _ClienteDetailRow(
                  label:
                      'ID interno',
                  value:
                      '${cliente.id}',
                ),

                _ClienteDetailRow(
                  label:
                      'Creado',
                  value:
                      _formatDateTime(
                    cliente.creadoEn,
                  ),
                ),

                _ClienteDetailRow(
                  label:
                      'Actualizado',
                  value:
                      _formatOptionalDate(
                    cliente
                        .actualizadoEn,
                  ),
                ),

                const Gap(
                  AppSpacing.lg,
                ),

                /*
                ═══════════════════════
                ACCIONES
                ═══════════════════════
                */

                Align(
                  alignment:
                      Alignment
                          .centerRight,

                  child:
                      OutlinedButton.icon(
                    onPressed: state
                            .isSubmittingAction
                        ? null
                        : onToggleState,

                    icon:
                        Icon(
                      cliente.activo
                          ? Icons
                              .block_outlined
                          : Icons
                              .check_circle_outline,

                      size: 17,
                    ),

                    label:
                        Text(
                      cliente.activo
                          ? 'Inactivar cliente'
                          : 'Activar cliente',
                    ),

                    style:
                        OutlinedButton
                            .styleFrom(
                      foregroundColor:
                          cliente.activo
                              ? theme
                                  .colorScheme
                                  .error
                              : const Color(
                                  0xFF2E7D32,
                                ),

                      side:
                          BorderSide(
                        color: cliente
                                .activo
                            ? theme
                                .colorScheme
                                .error
                                .withValues(
                                  alpha:
                                      .45,
                                )
                            : const Color(
                                0xFF77B77B,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/*
══════════════════════════════════════════════════════════════
FILA DE DETALLE
══════════════════════════════════════════════════════════════
*/

class _ClienteDetailRow
    extends StatelessWidget {
  const _ClienteDetailRow({
    required this.label,
    required this.value,
  });

  final String label;

  final String value;

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context);

    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 6,
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,

            child: Text(
              label,

              style: theme
                  .textTheme
                  .bodySmall
                  ?.copyWith(
                color: theme
                    .colorScheme
                    .onSurfaceVariant,
              ),
            ),
          ),

          const Gap(
            AppSpacing.md,
          ),

          Expanded(
            child: Text(
              value,

              style: theme
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                fontWeight:
                    FontWeight
                        .w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/*
══════════════════════════════════════════════════════════════
BADGE MINI
══════════════════════════════════════════════════════════════
*/

class _MiniPill
    extends StatelessWidget {
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
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 4,
      ),

      decoration:
          BoxDecoration(
        color: background,

        borderRadius:
            BorderRadius.circular(
          999,
        ),
      ),

      child: Text(
        label,

        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(
          color: foreground,

          fontWeight:
              FontWeight.w700,
        ),
      ),
    );
  }
}

/*
══════════════════════════════════════════════════════════════
MENSAJES CENTRADOS
══════════════════════════════════════════════════════════════
*/

class _CenteredMessage
    extends StatelessWidget {
  const _CenteredMessage({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(
          maxWidth: 520,
        ),

        child: child,
      ),
    );
  }
}

/*
══════════════════════════════════════════════════════════════
FECHAS
══════════════════════════════════════════════════════════════
*/

String _formatOptionalDate(
  DateTime? value,
) {
  if (value == null) {
    return 'Sin registro';
  }

  return _formatDateTime(
    value,
  );
}

String _formatDateTime(
  DateTime value,
) {
  return DateFormat(
    'dd/MM/yyyy HH:mm',
  ).format(
    value.toLocal(),
  );
}