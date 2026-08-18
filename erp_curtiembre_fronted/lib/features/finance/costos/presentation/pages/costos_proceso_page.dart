import 'package:erp_curtiembre_fronted/core/di/service_locator.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_breakpoints.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:erp_curtiembre_fronted/features/finance/costos/domain/entities/costo_proceso_record.dart';
import 'package:erp_curtiembre_fronted/features/finance/costos/presentation/cubit/costos_proceso_cubit.dart';
import 'package:erp_curtiembre_fronted/features/finance/costos/presentation/cubit/costos_proceso_state.dart';
import 'package:erp_curtiembre_fronted/features/finance/shared/presentation/widgets/finance_ui.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/buttons/app_button.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/feedback/app_message_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:talker_flutter/talker_flutter.dart';

class CostosProcesoPage extends StatefulWidget {
  const CostosProcesoPage({super.key});

  @override
  State<CostosProcesoPage> createState() => _CostosProcesoPageState();
}

class _CostosProcesoPageState extends State<CostosProcesoPage> {
  final Talker _talker = getIt<Talker>();

  @override
  void initState() {
    super.initState();
    _talker.ui('Se abrio la pantalla de costos por proceso.');
  }

  void _showActionResult(BuildContext context, bool success, String message) {
    _talker.ui(
      success
          ? 'Accion en costos por proceso completada correctamente.'
          : 'La accion en costos por proceso fallo: $message',
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

  Future<void> _calculateCurrent(BuildContext context) async {
    _talker.ui(
      'Se solicito calcular el costo del proceso actual.',
      logLevel: LogLevel.warning,
    );
    final result = await context.read<CostosProcesoCubit>().calculateCurrent();
    if (!context.mounted) return;
    _showActionResult(context, result.success, result.message);
  }

  @override
  Widget build(BuildContext context) {
    final session = context.select((AuthCubit cubit) => cubit.state.session);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Costos por proceso'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: TextButton.icon(
              onPressed: () {
                _talker.ui(
                  'Se regreso desde costos por proceso al panel principal.',
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
                  child: BlocBuilder<CostosProcesoCubit, CostosProcesoState>(
                    builder: (context, state) {
                      final isWide =
                          MediaQuery.sizeOf(context).width >=
                          AppBreakpoints.tablet;
                      final compactHeight = constraints.maxHeight < 860;

                      final listPanel = _CostosProcesoListPanel(
                        state: state,
                        onRetry: () {
                          _talker.ui(
                            'Se solicito reintentar la carga del listado de costos por proceso.',
                          );
                          context.read<CostosProcesoCubit>().initialize();
                        },
                        onSelectItem: (id) {
                          _talker.ui(
                            'Se selecciono el costo por proceso $id desde el listado.',
                            logLevel: LogLevel.debug,
                          );
                          context.read<CostosProcesoCubit>().selectCostoProceso(
                            id,
                          );
                        },
                      );

                      final detailPanel = _CostosProcesoDetailPanel(
                        state: state,
                        onRetry: () {
                          _talker.ui(
                            'Se solicito reintentar el detalle del costo por proceso seleccionado.',
                          );
                          context.read<CostosProcesoCubit>().retryDetail();
                        },
                        onCalculate: () => _calculateCurrent(context),
                      );

                      final headerAndFilters = <Widget>[
                        FinanceHeroCard(
                          title:
                              'Consolida insumos y mano de obra al nivel exacto de cada proceso productivo.',
                          description:
                              'Este bloque te deja recalcular el costo del proceso y auditar rapidamente si el peso economico viene mas por consumo o por esfuerzo operativo.',
                          badgeLabel: 'Procesos costados',
                          badgeValue: '${state.items.length}',
                          sessionUserName: session?.userName,
                        ),
                        const Gap(AppSpacing.xl),
                        _CostosProcesoFiltersCard(
                          state: state,
                          onOrderChanged: (value) {
                            _talker.ui(
                              'Se cambio el filtro de orden en costos por proceso a ${value ?? 'todas'}.',
                              logLevel: LogLevel.debug,
                            );
                            context.read<CostosProcesoCubit>().load(
                              ordenProduccionIdFilter: value,
                              ordenProcesoIdFilter: null,
                            );
                          },
                          onProcessChanged: (value) {
                            _talker.ui(
                              'Se cambio el filtro de proceso en costos por proceso a ${value ?? 'todos'}.',
                              logLevel: LogLevel.debug,
                            );
                            context.read<CostosProcesoCubit>().load(
                              ordenProduccionIdFilter:
                                  state.ordenProduccionIdFilter,
                              ordenProcesoIdFilter: value,
                            );
                          },
                          onCalculate: () => _calculateCurrent(context),
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
}

class _CostosProcesoFiltersCard extends StatelessWidget {
  const _CostosProcesoFiltersCard({
    required this.state,
    required this.onOrderChanged,
    required this.onProcessChanged,
    required this.onCalculate,
  });

  final CostosProcesoState state;
  final ValueChanged<int?> onOrderChanged;
  final ValueChanged<int?> onProcessChanged;
  final VoidCallback onCalculate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final processes = state.ordenProduccionIdFilter == null
        ? const []
        : state.processOptionsByOrderId[state.ordenProduccionIdFilter] ??
              const [];

    return FinanceSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Orden y proceso', style: theme.textTheme.titleLarge),
          const Gap(AppSpacing.sm),
          Text(
            'Selecciona el contexto productivo que quieres costear y luego dispara el recálculo sobre ese proceso.',
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
                width: 320,
                child: DropdownButtonFormField<int?>(
                  initialValue: state.ordenProcesoIdFilter,
                  decoration: const InputDecoration(labelText: 'Proceso'),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Todos'),
                    ),
                    ...processes.map(
                      (item) => DropdownMenuItem<int?>(
                        value: item.id,
                        child: Text(
                          '${item.procesoCodigo} | ${item.procesoNombre}',
                        ),
                      ),
                    ),
                  ],
                  onChanged: state.ordenProduccionIdFilter == null
                      ? null
                      : onProcessChanged,
                ),
              ),
              AppButton.secondary(
                label: 'Calcular costo',
                icon: Icons.calculate_outlined,
                isLoading: state.isSubmittingAction,
                onPressed: onCalculate,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CostosProcesoListPanel extends StatelessWidget {
  const _CostosProcesoListPanel({
    required this.state,
    required this.onRetry,
    required this.onSelectItem,
  });

  final CostosProcesoState state;
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
            'Listado de costos por proceso',
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
              CostosProcesoStatus.loading => const Center(
                child: CircularProgressIndicator(),
              ),
              CostosProcesoStatus.error => FinanceCenteredMessage(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppMessageCard.error(
                      title: 'No pudimos cargar los costos por proceso',
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
              CostosProcesoStatus.success =>
                state.items.isEmpty
                    ? const FinanceCenteredMessage(
                        child: AppMessageCard.info(
                          title: 'Sin resultados',
                          message:
                              'Todavia no hay costos por proceso con los filtros actuales.',
                        ),
                      )
                    : ListView.separated(
                        itemCount: state.items.length,
                        separatorBuilder: (_, _) => const Gap(AppSpacing.md),
                        itemBuilder: (context, index) {
                          final item = state.items[index];
                          return _CostoProcesoListTile(
                            item: item,
                            isSelected: item.id == state.selectedCostoProcesoId,
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

class _CostosProcesoDetailPanel extends StatelessWidget {
  const _CostosProcesoDetailPanel({
    required this.state,
    required this.onRetry,
    required this.onCalculate,
  });

  final CostosProcesoState state;
  final VoidCallback onRetry;
  final VoidCallback onCalculate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = state.selectedCostoProceso;

    return FinanceSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detalle del costo por proceso',
            style: theme.textTheme.titleLarge,
          ),
          const Gap(AppSpacing.xs),
          Text(
            'Revisa la composicion entre insumos y mano de obra, y recalcula cuando la operacion cambie.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(AppSpacing.lg),
          AppButton.secondary(
            label: 'Recalcular proceso',
            icon: Icons.calculate_outlined,
            isLoading: state.isSubmittingAction,
            onPressed: onCalculate,
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
                          'Escoge un proceso costado para revisar su detalle.',
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
                            label: item.procesoCodigo,
                            background: theme.colorScheme.primaryContainer,
                            foreground: theme.colorScheme.onPrimaryContainer,
                          ),
                        ],
                      ),
                      const Gap(AppSpacing.xs),
                      Text(
                        item.procesoNombre,
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
                            title: 'Componentes',
                            lines: [
                              'Insumos: S/ ${item.costoInsumos.toStringAsFixed(2)}',
                              'Mano de obra: S/ ${item.costoManoObra.toStringAsFixed(2)}',
                              'Total: S/ ${item.costoTotal.toStringAsFixed(2)}',
                            ],
                          ),
                          FinanceDetailCard(
                            title: 'Trazabilidad',
                            lines: [
                              'Orden ID: ${item.ordenProduccionId}',
                              'Proceso ID: ${item.ordenProcesoId}',
                              'Calculado: ${formatFinanceDateTime(item.calculadoEn)}',
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

class _CostoProcesoListTile extends StatelessWidget {
  const _CostoProcesoListTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final CostoProcesoRecord item;
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
              Text(
                item.ordenProduccionCodigo,
                style: theme.textTheme.titleMedium,
              ),
              const Gap(AppSpacing.xs),
              Text(
                '${item.procesoCodigo} | ${item.procesoNombre}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const Gap(AppSpacing.md),
              Text(
                'Total: S/ ${item.costoTotal.toStringAsFixed(2)} | ${formatFinanceDateTime(item.calculadoEn)}',
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
}
