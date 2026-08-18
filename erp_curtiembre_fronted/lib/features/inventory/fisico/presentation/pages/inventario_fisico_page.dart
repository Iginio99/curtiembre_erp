import 'package:erp_curtiembre_fronted/core/di/service_locator.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_state.dart';
import 'package:erp_curtiembre_fronted/features/inventory/fisico/domain/entities/inventario_fisico_detail.dart';
import 'package:erp_curtiembre_fronted/features/inventory/fisico/domain/entities/inventario_fisico_record.dart';
import 'package:erp_curtiembre_fronted/features/inventory/fisico/presentation/cubit/inventario_fisico_cubit.dart';
import 'package:erp_curtiembre_fronted/features/inventory/fisico/presentation/cubit/inventario_fisico_state.dart';
import 'package:erp_curtiembre_fronted/features/inventory/fisico/presentation/widgets/inventario_fisico_close_dialog.dart';
import 'package:erp_curtiembre_fronted/features/inventory/fisico/presentation/widgets/inventario_fisico_counts_dialog.dart';
import 'package:erp_curtiembre_fronted/features/inventory/fisico/presentation/widgets/inventario_fisico_create_dialog.dart';
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

class InventarioFisicoPage extends StatefulWidget {
  const InventarioFisicoPage({super.key});

  @override
  State<InventarioFisicoPage> createState() => _InventarioFisicoPageState();
}

class _InventarioFisicoPageState extends State<InventarioFisicoPage> {
  final _yearController = TextEditingController();
  final Talker _talker = getIt<Talker>();

  @override
  void initState() {
    super.initState();
    _talker.ui('Se abrio la pantalla de inventario fisico.');
  }

  @override
  void dispose() {
    _yearController.dispose();
    super.dispose();
  }

