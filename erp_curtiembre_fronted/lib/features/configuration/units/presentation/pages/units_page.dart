import 'package:erp_curtiembre_fronted/core/theme/app_breakpoints.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:erp_curtiembre_fronted/features/configuration/units/domain/entities/unit_record.dart';
import 'package:erp_curtiembre_fronted/features/configuration/units/presentation/cubit/units_cubit.dart';
import 'package:erp_curtiembre_fronted/features/configuration/units/presentation/cubit/units_state.dart';
import 'package:erp_curtiembre_fronted/features/configuration/units/presentation/widgets/unit_upsert_dialog.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/buttons/app_button.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/feedback/app_message_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class UnitsPage extends StatefulWidget {
  const UnitsPage({super.key});

  @override
  State<UnitsPage> createState() => _UnitsPageState();
}

class _UnitsPageState extends State<UnitsPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applySearch() {
    FocusScope.of(context).unfocus();
    context.read<UnitsCubit>().load(searchTerm: _searchController.text.trim());
  }

  Future<void> _openCreateUnitDialog(UnitsState state) async {
    final payload = await showDialog<UnitUpsertFormData>(
      context: context,
      builder: (_) => UnitUpsertDialog(
        title: 'Nueva unidad de medida',
        submitLabel: 'Crear unidad',
        isSubmitting: state.isSubmittingAction,
      ),
    );

    if (payload == null || !mounted) {
      return;
    }

    final result = await context.read<UnitsCubit>().createUnit(
          codigo: payload.codigo,
          nombre: payload.nombre,
          permiteDecimales: payload.permiteDecimales,
        );

    if (!mounted) {
      return;
    }

    _showActionResult(result);
  }

  Future<void> _openEditUnitDialog(
    UnitsState state,
    UnitRecord unit,
  ) async {
    final payload = await showDialog<UnitUpsertFormData>(
      context: context,
      builder: (_) => UnitUpsertDialog(
        title: 'Editar unidad de medida',
        submitLabel: 'Guardar cambios',
        isSubmitting: state.isSubmittingAction,
        initialUnit: unit,
      ),
    );

    if (payload == null || !mounted) {
      return;
    }

    final result = await context.read<UnitsCubit>().updateSelectedUnit(
          codigo: payload.codigo,
          nombre: payload.nombre,
          permiteDecimales: payload.permiteDecimales,
        );

    if (!mounted) {
      return;
    }

    _showActionResult(result);
  }

  Future<void> _toggleUnitState(UnitRecord unit) async {
    final result = await context.read<UnitsCubit>().setSelectedUnitActive(!unit.activo);
    if (!mounted) {
      return;
    }

    _showActionResult(result);
  }

  void _showActionResult(UnitsActionResult result) {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unidades de medida'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: TextButton.icon(
              onPressed: () => context.go('/home'),
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
                  child: BlocBuilder<UnitsCubit, UnitsState>(
                    builder: (context, state) {
                      final isWide =
                          MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;
                      final compactHeight = constraints.maxHeight < 860;

                      if (_searchController.text != state.searchTerm) {
                        _searchController.value = TextEditingValue(
                          text: state.searchTerm,
                          selection: TextSelection.collapsed(
                            offset: state.searchTerm.length,
                          ),
                        );
                      }

                      final listPanel = _UnitsListPanel(
                        state: state,
                        onRetry: () => context.read<UnitsCubit>().initialize(),
                        onSelectUnit: (unitId) => context.read<UnitsCubit>().selectUnit(unitId),
                      );

                      final detailPanel = _UnitDetailPanel(
                        state: state,
                        onRetry: () => context.read<UnitsCubit>().retryDetail(),
                        onEditUnit: state.selectedUnit == null
                            ? null
                            : () => _openEditUnitDialog(state, state.selectedUnit!),
                        onToggleState: state.selectedUnit == null
                            ? null
                            : () => _toggleUnitState(state.selectedUnit!),
                      );

                      final headerAndFilters = <Widget>[
                        _UnitsHeader(
                          userName: session?.userName,
                          itemCount: state.items.length,
                        ),
                        const Gap(AppSpacing.xl),
                        _UnitsFiltersCard(
                          controller: _searchController,
                          selectedActivityFilter: state.activityFilter,
                          selectedDecimalFilter: state.decimalFilter,
                          isLoading: state.status == UnitsStatus.loading,
                          isSubmittingAction: state.isSubmittingAction,
                          onSearch: _applySearch,
                          onCreateUnit: () => _openCreateUnitDialog(state),
                          onActivityFilterChanged: (filter) =>
                              context.read<UnitsCubit>().load(activityFilter: filter),
                          onDecimalFilterChanged: (filter) =>
                              context.read<UnitsCubit>().load(decimalFilter: filter),
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
                              SizedBox(
                                height: 520,
                                child: listPanel,
                              ),
                              const Gap(AppSpacing.xl),
                              SizedBox(
                                height: 560,
                                child: detailPanel,
                              ),
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

class _UnitsHeader extends StatelessWidget {
  const _UnitsHeader({
    required this.userName,
    required this.itemCount,
  });

  final String? userName;
  final int itemCount;

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
                  'Controla las unidades base que usara inventario, formulas y produccion.',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    height: 1.12,
                  ),
                ),
                const Gap(AppSpacing.sm),
                Text(
                  'Administra unidades enteras o decimales con una vista clara para configuracion operativa.',
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
              _UnitsSummaryBadge(
                label: 'Unidades visibles',
                value: '$itemCount',
              ),
              if (userName != null)
                _UnitsSummaryBadge(
                  label: 'Sesion actual',
                  value: userName!,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UnitsFiltersCard extends StatelessWidget {
  const _UnitsFiltersCard({
    required this.controller,
    required this.selectedActivityFilter,
    required this.selectedDecimalFilter,
    required this.isLoading,
    required this.isSubmittingAction,
    required this.onSearch,
    required this.onCreateUnit,
    required this.onActivityFilterChanged,
    required this.onDecimalFilterChanged,
  });

  final TextEditingController controller;
  final UnitActivityFilter selectedActivityFilter;
  final UnitDecimalFilter selectedDecimalFilter;
  final bool isLoading;
  final bool isSubmittingAction;
  final VoidCallback onSearch;
  final VoidCallback onCreateUnit;
  final ValueChanged<UnitActivityFilter> onActivityFilterChanged;
  final ValueChanged<UnitDecimalFilter> onDecimalFilterChanged;

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
          Text('Busqueda y comportamiento', style: theme.textTheme.titleLarge),
          const Gap(AppSpacing.sm),
          Text(
            'Filtra por codigo, nombre, estado y soporte de decimales.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.lg,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 420,
                child: TextField(
                  controller: controller,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => onSearch(),
                  decoration: const InputDecoration(
                    labelText: 'Buscar unidad',
                    hintText: 'Ej. KG o Kilogramo',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
              AppButton.primary(
                label: 'Aplicar busqueda',
                icon: Icons.search_rounded,
                isLoading: isLoading,
                onPressed: onSearch,
                expand: false,
              ),
              AppButton.secondary(
                label: 'Nueva unidad',
                icon: Icons.square_foot_outlined,
                isLoading: isSubmittingAction,
                onPressed: onCreateUnit,
              ),
            ],
          ),
          const Gap(AppSpacing.lg),
          SegmentedButton<UnitActivityFilter>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment<UnitActivityFilter>(
                value: UnitActivityFilter.active,
                label: Text('Activas'),
                icon: Icon(Icons.verified_outlined),
              ),
              ButtonSegment<UnitActivityFilter>(
                value: UnitActivityFilter.inactive,
                label: Text('Inactivas'),
                icon: Icon(Icons.block_outlined),
              ),
              ButtonSegment<UnitActivityFilter>(
                value: UnitActivityFilter.all,
                label: Text('Todas'),
                icon: Icon(Icons.tune_outlined),
              ),
            ],
            selected: {selectedActivityFilter},
            onSelectionChanged: (selection) {
              final filter = selection.firstOrNull;
              if (filter != null) {
                onActivityFilterChanged(filter);
              }
            },
          ),
          const Gap(AppSpacing.md),
          SegmentedButton<UnitDecimalFilter>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment<UnitDecimalFilter>(
                value: UnitDecimalFilter.all,
                label: Text('Todas'),
                icon: Icon(Icons.unfold_more_outlined),
              ),
              ButtonSegment<UnitDecimalFilter>(
                value: UnitDecimalFilter.decimals,
                label: Text('Con decimales'),
                icon: Icon(Icons.functions_outlined),
              ),
              ButtonSegment<UnitDecimalFilter>(
                value: UnitDecimalFilter.integers,
                label: Text('Solo enteras'),
                icon: Icon(Icons.looks_one_outlined),
              ),
            ],
            selected: {selectedDecimalFilter},
            onSelectionChanged: (selection) {
              final filter = selection.firstOrNull;
              if (filter != null) {
                onDecimalFilterChanged(filter);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _UnitsListPanel extends StatelessWidget {
  const _UnitsListPanel({
    required this.state,
    required this.onRetry,
    required this.onSelectUnit,
  });

  final UnitsState state;
  final VoidCallback onRetry;
  final ValueChanged<int> onSelectUnit;

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
            Text('Listado de unidades', style: theme.textTheme.titleLarge),
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
                UnitsStatus.loading => const Center(child: CircularProgressIndicator()),
                UnitsStatus.error => _UnitsCenteredMessage(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppMessageCard.error(
                          title: 'No pudimos cargar las unidades',
                          message: state.errorMessage ??
                              'Intenta nuevamente para consultar la configuracion.',
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
                UnitsStatus.success => state.items.isEmpty
                    ? const _UnitsCenteredMessage(
                        child: AppMessageCard.info(
                          title: 'Sin resultados',
                          message:
                              'No encontramos unidades de medida con los filtros actuales.',
                        ),
                      )
                    : ListView.separated(
                        itemCount: state.items.length,
                        separatorBuilder: (_, _) => const Gap(AppSpacing.md),
                        itemBuilder: (context, index) {
                          final item = state.items[index];
                          return _UnitListTileCard(
                            item: item,
                            isSelected: item.id == state.selectedUnitId,
                            onTap: () => onSelectUnit(item.id),
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

class _UnitDetailPanel extends StatelessWidget {
  const _UnitDetailPanel({
    required this.state,
    required this.onRetry,
    required this.onEditUnit,
    required this.onToggleState,
  });

  final UnitsState state;
  final VoidCallback onRetry;
  final VoidCallback? onEditUnit;
  final VoidCallback? onToggleState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unit = state.selectedUnit;

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
            Text('Detalle de la unidad', style: theme.textTheme.titleLarge),
            const Gap(AppSpacing.xs),
            Text(
              'Revisa la configuracion de la unidad y su comportamiento de cantidades.',
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
                    return _UnitsCenteredMessage(
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

                  if (unit == null) {
                    return const _UnitsCenteredMessage(
                      child: AppMessageCard.info(
                        title: 'Selecciona una unidad',
                        message:
                            'Escoge un registro del listado para revisar su informacion.',
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
                              unit.nombre,
                              style: theme.textTheme.headlineSmall,
                            ),
                            _UnitStatusBadge(
                              label: unit.activo ? 'Activa' : 'Inactiva',
                              icon: unit.activo
                                  ? Icons.verified_outlined
                                  : Icons.block_outlined,
                              background: unit.activo
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.surfaceContainerHighest,
                              foreground: unit.activo
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            _UnitStatusBadge(
                              label: unit.permiteDecimales
                                  ? 'Permite decimales'
                                  : 'Solo enteros',
                              icon: unit.permiteDecimales
                                  ? Icons.functions_outlined
                                  : Icons.looks_one_outlined,
                              background: theme.colorScheme.secondaryContainer,
                              foreground: theme.colorScheme.onSecondaryContainer,
                            ),
                          ],
                        ),
                        const Gap(AppSpacing.xs),
                        Text(
                          unit.codigo,
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
                              label: 'Editar unidad',
                              icon: Icons.edit_outlined,
                              isLoading: state.isSubmittingAction,
                              onPressed: onEditUnit,
                            ),
                            AppButton.secondary(
                              label:
                                  unit.activo ? 'Inactivar unidad' : 'Activar unidad',
                              icon: unit.activo
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
                            _UnitDetailCard(
                              title: 'Identidad',
                              lines: [
                                'ID: ${unit.id}',
                                'Codigo: ${unit.codigo}',
                                'Nombre: ${unit.nombre}',
                              ],
                            ),
                            _UnitDetailCard(
                              title: 'Comportamiento',
                              lines: [
                                unit.permiteDecimales
                                    ? 'Acepta cantidades con decimales.'
                                    : 'Solo acepta cantidades enteras.',
                              ],
                            ),
                            _UnitDetailCard(
                              title: 'Trazabilidad',
                              lines: [
                                'Creada: ${_formatDateTime(unit.creadoEn)}',
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
      ),
    );
  }
}

class _UnitListTileCard extends StatelessWidget {
  const _UnitListTileCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final UnitRecord item;
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
                  Text(item.nombre, style: theme.textTheme.titleMedium),
                  _UnitMiniPill(
                    label: item.activo ? 'Activa' : 'Inactiva',
                    background: item.activo
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    foreground: item.activo
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  _UnitMiniPill(
                    label: item.permiteDecimales ? 'Decimales' : 'Enteros',
                    background: theme.colorScheme.secondaryContainer,
                    foreground: theme.colorScheme.onSecondaryContainer,
                  ),
                ],
              ),
              const Gap(AppSpacing.sm),
              Text(
                item.codigo,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnitDetailCard extends StatelessWidget {
  const _UnitDetailCard({
    required this.title,
    required this.lines,
  });

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

class _UnitStatusBadge extends StatelessWidget {
  const _UnitStatusBadge({
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
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: foreground,
                ),
          ),
        ],
      ),
    );
  }
}

class _UnitMiniPill extends StatelessWidget {
  const _UnitMiniPill({
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
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
            ),
      ),
    );
  }
}

class _UnitsSummaryBadge extends StatelessWidget {
  const _UnitsSummaryBadge({
    required this.label,
    required this.value,
  });

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
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitsCenteredMessage extends StatelessWidget {
  const _UnitsCenteredMessage({required this.child});

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
