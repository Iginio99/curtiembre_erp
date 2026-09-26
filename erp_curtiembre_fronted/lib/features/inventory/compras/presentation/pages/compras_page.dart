import 'package:erp_curtiembre_fronted/core/di/service_locator.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_breakpoints.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_state.dart';
import 'package:erp_curtiembre_fronted/features/inventory/compras/domain/entities/orden_compra_detail.dart';
import 'package:erp_curtiembre_fronted/features/inventory/compras/domain/entities/orden_compra_record.dart';
import 'package:erp_curtiembre_fronted/features/inventory/compras/presentation/cubit/compras_cubit.dart';
import 'package:erp_curtiembre_fronted/features/inventory/compras/presentation/cubit/compras_state.dart';
import 'package:erp_curtiembre_fronted/features/inventory/compras/presentation/widgets/orden_compra_decision_dialog.dart';
import 'package:erp_curtiembre_fronted/features/inventory/compras/presentation/widgets/orden_compra_upsert_dialog.dart';
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

class ComprasPage extends StatefulWidget {
  const ComprasPage({super.key});

  @override
  State<ComprasPage> createState() => _ComprasPageState();
}

class _ComprasPageState extends State<ComprasPage> {
  final _searchController = TextEditingController();
  final Talker _talker = getIt<Talker>();

  @override
  void initState() {
    super.initState();
    _talker.ui('Se abrio la pantalla de compras.');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applySearch() {
    FocusScope.of(context).unfocus();
    _talker.ui(
      'Se aplico una busqueda en compras con texto=${_describeText(_searchController.text)}.',
    );
    context.read<ComprasCubit>().load(
      searchTerm: _searchController.text.trim(),
    );
  }

  void _selectOrder(int orderId, {required bool openMobileDetail}) {
    _talker.ui(
      'Se selecciono la orden de compra $orderId desde el listado.',
      logLevel: LogLevel.debug,
    );
    context.read<ComprasCubit>().selectOrder(orderId);

    if (!openMobileDetail) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BlocProvider.value(
        value: context.read<ComprasCubit>(),
        child: _MobileCompraDetailSheet(
          onApprove: _approveOrder,
          onReject: () => _openDecisionDialog(
            title: 'Rechazar orden',
            submitLabel: 'Rechazar',
            helperText:
                'Explica por que esta orden no debe continuar en el flujo.',
            action: (motivo) =>
                context.read<ComprasCubit>().rejectSelectedOrder(motivo),
          ),
          onCancel: () => _openDecisionDialog(
            title: 'Anular orden',
            submitLabel: 'Anular',
            helperText:
                'Registra el motivo de anulacion para dejar trazabilidad.',
            action: (motivo) =>
                context.read<ComprasCubit>().cancelSelectedOrder(motivo),
          ),
        ),
      ),
    );
  }

  Future<void> _openCreateDialog(ComprasState state) async {
    _talker.ui('Se abrio el dialogo para crear una orden de compra.');
    final payload = await showDialog<OrdenCompraUpsertFormData>(
      context: context,
      builder: (_) => OrdenCompraUpsertDialog(
        proveedores: state.proveedores,
        insumos: state.insumos,
        isSubmitting: state.isSubmittingAction,
      ),
    );

    if (payload == null || !mounted) {
      _talker.ui(
        'Se cerro el dialogo de compra sin confirmar.',
        logLevel: LogLevel.debug,
      );
      return;
    }
    _talker.ui(
      'Se confirmo la creacion de una orden de compra para proveedorId=${payload.proveedorId} con ${payload.detalles.length} detalles.',
    );

    final result = await context.read<ComprasCubit>().createOrder(
      proveedorId: payload.proveedorId,
      fechaEmision: payload.fechaEmision,
      observacion: payload.observacion,
      detalles: payload.detalles,
    );

    if (!mounted) return;
    _showActionResult(result);
  }

