import 'package:erp_curtiembre_fronted/core/di/service_locator.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_breakpoints.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:erp_curtiembre_fronted/features/finance/depreciaciones/domain/entities/depreciacion_periodo_record.dart';
import 'package:erp_curtiembre_fronted/features/finance/depreciaciones/presentation/cubit/depreciaciones_cubit.dart';
import 'package:erp_curtiembre_fronted/features/finance/depreciaciones/presentation/cubit/depreciaciones_state.dart';
import 'package:erp_curtiembre_fronted/features/finance/depreciaciones/presentation/widgets/depreciacion_calculate_dialog.dart';
import 'package:erp_curtiembre_fronted/features/finance/shared/presentation/widgets/finance_ui.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/buttons/app_button.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/feedback/app_message_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:talker_flutter/talker_flutter.dart';

class DepreciacionesPage extends StatefulWidget {
  const DepreciacionesPage({super.key});

  @override
  State<DepreciacionesPage> createState() => _DepreciacionesPageState();
}

class _DepreciacionesPageState extends State<DepreciacionesPage> {
  final Talker _talker = getIt<Talker>();

  @override
  void initState() {
    super.initState();
    _talker.ui('Se abrio la pantalla de depreciaciones.');
  }

  Future<void> _openCalculateDialog(
    BuildContext context,
    DepreciacionesState state,
  ) async {
    final openPeriodos = state.periodoOptions
        .where((item) => item.isOpen)
        .toList(growable: false);
    if (openPeriodos.isEmpty) {
      _talker.ui(
        'Se intento calcular depreciacion sin periodos abiertos disponibles.',
        logLevel: LogLevel.warning,
      );
      _showActionResult(
        context,
        false,
        'No hay periodos abiertos disponibles para calcular depreciacion.',
      );
      return;
    }

    _talker.ui(
      'Se abrio el dialogo para calcular depreciaciones por periodo.',
      logLevel: LogLevel.warning,
    );
    final payload = await showDialog<DepreciacionCalculateDialogResult>(
      context: context,
      builder: (_) => DepreciacionCalculateDialog(
        periodos: openPeriodos,
        isSubmitting: state.isSubmittingAction,
      ),
    );

    if (payload == null || !context.mounted) {
      _talker.ui(
        'Se cerro el calculo de depreciaciones sin confirmar.',
        logLevel: LogLevel.debug,
      );
      return;
    }
    _talker.ui(
      'Se confirmo el calculo de depreciaciones para el periodo ${payload.periodoId}.',
      logLevel: LogLevel.warning,
    );

    final result = await context.read<DepreciacionesCubit>().calculateForPeriod(
      payload.periodoId,
    );

    if (!context.mounted) {
      return;
    }
    _showActionResult(context, result.success, result.message);
  }

