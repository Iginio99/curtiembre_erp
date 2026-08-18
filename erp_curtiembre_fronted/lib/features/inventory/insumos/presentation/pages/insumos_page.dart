import 'package:erp_curtiembre_fronted/core/di/service_locator.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_breakpoints.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_state.dart';
import 'package:erp_curtiembre_fronted/features/inventory/insumos/domain/constants/insumo_tipo_bien_options.dart';
import 'package:erp_curtiembre_fronted/features/inventory/insumos/domain/entities/insumo_record.dart';
import 'package:erp_curtiembre_fronted/features/inventory/insumos/presentation/cubit/insumos_cubit.dart';
import 'package:erp_curtiembre_fronted/features/inventory/insumos/presentation/cubit/insumos_state.dart';
import 'package:erp_curtiembre_fronted/features/inventory/insumos/presentation/widgets/insumo_upsert_dialog.dart';
import 'package:erp_curtiembre_fronted/features/security/presentation/cubit/security_access_cubit.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/buttons/app_button.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/feedback/app_message_card.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/layout/app_shell.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/layout/app_surface_card.dart';
import 'package:erp_curtiembre_fronted/shared/navigation/app_access_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:talker_flutter/talker_flutter.dart';

class InsumosPage extends StatefulWidget {
  const InsumosPage({super.key});

  @override
  State<InsumosPage> createState() => _InsumosPageState();
}

class _InsumosPageState extends State<InsumosPage> {
  final _searchController = TextEditingController();
  final Talker _talker = getIt<Talker>();

  @override
  void initState() {
    super.initState();
    _talker.ui('Se abrio la pantalla de insumos.');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applySearch() {
    FocusScope.of(context).unfocus();
    _talker.ui(
      'Se aplico la busqueda de insumos con texto=${_describeText(_searchController.text)}.',
    );
    context.read<InsumosCubit>().load(
      searchTerm: _searchController.text.trim(),
    );
  }

  void _selectInsumo(int insumoId, {required bool openMobileDetail}) {
    _talker.ui(
      'Se selecciono el insumo $insumoId desde el listado.',
      logLevel: LogLevel.debug,
    );
    context.read<InsumosCubit>().selectInsumo(insumoId);

    if (!openMobileDetail) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BlocProvider.value(
        value: context.read<InsumosCubit>(),
        child: _MobileInsumoDetailSheet(
          onEdit: () {
            final state = context.read<InsumosCubit>().state;
            final insumo = state.selectedInsumo;
            if (insumo != null) _openEditDialog(state, insumo);
          },
          onToggleState: () {
            final insumo = context.read<InsumosCubit>().state.selectedInsumo;
            if (insumo != null) _toggleState(insumo);
          },
        ),
      ),
    );
  }

  Future<void> _openCreateDialog(InsumosState state) async {
    _talker.ui('Se abrio el dialogo para crear un insumo.');
    final payload = await showDialog<InsumoUpsertFormData>(
      context: context,
      builder: (_) => InsumoUpsertDialog(
        title: 'Nuevo insumo',
        submitLabel: 'Crear insumo',
        unitOptions: state.unitOptions,
        isSubmitting: state.isSubmittingAction,
      ),
    );

    if (payload == null || !mounted) {
      _talker.ui(
        'Se cerro la creacion de insumo sin confirmar.',
        logLevel: LogLevel.debug,
      );
      return;
    }
    _talker.ui(
      'Se confirmo la creacion de un insumo con codigo=${payload.codigo}, nombre=${_describeText(payload.nombre)}.',
    );

    final result = await context.read<InsumosCubit>().createInsumo(
      codigo: payload.codigo,
      nombre: payload.nombre,
      tipoBien: payload.tipoBien,
      presentacion: payload.presentacion,
      unidadMedidaId: payload.unidadMedidaId,
      stockMinimo: payload.stockMinimo,
      requiereLote: payload.requiereLote,
    );

    if (!mounted) {
      return;
    }

    _showActionResult(result);
  }

  Future<void> _openEditDialog(InsumosState state, InsumoRecord insumo) async {
    _talker.ui(
      'Se abrio el dialogo para editar el insumo ${insumo.id}.',
      logLevel: LogLevel.warning,
    );
    final payload = await showDialog<InsumoUpsertFormData>(
      context: context,
      builder: (_) => InsumoUpsertDialog(
        title: 'Editar insumo',
        submitLabel: 'Guardar cambios',
        unitOptions: state.unitOptions,
        isSubmitting: state.isSubmittingAction,
        initialInsumo: insumo,
      ),
    );

    if (payload == null || !mounted) {
      _talker.ui(
        'Se cerro la edicion del insumo ${insumo.id} sin confirmar.',
        logLevel: LogLevel.debug,
      );
      return;
    }
    _talker.ui(
      'Se confirmo la edicion del insumo ${insumo.id} con codigo=${payload.codigo}.',
      logLevel: LogLevel.warning,
    );

    final result = await context.read<InsumosCubit>().updateSelectedInsumo(
      codigo: payload.codigo,
      nombre: payload.nombre,
      tipoBien: payload.tipoBien,
      presentacion: payload.presentacion,
      unidadMedidaId: payload.unidadMedidaId,
      stockMinimo: payload.stockMinimo,
      requiereLote: payload.requiereLote,
    );

    if (!mounted) {
      return;
    }

    _showActionResult(result);
  }

