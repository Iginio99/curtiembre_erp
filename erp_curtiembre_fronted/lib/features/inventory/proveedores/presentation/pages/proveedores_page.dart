import 'package:erp_curtiembre_fronted/core/di/service_locator.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_breakpoints.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_state.dart';
import 'package:erp_curtiembre_fronted/features/inventory/proveedores/domain/entities/proveedor_record.dart';
import 'package:erp_curtiembre_fronted/features/inventory/proveedores/presentation/cubit/proveedores_cubit.dart';
import 'package:erp_curtiembre_fronted/features/inventory/proveedores/presentation/cubit/proveedores_state.dart';
import 'package:erp_curtiembre_fronted/features/inventory/proveedores/presentation/widgets/proveedor_upsert_dialog.dart';
import 'package:erp_curtiembre_fronted/features/security/presentation/cubit/security_access_cubit.dart';
import 'package:erp_curtiembre_fronted/shared/navigation/app_access_routes.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/buttons/app_button.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/feedback/app_message_card.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/layout/app_shell.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/layout/app_surface_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:talker_flutter/talker_flutter.dart';

class ProveedoresPage extends StatefulWidget {
  const ProveedoresPage({super.key});

  @override
  State<ProveedoresPage> createState() => _ProveedoresPageState();
}

class _ProveedoresPageState extends State<ProveedoresPage> {
  final _searchController = TextEditingController();
  final Talker _talker = getIt<Talker>();

  @override
  void initState() {
    super.initState();
    _talker.ui('Se abrio la pantalla de proveedores.');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applySearch() {
    FocusScope.of(context).unfocus();
    _talker.ui(
      'Se aplico la busqueda de proveedores con texto=${_describeText(_searchController.text)}.',
    );
    context.read<ProveedoresCubit>().load(
      searchTerm: _searchController.text.trim(),
    );
  }

  void _selectProveedor(int proveedorId, {required bool openMobileDetail}) {
    _talker.ui(
      'Se selecciono el proveedor $proveedorId desde el listado.',
      logLevel: LogLevel.debug,
    );
    context.read<ProveedoresCubit>().selectProveedor(proveedorId);

    if (!openMobileDetail) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BlocProvider.value(
        value: context.read<ProveedoresCubit>(),
        child: _MobileProveedorDetailSheet(
          onEdit: () {
            final state = context.read<ProveedoresCubit>().state;
            final proveedor = state.selectedProveedor;
            if (proveedor != null) _openEditDialog(state, proveedor);
          },
          onToggleState: () {
            final proveedor = context
                .read<ProveedoresCubit>()
                .state
                .selectedProveedor;
            if (proveedor != null) _toggleState(proveedor);
          },
        ),
      ),
    );
  }

  Future<void> _openCreateDialog(ProveedoresState state) async {
    _talker.ui('Se abrio el dialogo para crear un proveedor.');
    final payload = await showDialog<ProveedorUpsertFormData>(
      context: context,
      builder: (_) => ProveedorUpsertDialog(
        title: 'Nuevo proveedor',
        submitLabel: 'Crear proveedor',
        isSubmitting: state.isSubmittingAction,
      ),
    );

    if (payload == null || !mounted) return;

    final result = await context.read<ProveedoresCubit>().createProveedor(
      rucDocumento: payload.rucDocumento,
      razonSocial: payload.razonSocial,
      direccion: payload.direccion,
      telefono: payload.telefono,
      correo: payload.correo,
      contacto: payload.contacto,
    );

    if (mounted) _showActionResult(result);
  }

  Future<void> _openEditDialog(
    ProveedoresState state,
    ProveedorRecord proveedor,
  ) async {
    _talker.ui(
      'Se abrio el dialogo para editar el proveedor ${proveedor.id}.',
      logLevel: LogLevel.warning,
    );
    final payload = await showDialog<ProveedorUpsertFormData>(
      context: context,
      builder: (_) => ProveedorUpsertDialog(
        title: 'Editar proveedor',
        submitLabel: 'Guardar cambios',
        isSubmitting: state.isSubmittingAction,
        initialProveedor: proveedor,
      ),
    );

    if (payload == null || !mounted) return;

    final result = await context
        .read<ProveedoresCubit>()
        .updateSelectedProveedor(
          rucDocumento: payload.rucDocumento,
          razonSocial: payload.razonSocial,
          direccion: payload.direccion,
          telefono: payload.telefono,
          correo: payload.correo,
          contacto: payload.contacto,
        );

    if (mounted) _showActionResult(result);
  }

