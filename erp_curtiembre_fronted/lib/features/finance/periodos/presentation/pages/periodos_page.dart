import 'package:erp_curtiembre_fronted/core/di/service_locator.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_breakpoints.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:erp_curtiembre_fronted/features/finance/periodos/domain/entities/periodo_costo_record.dart';
import 'package:erp_curtiembre_fronted/features/finance/periodos/presentation/cubit/periodos_cubit.dart';
import 'package:erp_curtiembre_fronted/features/finance/periodos/presentation/cubit/periodos_state.dart';
import 'package:erp_curtiembre_fronted/features/finance/periodos/presentation/widgets/periodo_close_dialog.dart';
import 'package:erp_curtiembre_fronted/features/finance/periodos/presentation/widgets/periodo_upsert_dialog.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/buttons/app_button.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/feedback/app_message_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:talker_flutter/talker_flutter.dart';

class PeriodosPage extends StatefulWidget {
  const PeriodosPage({super.key});

  @override
  State<PeriodosPage> createState() => _PeriodosPageState();
}

class _PeriodosPageState extends State<PeriodosPage> {
  final _anioController = TextEditingController();
  final Talker _talker = getIt<Talker>();

  @override
  void initState() {
    super.initState();
    _talker.ui('Se abrio la pantalla de periodos de costo.');
  }

  @override
  void dispose() {
    _anioController.dispose();
    super.dispose();
  }

  void _applyFilters(
    PeriodosState state, {
    int? monthOverride,
    String? statusOverride,
  }) {
    FocusScope.of(context).unfocus();
    _talker.ui(
      'Se aplicaron filtros de periodos de costo con anio=${int.tryParse(_anioController.text.trim())?.toString() ?? 'vacio'}, mes=${monthOverride ?? state.mesFilter ?? 'todos'}, estado=${_describeState(statusOverride ?? state.estadoFilter)}.',
    );
    context.read<PeriodosCubit>().load(
      anioFilter: int.tryParse(_anioController.text.trim()),
      mesFilter: monthOverride ?? state.mesFilter,
      estadoFilter: statusOverride ?? state.estadoFilter,
    );
  }

  Future<void> _openCreateDialog(PeriodosState state) async {
    _talker.ui(
      'Se abrio el dialogo para crear un periodo de costo.',
      logLevel: LogLevel.warning,
    );
    final payload = await showDialog<PeriodoUpsertFormData>(
      context: context,
      builder: (_) =>
          PeriodoUpsertDialog(isSubmitting: state.isSubmittingAction),
    );

    if (payload == null || !mounted) {
      _talker.ui(
        'Se cerro la creacion de periodo de costo sin confirmar.',
        logLevel: LogLevel.debug,
      );
      return;
    }
    _talker.ui(
      'Se confirmo la creacion de un periodo de costo con anio=${payload.anio}, mes=${payload.mes}, observacion=${_describeText(payload.observacion)}.',
      logLevel: LogLevel.warning,
    );

    final result = await context.read<PeriodosCubit>().createPeriodo(
      anio: payload.anio,
      mes: payload.mes,
      observacion: payload.observacion,
    );

    if (!mounted) return;
    _showActionResult(result.success, result.message);
  }

  Future<void> _openCloseDialog(
    PeriodosState state,
    PeriodoCostoRecord periodo,
  ) async {
    _talker.ui(
      'Se abrio el dialogo para cerrar el periodo de costo ${periodo.id}.',
      logLevel: LogLevel.warning,
    );
    final payload = await showDialog<PeriodoCloseDialogResult>(
      context: context,
      builder: (_) => PeriodoCloseDialog(
        periodo: periodo,
        isSubmitting: state.isSubmittingAction,
      ),
    );

    if (payload == null || !mounted) {
      _talker.ui(
        'Se cerro el cierre del periodo de costo ${periodo.id} sin confirmar.',
        logLevel: LogLevel.debug,
      );
      return;
    }
    _talker.ui(
      'Se confirmo el cierre del periodo de costo ${periodo.id} con observacion=${_describeText(payload.observacion)}.',
      logLevel: LogLevel.warning,
    );

    final result = await context.read<PeriodosCubit>().closeSelectedPeriodo(
      observacion: payload.observacion,
    );

    if (!mounted) return;
    _showActionResult(result.success, result.message);
  }