  Future<void> _toggleState(InsumoRecord insumo) async {
    _talker.ui(
      'Se solicito ${insumo.activo ? 'inactivar' : 'activar'} el insumo ${insumo.id}.',
      logLevel: LogLevel.warning,
    );
    final result = await context.read<InsumosCubit>().setSelectedInsumoActive(
      !insumo.activo,
    );

    if (!mounted) {
      return;
    }

    _showActionResult(result);
  }

  void _showActionResult(InsumosActionResult result) {
    _talker.ui(
      result.success
          ? 'Accion en insumos completada correctamente.'
          : 'La accion en insumos fallo: ${result.message}',
      logLevel: result.success ? LogLevel.debug : LogLevel.error,
    );
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
      title: 'Insumos',
      currentPath: '/inventario/insumos',
      breadcrumbs: const ['Inicio', 'Inventario', 'Insumos'],
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
              child: BlocBuilder<InsumosCubit, InsumosState>(
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

                  final listPanel = _InsumosListPanel(
                    state: state,
                    onRetry: () => context.read<InsumosCubit>().initialize(),
                    onSelectInsumo: (id) =>
                        _selectInsumo(id, openMobileDetail: isMobile),
                  );

                  final detailPanel = _InsumoDetailPanel(
                    state: state,
                    onRetry: () => context.read<InsumosCubit>().retryDetail(),
                    onEdit: state.selectedInsumo == null
                        ? null
                        : () => _openEditDialog(state, state.selectedInsumo!),
                    onToggleState: state.selectedInsumo == null
                        ? null
                        : () => _toggleState(state.selectedInsumo!),
                  );

                  final headerAndFilters = <Widget>[
                    Text(
                      'Administra el catálogo de insumos, sus mínimos de stock y reglas de trazabilidad.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Gap(AppSpacing.lg),
                    _InsumosFiltersCard(
                      state: state,
                      controller: _searchController,
                      isCompact: isMobile,
                      isLoading: state.status == InsumosStatus.loading,
                      isSubmittingAction: state.isSubmittingAction,
                      onSearch: _applySearch,
                      onCreateInsumo: () => _openCreateDialog(state),
                      onActivityFilterChanged: (filter) => context
                          .read<InsumosCubit>()
                          .load(activityFilter: filter),
                      onStockBajoChanged: (value) => context
                          .read<InsumosCubit>()
                          .load(stockBajoOnly: value),
                      onTipoBienChanged: (value) => context
                          .read<InsumosCubit>()
                          .load(tipoBienFilter: value),
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
                          if (!isMobile) ...[
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
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return '${normalized.length} caracteres';
  }
}

class _InsumosFiltersCard extends StatelessWidget {
  const _InsumosFiltersCard({
    required this.state,
    required this.controller,
    required this.isCompact,
    required this.isLoading,
    required this.isSubmittingAction,
    required this.onSearch,
    required this.onCreateInsumo,
    required this.onActivityFilterChanged,
    required this.onStockBajoChanged,
    required this.onTipoBienChanged,
  });

  final InsumosState state;
  final TextEditingController controller;
  final bool isCompact;
  final bool isLoading;
  final bool isSubmittingAction;
  final VoidCallback onSearch;
  final VoidCallback onCreateInsumo;
  final ValueChanged<InsumoActivityFilter> onActivityFilterChanged;
  final ValueChanged<bool> onStockBajoChanged;
  final ValueChanged<String?> onTipoBienChanged;

  @override
  Widget build(BuildContext context) {
    final filters = _InsumosFilterControls(
      state: state,
      onActivityFilterChanged: onActivityFilterChanged,
      onStockBajoChanged: onStockBajoChanged,
      onTipoBienChanged: onTipoBienChanged,
    );

    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: isCompact
          ? Row(
              children: [
                Expanded(
                  child: _InsumosSearchField(
                    controller: controller,
                    isLoading: isLoading,
                    onSearch: onSearch,
                  ),
                ),
                const Gap(AppSpacing.sm),
                IconButton.outlined(
                  tooltip: 'Filtros',
                  onPressed: () => _openFilters(context, filters),
                  icon: const Icon(Icons.tune_rounded),
                ),
                const Gap(AppSpacing.xs),
                IconButton.filled(
                  tooltip: 'Nuevo insumo',
                  onPressed: state.unitOptions.isEmpty ? null : onCreateInsumo,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final horizontal = constraints.maxWidth >= 980;
                final search = _InsumosSearchField(
                  controller: controller,
                  isLoading: isLoading,
                  onSearch: onSearch,
                );
                final action = FilledButton.icon(
                  onPressed: state.unitOptions.isEmpty ? null : onCreateInsumo,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Nuevo insumo'),
                );

                if (horizontal) {
                  return Row(
                    children: [
                      Expanded(child: search),
                      const Gap(AppSpacing.md),
                      filters.typeFilter,
                      const Gap(AppSpacing.md),
                      filters.activityFilter,
                      const Gap(AppSpacing.md),
                      filters.lowStockToggle,
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
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.md,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        filters.typeFilter,
                        filters.activityFilter,
                        filters.lowStockToggle,
                      ],
                    ),
                  ],
                );
              },
            ),
    );
  }

  void _openFilters(BuildContext context, _InsumosFilterControls filters) {
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
            filters.typeFilter,
            const Gap(AppSpacing.lg),
            Text('Estado', style: Theme.of(context).textTheme.labelLarge),
            const Gap(AppSpacing.sm),
            SizedBox(width: double.infinity, child: filters.activityFilter),
            const Gap(AppSpacing.lg),
            filters.lowStockToggle,
          ],
        ),
      ),
    );
  }
}