  Future<void> _toggleState(ProveedorRecord proveedor) async {
    _talker.ui(
      'Se solicito ${proveedor.activo ? 'inactivar' : 'activar'} el proveedor ${proveedor.id}.',
      logLevel: LogLevel.warning,
    );
    final result = await context
        .read<ProveedoresCubit>()
        .setSelectedProveedorActive(!proveedor.activo);

    if (mounted) _showActionResult(result);
  }

  void _showActionResult(ProveedoresActionResult result) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(result.message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: result.success ? null : const Color(0xFF8A2F22),
      ),
    );
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
      title: 'Proveedores',
      currentPath: '/inventario/proveedores',
      breadcrumbs: const ['Inicio', 'Inventario', 'Proveedores'],
      userName: session.nombreCompleto,
      roleName: session.rolNombre,
      accessibleRoutes: AppAccessRoutes.forPermissions(permissionCodes),
      onSignOut: isSigningOut
          ? () {}
          : () => context.read<AuthCubit>().signOut(),
      child: LayoutBuilder(
        builder: (context, constraints) => Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1440),
              child: BlocBuilder<ProveedoresCubit, ProveedoresState>(
                builder: (context, state) {
                  final isWide = constraints.maxWidth >= 1040;
                  final isMobile =
                      constraints.maxWidth < AppBreakpoints.mobileLarge;
                  final compactHeight = constraints.maxHeight < 860;

                  if (_searchController.text != state.searchTerm) {
                    _searchController.value = TextEditingValue(
                      text: state.searchTerm,
                      selection: TextSelection.collapsed(
                        offset: state.searchTerm.length,
                      ),
                    );
                  }

                  final listPanel = _ProveedoresListPanel(
                    state: state,
                    onRetry: () =>
                        context.read<ProveedoresCubit>().initialize(),
                    onSelectProveedor: (id) =>
                        _selectProveedor(id, openMobileDetail: isMobile),
                  );
                  final detailPanel = _ProveedorDetailPanel(
                    state: state,
                    onRetry: () =>
                        context.read<ProveedoresCubit>().retryDetail(),
                    onEdit: state.selectedProveedor == null
                        ? null
                        : () =>
                              _openEditDialog(state, state.selectedProveedor!),
                    onToggleState: state.selectedProveedor == null
                        ? null
                        : () => _toggleState(state.selectedProveedor!),
                  );
                  final headerAndFilters = <Widget>[
                    Text(
                      'Administra el catálogo de proveedores y sus datos de contacto para las compras.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Gap(AppSpacing.lg),
                    _ProveedoresFiltersCard(
                      state: state,
                      controller: _searchController,
                      isCompact: isMobile,
                      isLoading: state.status == ProveedoresStatus.loading,
                      isSubmittingAction: state.isSubmittingAction,
                      onSearch: _applySearch,
                      onCreateProveedor: () => _openCreateDialog(state),
                      onActivityFilterChanged: (filter) =>
                          context.read<ProveedoresCubit>().load(filter: filter),
                    ),
                    const Gap(AppSpacing.xl),
                  ];

                  if (compactHeight) {
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...headerAndFilters,
                          SizedBox(
                            height: isWide ? 620 : 560,
                            child: isWide
                                ? Row(
                                    children: [
                                      Expanded(flex: 9, child: listPanel),
                                      const Gap(AppSpacing.xl),
                                      Expanded(flex: 8, child: detailPanel),
                                    ],
                                  )
                                : listPanel,
                          ),
                          if (!isWide && !isMobile) ...[
                            const Gap(AppSpacing.xl),
                            SizedBox(height: 560, child: detailPanel),
                          ],
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
                            : isMobile
                            ? listPanel
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
        ),
      ),
    );
  }

  String _describeText(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty
        ? 'vacio'
        : '${normalized.length} caracteres';
  }
}

class _ProveedoresFiltersCard extends StatelessWidget {
  const _ProveedoresFiltersCard({
    required this.state,
    required this.controller,
    required this.isCompact,
    required this.isLoading,
    required this.isSubmittingAction,
    required this.onSearch,
    required this.onCreateProveedor,
    required this.onActivityFilterChanged,
  });

  final ProveedoresState state;
  final TextEditingController controller;
  final bool isCompact;
  final bool isLoading;
  final bool isSubmittingAction;
  final VoidCallback onSearch;
  final VoidCallback onCreateProveedor;
  final ValueChanged<ProveedorActivityFilter> onActivityFilterChanged;

