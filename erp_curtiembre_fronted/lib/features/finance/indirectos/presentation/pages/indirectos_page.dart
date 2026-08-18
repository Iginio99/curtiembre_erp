import 'package:erp_curtiembre_fronted/core/di/service_locator.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_breakpoints.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:erp_curtiembre_fronted/features/finance/indirectos/domain/entities/costo_indirecto_record.dart';
import 'package:erp_curtiembre_fronted/features/finance/indirectos/presentation/cubit/indirectos_cubit.dart';
import 'package:erp_curtiembre_fronted/features/finance/indirectos/presentation/cubit/indirectos_state.dart';
import 'package:erp_curtiembre_fronted/features/finance/indirectos/presentation/widgets/indirecto_upsert_dialog.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/buttons/app_button.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/feedback/app_message_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:talker_flutter/talker_flutter.dart';

class IndirectosPage extends StatefulWidget {
  const IndirectosPage({super.key});

  @override
  State<IndirectosPage> createState() => _IndirectosPageState();
}

class _IndirectosPageState extends State<IndirectosPage> {
  final _searchController = TextEditingController();
  final Talker _talker = getIt<Talker>();

  @override
  void initState() {
    super.initState();
    _talker.ui('Se abrio la pantalla de costos indirectos.');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters(
    IndirectosState state, {
    int? periodOverride,
    String? typeOverride,
  }) {
    FocusScope.of(context).unfocus();
    _talker.ui(
      'Se aplicaron filtros de costos indirectos con periodo=${periodOverride ?? state.periodoCostoIdFilter ?? 'todos'}, tipo=${_describeType(typeOverride ?? state.tipoCostoFilter)}, texto=${_describeText(_searchController.text)}.',
    );
    context.read<IndirectosCubit>().load(
      periodoCostoIdFilter: periodOverride ?? state.periodoCostoIdFilter,
      tipoCostoFilter: typeOverride ?? state.tipoCostoFilter,
      searchTerm: _searchController.text.trim(),
    );
  }

  Future<void> _openCreateDialog(IndirectosState state) async {
    _talker.ui(
      'Se abrio el dialogo para crear un costo indirecto.',
      logLevel: LogLevel.warning,
    );
    final payload = await showDialog<IndirectoUpsertFormData>(
      context: context,
      builder: (_) => IndirectoUpsertDialog(
        periodos: state.periodoOptions,
        isSubmitting: state.isSubmittingAction,
      ),
    );

    if (payload == null || !mounted) {
      _talker.ui(
        'Se cerro la creacion de costo indirecto sin confirmar.',
        logLevel: LogLevel.debug,
      );
      return;
    }
    _talker.ui(
      'Se confirmo la creacion de un costo indirecto con periodo=${payload.periodoCostoId}, tipo=${_describeType(payload.tipoCosto)}, descripcion=${_describeText(payload.descripcion)}.',
      logLevel: LogLevel.warning,
    );

    final result = await context.read<IndirectosCubit>().createIndirecto(
      periodoCostoId: payload.periodoCostoId,
      tipoCosto: payload.tipoCosto,
      descripcion: payload.descripcion,
      monto: payload.monto,
    );

    if (!mounted) return;
    _showActionResult(result.success, result.message);
  }

  void _showActionResult(bool success, String message) {
    _talker.ui(
      success
          ? 'Accion en costos indirectos completada correctamente.'
          : 'La accion en costos indirectos fallo: $message',
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
        title: const Text('Costos indirectos'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: TextButton.icon(
              onPressed: () {
                _talker.ui(
                  'Se regreso desde costos indirectos al panel principal.',
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
                  child: BlocBuilder<IndirectosCubit, IndirectosState>(
                    builder: (context, state) {
                      final isWide =
                          MediaQuery.sizeOf(context).width >=
                          AppBreakpoints.tablet;
                      final compactHeight = constraints.maxHeight < 860;

                      if (_searchController.text != state.searchTerm) {
                        _searchController.value = TextEditingValue(
                          text: state.searchTerm,
                          selection: TextSelection.collapsed(
                            offset: state.searchTerm.length,
                          ),
                        );
                      }

                      final listPanel = _IndirectosListPanel(
                        state: state,
                        onRetry: () {
                          _talker.ui(
                            'Se solicito reintentar la carga del listado de costos indirectos.',
                          );
                          context.read<IndirectosCubit>().initialize();
                        },
                        onSelectIndirecto: (id) {
                          _talker.ui(
                            'Se selecciono el costo indirecto $id desde el listado.',
                            logLevel: LogLevel.debug,
                          );
                          context.read<IndirectosCubit>().selectIndirecto(id);
                        },
                      );

                      final detailPanel = _IndirectoDetailPanel(
                        state: state,
                        onRetry: () {
                          _talker.ui(
                            'Se solicito reintentar el detalle del costo indirecto seleccionado.',
                          );
                          context.read<IndirectosCubit>().retryDetail();
                        },
                      );

                      final headerAndFilters = <Widget>[
                        _FinanceHeroCard(
                          title:
                              'Registra los costos mensuales que luego se distribuyen sobre las ordenes de produccion.',
                          description:
                              'Este bloque sirve para consolidar gastos de soporte como luz, agua, alquiler o mantenimiento dentro del periodo correcto.',
                          badgeLabel: 'Indirectos visibles',
                          badgeValue: '${state.items.length}',
                          sessionUserName: session?.userName,
                        ),
                        const Gap(AppSpacing.xl),
                        _IndirectosFiltersCard(
                          state: state,
                          controller: _searchController,
                          isLoading: state.status == IndirectosStatus.loading,
                          isSubmitting: state.isSubmittingAction,
                          onApply: () => _applyFilters(state),
                          onPeriodChanged: (value) =>
                              _applyFilters(state, periodOverride: value),
                          onTypeChanged: (value) =>
                              _applyFilters(state, typeOverride: value),
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

  String _describeType(String? value) {
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

class _IndirectosFiltersCard extends StatelessWidget {
  const _IndirectosFiltersCard({
    required this.state,
    required this.controller,
    required this.isLoading,
    required this.isSubmitting,
    required this.onApply,
    required this.onPeriodChanged,
    required this.onTypeChanged,
    required this.onCreate,
  });

  final IndirectosState state;
  final TextEditingController controller;
  final bool isLoading;
  final bool isSubmitting;
  final VoidCallback onApply;
  final ValueChanged<int?> onPeriodChanged;
  final ValueChanged<String?> onTypeChanged;
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
          Text('Busqueda y carga', style: theme.textTheme.titleLarge),
          const Gap(AppSpacing.sm),
          Text(
            'Filtra por periodo, tipo o texto libre y registra nuevos costos solo sobre periodos que sigan abiertos.',
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
                width: 320,
                child: TextField(
                  controller: controller,
                  onSubmitted: (_) => onApply(),
                  decoration: const InputDecoration(
                    labelText: 'Buscar costo',
                    hintText: 'Ej. luz, agua o alquiler',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
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
                        child: Text('${item.codigo} · ${item.estado}'),
                      ),
                    ),
                  ],
                  onChanged: onPeriodChanged,
                ),
              ),
              SizedBox(
                width: 240,
                child: DropdownButtonFormField<String?>(
                  initialValue: state.tipoCostoFilter,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Todos'),
                    ),
                    ...state.availableTypes.map(
                      (item) => DropdownMenuItem<String?>(
                        value: item,
                        child: Text(item),
                      ),
                    ),
                  ],
                  onChanged: onTypeChanged,
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
                label: 'Nuevo costo',
                icon: Icons.add_card_outlined,
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

class _IndirectosListPanel extends StatelessWidget {
  const _IndirectosListPanel({
    required this.state,
    required this.onRetry,
    required this.onSelectIndirecto,
  });

  final IndirectosState state;
  final VoidCallback onRetry;
  final ValueChanged<int> onSelectIndirecto;

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
            Text('Listado de indirectos', style: theme.textTheme.titleLarge),
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
                IndirectosStatus.loading => const Center(
                  child: CircularProgressIndicator(),
                ),
                IndirectosStatus.error => _CenteredMessage(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppMessageCard.error(
                        title: 'No pudimos cargar los indirectos',
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
                IndirectosStatus.success =>
                  state.items.isEmpty
                      ? const _CenteredMessage(
                          child: AppMessageCard.info(
                            title: 'Sin resultados',
                            message:
                                'No encontramos costos indirectos con los filtros actuales.',
                          ),
                        )
                      : ListView.separated(
                          itemCount: state.items.length,
                          separatorBuilder: (_, _) => const Gap(AppSpacing.md),
                          itemBuilder: (context, index) {
                            final item = state.items[index];
                            return _IndirectoListTileCard(
                              item: item,
                              isSelected: item.id == state.selectedIndirectoId,
                              onTap: () => onSelectIndirecto(item.id),
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

class _IndirectoDetailPanel extends StatelessWidget {
  const _IndirectoDetailPanel({required this.state, required this.onRetry});

  final IndirectosState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final indirecto = state.selectedIndirecto;

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
            Text(
              'Detalle del costo indirecto',
              style: theme.textTheme.titleLarge,
            ),
            const Gap(AppSpacing.xs),
            Text(
              'Revisa periodo, tipo, monto y trazabilidad del registro seleccionado.',
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

                  if (indirecto == null) {
                    return const _CenteredMessage(
                      child: AppMessageCard.info(
                        title: 'Selecciona un costo',
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
                              indirecto.tipoCosto,
                              style: theme.textTheme.headlineSmall,
                            ),
                            _StatusPill(
                              label: indirecto.periodoEstado,
                              background: indirecto.periodoEstado == 'ABIERTO'
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.surfaceContainerHighest,
                              foreground: indirecto.periodoEstado == 'ABIERTO'
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                        const Gap(AppSpacing.sm),
                        Text(
                          'Periodo ${indirecto.periodoCodigo}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const Gap(AppSpacing.xl),
                        Wrap(
                          spacing: AppSpacing.lg,
                          runSpacing: AppSpacing.lg,
                          children: [
                            _DetailCard(
                              title: 'Identidad',
                              lines: [
                                'ID: ${indirecto.id}',
                                'Tipo: ${indirecto.tipoCosto}',
                                'Periodo: ${indirecto.periodoCodigo}',
                              ],
                            ),
                            _DetailCard(
                              title: 'Monto',
                              lines: [
                                'Total registrado: S/ ${indirecto.monto.toStringAsFixed(2)}',
                                'Fecha: ${_formatDateTime(indirecto.registradoEn)}',
                              ],
                            ),
                            _DetailCard(
                              title: 'Trazabilidad',
                              lines: [
                                'Periodo estado: ${indirecto.periodoEstado}',
                                'Registrado por usuario: ${indirecto.registradoPorUsuarioId?.toString() ?? 'Sin registro'}',
                              ],
                            ),
                          ],
                        ),
                        if ((indirecto.descripcion ?? '')
                            .trim()
                            .isNotEmpty) ...[
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
                                  indirecto.descripcion!,
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

class _IndirectoListTileCard extends StatelessWidget {
  const _IndirectoListTileCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final CostoIndirectoRecord item;
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
                  Text(item.tipoCosto, style: theme.textTheme.titleMedium),
                  _StatusPill(
                    label: item.periodoEstado,
                    background: item.periodoEstado == 'ABIERTO'
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    foreground: item.periodoEstado == 'ABIERTO'
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const Gap(AppSpacing.sm),
              Text(
                'Periodo ${item.periodoCodigo}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const Gap(AppSpacing.md),
              Text(
                'Monto: S/ ${item.monto.toStringAsFixed(2)} · ${_formatDateTime(item.registradoEn)}',
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

String _formatDateTime(DateTime value) {
  return DateFormat('dd/MM/yyyy hh:mm a').format(value.toLocal());
}
