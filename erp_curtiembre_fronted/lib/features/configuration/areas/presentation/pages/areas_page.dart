import 'package:erp_curtiembre_fronted/core/theme/app_breakpoints.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:erp_curtiembre_fronted/features/configuration/areas/domain/entities/area_record.dart';
import 'package:erp_curtiembre_fronted/features/configuration/areas/presentation/cubit/areas_cubit.dart';
import 'package:erp_curtiembre_fronted/features/configuration/areas/presentation/cubit/areas_state.dart';
import 'package:erp_curtiembre_fronted/features/configuration/areas/presentation/widgets/area_upsert_dialog.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/buttons/app_button.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/feedback/app_message_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class AreasPage extends StatefulWidget {
  const AreasPage({super.key});

  @override
  State<AreasPage> createState() => _AreasPageState();
}

class _AreasPageState extends State<AreasPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applySearch() {
    FocusScope.of(context).unfocus();
    context.read<AreasCubit>().load(searchTerm: _searchController.text.trim());
  }

  Future<void> _openCreateAreaDialog(AreasState state) async {
    final payload = await showDialog<AreaUpsertFormData>(
      context: context,
      builder: (_) => AreaUpsertDialog(
        title: 'Nueva area',
        submitLabel: 'Crear area',
        isSubmitting: state.isSubmittingAction,
      ),
    );

    if (payload == null || !mounted) {
      return;
    }

    final result = await context.read<AreasCubit>().createArea(
          codigo: payload.codigo,
          nombre: payload.nombre,
          descripcion: payload.descripcion,
        );

    if (!mounted) {
      return;
    }

    _showActionResult(result);
  }

  Future<void> _openEditAreaDialog(
    AreasState state,
    AreaRecord area,
  ) async {
    final payload = await showDialog<AreaUpsertFormData>(
      context: context,
      builder: (_) => AreaUpsertDialog(
        title: 'Editar area',
        submitLabel: 'Guardar cambios',
        isSubmitting: state.isSubmittingAction,
        initialArea: area,
      ),
    );

    if (payload == null || !mounted) {
      return;
    }

    final result = await context.read<AreasCubit>().updateSelectedArea(
          codigo: payload.codigo,
          nombre: payload.nombre,
          descripcion: payload.descripcion,
        );

    if (!mounted) {
      return;
    }

    _showActionResult(result);
  }

  Future<void> _toggleAreaState(AreaRecord area) async {
    final result = await context.read<AreasCubit>().setSelectedAreaActive(!area.activo);
    if (!mounted) {
      return;
    }

    _showActionResult(result);
  }

  void _showActionResult(AreasActionResult result) {
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
        title: const Text('Areas'),
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
                  child: BlocBuilder<AreasCubit, AreasState>(
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

                      final listPanel = _AreasListPanel(
                        state: state,
                        onRetry: () => context.read<AreasCubit>().initialize(),
                        onSelectArea: (areaId) => context.read<AreasCubit>().selectArea(areaId),
                      );

                      final detailPanel = _AreaDetailPanel(
                        state: state,
                        onRetry: () => context.read<AreasCubit>().retryDetail(),
                        onEditArea: state.selectedArea == null
                            ? null
                            : () => _openEditAreaDialog(state, state.selectedArea!),
                        onToggleState: state.selectedArea == null
                            ? null
                            : () => _toggleAreaState(state.selectedArea!),
                      );

                      final headerAndFilters = <Widget>[
                        _AreasHeader(
                          userName: session?.userName,
                          itemCount: state.items.length,
                        ),
                        const Gap(AppSpacing.xl),
                        _AreasFiltersCard(
                          controller: _searchController,
                          selectedFilter: state.filter,
                          isLoading: state.status == AreasStatus.loading,
                          isSubmittingAction: state.isSubmittingAction,
                          onSearch: _applySearch,
                          onCreateArea: () => _openCreateAreaDialog(state),
                          onFilterChanged: (filter) =>
                              context.read<AreasCubit>().load(filter: filter),
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

class _AreasHeader extends StatelessWidget {
  const _AreasHeader({
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
                  'Organiza las areas base que estructuran el trabajo del sistema.',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    height: 1.12,
                  ),
                ),
                const Gap(AppSpacing.sm),
                Text(
                  'Consulta, registra y ajusta areas maestras para mantener una configuracion consistente entre modulos.',
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
              _AreasSummaryBadge(
                label: 'Areas visibles',
                value: '$itemCount',
              ),
              if (userName != null)
                _AreasSummaryBadge(
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

class _AreasFiltersCard extends StatelessWidget {
  const _AreasFiltersCard({
    required this.controller,
    required this.selectedFilter,
    required this.isLoading,
    required this.isSubmittingAction,
    required this.onSearch,
    required this.onCreateArea,
    required this.onFilterChanged,
  });

  final TextEditingController controller;
  final AreaActivityFilter selectedFilter;
  final bool isLoading;
  final bool isSubmittingAction;
  final VoidCallback onSearch;
  final VoidCallback onCreateArea;
  final ValueChanged<AreaActivityFilter> onFilterChanged;

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
            'Filtra por codigo o nombre y alterna rapidamente entre areas activas, inactivas o todas.',
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
                    labelText: 'Buscar area',
                    hintText: 'Ej. ADM o Administracion',
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
                label: 'Nueva area',
                icon: Icons.add_business_outlined,
                isLoading: isSubmittingAction,
                onPressed: onCreateArea,
              ),
            ],
          ),
          const Gap(AppSpacing.lg),
          SegmentedButton<AreaActivityFilter>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment<AreaActivityFilter>(
                value: AreaActivityFilter.active,
                label: Text('Activas'),
                icon: Icon(Icons.verified_outlined),
              ),
              ButtonSegment<AreaActivityFilter>(
                value: AreaActivityFilter.inactive,
                label: Text('Inactivas'),
                icon: Icon(Icons.block_outlined),
              ),
              ButtonSegment<AreaActivityFilter>(
                value: AreaActivityFilter.all,
                label: Text('Todas'),
                icon: Icon(Icons.account_tree_outlined),
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

class _AreasListPanel extends StatelessWidget {
  const _AreasListPanel({
    required this.state,
    required this.onRetry,
    required this.onSelectArea,
  });

  final AreasState state;
  final VoidCallback onRetry;
  final ValueChanged<int> onSelectArea;

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
            Text('Listado de areas', style: theme.textTheme.titleLarge),
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
                AreasStatus.loading => const Center(child: CircularProgressIndicator()),
                AreasStatus.error => _AreasCenteredMessage(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppMessageCard.error(
                          title: 'No pudimos cargar las areas',
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
                AreasStatus.success => state.items.isEmpty
                    ? const _AreasCenteredMessage(
                        child: AppMessageCard.info(
                          title: 'Sin resultados',
                          message: 'No encontramos areas con los filtros actuales.',
                        ),
                      )
                    : ListView.separated(
                        itemCount: state.items.length,
                        separatorBuilder: (_, _) => const Gap(AppSpacing.md),
                        itemBuilder: (context, index) {
                          final item = state.items[index];
                          return _AreaListTileCard(
                            item: item,
                            isSelected: item.id == state.selectedAreaId,
                            onTap: () => onSelectArea(item.id),
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

class _AreaDetailPanel extends StatelessWidget {
  const _AreaDetailPanel({
    required this.state,
    required this.onRetry,
    required this.onEditArea,
    required this.onToggleState,
  });

  final AreasState state;
  final VoidCallback onRetry;
  final VoidCallback? onEditArea;
  final VoidCallback? onToggleState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final area = state.selectedArea;

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
            Text('Detalle del area', style: theme.textTheme.titleLarge),
            const Gap(AppSpacing.xs),
            Text(
              'Revisa la configuracion del area y administra su vigencia operativa.',
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
                    return _AreasCenteredMessage(
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

                  if (area == null) {
                    return const _AreasCenteredMessage(
                      child: AppMessageCard.info(
                        title: 'Selecciona un area',
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
                              area.nombre,
                              style: theme.textTheme.headlineSmall,
                            ),
                            _AreaStatusBadge(
                              label: area.activo ? 'Activa' : 'Inactiva',
                              icon: area.activo
                                  ? Icons.verified_outlined
                                  : Icons.block_outlined,
                              background: area.activo
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.surfaceContainerHighest,
                              foreground: area.activo
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                        const Gap(AppSpacing.xs),
                        Text(
                          area.codigo,
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
                              label: 'Editar area',
                              icon: Icons.edit_outlined,
                              isLoading: state.isSubmittingAction,
                              onPressed: onEditArea,
                            ),
                            AppButton.secondary(
                              label: area.activo ? 'Inactivar area' : 'Activar area',
                              icon: area.activo
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
                            _AreaDetailCard(
                              title: 'Identidad',
                              lines: [
                                'ID: ${area.id}',
                                'Codigo: ${area.codigo}',
                                'Nombre: ${area.nombre}',
                              ],
                            ),
                            _AreaDetailCard(
                              title: 'Descripcion',
                              lines: [
                                area.descripcion?.isNotEmpty == true
                                    ? area.descripcion!
                                    : 'Sin descripcion registrada.',
                              ],
                            ),
                            _AreaDetailCard(
                              title: 'Trazabilidad',
                              lines: [
                                'Creada: ${_formatDateTime(area.creadoEn)}',
                                'Actualizada: ${_formatOptionalDate(area.actualizadoEn)}',
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

class _AreaListTileCard extends StatelessWidget {
  const _AreaListTileCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final AreaRecord item;
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
                  _AreaMiniPill(
                    label: item.activo ? 'Activa' : 'Inactiva',
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

class _AreaDetailCard extends StatelessWidget {
  const _AreaDetailCard({
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

class _AreaStatusBadge extends StatelessWidget {
  const _AreaStatusBadge({
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

class _AreaMiniPill extends StatelessWidget {
  const _AreaMiniPill({
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

class _AreasSummaryBadge extends StatelessWidget {
  const _AreasSummaryBadge({
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

class _AreasCenteredMessage extends StatelessWidget {
  const _AreasCenteredMessage({required this.child});

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

String _formatOptionalDate(DateTime? value) {
  if (value == null) {
    return 'Sin registro';
  }

  return _formatDateTime(value);
}

String _formatDateTime(DateTime value) {
  return DateFormat('dd/MM/yyyy hh:mm a').format(value.toLocal());
}