  @override
  Widget build(BuildContext context) {
    final activityFilter = _ProveedorActivityFilter(
      value: state.filter,
      onChanged: onActivityFilterChanged,
    );
    final search = _ProveedoresSearchField(
      controller: controller,
      isLoading: isLoading,
      onSearch: onSearch,
    );

    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: isCompact
          ? Row(
              children: [
                Expanded(child: search),
                const Gap(AppSpacing.sm),
                IconButton.outlined(
                  tooltip: 'Filtros',
                  onPressed: () => _openFilters(context, activityFilter),
                  icon: const Icon(Icons.tune_rounded),
                ),
                const Gap(AppSpacing.xs),
                IconButton.filled(
                  tooltip: 'Nuevo proveedor',
                  onPressed: isSubmittingAction ? null : onCreateProveedor,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final action = FilledButton.icon(
                  onPressed: isSubmittingAction ? null : onCreateProveedor,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Nuevo proveedor'),
                );
                if (constraints.maxWidth >= 760) {
                  return Row(
                    children: [
                      Expanded(child: search),
                      const Gap(AppSpacing.md),
                      activityFilter,
                      const Gap(AppSpacing.md),
                      action,
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: search),
                        const Gap(AppSpacing.md),
                        action,
                      ],
                    ),
                    const Gap(AppSpacing.md),
                    activityFilter,
                  ],
                );
              },
            ),
    );
  }

  void _openFilters(BuildContext context, Widget activityFilter) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const Gap(AppSpacing.lg),
            Text('Filtros', style: Theme.of(context).textTheme.titleLarge),
            const Gap(AppSpacing.lg),
            Text('Estado', style: Theme.of(context).textTheme.labelLarge),
            const Gap(AppSpacing.sm),
            SizedBox(width: double.infinity, child: activityFilter),
          ],
        ),
      ),
    );
  }
}

class _ProveedorActivityFilter extends StatelessWidget {
  const _ProveedorActivityFilter({
    required this.value,
    required this.onChanged,
  });

  final ProveedorActivityFilter value;
  final ValueChanged<ProveedorActivityFilter> onChanged;

  @override
  Widget build(BuildContext context) =>
      SegmentedButton<ProveedorActivityFilter>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(
            value: ProveedorActivityFilter.active,
            label: Text('Activos'),
          ),
          ButtonSegment(
            value: ProveedorActivityFilter.inactive,
            label: Text('Inactivos'),
          ),
          ButtonSegment(
            value: ProveedorActivityFilter.all,
            label: Text('Todos'),
          ),
        ],
        selected: {value},
        onSelectionChanged: (selection) {
          final selected = selection.firstOrNull;
          if (selected != null) onChanged(selected);
        },
      );
}

class _ProveedoresSearchField extends StatelessWidget {
  const _ProveedoresSearchField({
    required this.controller,
    required this.isLoading,
    required this.onSearch,
  });

  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    textInputAction: TextInputAction.search,
    onSubmitted: (_) => onSearch(),
    decoration: InputDecoration(
      isDense: true,
      hintText: 'Buscar por RUC, razón social o contacto...',
      prefixIcon: const Icon(Icons.search_rounded),
      suffixIcon: isLoading
          ? const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : IconButton(
              tooltip: 'Aplicar búsqueda',
              onPressed: onSearch,
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
    ),
  );
}

class _ProveedoresListPanel extends StatelessWidget {
  const _ProveedoresListPanel({
    required this.state,
    required this.onRetry,
    required this.onSelectProveedor,
  });

