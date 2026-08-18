import 'package:erp_curtiembre_fronted/core/theme/app_breakpoints.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:erp_curtiembre_fronted/features/configuration/skin_types/domain/entities/skin_type_record.dart';
import 'package:erp_curtiembre_fronted/features/configuration/skin_types/presentation/cubit/skin_types_cubit.dart';
import 'package:erp_curtiembre_fronted/features/configuration/skin_types/presentation/cubit/skin_types_state.dart';
import 'package:erp_curtiembre_fronted/features/configuration/skin_types/presentation/widgets/skin_type_upsert_dialog.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/buttons/app_button.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/feedback/app_message_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class SkinTypesPage extends StatefulWidget {
  const SkinTypesPage({super.key});

  @override
  State<SkinTypesPage> createState() => _SkinTypesPageState();
}

class _SkinTypesPageState extends State<SkinTypesPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applySearch() {
    FocusScope.of(context).unfocus();
    context.read<SkinTypesCubit>().load(searchTerm: _searchController.text.trim());
  }

  Future<void> _openCreateDialog(SkinTypesState state) async {
    final payload = await showDialog<SkinTypeUpsertFormData>(
      context: context,
      builder: (_) => SkinTypeUpsertDialog(
        title: 'Nuevo tipo de piel',
        submitLabel: 'Crear tipo',
        isSubmitting: state.isSubmittingAction,
      ),
    );

    if (payload == null || !mounted) {
      return;
    }

    final result = await context.read<SkinTypesCubit>().createSkinType(
          codigo: payload.codigo,
          nombre: payload.nombre,
          descripcion: payload.descripcion,
        );

    if (!mounted) {
      return;
    }

    _showActionResult(result);
  }

  Future<void> _openEditDialog(
    SkinTypesState state,
    SkinTypeRecord item,
  ) async {
    final payload = await showDialog<SkinTypeUpsertFormData>(
      context: context,
      builder: (_) => SkinTypeUpsertDialog(
        title: 'Editar tipo de piel',
        submitLabel: 'Guardar cambios',
        isSubmitting: state.isSubmittingAction,
        initialSkinType: item,
      ),
    );

    if (payload == null || !mounted) {
      return;
    }

    final result = await context.read<SkinTypesCubit>().updateSelectedSkinType(
          codigo: payload.codigo,
          nombre: payload.nombre,
          descripcion: payload.descripcion,
        );

    if (!mounted) {
      return;
    }

    _showActionResult(result);
  }

  Future<void> _toggleState(SkinTypeRecord item) async {
    final result =
        await context.read<SkinTypesCubit>().setSelectedSkinTypeActive(!item.activo);
    if (!mounted) {
      return;
    }

    _showActionResult(result);
  }

  void _showActionResult(SkinTypesActionResult result) {
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
        title: const Text('Tipos de piel'),
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
                  child: BlocBuilder<SkinTypesCubit, SkinTypesState>(
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

                      final listPanel = _SkinTypesListPanel(
                        state: state,
                        onRetry: () => context.read<SkinTypesCubit>().initialize(),
                        onSelectItem: (itemId) =>
                            context.read<SkinTypesCubit>().selectSkinType(itemId),
                      );

                      final detailPanel = _SkinTypeDetailPanel(
                        state: state,
                        onRetry: () => context.read<SkinTypesCubit>().retryDetail(),
                        onEdit: state.selectedSkinType == null
                            ? null
                            : () => _openEditDialog(state, state.selectedSkinType!),
                        onToggleState: state.selectedSkinType == null
                            ? null
                            : () => _toggleState(state.selectedSkinType!),
                      );

                      final headerAndFilters = <Widget>[
                        _SkinTypesHeader(
                          userName: session?.userName,
                          itemCount: state.items.length,
                        ),
                        const Gap(AppSpacing.xl),
                        _SkinTypesFiltersCard(
                          controller: _searchController,
                          selectedFilter: state.filter,
                          isLoading: state.status == SkinTypesStatus.loading,
                          isSubmittingAction: state.isSubmittingAction,
                          onSearch: _applySearch,
                          onCreateItem: () => _openCreateDialog(state),
                          onFilterChanged: (filter) =>
                              context.read<SkinTypesCubit>().load(filter: filter),
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

class _SkinTypesHeader extends StatelessWidget {
  const _SkinTypesHeader({
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
                  'Define los tipos de piel base para estandarizar formulas y procesos.',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    height: 1.12,
                  ),
                ),
                const Gap(AppSpacing.sm),
                Text(
                  'Administra catalogos de piel con una vista clara y operativa para configuracion.',
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
              _SkinTypesSummaryBadge(
                label: 'Tipos visibles',
                value: '$itemCount',
              ),
              if (userName != null)
                _SkinTypesSummaryBadge(
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

class _SkinTypesFiltersCard extends StatelessWidget {
  const _SkinTypesFiltersCard({
    required this.controller,
    required this.selectedFilter,
    required this.isLoading,
    required this.isSubmittingAction,
    required this.onSearch,
    required this.onCreateItem,
    required this.onFilterChanged,
  });

  final TextEditingController controller;
  final SkinTypeActivityFilter selectedFilter;
  final bool isLoading;
  final bool isSubmittingAction;
  final VoidCallback onSearch;
  final VoidCallback onCreateItem;
  final ValueChanged<SkinTypeActivityFilter> onFilterChanged;

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
          Text('Busqueda y estado', style: theme.textTheme.titleLarge),
          const Gap(AppSpacing.sm),
          Text(
            'Filtra por codigo o nombre y alterna rapidamente entre activos, inactivos o todos.',
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
                    labelText: 'Buscar tipo de piel',
                    hintText: 'Ej. VACUNO o Vacuno',
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
                label: 'Nuevo tipo',
                icon: Icons.texture_outlined,
                isLoading: isSubmittingAction,
                onPressed: onCreateItem,
              ),
            ],
          ),
          const Gap(AppSpacing.lg),
          SegmentedButton<SkinTypeActivityFilter>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment<SkinTypeActivityFilter>(
                value: SkinTypeActivityFilter.active,
                label: Text('Activos'),
                icon: Icon(Icons.verified_outlined),
              ),
              ButtonSegment<SkinTypeActivityFilter>(
                value: SkinTypeActivityFilter.inactive,
                label: Text('Inactivos'),
                icon: Icon(Icons.block_outlined),
              ),
              ButtonSegment<SkinTypeActivityFilter>(
                value: SkinTypeActivityFilter.all,
                label: Text('Todos'),
                icon: Icon(Icons.layers_outlined),
              ),
            ],
            selected: {selectedFilter},
            onSelectionChanged: (selection) {
              final filter = selection.firstOrNull;
              if (filter != null) {
                onFilterChanged(filter);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _SkinTypesListPanel extends StatelessWidget {
  const _SkinTypesListPanel({
    required this.state,
    required this.onRetry,
    required this.onSelectItem,
  });

  final SkinTypesState state;
  final VoidCallback onRetry;
  final ValueChanged<int> onSelectItem;

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
            Text('Listado de tipos de piel', style: theme.textTheme.titleLarge),
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
                SkinTypesStatus.loading => const Center(child: CircularProgressIndicator()),
                SkinTypesStatus.error => _SkinTypesCenteredMessage(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppMessageCard.error(
                          title: 'No pudimos cargar los tipos de piel',
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
                SkinTypesStatus.success => state.items.isEmpty
                    ? const _SkinTypesCenteredMessage(
                        child: AppMessageCard.info(
                          title: 'Sin resultados',
                          message:
                              'No encontramos tipos de piel con los filtros actuales.',
                        ),
                      )
                    : ListView.separated(
                        itemCount: state.items.length,
                        separatorBuilder: (_, _) => const Gap(AppSpacing.md),
                        itemBuilder: (context, index) {
                          final item = state.items[index];
                          return _SkinTypeListTileCard(
                            item: item,
                            isSelected: item.id == state.selectedSkinTypeId,
                            onTap: () => onSelectItem(item.id),
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

class _SkinTypeDetailPanel extends StatelessWidget {
  const _SkinTypeDetailPanel({
    required this.state,
    required this.onRetry,
    required this.onEdit,
    required this.onToggleState,
  });

  final SkinTypesState state;
  final VoidCallback onRetry;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = state.selectedSkinType;

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
            Text('Detalle del tipo de piel', style: theme.textTheme.titleLarge),
            const Gap(AppSpacing.xs),
            Text(
              'Revisa la configuracion del catalogo y administra su vigencia operativa.',
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
                    return _SkinTypesCenteredMessage(
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
                    return const _SkinTypesCenteredMessage(
                      child: AppMessageCard.info(
                        title: 'Selecciona un tipo de piel',
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
                              item.nombre,
                              style: theme.textTheme.headlineSmall,
                            ),
                            _SkinTypeStatusBadge(
                              label: item.activo ? 'Activo' : 'Inactivo',
                              icon: item.activo
                                  ? Icons.verified_outlined
                                  : Icons.block_outlined,
                              background: item.activo
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.surfaceContainerHighest,
                              foreground: item.activo
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                        const Gap(AppSpacing.xs),
                        Text(
                          item.codigo,
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
                              label: 'Editar tipo',
                              icon: Icons.edit_outlined,
                              isLoading: state.isSubmittingAction,
                              onPressed: onEdit,
                            ),
                            AppButton.secondary(
                              label:
                                  item.activo ? 'Inactivar tipo' : 'Activar tipo',
                              icon: item.activo
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
                            _SkinTypeDetailCard(
                              title: 'Identidad',
                              lines: [
                                'ID: ${item.id}',
                                'Codigo: ${item.codigo}',
                                'Nombre: ${item.nombre}',
                              ],
                            ),
                            _SkinTypeDetailCard(
                              title: 'Descripcion',
                              lines: [
                                item.descripcion?.isNotEmpty == true
                                    ? item.descripcion!
                                    : 'Sin descripcion registrada.',
                              ],
                            ),
                            _SkinTypeDetailCard(
                              title: 'Trazabilidad',
                              lines: [
                                'Creado: ${_formatSkinTypeDateTime(item.creadoEn)}',
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

class _SkinTypeListTileCard extends StatelessWidget {
  const _SkinTypeListTileCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final SkinTypeRecord item;
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
                  _SkinTypeMiniPill(
                    label: item.activo ? 'Activo' : 'Inactivo',
                    background: item.activo
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    foreground: item.activo
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
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
              const Gap(AppSpacing.md),
              Text(
                item.descripcion?.isNotEmpty == true
                    ? item.descripcion!
                    : 'Sin descripcion registrada.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkinTypeDetailCard extends StatelessWidget {
  const _SkinTypeDetailCard({
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

class _SkinTypeStatusBadge extends StatelessWidget {
  const _SkinTypeStatusBadge({
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

class _SkinTypeMiniPill extends StatelessWidget {
  const _SkinTypeMiniPill({
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

class _SkinTypesSummaryBadge extends StatelessWidget {
  const _SkinTypesSummaryBadge({
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

class _SkinTypesCenteredMessage extends StatelessWidget {
  const _SkinTypesCenteredMessage({required this.child});

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

String _formatSkinTypeDateTime(DateTime value) {
  return DateFormat('dd/MM/yyyy hh:mm a').format(value.toLocal());
}