class _InsumosFilterControls {
  const _InsumosFilterControls({
    required this.state,
    required this.onActivityFilterChanged,
    required this.onStockBajoChanged,
    required this.onTipoBienChanged,
  });

  final InsumosState state;
  final ValueChanged<InsumoActivityFilter> onActivityFilterChanged;
  final ValueChanged<bool> onStockBajoChanged;
  final ValueChanged<String?> onTipoBienChanged;

  Widget get typeFilter => SizedBox(
    width: 190,
    child: DropdownButtonFormField<String?>(
      initialValue: state.tipoBienFilter,
      isExpanded: true,
      decoration: const InputDecoration(
        isDense: true,
        hintText: 'Tipo de bien',
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Todos')),
        ...inventoryInsumoTipoBienOptions.map(
          (option) => DropdownMenuItem(
            value: option.value,
            child: Text(
              option.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      onChanged: onTipoBienChanged,
    ),
  );

  Widget get activityFilter => SegmentedButton<InsumoActivityFilter>(
    showSelectedIcon: false,
    segments: const [
      ButtonSegment(value: InsumoActivityFilter.all, label: Text('Todos')),
      ButtonSegment(value: InsumoActivityFilter.active, label: Text('Activos')),
      ButtonSegment(
        value: InsumoActivityFilter.inactive,
        label: Text('Inactivos'),
      ),
    ],
    selected: {state.activityFilter},
    onSelectionChanged: (selection) {
      final value = selection.firstOrNull;
      if (value != null) onActivityFilterChanged(value);
    },
  );

  Widget get lowStockToggle => InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: () => onStockBajoChanged(!state.stockBajoOnly),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(value: state.stockBajoOnly, onChanged: onStockBajoChanged),
          const Gap(AppSpacing.xs),
          const Text('Solo stock bajo'),
        ],
      ),
    ),
  );
}