  final ProveedoresState state;
  final VoidCallback onRetry;
  final ValueChanged<int> onSelectProveedor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                Text('Resultados', style: theme.textTheme.titleMedium),
                const Spacer(),
                Text(
                  '${state.items.length}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: switch (state.status) {
              ProveedoresStatus.loading => const Center(
                child: CircularProgressIndicator(),
              ),
              ProveedoresStatus.error => _CenteredMessage(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppMessageCard.error(
                      title: 'No pudimos cargar los proveedores',
                      message:
                          state.errorMessage ??
                          'Intenta nuevamente para consultar el catálogo comercial.',
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
              ProveedoresStatus.success =>
                state.items.isEmpty
                    ? const _CenteredMessage(
                        child: AppMessageCard.info(
                          title: 'Sin resultados',
                          message:
                              'No encontramos proveedores con los filtros actuales.',
                        ),
                      )
                    : ListView.separated(
                        itemCount: state.items.length,
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.xs,
                          AppSpacing.md,
                          AppSpacing.md,
                        ),
                        separatorBuilder: (_, _) => const Gap(AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final item = state.items[index];
                          return _ProveedorListTileCard(
                            item: item,
                            isSelected: item.id == state.selectedProveedorId,
                            onTap: () => onSelectProveedor(item.id),
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

class _ProveedorDetailPanel extends StatelessWidget {
  const _ProveedorDetailPanel({
    required this.state,
    required this.onRetry,
    required this.onEdit,
    required this.onToggleState,
  });

  final ProveedoresState state;
  final VoidCallback onRetry;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final proveedor = state.selectedProveedor;
    return AppSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Detalle del proveedor',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
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
                if (proveedor == null) {
                  return const _CenteredMessage(
                    child: AppMessageCard.info(
                      title: 'Selecciona un proveedor',
                      message:
                          'Escoge un registro del listado para revisar su información.',
                    ),
                  );
                }
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.md,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            proveedor.razonSocial,
                            style: theme.textTheme.headlineSmall,
                          ),
                          _StatusBadge(
                            label: proveedor.activo ? 'Activo' : 'Inactivo',
                            icon: proveedor.activo
                                ? Icons.verified_outlined
                                : Icons.block_outlined,
                            background: proveedor.activo
                                ? theme.colorScheme.primaryContainer
                                : theme.colorScheme.surfaceContainerHighest,
                            foreground: proveedor.activo
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                      const Gap(AppSpacing.xs),
                      Text(
                        proveedor.rucDocumento,
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
                            label: 'Editar proveedor',
                            icon: Icons.edit_outlined,
                            isLoading: state.isSubmittingAction,
                            onPressed: onEdit,
                          ),
                          AppButton.secondary(
                            label: proveedor.activo
                                ? 'Inactivar proveedor'
                                : 'Activar proveedor',
                            icon: proveedor.activo
                                ? Icons.block_outlined
                                : Icons.check_circle_outline,
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
                              'ID: ${proveedor.id}',
                              'Documento: ${proveedor.rucDocumento}',
                              'Razón social: ${proveedor.razonSocial}',
                            ],
                          ),
                          _DetailCard(
                            title: 'Contacto',
                            lines: [
                              'Persona: ${proveedor.contacto ?? 'Sin contacto'}',
                              'Teléfono: ${proveedor.telefono ?? 'Sin teléfono'}',
                              'Correo: ${proveedor.correo ?? 'Sin correo'}',
                            ],
                          ),
                          _DetailCard(
                            title: 'Ubicación y trazabilidad',
                            lines: [
                              'Dirección: ${proveedor.direccion ?? 'Sin dirección'}',
                              'Creado: ${_formatDateTime(proveedor.creadoEn)}',
                              'Actualizado: ${_formatOptionalDate(proveedor.actualizadoEn)}',
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileProveedorDetailSheet extends StatelessWidget {
  const _MobileProveedorDetailSheet({
    required this.onEdit,
    required this.onToggleState,
  });

  final VoidCallback onEdit;
  final VoidCallback onToggleState;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return FractionallySizedBox(
      heightFactor: 0.88,
      child: Material(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.outlineVariant,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const Gap(AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Detalle del proveedor',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar detalle',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const Gap(AppSpacing.sm),
                Expanded(
                  child: BlocBuilder<ProveedoresCubit, ProveedoresState>(
                    builder: (context, state) => _ProveedorDetailPanel(
                      state: state,
                      onRetry: () =>
                          context.read<ProveedoresCubit>().retryDetail(),
                      onEdit: state.selectedProveedor == null ? null : onEdit,
                      onToggleState: state.selectedProveedor == null
                          ? null
                          : onToggleState,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProveedorListTileCard extends StatelessWidget {
  const _ProveedorListTileCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final ProveedorRecord item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.48)
                : theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.42)
                  : theme.colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.local_shipping_outlined,
                  size: 19,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const Gap(AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.rucDocumento,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Gap(AppSpacing.xs),
                    Text(
                      item.razonSocial,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    const Gap(AppSpacing.xs),
                    Text(
                      item.contacto ??
                          item.correo ??
                          'Sin contacto principal registrado.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(AppSpacing.sm),
              Tooltip(
                message: item.activo ? 'Activo' : 'Inactivo',
                child: Icon(
                  item.activo
                      ? Icons.check_circle_outline_rounded
                      : Icons.block_rounded,
                  color: item.activo
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  size: 20,
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
  Widget build(BuildContext context) => Container(
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

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: child,
    ),
  );
}

String _formatOptionalDate(DateTime? value) =>
    value == null ? 'Sin registro' : _formatDateTime(value);

String _formatDateTime(DateTime value) =>
    DateFormat('dd/MM/yyyy hh:mm a').format(value.toLocal());
