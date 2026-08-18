import 'package:erp_curtiembre_fronted/core/di/service_locator.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_breakpoints.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:erp_curtiembre_fronted/features/finance/costos/domain/entities/costo_orden_record.dart';
import 'package:erp_curtiembre_fronted/features/finance/costos/presentation/cubit/costos_orden_cubit.dart';
import 'package:erp_curtiembre_fronted/features/finance/costos/presentation/cubit/costos_orden_state.dart';
import 'package:erp_curtiembre_fronted/features/finance/shared/presentation/widgets/finance_ui.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/buttons/app_button.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/feedback/app_message_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:talker_flutter/talker_flutter.dart';

class CostosOrdenPage extends StatefulWidget {
  const CostosOrdenPage({super.key});

  @override
  State<CostosOrdenPage> createState() => _CostosOrdenPageState();
}

class _CostosOrdenPageState extends State<CostosOrdenPage> {
  final Talker _talker = getIt<Talker>();

  @override
  void initState() {
    super.initState();
    _talker.ui('Se abrio la pantalla de costos por orden.');
  }

  void _showActionResult(BuildContext context, bool success, String message) {
    _talker.ui(
      success
          ? 'Accion en costos por orden completada correctamente.'
          : 'La accion en costos por orden fallo: $message',
      logLevel: success ? LogLevel.debug : LogLevel.error,
    );
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: success ? null : const Color(0xFF8A2F22),
      ),
    );
  }

  Future<void> _calculateEstimated(BuildContext context) async {
    _talker.ui(
      'Se solicito calcular el costo estimado de la orden actual.',
      logLevel: LogLevel.warning,
    );
    final result = await context
        .read<CostosOrdenCubit>()
        .calculateEstimatedCurrent();
    if (!context.mounted) return;
    _showActionResult(context, result.success, result.message);
  }

  Future<void> _calculateReal(BuildContext context) async {
    _talker.ui(
      'Se solicito calcular el costo real de la orden actual.',
      logLevel: LogLevel.warning,
    );
    final result = await context
        .read<CostosOrdenCubit>()
        .calculateRealCurrent();
    if (!context.mounted) return;
    _showActionResult(context, result.success, result.message);
  }

  Future<void> _closeCurrent(BuildContext context) async {
    _talker.ui(
      'Se solicito cerrar el costo de la orden actual.',
      logLevel: LogLevel.warning,
    );
    final result = await context.read<CostosOrdenCubit>().closeCurrent();
    if (!context.mounted) return;
    _showActionResult(context, result.success, result.message);
  }

  @override
  Widget build(BuildContext context) {
    final session = context.select((AuthCubit cubit) => cubit.state.session);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Costos por orden'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: TextButton.icon(
              onPressed: () {
                _talker.ui(
                  'Se regreso desde costos por orden al panel principal.',
                );
                context.go('/home');
              },
              icon: const Icon(Icons.dashboard_outlined),
              label: const Text('Panel'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1440),
                  child: BlocBuilder<CostosOrdenCubit, CostosOrdenState>(
                    builder: (context, state) {
                      final isWide =
                          MediaQuery.sizeOf(context).width >=
                          AppBreakpoints.tablet;
                      final compactHeight = constraints.maxHeight < 860;

                      final listPanel = _CostosOrdenListPanel(
                        state: state,
                        onRetry: () {
                          _talker.ui(
                            'Se solicito reintentar la carga del listado de costos por orden.',
                          );
                          context.read<CostosOrdenCubit>().initialize();
                        },
                        onSelectItem: (id) {
                          _talker.ui(
                            'Se selecciono el costo por orden $id desde el listado.',
                            logLevel: LogLevel.debug,
                          );
                          context.read<CostosOrdenCubit>().selectCostoOrden(id);
                        },
                      );

                      final detailPanel = _CostosOrdenDetailPanel(
                        state: state,
                        onRetry: () {
                          _talker.ui(
                            'Se solicito reintentar el detalle del costo por orden seleccionado.',
                          );
                          context.read<CostosOrdenCubit>().retryDetail();
                        },
                        onCalculateEstimated: () =>
                            _calculateEstimated(context),
                        onCalculateReal: () => _calculateReal(context),
                        onClose: () => _closeCurrent(context),
                      );

                      final headerAndFilters = <Widget>[
                        FinanceHeroCard(
                          title:
                              'Consolida el costo total de la orden y valida el impacto real de pieles, insumos, mano de obra, indirectos y depreciacion.',
                          description:
                              'Desde aqui calculas estimado, luego real, y finalmente cierras el costo para dejar lista la base de precio y rentabilidad.',
                          badgeLabel: 'Ordenes costadas',
                          badgeValue: '${state.items.length}',
                          sessionUserName: session?.userName,
                        ),
                        const Gap(AppSpacing.xl),
                        _CostosOrdenFiltersCard(
                          state: state,
                          onOrderChanged: (value) {
                            _talker.ui(
                              'Se cambio el filtro de orden en costos por orden a ${value ?? 'todas'}.',
                              logLevel: LogLevel.debug,
                            );
                            context.read<CostosOrdenCubit>().load(
                              ordenProduccionIdFilter: value,
                              periodoCostoIdFilter: state.periodoCostoIdFilter,
                              estadoFilter: state.estadoFilter,
                            );
                          },
                          onPeriodoChanged: (value) {
                            _talker.ui(
                              'Se cambio el filtro de periodo en costos por orden a ${value ?? 'todos'}.',
                              logLevel: LogLevel.debug,
                            );
                            context.read<CostosOrdenCubit>().load(
                              ordenProduccionIdFilter:
                                  state.ordenProduccionIdFilter,
                              periodoCostoIdFilter: value,
                              estadoFilter: state.estadoFilter,
                            );
                          },
                          onEstadoChanged: (value) {
                            _talker.ui(
                              'Se cambio el filtro de estado en costos por orden a ${_describeState(value)}.',
                              logLevel: LogLevel.debug,
                            );
                            context.read<CostosOrdenCubit>().load(
                              ordenProduccionIdFilter:
                                  state.ordenProduccionIdFilter,
                              periodoCostoIdFilter: state.periodoCostoIdFilter,
                              estadoFilter: value,
                            );
                          },
                          onCalculateEstimated: () =>
                              _calculateEstimated(context),
                          onCalculateReal: () => _calculateReal(context),
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
      ),
    );
  }

  String _describeState(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return normalized;
  }
}

class _CostosOrdenFiltersCard extends StatelessWidget {
  const _CostosOrdenFiltersCard({
    required this.state,
    required this.onOrderChanged,
    required this.onPeriodoChanged,
    required this.onEstadoChanged,
    required this.onCalculateEstimated,
    required this.onCalculateReal,
  });

  final CostosOrdenState state;
  final ValueChanged<int?> onOrderChanged;
  final ValueChanged<int?> onPeriodoChanged;
  final ValueChanged<String?> onEstadoChanged;
  final VoidCallback onCalculateEstimated;
  final VoidCallback onCalculateReal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FinanceSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Orden, periodo y estado', style: theme.textTheme.titleLarge),
          const Gap(AppSpacing.sm),
          Text(
            'Filtra la base financiera y usa la orden seleccionada para calcular estimado o real segun su avance.',
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
                width: 360,
                child: DropdownButtonFormField<int?>(
                  initialValue: state.ordenProduccionIdFilter,
                  decoration: const InputDecoration(
                    labelText: 'Orden de produccion',
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Todas'),
                    ),
                    ...state.ordenOptions.map(
                      (item) => DropdownMenuItem<int?>(
                        value: item.id,
                        child: Text(
                          '${item.codigo} | ${item.clienteRazonSocial}',
                        ),
                      ),
                    ),
                  ],
                  onChanged: onOrderChanged,
                ),
              ),
              SizedBox(
                width: 260,
                child: DropdownButtonFormField<int?>(
                  initialValue: state.periodoCostoIdFilter,
                  decoration: const InputDecoration(
                    labelText: 'Periodo de costo',
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Todos'),
                    ),
                    ...state.periodoOptions.map(
                      (item) => DropdownMenuItem<int?>(
                        value: item.id,
                        child: Text('${item.codigo} | ${item.estado}'),
                      ),
                    ),
                  ],
                  onChanged: onPeriodoChanged,
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
                      value: 'ESTIMADO',
                      child: Text('ESTIMADO'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'REAL',
                      child: Text('REAL'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'CERRADO',
                      child: Text('CERRADO'),
                    ),
                  ],
                  onChanged: onEstadoChanged,
                ),
              ),
              AppButton.secondary(
                label: 'Calcular estimado',
                icon: Icons.analytics_outlined,
                isLoading: state.isSubmittingAction,
                onPressed: onCalculateEstimated,
              ),
              AppButton.secondary(
                label: 'Calcular real',
                icon: Icons.price_change_outlined,
                isLoading: state.isSubmittingAction,
                onPressed: onCalculateReal,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CostosOrdenListPanel extends StatelessWidget {
  const _CostosOrdenListPanel({
    required this.state,
    required this.onRetry,
    required this.onSelectItem,
  });

  final CostosOrdenState state;
  final VoidCallback onRetry;
  final ValueChanged<int> onSelectItem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FinanceSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Listado de costos por orden',
            style: theme.textTheme.titleLarge,
          ),
          const Gap(AppSpacing.xs),
          Text(
            '${state.items.length} registro(s) para la vista actual.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(AppSpacing.lg),
          Expanded(
            child: switch (state.status) {
              CostosOrdenStatus.loading => const Center(
                child: CircularProgressIndicator(),
              ),
              CostosOrdenStatus.error => FinanceCenteredMessage(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppMessageCard.error(
                      title: 'No pudimos cargar los costos por orden',
                      message:
                          state.errorMessage ??
                          'Intenta nuevamente para consultar la base financiera.',
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
              CostosOrdenStatus.success =>
                state.items.isEmpty
                    ? const FinanceCenteredMessage(
                        child: AppMessageCard.info(
                          title: 'Sin resultados',
                          message:
                              'Todavia no hay costos por orden con los filtros actuales.',
                        ),
                      )
                    : ListView.separated(
                        itemCount: state.items.length,
                        separatorBuilder: (_, _) => const Gap(AppSpacing.md),
                        itemBuilder: (context, index) {
                          final item = state.items[index];
                          return _CostoOrdenListTile(
                            item: item,
                            isSelected: item.id == state.selectedCostoOrdenId,
                            onTap: () => onSelectItem(item.id),
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

class _CostosOrdenDetailPanel extends StatelessWidget {
  const _CostosOrdenDetailPanel({
    required this.state,
    required this.onRetry,
    required this.onCalculateEstimated,
    required this.onCalculateReal,
    required this.onClose,
  });

  final CostosOrdenState state;
  final VoidCallback onRetry;
  final VoidCallback onCalculateEstimated;
  final VoidCallback onCalculateReal;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = state.selectedCostoOrden;

    return FinanceSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detalle del costo por orden',
            style: theme.textTheme.titleLarge,
          ),
          const Gap(AppSpacing.xs),
          Text(
            'Revisa el reparto completo del costo y avanza desde estimado hasta cerrado segun el estado actual.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              AppButton.secondary(
                label: 'Calcular estimado',
                icon: Icons.analytics_outlined,
                isLoading: state.isSubmittingAction,
                onPressed: onCalculateEstimated,
              ),
              AppButton.secondary(
                label: 'Calcular real',
                icon: Icons.price_change_outlined,
                isLoading: state.isSubmittingAction,
                onPressed: onCalculateReal,
              ),
              AppButton.secondary(
                label: 'Cerrar costo',
                icon: Icons.lock_outline,
                isLoading: state.isSubmittingAction,
                onPressed: item?.canClose == true ? onClose : null,
              ),
            ],
          ),
          const Gap(AppSpacing.lg),
          Expanded(
            child: Builder(
              builder: (context) {
                if (state.isDetailLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.detailErrorMessage != null) {
                  return FinanceCenteredMessage(
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
                if (item == null) {
                  return const FinanceCenteredMessage(
                    child: AppMessageCard.info(
                      title: 'Selecciona un registro',
                      message:
                          'Escoge una orden costada para revisar su detalle.',
                    ),
                  );
                }

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.md,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            item.ordenProduccionCodigo,
                            style: theme.textTheme.headlineSmall,
                          ),
                          FinanceStatusPill(
                            label: item.estado,
                            background: _statusBackground(theme, item.estado),
                            foreground: _statusForeground(theme, item.estado),
                          ),
                        ],
                      ),
                      const Gap(AppSpacing.xs),
                      Text(
                        item.periodoCodigo == null
                            ? 'Sin periodo asignado'
                            : 'Periodo ${item.periodoCodigo}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const Gap(AppSpacing.xl),
                      Wrap(
                        spacing: AppSpacing.lg,
                        runSpacing: AppSpacing.lg,
                        children: [
                          FinanceDetailCard(
                            title: 'Costos directos',
                            lines: [
                              'Pieles: S/ ${item.costoPieles.toStringAsFixed(2)}',
                              'Insumos: S/ ${item.costoInsumos.toStringAsFixed(2)}',
                              'Mano de obra: S/ ${item.costoManoObra.toStringAsFixed(2)}',
                            ],
                          ),
                          FinanceDetailCard(
                            title: 'Asignaciones',
                            lines: [
                              'Indirectos: S/ ${item.costoIndirectoAsignado.toStringAsFixed(2)}',
                              'Depreciacion: S/ ${item.costoDepreciacionAsignado.toStringAsFixed(2)}',
                              'Total: S/ ${item.costoTotal.toStringAsFixed(2)}',
                            ],
                          ),
                          FinanceDetailCard(
                            title: 'Cierre economico',
                            lines: [
                              'Pieles buenas: ${item.pielesBuenasFinales?.toStringAsFixed(2) ?? 'Sin registro'}',
                              'Costo por piel: ${item.costoPorPiel == null ? 'Sin registro' : 'S/ ${item.costoPorPiel!.toStringAsFixed(2)}'}',
                              'Calculado: ${formatFinanceDateTime(item.calculadoEn)}',
                            ],
                          ),
                        ],
                      ),
                      const Gap(AppSpacing.lg),
                      Wrap(
                        spacing: AppSpacing.lg,
                        runSpacing: AppSpacing.lg,
                        children: [
                          FinanceDetailCard(
                            title: 'Estimacion y real',
                            width: 400,
                            lines: [
                              'Costo estimado: ${item.costoEstimado == null ? 'Sin registro' : 'S/ ${item.costoEstimado!.toStringAsFixed(2)}'}',
                              'Costo real: ${item.costoReal == null ? 'Sin registro' : 'S/ ${item.costoReal!.toStringAsFixed(2)}'}',
                              'Usuario calculador: ${item.calculadoPorUsuarioId?.toString() ?? 'Sin registro'}',
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

  Color _statusBackground(ThemeData theme, String status) {
    return switch (status) {
      'ESTIMADO' => theme.colorScheme.secondaryContainer,
      'REAL' => theme.colorScheme.primaryContainer,
      'CERRADO' => theme.colorScheme.surfaceContainerHighest,
      _ => theme.colorScheme.surfaceContainerHighest,
    };
  }

  Color _statusForeground(ThemeData theme, String status) {
    return switch (status) {
      'ESTIMADO' => theme.colorScheme.onSecondaryContainer,
      'REAL' => theme.colorScheme.onPrimaryContainer,
      'CERRADO' => theme.colorScheme.onSurfaceVariant,
      _ => theme.colorScheme.onSurfaceVariant,
    };
  }
}

class _CostoOrdenListTile extends StatelessWidget {
  const _CostoOrdenListTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final CostoOrdenRecord item;
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
                  Text(
                    item.ordenProduccionCodigo,
                    style: theme.textTheme.titleMedium,
                  ),
                  FinanceStatusPill(
                    label: item.estado,
                    background: _statusBackground(theme, item.estado),
                    foreground: _statusForeground(theme, item.estado),
                  ),
                ],
              ),
              const Gap(AppSpacing.xs),
              Text(
                item.periodoCodigo == null
                    ? 'Sin periodo'
                    : 'Periodo ${item.periodoCodigo}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const Gap(AppSpacing.md),
              Text(
                'Total: S/ ${item.costoTotal.toStringAsFixed(2)} | Costo/piel: ${item.costoPorPiel == null ? 'Sin registro' : 'S/ ${item.costoPorPiel!.toStringAsFixed(2)}'}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusBackground(ThemeData theme, String status) {
    return switch (status) {
      'ESTIMADO' => theme.colorScheme.secondaryContainer,
      'REAL' => theme.colorScheme.primaryContainer,
      'CERRADO' => theme.colorScheme.surfaceContainerHighest,
      _ => theme.colorScheme.surfaceContainerHighest,
    };
  }

  Color _statusForeground(ThemeData theme, String status) {
    return switch (status) {
      'ESTIMADO' => theme.colorScheme.onSecondaryContainer,
      'REAL' => theme.colorScheme.onPrimaryContainer,
      'CERRADO' => theme.colorScheme.onSurfaceVariant,
      _ => theme.colorScheme.onSurfaceVariant,
    };
  }
}