  void _showActionResult(bool success, String message) {
    _talker.ui(
      success
          ? 'Accion en periodos de costo completada correctamente.'
          : 'La accion en periodos de costo fallo: $message',
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
        title: const Text('Periodos de costo'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: TextButton.icon(
              onPressed: () {
                _talker.ui(
                  'Se regreso desde periodos de costo al panel principal.',
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
                  child: BlocBuilder<PeriodosCubit, PeriodosState>(
                    builder: (context, state) {
                      final isWide =
                          MediaQuery.sizeOf(context).width >=
                          AppBreakpoints.tablet;
                      final compactHeight = constraints.maxHeight < 860;

                      if (_anioController.text !=
                          (state.anioFilter?.toString() ?? '')) {
                        _anioController.value = TextEditingValue(
                          text: state.anioFilter?.toString() ?? '',
                          selection: TextSelection.collapsed(
                            offset: (state.anioFilter?.toString() ?? '').length,
                          ),
                        );
                      }

                      final listPanel = _PeriodosListPanel(
                        state: state,
                        onRetry: () {
                          _talker.ui(
                            'Se solicito reintentar la carga del listado de periodos de costo.',
                          );
                          context.read<PeriodosCubit>().initialize();
                        },
                        onSelectPeriodo: (id) {
                          _talker.ui(
                            'Se selecciono el periodo de costo $id desde el listado.',
                            logLevel: LogLevel.debug,
                          );
                          context.read<PeriodosCubit>().selectPeriodo(id);
                        },
                      );

                      final detailPanel = _PeriodoDetailPanel(
                        state: state,
                        onRetry: () {
                          _talker.ui(
                            'Se solicito reintentar el detalle del periodo de costo seleccionado.',
                          );
                          context.read<PeriodosCubit>().retryDetail();
                        },
                        onClosePeriodo:
                            state.selectedPeriodo == null ||
                                !state.selectedPeriodo!.isOpen
                            ? null
                            : () => _openCloseDialog(
                                state,
                                state.selectedPeriodo!,
                              ),
                      );

                      final headerAndFilters = <Widget>[
                        _FinanceHeroCard(
                          title:
                              'Controla el calendario mensual que usara Finanzas para consolidar costos e indirectos.',
                          description:
                              'Desde aqui abres el periodo, revisas su estado y lo cierras cuando ya no debe aceptar nuevas cargas operativas.',
                          badgeLabel: 'Periodos visibles',
                          badgeValue: '${state.items.length}',
                          sessionUserName: session?.userName,
                        ),
                        const Gap(AppSpacing.xl),
                        _PeriodosFiltersCard(
                          state: state,
                          anioController: _anioController,
                          isLoading: state.status == PeriodosStatus.loading,
                          isSubmitting: state.isSubmittingAction,
                          onApply: () => _applyFilters(state),
                          onMonthChanged: (value) =>
                              _applyFilters(state, monthOverride: value),
                          onStatusChanged: (value) =>
                              _applyFilters(state, statusOverride: value),
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

  String _describeState(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return normalized;
  }
}

class _FinanceHeroCard extends StatelessWidget {
  const _FinanceHeroCard({
    required this.title,
    required this.description,
    required this.badgeLabel,
    required this.badgeValue,
    required this.sessionUserName,
  });

  final String title;
  final String description;
  final String badgeLabel;
  final String badgeValue;
  final String? sessionUserName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Wrap(
        spacing: AppSpacing.xl,
        runSpacing: AppSpacing.lg,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    height: 1.12,
                  ),
                ),
                const Gap(AppSpacing.sm),
                Text(
                  description,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _FinanceSummaryBadge(label: badgeLabel, value: badgeValue),
              if (sessionUserName != null)
                _FinanceSummaryBadge(
                  label: 'Sesion actual',
                  value: sessionUserName!,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FinanceSummaryBadge extends StatelessWidget {
  const _FinanceSummaryBadge({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
          const Gap(AppSpacing.xs),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _PeriodosFiltersCard extends StatelessWidget {
  const _PeriodosFiltersCard({
    required this.state,
    required this.anioController,
    required this.isLoading,
    required this.isSubmitting,
    required this.onApply,
    required this.onMonthChanged,
    required this.onStatusChanged,
    required this.onCreate,
  });

  final PeriodosState state;
  final TextEditingController anioController;
  final bool isLoading;
  final bool isSubmitting;
  final VoidCallback onApply;
  final ValueChanged<int?> onMonthChanged;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Busqueda y gestion', style: theme.textTheme.titleLarge),
          const Gap(AppSpacing.sm),
          Text(
            'Filtra por anio, mes o estado y abre nuevos periodos cuando el calendario financiero lo requiera.',
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
                width: 220,
                child: TextField(
                  controller: anioController,
                  keyboardType: TextInputType.number,
                  onSubmitted: (_) => onApply(),
                  decoration: const InputDecoration(
                    labelText: 'Anio',
                    hintText: 'Ej. 2026',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<int?>(
                  initialValue: state.mesFilter,
                  decoration: const InputDecoration(labelText: 'Mes'),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Todos'),
                    ),
                    ...List.generate(
                      12,
                      (index) => DropdownMenuItem<int?>(
                        value: index + 1,
                        child: Text(_periodMonthLabel(index + 1)),
                      ),
                    ),
                  ],
                  onChanged: onMonthChanged,
                ),
              ),
              SizedBox(
                width: 240,
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
                      child: Text('ABIERTO'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'CERRADO',
                      child: Text('CERRADO'),
                    ),
                  ],
                  onChanged: onStatusChanged,
                ),
              ),
              AppButton.primary(
                label: 'Aplicar filtros',
                icon: Icons.search_rounded,
                isLoading: isLoading,
                onPressed: onApply,
                expand: false,
              ),
              AppButton.secondary(
                label: 'Nuevo periodo',
                icon: Icons.add_chart_outlined,
                isLoading: isSubmitting,
                onPressed: onCreate,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PeriodosListPanel extends StatelessWidget {
  const _PeriodosListPanel({
    required this.state,
    required this.onRetry,
    required this.onSelectPeriodo,
  });

  final PeriodosState state;
  final VoidCallback onRetry;
  final ValueChanged<int> onSelectPeriodo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Listado de periodos', style: theme.textTheme.titleLarge),
            const Gap(AppSpacing.xs),
            Text(
              '${state.items.length} resultado(s) para la vista actual.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Gap(AppSpacing.lg),
            Expanded(
              child: switch (state.status) {
                PeriodosStatus.loading => const Center(
                  child: CircularProgressIndicator(),
                ),
                PeriodosStatus.error => _CenteredMessage(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppMessageCard.error(
                        title: 'No pudimos cargar los periodos',
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
                PeriodosStatus.success =>
                  state.items.isEmpty
                      ? const _CenteredMessage(
                          child: AppMessageCard.info(
                            title: 'Sin resultados',
                            message:
                                'No encontramos periodos con los filtros actuales.',
                          ),
                        )
                      : ListView.separated(
                          itemCount: state.items.length,
                          separatorBuilder: (_, _) => const Gap(AppSpacing.md),
                          itemBuilder: (context, index) {
                            final item = state.items[index];
                            return _PeriodoListTileCard(
                              item: item,
                              isSelected: item.id == state.selectedPeriodoId,
                              onTap: () => onSelectPeriodo(item.id),
                            );
                          },
                        ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodoDetailPanel extends StatelessWidget {
  const _PeriodoDetailPanel({
    required this.state,
    required this.onRetry,
    required this.onClosePeriodo,
  });

  final PeriodosState state;
  final VoidCallback onRetry;
  final VoidCallback? onClosePeriodo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final periodo = state.selectedPeriodo;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Detalle del periodo', style: theme.textTheme.titleLarge),
            const Gap(AppSpacing.xs),
            Text(
              'Revisa vigencia, monto indirecto acumulado y el estado operativo del periodo.',
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

                  if (periodo == null) {
                    return const _CenteredMessage(
                      child: AppMessageCard.info(
                        title: 'Selecciona un periodo',
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
                              periodo.codigo,
                              style: theme.textTheme.headlineSmall,
                            ),
                            _StatusPill(
                              label: periodo.estado,
                              background: periodo.isOpen
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.surfaceContainerHighest,
                              foreground: periodo.isOpen
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                        const Gap(AppSpacing.lg),
                        if (periodo.isOpen)
                          AppButton.secondary(
                            label: 'Cerrar periodo',
                            icon: Icons.lock_clock_outlined,
                            isLoading: state.isSubmittingAction,
                            onPressed: onClosePeriodo,
                          ),
                        if (periodo.isOpen) const Gap(AppSpacing.xl),
                        Wrap(
                          spacing: AppSpacing.lg,
                          runSpacing: AppSpacing.lg,
                          children: [
                            _DetailCard(
                              title: 'Identidad',
                              lines: [
                                'ID: ${periodo.id}',
                                'Anio: ${periodo.anio}',
                                'Mes: ${_periodMonthLabel(periodo.mes)}',
                              ],
                            ),
                            _DetailCard(
                              title: 'Vigencia',
                              lines: [
                                'Inicio: ${_formatDate(periodo.fechaInicio)}',
                                'Fin: ${_formatDate(periodo.fechaFin)}',
                                'Cerrado: ${_formatOptionalDateTime(periodo.cerradoEn)}',
                              ],
                            ),
                            _DetailCard(
                              title: 'Costos',
                              lines: [
                                'Indirectos acumulados: S/ ${periodo.totalIndirectos.toStringAsFixed(2)}',
                                'Cerrado por usuario: ${periodo.cerradoPorUsuarioId?.toString() ?? 'Sin registro'}',
                              ],
                            ),
                          ],
                        ),
                        if ((periodo.observacion ?? '').trim().isNotEmpty) ...[
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
                                  'Observacion',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const Gap(AppSpacing.md),
                                Text(
                                  periodo.observacion!,
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
      ),
    );
  }
}

class _PeriodoListTileCard extends StatelessWidget {
  const _PeriodoListTileCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final PeriodoCostoRecord item;
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
                  _StatusPill(
                    label: item.estado,
                    background: item.isOpen
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    foreground: item.isOpen
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const Gap(AppSpacing.sm),
              Text(
                '${_formatDate(item.fechaInicio)} · ${_formatDate(item.fechaFin)}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const Gap(AppSpacing.md),
              Text(
                'Indirectos: S/ ${item.totalIndirectos.toStringAsFixed(2)}',
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: foreground),
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
      width: 280,
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

String _formatDate(DateTime value) {
  return DateFormat('dd/MM/yyyy').format(value.toLocal());
}

String _formatOptionalDateTime(DateTime? value) {
  if (value == null) return 'Sin registro';
  return DateFormat('dd/MM/yyyy hh:mm a').format(value.toLocal());
}

String _periodMonthLabel(int month) {
  const months = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];
  return months[month - 1];
}