class _InsumosSearchField extends StatelessWidget {
  const _InsumosSearchField({
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
      hintText: 'Buscar por código o nombre...',
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

class _InsumosListPanel extends StatelessWidget {
  const _InsumosListPanel({
    required this.state,
    required this.onRetry,
    required this.onSelectInsumo,
  });

  final InsumosState state;
  final VoidCallback onRetry;
  final ValueChanged<int> onSelectInsumo;

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
              InsumosStatus.loading => const Center(
                child: CircularProgressIndicator(),
              ),
              InsumosStatus.error => _CenteredMessage(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppMessageCard.error(
                      title: 'No pudimos cargar los insumos',
                      message:
                          state.errorMessage ??
                          'Intenta nuevamente para consultar el inventario maestro.',
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
              InsumosStatus.success =>
                state.items.isEmpty
                    ? const _CenteredMessage(
                        child: AppMessageCard.info(
                          title: 'Sin resultados',
                          message:
                              'No encontramos insumos con los filtros actuales.',
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
                          return _InsumoListTileCard(
                            item: item,
                            isSelected: item.id == state.selectedInsumoId,
                            onTap: () => onSelectInsumo(item.id),
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

class _InsumoDetailPanel extends StatelessWidget {
  const _InsumoDetailPanel({
    required this.state,
    required this.onRetry,
    required this.onEdit,
    required this.onToggleState,
  });

  final InsumosState state;
  final VoidCallback onRetry;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final insumo = state.selectedInsumo;

    return AppSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Detalle del insumo',
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

                if (insumo == null) {
                  return const _CenteredMessage(
                    child: AppMessageCard.info(
                      title: 'Selecciona un insumo',
                      message:
                          'Escoge un registro del listado para revisar su informacion.',
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
                            insumo.nombre,
                            style: theme.textTheme.headlineSmall,
                          ),
                          _StatusBadge(
                            label: insumo.activo ? 'Activo' : 'Inactivo',
                            icon: insumo.activo
                                ? Icons.verified_outlined
                                : Icons.block_outlined,
                            background: insumo.activo
                                ? theme.colorScheme.primaryContainer
                                : theme.colorScheme.surfaceContainerHighest,
                            foreground: insumo.activo
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          if (insumo.requiereLote)
                            _StatusBadge(
                              label: 'Requiere lote',
                              icon: Icons.qr_code_2_outlined,
                              background: const Color(0xFFE8F2FF),
                              foreground: const Color(0xFF0F4C81),
                            ),
                          if (insumo.stockBajo)
                            _StatusBadge(
                              label: 'Stock bajo',
                              icon: Icons.warning_amber_rounded,
                              background: const Color(0xFFF9E8BF),
                              foreground: const Color(0xFF7A5512),
                            ),
                        ],
                      ),
                      const Gap(AppSpacing.xs),
                      Text(
                        insumo.codigo,
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
                            label: 'Editar insumo',
                            icon: Icons.edit_outlined,
                            isLoading: state.isSubmittingAction,
                            onPressed: onEdit,
                          ),
                          AppButton.secondary(
                            label: insumo.activo
                                ? 'Inactivar insumo'
                                : 'Activar insumo',
                            icon: insumo.activo
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
                              'ID: ${insumo.id}',
                              'Codigo: ${insumo.codigo}',
                              'Tipo: ${_tipoBienLabel(insumo.tipoBien)}',
                            ],
                          ),
                          _DetailCard(
                            title: 'Operacion',
                            lines: [
                              'Unidad: ${insumo.unidadMedidaCodigo} · ${insumo.unidadMedidaNombre}',
                              'Presentacion: ${insumo.presentacion ?? 'Sin presentacion'}',
                              'Requiere lote: ${insumo.requiereLote ? 'Si' : 'No'}',
                            ],
                          ),
                          _DetailCard(
                            title: 'Stock y costo',
                            lines: [
                              'Stock actual: ${insumo.stockActual.toStringAsFixed(2)}',
                              'Stock minimo: ${insumo.stockMinimo.toStringAsFixed(2)}',
                              'Costo promedio: S/ ${insumo.costoPromedioActual.toStringAsFixed(2)}',
                            ],
                          ),
                          _DetailCard(
                            title: 'Trazabilidad',
                            lines: [
                              'Creado: ${_formatDateTime(insumo.creadoEn)}',
                              'Actualizado: ${_formatOptionalDate(insumo.actualizadoEn)}',
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

class _MobileInsumoDetailSheet extends StatelessWidget {
  const _MobileInsumoDetailSheet({
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
                        'Detalle del insumo',
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
                  child: BlocBuilder<InsumosCubit, InsumosState>(
                    builder: (context, state) => _InsumoDetailPanel(
                      state: state,
                      onRetry: () => context.read<InsumosCubit>().retryDetail(),
                      onEdit: state.selectedInsumo == null ? null : onEdit,
                      onToggleState: state.selectedInsumo == null
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

class _InsumoListTileCard extends StatelessWidget {
  const _InsumoListTileCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final InsumoRecord item;
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
                  color: item.stockBajo
                      ? theme.colorScheme.errorContainer
                      : theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item.stockBajo
                      ? Icons.warning_amber_rounded
                      : Icons.inventory_2_outlined,
                  size: 19,
                  color: item.stockBajo
                      ? theme.colorScheme.onErrorContainer
                      : theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const Gap(AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.codigo,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Gap(AppSpacing.xs),
                    Text(
                      item.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    const Gap(AppSpacing.xs),
                    Text(
                      _tipoBienLabel(item.tipoBien),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
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
              if (item.stockBajo) ...[
                const Gap(AppSpacing.xs),
                Icon(
                  Icons.warning_amber_rounded,
                  color: theme.colorScheme.error,
                  size: 18,
                ),
              ],
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

String _tipoBienLabel(String value) {
  final option = inventoryInsumoTipoBienOptions
      .where((item) => item.value == value)
      .firstOrNull;
  return option?.label ?? value;
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
