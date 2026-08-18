import 'package:erp_curtiembre_fronted/core/di/service_locator.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_breakpoints.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:erp_curtiembre_fronted/features/finance/mano_obra/domain/entities/mano_obra_directa_record.dart';
import 'package:erp_curtiembre_fronted/features/finance/mano_obra/presentation/cubit/mano_obra_cubit.dart';
import 'package:erp_curtiembre_fronted/features/finance/mano_obra/presentation/cubit/mano_obra_state.dart';
import 'package:erp_curtiembre_fronted/features/finance/mano_obra/presentation/widgets/mano_obra_upsert_dialog.dart';
import 'package:erp_curtiembre_fronted/features/finance/shared/presentation/widgets/finance_ui.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/buttons/app_button.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/feedback/app_message_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:talker_flutter/talker_flutter.dart';

class ManoObraPage extends StatefulWidget {
  const ManoObraPage({super.key});

  @override
  State<ManoObraPage> createState() => _ManoObraPageState();
}

class _ManoObraPageState extends State<ManoObraPage> {
  final Talker _talker = getIt<Talker>();

  @override
  void initState() {
    super.initState();
    _talker.ui('Se abrio la pantalla de mano de obra directa.');
  }

  Future<void> _openCreateDialog(
    BuildContext context,
    ManoObraState state,
  ) async {
    if (state.ordenOptions.isEmpty) {
      _talker.ui(
        'Se intento registrar mano de obra sin ordenes de produccion disponibles.',
        logLevel: LogLevel.warning,
      );
      _showActionResult(
        context,
        false,
        'Todavia no existen ordenes de produccion para registrar mano de obra.',
      );
      return;
    }

    _talker.ui(
      'Se abrio el dialogo para registrar mano de obra directa.',
      logLevel: LogLevel.warning,
    );
    final payload = await showDialog<ManoObraUpsertFormData>(
      context: context,
      builder: (_) => ManoObraUpsertDialog(
        ordenes: state.ordenOptions,
        processesByOrder: context.read<ManoObraCubit>().processOptionsForOrder,
        isSubmitting: state.isSubmittingAction,
      ),
    );

    if (payload == null || !context.mounted) {
      _talker.ui(
        'Se cerro el registro de mano de obra sin confirmar.',
        logLevel: LogLevel.debug,
      );
      return;
    }
    _talker.ui(
      'Se confirmo el registro de mano de obra con orden=${payload.ordenProduccionId}, proceso=${payload.ordenProcesoId}, monto=${payload.monto}, descripcion=${_describeText(payload.descripcion)}.',
      logLevel: LogLevel.warning,
    );

    final result = await context.read<ManoObraCubit>().createManoObra(
      ordenProduccionId: payload.ordenProduccionId,
      ordenProcesoId: payload.ordenProcesoId,
      monto: payload.monto,
      descripcion: payload.descripcion,
    );

    if (!context.mounted) {
      return;
    }
    _showActionResult(context, result.success, result.message);
  }