  void _showActionResult(BuildContext context, bool success, String message) {
    _talker.ui(
      success
          ? 'Accion en depreciaciones completada correctamente.'
          : 'La accion en depreciaciones fallo: $message',
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

  @override
  Widget build(BuildContext context) {
    final session = context.select((AuthCubit cubit) => cubit.state.session);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Depreciaciones'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: TextButton.icon(
              onPressed: () {
                _talker.ui(
                  'Se regreso desde depreciaciones al panel principal.',
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
                  child: BlocBuilder<DepreciacionesCubit, DepreciacionesState>(
                    builder: (context, state) {
                      final isWide =
                          MediaQuery.sizeOf(context).width >=
                          AppBreakpoints.tablet;
                      final compactHeight = constraints.maxHeight < 860;

                      final listPanel = _DepreciacionesListPanel(
                        state: state,
                        onRetry: () {
                          _talker.ui(
                            'Se solicito reintentar la carga del listado de depreciaciones.',
                          );
                          context.read<DepreciacionesCubit>().initialize();
                        },
                        onSelectItem: (id) {
                          _talker.ui(
                            'Se selecciono la depreciacion $id desde el listado.',
                            logLevel: LogLevel.debug,
                          );
                          context
                              .read<DepreciacionesCubit>()
                              .selectDepreciacion(id);
                        },
                      );

                      final detailPanel = _DepreciacionesDetailPanel(
                        state: state,
                        onRetry: () {
                          _talker.ui(
                            'Se solicito reintentar el detalle de la depreciacion seleccionada.',
                          );
                          context.read<DepreciacionesCubit>().retryDetail();
                        },
                      );

                      final headerAndFilters = <Widget>[
                        FinanceHeroCard(
                          title:
                              'Genera y revisa la depreciacion mensual usando los activos vigentes y el periodo financiero correcto.',
                          description:
                              'Este bloque sirve para auditar cuanto desgaste mensual entra al costo real antes de cerrar ordenes y reportes de rentabilidad.',
                          badgeLabel: 'Depreciaciones visibles',
                          badgeValue: '${state.items.length}',
                          sessionUserName: session?.userName,
                        ),
                        const Gap(AppSpacing.xl),
                        _DepreciacionesFiltersCard(
                          state: state,
                          onPeriodChanged: (value) {
                            _talker.ui(
                              'Se cambio el filtro de periodo en depreciaciones a ${value ?? 'todos'}.',
                              logLevel: LogLevel.debug,
                            );
                            context.read<DepreciacionesCubit>().load(
                              periodoCostoIdFilter: value,
                              activoDepreciableIdFilter:
                                  state.activoDepreciableIdFilter,
                            );
                          },
                          onActivoChanged: (value) {
                            _talker.ui(
                              'Se cambio el filtro de activo en depreciaciones a ${value ?? 'todos'}.',
                              logLevel: LogLevel.debug,
                            );
                            context.read<DepreciacionesCubit>().load(
                              periodoCostoIdFilter: state.periodoCostoIdFilter,
                              activoDepreciableIdFilter: value,
                            );
                          },
                          onCalculate: () =>
                              _openCalculateDialog(context, state),
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

class _DepreciacionesFiltersCard extends StatelessWidget {
  const _DepreciacionesFiltersCard({
    required this.state,
    required this.onPeriodChanged,
    required this.onActivoChanged,
    required this.onCalculate,
  });

  final DepreciacionesState state;
  final ValueChanged<int?> onPeriodChanged;
  final ValueChanged<int?> onActivoChanged;
  final VoidCallback onCalculate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FinanceSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Periodo y activo', style: theme.textTheme.titleLarge),
          const Gap(AppSpacing.sm),
          Text(
            'Filtra la vista para auditar depreciaciones ya generadas y lanza el calculo solo sobre periodos que aun siguen abiertos.',
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
                width: 260,
                child: DropdownButtonFormField<int?>(
                  initialValue: state.periodoCostoIdFilter,
                  decoration: const InputDecoration(labelText: 'Periodo'),
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
                  onChanged: onPeriodChanged,
                ),
              ),
              SizedBox(
                width: 320,
                child: DropdownButtonFormField<int?>(
                  initialValue: state.activoDepreciableIdFilter,
                  decoration: const InputDecoration(labelText: 'Activo'),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Todos'),
                    ),
                    ...state.activoOptions.map(
                      (item) => DropdownMenuItem<int?>(
                        value: item.id,
                        child: Text('${item.codigo} | ${item.nombre}'),
                      ),
                    ),
                  ],
                  onChanged: onActivoChanged,
                ),
              ),
              AppButton.secondary(
                label: 'Calcular depreciacion',
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

class _DepreciacionesListPanel extends StatelessWidget {
  const _DepreciacionesListPanel({
    required this.state,
    required this.onRetry,
    required this.onSelectItem,
  });

  final DepreciacionesState state;
  final VoidCallback onRetry;
  final ValueChanged<int> onSelectItem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FinanceSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Listado de depreciaciones', style: theme.textTheme.titleLarge),
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
              DepreciacionesStatus.loading => const Center(
                child: CircularProgressIndicator(),
              ),
              DepreciacionesStatus.error => FinanceCenteredMessage(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppMessageCard.error(
                      title: 'No pudimos cargar las depreciaciones',
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
              DepreciacionesStatus.success =>
                state.items.isEmpty
                    ? const FinanceCenteredMessage(
                        child: AppMessageCard.info(
                          title: 'Sin resultados',
                          message:
                              'Todavia no hay depreciaciones con los filtros actuales.',
                        ),
                      )
                    : ListView.separated(
                        itemCount: state.items.length,
                        separatorBuilder: (_, _) => const Gap(AppSpacing.md),
                        itemBuilder: (context, index) {
                          final item = state.items[index];
                          return _DepreciacionListTile(
                            item: item,
                            isSelected: item.id == state.selectedDepreciacionId,
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

class _DepreciacionesDetailPanel extends StatelessWidget {
  const _DepreciacionesDetailPanel({
    required this.state,
    required this.onRetry,
  });

  final DepreciacionesState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = state.selectedDepreciacion;

    return FinanceSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Detalle de depreciacion', style: theme.textTheme.titleLarge),
          const Gap(AppSpacing.xs),
          Text(
            'Revisa el periodo exacto, el activo afectado y el monto mensual ya calculado por backend.',
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
                          'Escoge un registro del listado para revisar su detalle.',
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
                            item.activoNombre,
                            style: theme.textTheme.headlineSmall,
                          ),
                          FinanceStatusPill(
                            label: item.periodoCodigo,
                            background: theme.colorScheme.primaryContainer,
                            foreground: theme.colorScheme.onPrimaryContainer,
                          ),
                        ],
                      ),
                      const Gap(AppSpacing.xs),
                      Text(
                        item.activoCodigo,
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
                            title: 'Periodo',
                            lines: [
                              'Periodo ID: ${item.periodoCostoId}',
                              'Anio: ${item.periodoAnio}',
                              'Mes: ${item.periodoMes.toString().padLeft(2, '0')}',
                            ],
                          ),
                          FinanceDetailCard(
                            title: 'Monto aplicado',
                            lines: [
                              'Depreciacion: S/ ${item.montoDepreciacion.toStringAsFixed(2)}',
                              'Calculado: ${formatFinanceDateTime(item.calculadoEn)}',
                              'Activo ID: ${item.activoDepreciableId}',
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

class _DepreciacionListTile extends StatelessWidget {
  const _DepreciacionListTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final DepreciacionPeriodoRecord item;
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
              Text(item.activoNombre, style: theme.textTheme.titleMedium),
              const Gap(AppSpacing.xs),
              Text(
                '${item.activoCodigo} | ${item.periodoCodigo}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const Gap(AppSpacing.md),
              Text(
                'Monto: S/ ${item.montoDepreciacion.toStringAsFixed(2)} | ${formatFinanceDateTime(item.calculadoEn)}',
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