  void _syncYearField(InventarioFisicoState state) {
    final text = state.periodoAnioFilter?.toString() ?? '';
    if (_yearController.text != text) {
      _yearController.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  void _applyYearFilter() {
    final raw = _yearController.text.trim();
    final parsed = raw.isEmpty ? null : int.tryParse(raw);
    _talker.ui(
      'Se aplico el filtro de anio en inventario fisico con valor=${parsed ?? 'vacio'}.',
    );
    context.read<InventarioFisicoCubit>().load(periodoAnioFilter: parsed);
  }

  Future<void> _openCreateDialog(InventarioFisicoState state) async {
    _talker.ui('Se abrio el dialogo para crear una toma fisica.');
    final payload = await showDialog<InventarioFisicoCreateFormData>(
      context: context,
      builder: (_) =>
          InventarioFisicoCreateDialog(isSubmitting: state.isSubmittingAction),
    );
    if (payload == null || !mounted) {
      _talker.ui(
        'Se cerro la creacion de inventario fisico sin confirmar.',
        logLevel: LogLevel.debug,
      );
      return;
    }
    _talker.ui(
      'Se confirmo la creacion de inventario fisico para periodo=${payload.periodoMes}/${payload.periodoAnio}.',
    );

    final result = await context
        .read<InventarioFisicoCubit>()
        .createInventarioFisico(
          periodoAnio: payload.periodoAnio,
          periodoMes: payload.periodoMes,
          observacion: payload.observacion,
        );

    if (!mounted) return;
    _showActionResult(result);
  }

  Future<void> _openCountsDialog(InventarioFisicoState state) async {
    final detail = state.selectedInventario;
    if (detail == null) return;
    _talker.ui(
      'Se abrio el dialogo para registrar conteos del inventario fisico ${detail.id}.',
      logLevel: LogLevel.warning,
    );

    final payload = await showDialog<InventarioFisicoCountsFormData>(
      context: context,
      builder: (_) => InventarioFisicoCountsDialog(
        insumos: state.insumos,
        existingDetails: detail.detalles,
        isSubmitting: state.isSubmittingAction,
      ),
    );
    if (payload == null || !mounted) {
      _talker.ui(
        'Se cerro el registro de conteos del inventario fisico ${detail.id} sin confirmar.',
        logLevel: LogLevel.debug,
      );
      return;
    }
    _talker.ui(
      'Se confirmo el registro de conteos del inventario fisico ${detail.id} con ${payload.detalles.length} detalles.',
      logLevel: LogLevel.warning,
    );

    final result = await context.read<InventarioFisicoCubit>().registerCounts(
      inventarioFisicoId: detail.id,
      detalles: payload.detalles,
    );

    if (!mounted) return;
    _showActionResult(result);
  }

  Future<void> _openCloseDialog(InventarioFisicoState state) async {
    _talker.ui(
      'Se abrio el dialogo para cerrar el inventario fisico seleccionado.',
      logLevel: LogLevel.warning,
    );
    final payload = await showDialog<String>(
      context: context,
      builder: (_) =>
          InventarioFisicoCloseDialog(isSubmitting: state.isSubmittingAction),
    );
    if (!mounted || payload == null) {
      _talker.ui(
        'Se cerro el cierre de inventario fisico sin confirmar.',
        logLevel: LogLevel.debug,
      );
      return;
    }
    _talker.ui(
      'Se confirmo el cierre del inventario fisico con observacion=${_describeText(payload)}.',
      logLevel: LogLevel.warning,
    );

    final result = await context.read<InventarioFisicoCubit>().closeSelected(
      observacion: payload.isEmpty ? null : payload,
    );

    if (!mounted) return;
    _showActionResult(result);
  }

  void _showActionResult(InventarioFisicoActionResult result) {
    _talker.ui(
      result.success
          ? 'Accion en inventario fisico completada correctamente.'
          : 'La accion en inventario fisico fallo: ${result.message}',
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
      title: 'Inventario físico',
      currentPath: '/inventario/fisico',
      breadcrumbs: const ['Inicio', 'Inventario', 'Inventario físico'],
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
                child: BlocBuilder<InventarioFisicoCubit, InventarioFisicoState>(
                  builder: (context, state) {
                    _syncYearField(state);
                    final isWide = constraints.maxWidth >= 1040;
                    final compactHeight = constraints.maxHeight < 860;

                    final listPanel = _InventarioFisicoListPanel(
                      state: state,
                      onRetry: () {
                        _talker.ui(
                          'Se solicito reintentar la carga del listado de inventario fisico.',
                        );
                        context.read<InventarioFisicoCubit>().initialize();
                      },
                      onSelectInventario: (id) {
                        _talker.ui(
                          'Se selecciono el inventario fisico $id desde el listado.',
                          logLevel: LogLevel.debug,
                        );
                        context.read<InventarioFisicoCubit>().selectInventario(
                          id,
                        );
                      },
                    );

                    final detailPanel = _InventarioFisicoDetailPanel(
                      state: state,
                      onRetry: () {
                        _talker.ui(
                          'Se solicito reintentar el detalle del inventario fisico seleccionado.',
                        );
                        context.read<InventarioFisicoCubit>().retryDetail();
                      },
                      onRegisterCounts: () => _openCountsDialog(state),
                      onCloseInventory: () => _openCloseDialog(state),
                    );

                    final headerAndFilters = <Widget>[
                      Text(
                        'Concilia el stock real mediante tomas por período, conteos por insumo y cierre controlado de diferencias.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Gap(AppSpacing.xl),
                      _InventarioFisicoFiltersCard(
                        state: state,
                        yearController: _yearController,
                        onApplyYear: _applyYearFilter,
                        onMonthChanged: (value) {
                          _talker.ui(
                            'Se cambio el filtro de mes en inventario fisico a ${value ?? 'todos'}.',
                            logLevel: LogLevel.debug,
                          );
                          context.read<InventarioFisicoCubit>().load(
                            periodoMesFilter: value,
                          );
                        },
                        onEstadoChanged: (value) {
                          _talker.ui(
                            'Se cambio el filtro de estado en inventario fisico a ${_describeState(value)}.',
                            logLevel: LogLevel.debug,
                          );
                          context.read<InventarioFisicoCubit>().load(
                            estadoFilter: value,
                          );
                        },
                        onCreate: () => _openCreateDialog(state),
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
                                height: 640,
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
                            SizedBox(height: 640, child: detailPanel),
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

  String _describeText(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return '${normalized.length} caracteres';
  }

  String _describeState(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return normalized;
  }
}

class _InventarioFisicoFiltersCard extends StatelessWidget {
  const _InventarioFisicoFiltersCard({
    required this.state,
    required this.yearController,
    required this.onApplyYear,
    required this.onMonthChanged,
    required this.onEstadoChanged,
    required this.onCreate,
  });

  final InventarioFisicoState state;
  final TextEditingController yearController;
  final VoidCallback onApplyYear;
  final ValueChanged<int?> onMonthChanged;
  final ValueChanged<String?> onEstadoChanged;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filtros operativos', style: theme.textTheme.titleLarge),
          const Gap(AppSpacing.sm),
          Text(
            'Filtra por periodo o estado y abre nuevas tomas cuando corresponda.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.lg,
            children: [
              SizedBox(
                width: 180,
                child: TextField(
                  controller: yearController,
                  keyboardType: TextInputType.number,
                  onSubmitted: (_) => onApplyYear(),
                  decoration: const InputDecoration(labelText: 'Periodo anio'),
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<int?>(
                  initialValue: state.periodoMesFilter,
                  decoration: const InputDecoration(labelText: 'Periodo mes'),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Todos'),
                    ),
                    ...List.generate(
                      12,
                      (index) => DropdownMenuItem<int?>(
                        value: index + 1,
                        child: Text(monthLabel(index + 1)),
                      ),
                    ),
                  ],
                  onChanged: onMonthChanged,
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String?>(
                  initialValue: state.estadoFilter,
                  decoration: const InputDecoration(labelText: 'Estado'),
                  items: const [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Todos'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'ABIERTO',
                      child: Text('Abierto'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'CERRADO',
                      child: Text('Cerrado'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'ANULADO',
                      child: Text('Anulado'),
                    ),
                  ],
                  onChanged: onEstadoChanged,
                ),
              ),
              AppButton.secondary(
                label: 'Aplicar anio',
                icon: Icons.filter_alt_outlined,
                onPressed: onApplyYear,
              ),
              AppButton.primary(
                label: 'Nueva toma fisica',
                icon: Icons.add_chart_outlined,
                expand: false,
                onPressed: state.isSubmittingAction ? null : onCreate,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InventarioFisicoListPanel extends StatelessWidget {
  const _InventarioFisicoListPanel({
    required this.state,
    required this.onRetry,
    required this.onSelectInventario,
  });

  final InventarioFisicoState state;
  final VoidCallback onRetry;
  final ValueChanged<int> onSelectInventario;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (state.status == InventarioFisicoStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == InventarioFisicoStatus.error) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppMessageCard.error(
            title: 'No pudimos cargar las tomas fisicas',
            message: state.errorMessage ?? 'Intenta nuevamente.',
          ),
          const Gap(AppSpacing.lg),
          AppButton.secondary(
            label: 'Reintentar',
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
          ),
        ],
      );
    }

    if (state.items.isEmpty) {
      return const AppMessageCard.info(
        title: 'Sin tomas registradas',
        message:
            'Todavia no hay inventarios fisicos para los filtros actuales.',
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: state.items.length,
        separatorBuilder: (_, index) => const Gap(AppSpacing.md),
        itemBuilder: (context, index) {
          final item = state.items[index];
          final selected = state.selectedInventarioId == item.id;
          return _InventarioFisicoListTile(
            item: item,
            selected: selected,
            onTap: () => onSelectInventario(item.id),
          );
        },
      ),
    );
  }
}

class _InventarioFisicoListTile extends StatelessWidget {
  const _InventarioFisicoListTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final InventarioFisicoRecord item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.48)
              : theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(item.codigo, style: theme.textTheme.titleMedium),
                ),
                _StatusPill(label: item.estado),
              ],
            ),
            const Gap(AppSpacing.sm),
            Text(
              'Periodo ${item.periodoMes.toString().padLeft(2, '0')}/${item.periodoAnio}',
              style: theme.textTheme.bodyLarge,
            ),
            const Gap(AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              children: [
                _InfoChip(
                  label: DateFormat('dd/MM/yyyy').format(item.fechaInicio),
                ),
                _InfoChip(label: '${item.totalItems} items'),
                _InfoChip(label: '${item.itemsConDiferencia} con diferencia'),
                _InfoChip(
                  label:
                      'Dif. ${item.totalDiferenciaAbsoluta.toStringAsFixed(2)}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InventarioFisicoDetailPanel extends StatelessWidget {
  const _InventarioFisicoDetailPanel({
    required this.state,
    required this.onRetry,
    required this.onRegisterCounts,
    required this.onCloseInventory,
  });

  final InventarioFisicoState state;
  final VoidCallback onRetry;
  final VoidCallback onRegisterCounts;
  final VoidCallback onCloseInventory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detail = state.selectedInventario;

    if (state.isDetailLoading) {
      return AppSurfaceCard(
        padding: EdgeInsets.zero,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state.detailErrorMessage != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppMessageCard.error(
            title: 'No pudimos cargar el detalle',
            message: state.detailErrorMessage!,
          ),
          const Gap(AppSpacing.lg),
          AppButton.secondary(
            label: 'Reintentar',
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
          ),
        ],
      );
    }

    if (detail == null) {
      return const AppMessageCard.info(
        title: 'Selecciona una toma',
        message:
            'Elige un inventario fisico para revisar conteos, diferencias y cierre.',
      );
    }

    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  detail.codigo,
                  style: theme.textTheme.headlineSmall,
                ),
              ),
              _StatusPill(label: detail.estado),
            ],
          ),
          const Gap(AppSpacing.sm),
          Text(
            'Periodo ${detail.periodoMes.toString().padLeft(2, '0')}/${detail.periodoAnio}',
            style: theme.textTheme.titleMedium,
          ),
          const Gap(AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              _InfoChip(
                label:
                    'Inicio ${DateFormat('dd/MM/yyyy HH:mm').format(detail.fechaInicio)}',
              ),
              if (detail.fechaCierre != null)
                _InfoChip(
                  label:
                      'Cierre ${DateFormat('dd/MM/yyyy HH:mm').format(detail.fechaCierre!)}',
                ),
              _InfoChip(label: 'Resp. ${detail.ejecutadoPorUsuarioId}'),
            ],
          ),
          if (detail.observacion != null &&
              detail.observacion!.trim().isNotEmpty) ...[
            const Gap(AppSpacing.lg),
            Text(
              detail.observacion!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const Gap(AppSpacing.xl),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _MetricCard(
                title: 'Items',
                value: detail.resumen.totalItems.toString(),
              ),
              _MetricCard(
                title: 'Con diferencia',
                value: detail.resumen.itemsConDiferencia.toString(),
              ),
              _MetricCard(
                title: 'Ajuste +',
                value: detail.resumen.itemsConAjustePositivo.toString(),
              ),
              _MetricCard(
                title: 'Ajuste -',
                value: detail.resumen.itemsConAjusteNegativo.toString(),
              ),
            ],
          ),
          const Gap(AppSpacing.xl),
          if (detail.isOpen)
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                AppButton.primary(
                  label: 'Registrar conteos',
                  icon: Icons.fact_check_outlined,
                  expand: false,
                  isLoading: state.isSubmittingAction,
                  onPressed: state.isSubmittingAction ? null : onRegisterCounts,
                ),
                AppButton.secondary(
                  label: 'Cerrar inventario',
                  icon: Icons.lock_outline,
                  isLoading: state.isSubmittingAction,
                  onPressed: state.isSubmittingAction ? null : onCloseInventory,
                ),
              ],
            ),
          if (detail.isOpen) const Gap(AppSpacing.xl),
          Text('Conteos registrados', style: theme.textTheme.titleLarge),
          const Gap(AppSpacing.md),
          Expanded(
            child: detail.detalles.isEmpty
                ? const AppMessageCard.info(
                    title: 'Aun sin conteos',
                    message:
                        'Registra las lineas auditadas para empezar a ver diferencias y preparar el cierre.',
                  )
                : ListView.separated(
                    itemCount: detail.detalles.length,
                    separatorBuilder: (_, index) => const Gap(AppSpacing.md),
                    itemBuilder: (context, index) =>
                        _ConteoLineTile(line: detail.detalles[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ConteoLineTile extends StatelessWidget {
  const _ConteoLineTile({required this.line});

  final InventarioFisicoConteoLine line;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diffColor = line.diferencia > 0
        ? theme.colorScheme.tertiary
        : line.diferencia < 0
        ? theme.colorScheme.error
        : theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${line.insumoCodigo} - ${line.insumoNombre}',
            style: theme.textTheme.titleMedium,
          ),
          const Gap(AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              _InfoChip(
                label:
                    'Sistema ${line.stockSistema.toStringAsFixed(2)} ${line.unidadMedidaCodigo}',
              ),
              _InfoChip(
                label:
                    'Contado ${line.stockContado.toStringAsFixed(2)} ${line.unidadMedidaCodigo}',
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: diffColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Diferencia ${line.diferencia.toStringAsFixed(2)}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: diffColor,
                  ),
                ),
              ),
            ],
          ),
          if (line.observacion != null &&
              line.observacion!.trim().isNotEmpty) ...[
            const Gap(AppSpacing.sm),
            Text(
              line.observacion!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 160,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.labelLarge),
          const Gap(AppSpacing.sm),
          Text(value, style: theme.textTheme.headlineSmall),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: theme.textTheme.labelMedium),
    );
  }
}