  Future<void> _approveOrder() async {
    _talker.ui(
      'Se solicito aprobar la orden de compra seleccionada.',
      logLevel: LogLevel.warning,
    );
    final result = await context.read<ComprasCubit>().approveSelectedOrder();
    if (!mounted) return;
    _showActionResult(result);
  }

  Future<void> _openDecisionDialog({
    required String title,
    required String submitLabel,
    required String helperText,
    required Future<ComprasActionResult> Function(String motivo) action,
  }) async {
    _talker.ui(
      'Se abrio el dialogo "$title" para una decision sobre orden de compra.',
      logLevel: LogLevel.warning,
    );
    final state = context.read<ComprasCubit>().state;
    final payload = await showDialog<OrdenCompraDecisionDialogResult>(
      context: context,
      builder: (_) => OrdenCompraDecisionDialog(
        title: title,
        submitLabel: submitLabel,
        helperText: helperText,
        isSubmitting: state.isSubmittingAction,
      ),
    );

    if (payload == null || !mounted) {
      _talker.ui(
        'Se cerro el dialogo "$title" sin confirmar.',
        logLevel: LogLevel.debug,
      );
      return;
    }
    _talker.ui(
      'Se confirmo la decision "$title" con motivo=${_describeText(payload.motivo)}.',
      logLevel: LogLevel.warning,
    );

    final result = await action(payload.motivo);
    if (!mounted) return;
    _showActionResult(result);
  }

  void _showActionResult(ComprasActionResult result) {
    _talker.ui(
      result.success
          ? 'Accion en compras completada correctamente.'
          : 'La accion en compras fallo: ${result.message}',
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
      title: 'Compras',
      currentPath: '/inventario/compras',
      breadcrumbs: const ['Inicio', 'Inventario', 'Compras'],
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
              child: BlocBuilder<ComprasCubit, ComprasState>(
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

                  final listPanel = _ComprasListPanel(
                    state: state,
                    onRetry: () => context.read<ComprasCubit>().initialize(),
                    onSelectOrder: (id) =>
                        _selectOrder(id, openMobileDetail: isMobile),
                  );
                  final detailPanel = _CompraDetailPanel(
                    state: state,
                    onRetry: () => context.read<ComprasCubit>().retryDetail(),
                    onApprove: _approveOrder,
                    onReject: () => _openDecisionDialog(
                      title: 'Rechazar orden',
                      submitLabel: 'Rechazar',
                      helperText:
                          'Explica por que esta orden no debe continuar en el flujo.',
                      action: (motivo) => context
                          .read<ComprasCubit>()
                          .rejectSelectedOrder(motivo),
                    ),
                    onCancel: () => _openDecisionDialog(
                      title: 'Anular orden',
                      submitLabel: 'Anular',
                      helperText:
                          'Registra el motivo de anulacion para dejar trazabilidad.',
                      action: (motivo) => context
                          .read<ComprasCubit>()
                          .cancelSelectedOrder(motivo),
                    ),
                  );
                  final headerAndFilters = <Widget>[
                    Text(
                      'Crea y controla órdenes de compra, desde su registro hasta la recepción de los insumos.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Gap(AppSpacing.lg),
                    _ComprasFiltersCard(
                      state: state,
                      controller: _searchController,
                      isCompact: isMobile,
                      isLoading: state.status == ComprasStatus.loading,
                      isSubmittingAction: state.isSubmittingAction,
                      onSearch: _applySearch,
                      onCreateOrder: () => _openCreateDialog(state),
                      onProveedorChanged: (value) => context
                          .read<ComprasCubit>()
                          .load(proveedorIdFilter: value),
                      onEstadoChanged: (value) => context
                          .read<ComprasCubit>()
                          .load(estadoFilter: value),
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
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return '${normalized.length} caracteres';
  }
}

class _ComprasFiltersCard extends StatelessWidget {
  const _ComprasFiltersCard({
    required this.state,
    required this.controller,
    required this.isCompact,
    required this.isLoading,
    required this.isSubmittingAction,
    required this.onSearch,
    required this.onCreateOrder,
    required this.onProveedorChanged,
    required this.onEstadoChanged,
  });

  final ComprasState state;
  final TextEditingController controller;
  final bool isCompact;
  final bool isLoading;
  final bool isSubmittingAction;
  final VoidCallback onSearch;
  final VoidCallback onCreateOrder;
  final ValueChanged<int?> onProveedorChanged;
  final ValueChanged<String?> onEstadoChanged;

  @override
  Widget build(BuildContext context) {
    final filters = _ComprasFilterControls(
      state: state,
      onProveedorChanged: onProveedorChanged,
      onEstadoChanged: onEstadoChanged,
    );
    final search = _ComprasSearchField(
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
                  onPressed: () => _openFilters(context, filters),
                  icon: const Icon(Icons.tune_rounded),
                ),
                const Gap(AppSpacing.xs),
                IconButton.filled(
                  tooltip: 'Nueva compra',
                  onPressed: isSubmittingAction ? null : onCreateOrder,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final action = FilledButton.icon(
                  onPressed: isSubmittingAction ? null : onCreateOrder,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Nueva compra'),
                );
                if (constraints.maxWidth >= 1100) {
                  return Row(
                    children: [
                      Expanded(child: search),
                      const Gap(AppSpacing.md),
                      filters.proveedor,
                      const Gap(AppSpacing.md),
                      filters.estado,
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
                      children: [filters.proveedor, filters.estado],
                    ),
                  ],
                );
              },
            ),
    );
  }

  void _openFilters(BuildContext context, _ComprasFilterControls filters) {
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
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const Gap(AppSpacing.lg),
            Text('Filtros', style: Theme.of(context).textTheme.titleLarge),
            const Gap(AppSpacing.lg),
            filters.proveedor,
            const Gap(AppSpacing.lg),
            filters.estado,
          ],
        ),
      ),
    );
  }
}