  void _showActionResult(BuildContext context, bool success, String message) {
    _talker.ui(
      success
          ? 'Accion en mano de obra directa completada correctamente.'
          : 'La accion en mano de obra directa fallo: $message',
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
        title: const Text('Mano de obra directa'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: TextButton.icon(
              onPressed: () {
                _talker.ui(
                  'Se regreso desde mano de obra directa al panel principal.',
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
                  child: BlocBuilder<ManoObraCubit, ManoObraState>(
                    builder: (context, state) {
                      final isWide =
                          MediaQuery.sizeOf(context).width >=
                          AppBreakpoints.tablet;
                      final compactHeight = constraints.maxHeight < 860;

                      final listPanel = _ManoObraListPanel(
                        state: state,
                        onRetry: () {
                          _talker.ui(
                            'Se solicito reintentar la carga del listado de mano de obra.',
                          );
                          context.read<ManoObraCubit>().initialize();
                        },
                        onSelectItem: (id) {
                          _talker.ui(
                            'Se selecciono el registro de mano de obra $id desde el listado.',
                            logLevel: LogLevel.debug,
                          );
                          context.read<ManoObraCubit>().selectManoObra(id);
                        },
                      );

                      final detailPanel = _ManoObraDetailPanel(
                        state: state,
                        onRetry: () {
                          _talker.ui(
                            'Se solicito reintentar el detalle de mano de obra seleccionado.',
                          );
                          context.read<ManoObraCubit>().retryDetail();
                        },
                      );

                      final headerAndFilters = <Widget>[
                        FinanceHeroCard(
                          title:
                              'Consolida el costo humano real por orden y proceso antes de cerrar el costo financiero.',
                          description:
                              'Cada registro queda amarrado a una orden de produccion y a un proceso real para que luego alimente costo por proceso y costo total de la orden.',
                          badgeLabel: 'Registros visibles',
                          badgeValue: '${state.items.length}',
                          sessionUserName: session?.userName,
                        ),
                        const Gap(AppSpacing.xl),
                        _ManoObraFiltersCard(
                          state: state,
                          onOrderChanged: (value) {
                            _talker.ui(
                              'Se cambio el filtro de orden en mano de obra a ${value ?? 'todas'}.',
                              logLevel: LogLevel.debug,
                            );
                            context.read<ManoObraCubit>().load(
                              ordenProduccionIdFilter: value,
                              ordenProcesoIdFilter: null,
                            );
                          },
                          onProcessChanged: (value) {
                            _talker.ui(
                              'Se cambio el filtro de proceso en mano de obra a ${value ?? 'todos'}.',
                              logLevel: LogLevel.debug,
                            );
                            context.read<ManoObraCubit>().load(
                              ordenProduccionIdFilter:
                                  state.ordenProduccionIdFilter,
                              ordenProcesoIdFilter: value,
                            );
                          },
                          onCreate: () => _openCreateDialog(context, state),
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

  String _describeText(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return '${normalized.length} caracteres';
  }
}

class _ManoObraFiltersCard extends StatelessWidget {
  const _ManoObraFiltersCard({
    required this.state,
    required this.onOrderChanged,
    required this.onProcessChanged,
    required this.onCreate,
  });

  final ManoObraState state;
  final ValueChanged<int?> onOrderChanged;
  final ValueChanged<int?> onProcessChanged;
  final VoidCallback onCreate;

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
          Text('Cruce operativo', style: theme.textTheme.titleLarge),
          const Gap(AppSpacing.sm),
          Text(
            'Filtra por orden o proceso y registra nuevos montos solo cuando la operacion ya existe en Produccion.',
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
                label: 'Registrar mano de obra',
                icon: Icons.payments_outlined,
                isLoading: state.isSubmittingAction,
                onPressed: onCreate,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ManoObraListPanel extends StatelessWidget {
  const _ManoObraListPanel({
    required this.state,
    required this.onRetry,
    required this.onSelectItem,
  });

  final ManoObraState state;
  final VoidCallback onRetry;
  final ValueChanged<int> onSelectItem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FinanceSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Listado de mano de obra', style: theme.textTheme.titleLarge),
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
              ManoObraStatus.loading => const Center(
                child: CircularProgressIndicator(),
              ),
              ManoObraStatus.error => FinanceCenteredMessage(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppMessageCard.error(
                      title: 'No pudimos cargar la mano de obra',
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
              ManoObraStatus.success =>
                state.items.isEmpty
                    ? const FinanceCenteredMessage(
                        child: AppMessageCard.info(
                          title: 'Sin registros',
                          message:
                              'Todavia no hay mano de obra para los filtros actuales.',
                        ),
                      )
                    : ListView.separated(
                        itemCount: state.items.length,
                        separatorBuilder: (_, _) => const Gap(AppSpacing.md),
                        itemBuilder: (context, index) {
                          final item = state.items[index];
                          return _ManoObraListTile(
                            item: item,
                            isSelected: item.id == state.selectedManoObraId,
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

class _ManoObraDetailPanel extends StatelessWidget {
  const _ManoObraDetailPanel({required this.state, required this.onRetry});

  final ManoObraState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = state.selectedManoObra;

    return FinanceSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Detalle de mano de obra', style: theme.textTheme.titleLarge),
          const Gap(AppSpacing.xs),
          Text(
            'Revisa el proceso asociado, el monto aplicado y la trazabilidad del registro.',
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
                            title: 'Identidad',
                            lines: [
                              'ID: ${item.id}',
                              'Orden ID: ${item.ordenProduccionId}',
                              'Proceso ID: ${item.ordenProcesoId}',
                            ],
                          ),
                          FinanceDetailCard(
                            title: 'Monto y fecha',
                            lines: [
                              'Monto: S/ ${item.monto.toStringAsFixed(2)}',
                              'Registrado: ${formatFinanceDateTime(item.registradoEn)}',
                              'Usuario: ${item.registradoPorUsuarioId?.toString() ?? 'Sin registro'}',
                            ],
                          ),
                        ],
                      ),
                      if ((item.descripcion ?? '').trim().isNotEmpty) ...[
                        const Gap(AppSpacing.xl),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Descripcion',
                                style: theme.textTheme.titleMedium,
                              ),
                              const Gap(AppSpacing.md),
                              Text(
                                item.descripcion!,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
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

class _ManoObraListTile extends StatelessWidget {
  const _ManoObraListTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final ManoObraDirectaRecord item;
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
                'Monto: S/ ${item.monto.toStringAsFixed(2)} | ${formatFinanceDateTime(item.registradoEn)}',
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