class _ComprasFilterControls {
  const _ComprasFilterControls({
    required this.state,
    required this.onProveedorChanged,
    required this.onEstadoChanged,
  });

  final ComprasState state;
  final ValueChanged<int?> onProveedorChanged;
  final ValueChanged<String?> onEstadoChanged;

  Widget get proveedor => SizedBox(
    width: 280,
    child: DropdownButtonFormField<int?>(
      initialValue: state.proveedorIdFilter,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Proveedor'),
      items: [
        const DropdownMenuItem<int?>(value: null, child: Text('Todos')),
        ...state.proveedores.map(
          (item) => DropdownMenuItem<int?>(
            value: item.id,
            child: Text(item.displayName, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: onProveedorChanged,
    ),
  );

  Widget get estado => SizedBox(
    width: 220,
    child: DropdownButtonFormField<String?>(
      initialValue: state.estadoFilter,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Estado'),
      items: const [
        DropdownMenuItem<String?>(value: null, child: Text('Todos')),
        DropdownMenuItem<String?>(value: 'PENDIENTE', child: Text('Pendiente')),
        DropdownMenuItem<String?>(value: 'APROBADA', child: Text('Aprobada')),
        DropdownMenuItem<String?>(
          value: 'PARCIALMENTE_RECIBIDA',
          child: Text('Parcialmente recibida'),
        ),
        DropdownMenuItem<String?>(
          value: 'TOTALMENTE_RECIBIDA',
          child: Text('Totalmente recibida'),
        ),
        DropdownMenuItem<String?>(value: 'RECHAZADA', child: Text('Rechazada')),
        DropdownMenuItem<String?>(value: 'ANULADA', child: Text('Anulada')),
      ],
      onChanged: onEstadoChanged,
    ),
  );
}

class _ComprasSearchField extends StatelessWidget {
  const _ComprasSearchField({
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
      hintText: 'Buscar por código o proveedor...',
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

class _ComprasListPanel extends StatelessWidget {
  const _ComprasListPanel({
    required this.state,
    required this.onRetry,
    required this.onSelectOrder,
  });

  final ComprasState state;
  final VoidCallback onRetry;
  final ValueChanged<int> onSelectOrder;

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
              ComprasStatus.loading => const Center(
                child: CircularProgressIndicator(),
              ),
              ComprasStatus.error => _CenteredMessage(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppMessageCard.error(
                      title: 'No pudimos cargar las compras',
                      message:
                          state.errorMessage ??
                          'Intenta nuevamente para consultar las ordenes.',
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
              ComprasStatus.success =>
                state.items.isEmpty
                    ? const _CenteredMessage(
                        child: AppMessageCard.info(
                          title: 'Sin resultados',
                          message:
                              'No encontramos compras con los filtros actuales.',
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
                          return _CompraListTileCard(
                            item: item,
                            isSelected: item.id == state.selectedOrderId,
                            onTap: () => onSelectOrder(item.id),
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

class _CompraDetailPanel extends StatelessWidget {
  const _CompraDetailPanel({
    required this.state,
    required this.onRetry,
    required this.onApprove,
    required this.onReject,
    required this.onCancel,
  });

  final ComprasState state;
  final VoidCallback onRetry;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detail = state.selectedOrder;

    return AppSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Detalle de la compra',
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

                if (detail == null) {
                  return const _CenteredMessage(
                    child: AppMessageCard.info(
                      title: 'Selecciona una compra',
                      message:
                          'Escoge un documento del listado para revisar su detalle.',
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
                            detail.codigo,
                            style: theme.textTheme.headlineSmall,
                          ),
                          _StatePill(state: detail.estado),
                        ],
                      ),
                      const Gap(AppSpacing.xs),
                      Text(
                        detail.proveedorRazonSocial,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const Gap(AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          AppButton.secondary(
                            label: 'Aprobar',
                            icon: Icons.check_circle_outline,
                            isLoading: state.isSubmittingAction,
                            onPressed: detail.canApprove ? onApprove : null,
                          ),
                          AppButton.secondary(
                            label: 'Rechazar',
                            icon: Icons.cancel_outlined,
                            isLoading: state.isSubmittingAction,
                            onPressed: detail.canReject ? onReject : null,
                          ),
                          AppButton.secondary(
                            label: 'Anular',
                            icon: Icons.block_outlined,
                            isLoading: state.isSubmittingAction,
                            onPressed: detail.canCancel ? onCancel : null,
                          ),
                        ],
                      ),
                      const Gap(AppSpacing.lg),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Wrap(
                          spacing: AppSpacing.lg,
                          runSpacing: AppSpacing.xs,
                          children: [
                            _CompactInfo(
                              label: 'Emision',
                              value: DateFormat(
                                'dd/MM/yyyy',
                              ).format(detail.fechaEmision.toLocal()),
                            ),
                            if ((detail.observacion ?? '').trim().isNotEmpty)
                              _CompactInfo(
                                label: 'Observacion',
                                value: detail.observacion!,
                              ),
                            if ((detail.motivo ?? '').trim().isNotEmpty)
                              _CompactInfo(
                                label: 'Motivo',
                                value: detail.motivo!,
                              ),
                          ],
                        ),
                      ),
                      const Gap(AppSpacing.lg),
                      Row(
                        children: [
                          Text('Insumos', style: theme.textTheme.titleMedium),
                          const Spacer(),
                          Text(
                            '${detail.detalles.length} items',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const Gap(AppSpacing.sm),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: Column(
                          children: [
                            for (
                              var index = 0;
                              index < detail.detalles.length;
                              index++
                            )
                              _CompraItemRow(
                                item: detail.detalles[index],
                                showDivider: index < detail.detalles.length - 1,
                              ),
                          ],
                        ),
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

class _CompactInfo extends StatelessWidget {
  const _CompactInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RichText(
      text: TextSpan(
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}

class _CompraItemRow extends StatelessWidget {
  const _CompraItemRow({required this.item, required this.showDivider});

  final OrdenCompraDetalleLine item;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unitCost = item.costoUnitarioEstimado == null
        ? 'Sin costo'
        : 'S/ ${item.costoUnitarioEstimado!.toStringAsFixed(2)}';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(color: theme.colorScheme.outlineVariant),
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${item.insumoCodigo} · ${item.insumoNombre}',
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Gap(AppSpacing.sm),
              Text(
                'S/ ${item.montoEstimado.toStringAsFixed(2)}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Gap(AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              _CompactInfo(
                label: 'Solic.',
                value: item.cantidadSolicitada.toStringAsFixed(2),
              ),
              _CompactInfo(
                label: 'Recib.',
                value: item.cantidadRecibida.toStringAsFixed(2),
              ),
              _CompactInfo(
                label: 'Pend.',
                value: item.saldoPendiente.toStringAsFixed(2),
              ),
              _CompactInfo(label: 'Unit.', value: unitCost),
            ],
          ),
          if ((item.observacion ?? '').trim().isNotEmpty) ...[
            const Gap(AppSpacing.xs),
            Text(
              item.observacion!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MobileCompraDetailSheet extends StatelessWidget {
  const _MobileCompraDetailSheet({
    required this.onApprove,
    required this.onReject,
    required this.onCancel,
  });

  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return FractionallySizedBox(
      heightFactor: 0.9,
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
                        'Detalle de la compra',
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
                  child: BlocBuilder<ComprasCubit, ComprasState>(
                    builder: (context, state) => _CompraDetailPanel(
                      state: state,
                      onRetry: () => context.read<ComprasCubit>().retryDetail(),
                      onApprove: state.selectedOrder?.canApprove == true
                          ? onApprove
                          : null,
                      onReject: state.selectedOrder?.canReject == true
                          ? onReject
                          : null,
                      onCancel: state.selectedOrder?.canCancel == true
                          ? onCancel
                          : null,
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

class _CompraListTileCard extends StatelessWidget {
  const _CompraListTileCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final OrdenCompraRecord item;
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
                  Text(item.codigo, style: theme.textTheme.titleMedium),
                  _StatePill(state: item.estado),
                ],
              ),
              const Gap(AppSpacing.sm),
              Text(
                item.proveedorRazonSocial,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const Gap(AppSpacing.md),
              Text(
                'Items: ${item.totalItems} · Solicitado: ${item.cantidadTotalSolicitada.toStringAsFixed(2)} · Recibido: ${item.cantidadTotalRecibida.toStringAsFixed(2)}',
                style: theme.textTheme.bodyMedium,
              ),
              const Gap(AppSpacing.xs),
              Text(
                'Monto estimado: S/ ${item.montoTotalEstimado.toStringAsFixed(2)}',
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

class _StatePill extends StatelessWidget {
  const _StatePill({required this.state});

  final String state;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (state) {
      'PENDIENTE' => (const Color(0xFFF9E8BF), const Color(0xFF7A5512)),
      'APROBADA' => (const Color(0xFFE2F6E8), const Color(0xFF20633A)),
      'PARCIALMENTE_RECIBIDA' => (
        const Color(0xFFE8F2FF),
        const Color(0xFF0F4C81),
      ),
      'TOTALMENTE_RECIBIDA' => (
        const Color(0xFFDFF4F7),
        const Color(0xFF0E5C69),
      ),
      'RECHAZADA' => (const Color(0xFFF7E0DF), const Color(0xFF8A2F22)),
      'ANULADA' => (const Color(0xFFE7E2E0), const Color(0xFF5D5552)),
      _ => (
        Theme.of(context).colorScheme.surfaceContainerHighest,
        Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    };

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
        state,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: foreground),
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
