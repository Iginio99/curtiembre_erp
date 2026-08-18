import 'package:erp_curtiembre_fronted/core/di/service_locator.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_breakpoints.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_state.dart';
import 'package:erp_curtiembre_fronted/features/inventory/insumos/domain/constants/insumo_tipo_bien_options.dart';
import 'package:erp_curtiembre_fronted/features/inventory/stock/domain/entities/stock_record.dart';
import 'package:erp_curtiembre_fronted/features/inventory/stock/presentation/cubit/stock_cubit.dart';
import 'package:erp_curtiembre_fronted/features/inventory/stock/presentation/cubit/stock_state.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/buttons/app_button.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/feedback/app_message_card.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/layout/app_shell.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/layout/app_surface_card.dart';
import 'package:erp_curtiembre_fronted/shared/navigation/app_access_routes.dart';
import 'package:erp_curtiembre_fronted/features/security/presentation/cubit/security_access_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:talker_flutter/talker_flutter.dart';

class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  final _searchController = TextEditingController();
  final Talker _talker = getIt<Talker>();

  @override
  void initState() {
    super.initState();
    _talker.ui('Se abrio la pantalla de stock.');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applySearch() {
    FocusScope.of(context).unfocus();
    _talker.ui(
      'Se aplico la busqueda de stock con texto=${_describeText(_searchController.text)}.',
    );
    context.read<StockCubit>().load(searchTerm: _searchController.text.trim());
  }

  void _selectInsumo(int insumoId, {required bool openMobileDetail}) {
    _talker.ui(
      'Se selecciono el insumo $insumoId desde el listado de stock.',
      logLevel: LogLevel.debug,
    );
    context.read<StockCubit>().selectInsumo(insumoId);

    if (!openMobileDetail) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => BlocProvider.value(
        value: context.read<StockCubit>(),
        child: const _MobileStockDetailSheet(),
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
      title: 'Stock actual',
      currentPath: '/inventario/stock',
      breadcrumbs: const ['Inicio', 'Inventario', 'Stock actual'],
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
                child: BlocBuilder<StockCubit, StockState>(
                  builder: (context, state) {
                    final isWide = constraints.maxWidth >= 1040;
                    final isMobile =
                        constraints.maxWidth < AppBreakpoints.mobileLarge;
                    final compactHeight = constraints.maxHeight < 860;

                    if (_searchController.text != state.searchTerm) {
                      _searchController.value = TextEditingValue(
                        text: state.searchTerm,
                        selection: TextSelection.collapsed(
                          offset: state.searchTerm.length,
                        ),
                      );
                    }

                    final listPanel = _StockListPanel(
                      state: state,
                      showTable: isWide,
                      onRetry: () {
                        _talker.ui(
                          'Se solicito reintentar la carga del listado de stock.',
                        );
                        context.read<StockCubit>().initialize();
                      },
                      onSelectInsumo: (id) {
                        _selectInsumo(id, openMobileDetail: isMobile);
                      },
                    );

                    final detailPanel = _StockDetailPanelV2(
                      state: state,
                      onRetry: () {
                        _talker.ui(
                          'Se solicito reintentar el detalle del stock seleccionado.',
                        );
                        context.read<StockCubit>().retryDetail();
                      },
                    );

                    final headerAndFilters = <Widget>[
                      Text(
                        'Consulta cantidades disponibles, stock mínimo y costo promedio vigente.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Gap(AppSpacing.lg),
                      _StockFiltersCard(
                        state: state,
                        controller: _searchController,
                        isCompact:
                            constraints.maxWidth < AppBreakpoints.mobileLarge,
                        isLoading: state.status == StockStatus.loading,
                        onSearch: _applySearch,
                        onActivityFilterChanged: (filter) {
                          _talker.ui(
                            'Se cambio el filtro de actividad de stock a ${_describeActivityFilter(filter)}.',
                            logLevel: LogLevel.debug,
                          );
                          context.read<StockCubit>().load(
                            activityFilter: filter,
                          );
                        },
                        onLowStockChanged: (value) {
                          _talker.ui(
                            'Se cambio el filtro de stock bajo a $value.',
                            logLevel: LogLevel.debug,
                          );
                          context.read<StockCubit>().load(lowStockOnly: value);
                        },
                        onTipoBienChanged: (value) {
                          _talker.ui(
                            'Se cambio el filtro de tipo de bien en stock a ${_describeType(value)}.',
                            logLevel: LogLevel.debug,
                          );
                          context.read<StockCubit>().load(
                            tipoBienFilter: value,
                          );
                        },
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
                            if (!isMobile) ...[
                              const Gap(AppSpacing.xl),
                              SizedBox(height: 560, child: detailPanel),
                            ],
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
                              : isMobile
                              ? listPanel
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

  String _describeType(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return normalized;
  }

  String _describeActivityFilter(StockActivityFilter value) {
    return switch (value) {
      StockActivityFilter.active => 'activos',
      StockActivityFilter.inactive => 'inactivos',
      StockActivityFilter.all => 'todos',
    };
  }
}

class _StockFiltersCard extends StatelessWidget {
  const _StockFiltersCard({
    required this.state,
    required this.controller,
    required this.isCompact,
    required this.isLoading,
    required this.onSearch,
    required this.onActivityFilterChanged,
    required this.onLowStockChanged,
    required this.onTipoBienChanged,
  });

  final StockState state;
  final TextEditingController controller;
  final bool isCompact;
  final bool isLoading;
  final VoidCallback onSearch;
  final ValueChanged<StockActivityFilter> onActivityFilterChanged;
  final ValueChanged<bool> onLowStockChanged;
  final ValueChanged<String?> onTipoBienChanged;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: isCompact
          ? _MobileStockFilters(
              state: state,
              controller: controller,
              isLoading: isLoading,
              onSearch: onSearch,
              onActivityFilterChanged: onActivityFilterChanged,
              onLowStockChanged: onLowStockChanged,
              onTipoBienChanged: onTipoBienChanged,
            )
          : _DesktopStockFilters(
              state: state,
              controller: controller,
              isLoading: isLoading,
              onSearch: onSearch,
              onActivityFilterChanged: onActivityFilterChanged,
              onLowStockChanged: onLowStockChanged,
              onTipoBienChanged: onTipoBienChanged,
            ),
    );
  }
}

class _DesktopStockFilters extends StatelessWidget {
  const _DesktopStockFilters({
    required this.state,
    required this.controller,
    required this.isLoading,
    required this.onSearch,
    required this.onActivityFilterChanged,
    required this.onLowStockChanged,
    required this.onTipoBienChanged,
  });

  final StockState state;
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSearch;
  final ValueChanged<StockActivityFilter> onActivityFilterChanged;
  final ValueChanged<bool> onLowStockChanged;
  final ValueChanged<String?> onTipoBienChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth >= 900;
        final search = _StockSearchField(
          controller: controller,
          onSearch: onSearch,
          isLoading: isLoading,
        );
        final typeFilter = SizedBox(
          width: horizontal ? 190 : 220,
          child: _TipoBienFilter(
            value: state.tipoBienFilter,
            onChanged: onTipoBienChanged,
            compact: true,
          ),
        );
        final filters = [
          typeFilter,
          _ActivityFilterSegment(
            value: state.activityFilter,
            onChanged: onActivityFilterChanged,
          ),
          _LowStockToggle(
            value: state.lowStockOnly,
            onChanged: onLowStockChanged,
          ),
        ];

        if (horizontal) {
          return Row(
            children: [
              Expanded(child: search),
              const Gap(AppSpacing.md),
              ...filters.expand((widget) => [widget, const Gap(AppSpacing.md)]),
            ]..removeLast(),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            search,
            const Gap(AppSpacing.md),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: filters,
            ),
          ],
        );
      },
    );
  }
}

class _MobileStockFilters extends StatelessWidget {
  const _MobileStockFilters({
    required this.state,
    required this.controller,
    required this.isLoading,
    required this.onSearch,
    required this.onActivityFilterChanged,
    required this.onLowStockChanged,
    required this.onTipoBienChanged,
  });

  final StockState state;
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSearch;
  final ValueChanged<StockActivityFilter> onActivityFilterChanged;
  final ValueChanged<bool> onLowStockChanged;
  final ValueChanged<String?> onTipoBienChanged;

  int get _activeFilterCount =>
      (state.tipoBienFilter == null ? 0 : 1) +
      (state.activityFilter == StockActivityFilter.active ? 0 : 1) +
      (state.lowStockOnly ? 1 : 0);

  void _openFilters(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => _StockFiltersSheet(
        state: state,
        isLoading: isLoading,
        onApply: () {
          Navigator.of(context).pop();
          onSearch();
        },
        onActivityFilterChanged: onActivityFilterChanged,
        onLowStockChanged: onLowStockChanged,
        onTipoBienChanged: onTipoBienChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: _StockSearchField(controller: controller, onSearch: onSearch),
        ),
        const Gap(AppSpacing.sm),
        Badge(
          isLabelVisible: _activeFilterCount > 0,
          label: Text('$_activeFilterCount'),
          child: IconButton.outlined(
            tooltip: 'Abrir filtros',
            onPressed: () => _openFilters(context),
            icon: Icon(Icons.tune_rounded, color: colors.primary),
          ),
        ),
      ],
    );
  }
}

class _StockFiltersSheet extends StatelessWidget {
  const _StockFiltersSheet({
    required this.state,
    required this.isLoading,
    required this.onApply,
    required this.onActivityFilterChanged,
    required this.onLowStockChanged,
    required this.onTipoBienChanged,
  });

  final StockState state;
  final bool isLoading;
  final VoidCallback onApply;
  final ValueChanged<StockActivityFilter> onActivityFilterChanged;
  final ValueChanged<bool> onLowStockChanged;
  final ValueChanged<String?> onTipoBienChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: colors.outlineVariant,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const Gap(AppSpacing.lg),
          Text('Filtros', style: Theme.of(context).textTheme.titleLarge),
          const Gap(AppSpacing.lg),
          _TipoBienFilter(
            value: state.tipoBienFilter,
            onChanged: onTipoBienChanged,
          ),
          const Gap(AppSpacing.lg),
          Text('Estado', style: Theme.of(context).textTheme.labelLarge),
          const Gap(AppSpacing.sm),
          _ActivityFilterSegment(
            value: state.activityFilter,
            onChanged: onActivityFilterChanged,
            expand: true,
          ),
          const Gap(AppSpacing.lg),
          _LowStockToggle(
            value: state.lowStockOnly,
            onChanged: onLowStockChanged,
          ),
          const Gap(AppSpacing.xl),
          AppButton.primary(
            label: 'Aplicar búsqueda',
            icon: Icons.search_rounded,
            isLoading: isLoading,
            onPressed: onApply,
          ),
        ],
      ),
    );
  }
}

class _StockSearchField extends StatelessWidget {
  const _StockSearchField({
    required this.controller,
    required this.onSearch,
    this.isLoading = false,
  });

  final TextEditingController controller;
  final VoidCallback onSearch;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => onSearch(),
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Buscar por código o nombre...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: isLoading
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : IconButton(
                tooltip: 'Aplicar búsqueda',
                onPressed: onSearch,
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
      ),
    );
  }
}

class _ActivityFilterSegment extends StatelessWidget {
  const _ActivityFilterSegment({
    required this.value,
    required this.onChanged,
    this.expand = false,
  });

  final StockActivityFilter value;
  final ValueChanged<StockActivityFilter> onChanged;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final segment = SegmentedButton<StockActivityFilter>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(value: StockActivityFilter.all, label: Text('Todos')),
        ButtonSegment(
          value: StockActivityFilter.active,
          label: Text('Activos'),
        ),
        ButtonSegment(
          value: StockActivityFilter.inactive,
          label: Text('Inactivos'),
        ),
      ],
      selected: {value},
      onSelectionChanged: (selection) {
        final filter = selection.firstOrNull;
        if (filter != null) onChanged(filter);
      },
    );

    return expand ? SizedBox(width: double.infinity, child: segment) : segment;
  }
}

class _LowStockToggle extends StatelessWidget {
  const _LowStockToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(value: value, onChanged: onChanged),
            const Gap(AppSpacing.xs),
            const Text('Solo stock bajo'),
          ],
        ),
      ),
    );
  }
}

class _TipoBienFilter extends StatelessWidget {
  const _TipoBienFilter({
    required this.value,
    required this.onChanged,
    this.compact = false,
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        isDense: compact,
        labelText: compact ? null : 'Tipo de bien',
        hintText: compact ? 'Tipo de bien' : null,
      ),
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('Todos')),
        ...inventoryInsumoTipoBienOptions.map(
          (option) => DropdownMenuItem<String?>(
            value: option.value,
            child: Text(
              option.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class _StockListPanel extends StatelessWidget {
  const _StockListPanel({
    required this.state,
    required this.showTable,
    required this.onRetry,
    required this.onSelectInsumo,
  });

  final StockState state;
  final bool showTable;
  final VoidCallback onRetry;
  final ValueChanged<int> onSelectInsumo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                Text('Resultados', style: theme.textTheme.titleMedium),
                const Spacer(),
                Text(
                  '${state.items.length}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: switch (state.status) {
              StockStatus.loading => const Center(
                child: CircularProgressIndicator(),
              ),
              StockStatus.error => _CenteredMessage(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppMessageCard.error(
                      title: 'No pudimos cargar el stock',
                      message:
                          state.errorMessage ??
                          'Intenta nuevamente para consultar el inventario.',
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
              StockStatus.success =>
                state.items.isEmpty
                    ? const _CenteredMessage(
                        child: AppMessageCard.info(
                          title: 'Sin resultados',
                          message:
                              'No encontramos stock con los filtros actuales.',
                        ),
                      )
                    : showTable
                    ? _StockTable(
                        items: state.items,
                        selectedInsumoId: state.selectedInsumoId,
                        onSelectInsumo: onSelectInsumo,
                      )
                    : ListView.separated(
                        itemCount: state.items.length,
                        separatorBuilder: (_, _) => const Gap(AppSpacing.md),
                        itemBuilder: (context, index) {
                          final item = state.items[index];
                          return _StockListTileCard(
                            item: item,
                            isSelected: item.insumoId == state.selectedInsumoId,
                            onTap: () => onSelectInsumo(item.insumoId),
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

class _StockTable extends StatelessWidget {
  const _StockTable({
    required this.items,
    required this.selectedInsumoId,
    required this.onSelectInsumo,
  });

  final List<StockRecord> items;
  final int? selectedInsumoId;
  final ValueChanged<int> onSelectInsumo;

  static const _columnWidths = <int, TableColumnWidth>{
    0: FlexColumnWidth(0.95),
    1: FlexColumnWidth(1.7),
    2: FlexColumnWidth(1.15),
    3: FlexColumnWidth(0.8),
    4: FlexColumnWidth(0.8),
    5: FlexColumnWidth(0.95),
    6: FlexColumnWidth(0.85),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.separated(
      itemCount: items.length + 1,
      separatorBuilder: (_, index) =>
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Container(
            color: theme.colorScheme.surfaceContainerLow,
            child: Table(
              columnWidths: _columnWidths,
              children: [
                TableRow(
                  children: [
                    _StockTableHeaderCell('Código'),
                    _StockTableHeaderCell('Insumo'),
                    _StockTableHeaderCell('Tipo de bien'),
                    _StockTableHeaderCell('Actual', alignEnd: true),
                    _StockTableHeaderCell('Mín.', alignEnd: true),
                    _StockTableHeaderCell('Costo', alignEnd: true),
                    _StockTableHeaderCell('Estado', centered: true),
                  ],
                ),
              ],
            ),
          );
        }

        final item = items[index - 1];
        final selected = item.insumoId == selectedInsumoId;
        return Material(
          color: selected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.42)
              : Colors.transparent,
          child: InkWell(
            onTap: () => onSelectInsumo(item.insumoId),
            child: Table(
              columnWidths: _columnWidths,
              children: [
                TableRow(
                  children: [
                    _StockTableCell(item.codigo),
                    _StockTableCell(
                      item.nombre,
                      emphasize: true,
                      trailing: item.stockBajo
                          ? const Padding(
                              padding: EdgeInsets.only(top: AppSpacing.xs),
                              child: _InlineStockLowIndicator(),
                            )
                          : null,
                    ),
                    _StockTableCell(_tipoBienLabel(item.tipoBien)),
                    _StockTableCell(
                      '${item.cantidadActual.toStringAsFixed(2)} ${item.unidadMedidaCodigo}',
                      alignEnd: true,
                    ),
                    _StockTableCell(
                      '${item.stockMinimo.toStringAsFixed(2)} ${item.unidadMedidaCodigo}',
                      alignEnd: true,
                    ),
                    _StockTableCell(
                      'S/ ${item.costoPromedioActual.toStringAsFixed(2)}',
                      alignEnd: true,
                    ),
                    _StockStateCell(item: item),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StockTableHeaderCell extends StatelessWidget {
  const _StockTableHeaderCell(
    this.label, {
    this.alignEnd = false,
    this.centered = false,
  });

  final String label;
  final bool alignEnd;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Text(
        label,
        textAlign: centered
            ? TextAlign.center
            : alignEnd
            ? TextAlign.end
            : TextAlign.start,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _StockTableCell extends StatelessWidget {
  const _StockTableCell(
    this.value, {
    this.alignEnd = false,
    this.emphasize = false,
    this.trailing,
  });

  final String value;
  final bool alignEnd;
  final bool emphasize;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: alignEnd
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: alignEnd ? TextAlign.end : TextAlign.start,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          if (trailing case final Widget trailing) trailing,
        ],
      ),
    );
  }
}

class _StockStateCell extends StatelessWidget {
  const _StockStateCell({required this.item});

  final StockRecord item;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Center(
        child: Tooltip(
          message: item.activo ? 'Activo' : 'Inactivo',
          child: Semantics(
            label: item.activo ? 'Estado: activo' : 'Estado: inactivo',
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: item.activo
                    ? colors.primaryContainer
                    : colors.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                item.activo
                    ? Icons.check_circle_outline_rounded
                    : Icons.block_rounded,
                size: 19,
                color: item.activo
                    ? colors.onPrimaryContainer
                    : colors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineStockLowIndicator extends StatelessWidget {
  const _InlineStockLowIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.warning_amber_rounded,
          size: 14,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          'Stock bajo',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.error,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StockDetailPanelV2 extends StatelessWidget {
  const _StockDetailPanelV2({
    required this.state,
    required this.onRetry,
    this.framed = true,
  });

  final StockState state;
  final VoidCallback onRetry;
  final bool framed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detail = state.selectedStock;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            'Detalle de stock',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Divider(height: 1, color: theme.colorScheme.outlineVariant),
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

              if (detail == null) {
                return const _CenteredMessage(
                  child: AppMessageCard.info(
                    title: 'Selecciona un insumo',
                    message:
                        'Escoge un registro del listado para revisar sus existencias vigentes.',
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CÓDIGO: ${detail.codigo}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Gap(AppSpacing.xs),
                    Text(
                      detail.nombre,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Gap(AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _StatusPill(
                          label: detail.activo ? 'Activo' : 'Inactivo',
                          background: detail.activo
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.surfaceContainerHighest,
                          foreground: detail.activo
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        if (detail.stockBajo)
                          _StatusPill(
                            label: 'Stock bajo',
                            background: theme.colorScheme.errorContainer,
                            foreground: theme.colorScheme.onErrorContainer,
                          ),
                      ],
                    ),
                    const Gap(AppSpacing.xl),
                    _StockDetailSection(
                      title: 'Existencias',
                      icon: Icons.inventory_2_outlined,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final current = _StockDetailMetric(
                            label: 'Stock actual',
                            value:
                                '${detail.cantidadActual.toStringAsFixed(2)} ${detail.unidadMedidaCodigo}',
                            emphasize: true,
                          );
                          final minimum = _StockDetailMetric(
                            label: 'Stock minimo',
                            value:
                                '${detail.stockMinimo.toStringAsFixed(2)} ${detail.unidadMedidaCodigo}',
                          );
                          if (constraints.maxWidth < 300) {
                            return Column(
                              children: [
                                current,
                                const Gap(AppSpacing.sm),
                                minimum,
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(child: current),
                              const Gap(AppSpacing.sm),
                              Expanded(child: minimum),
                            ],
                          );
                        },
                      ),
                    ),
                    const Gap(AppSpacing.lg),
                    _StockDetailSection(
                      title: 'Clasificación y costos',
                      icon: Icons.category_outlined,
                      child: Column(
                        children: [
                          _StockDetailAttribute(
                            label: 'Tipo de bien',
                            value: _tipoBienLabel(detail.tipoBien),
                          ),
                          _StockDetailAttribute(
                            label: 'Unidad de medida',
                            value:
                                '${detail.unidadMedidaNombre} (${detail.unidadMedidaCodigo})',
                          ),
                          _StockDetailAttribute(
                            label: 'Costo promedio',
                            value:
                                'S/ ${detail.costoPromedioActual.toStringAsFixed(2)} / ${detail.unidadMedidaCodigo}',
                          ),
                          _StockDetailAttribute(
                            label: 'Última actualización',
                            value: DateFormat(
                              'dd/MM/yyyy HH:mm',
                            ).format(detail.actualizadoEn.toLocal()),
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );

    return framed
        ? AppSurfaceCard(padding: EdgeInsets.zero, child: content)
        : content;
  }
}

class _StockDetailSection extends StatelessWidget {
  const _StockDetailSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 19, color: theme.colorScheme.primary),
              const Gap(AppSpacing.sm),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const Gap(AppSpacing.md),
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
          const Gap(AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _StockDetailMetric extends StatelessWidget {
  const _StockDetailMetric({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(AppSpacing.xs),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w700,
              color: emphasize ? theme.colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _StockDetailAttribute extends StatelessWidget {
  const _StockDetailAttribute({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: AppSpacing.xs,
        spacing: AppSpacing.md,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileStockDetailSheet extends StatelessWidget {
  const _MobileStockDetailSheet();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return FractionallySizedBox(
      heightFactor: 0.86,
      child: Material(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.outlineVariant,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Detalle de stock',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar detalle',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: BlocBuilder<StockCubit, StockState>(
                    builder: (context, state) => _StockDetailPanelV2(
                      state: state,
                      onRetry: () => context.read<StockCubit>().retryDetail(),
                      framed: false,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StockListTileCard extends StatelessWidget {
  const _StockListTileCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final StockRecord item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.48)
                : theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.42)
                  : theme.colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: item.stockBajo
                      ? theme.colorScheme.errorContainer
                      : theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item.stockBajo
                      ? Icons.warning_amber_rounded
                      : Icons.inventory_2_outlined,
                  size: 18,
                  color: item.stockBajo
                      ? theme.colorScheme.onErrorContainer
                      : theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const Gap(AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.codigo,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Gap(AppSpacing.xs),
                    Text(
                      item.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    const Gap(AppSpacing.xs),
                    Text(
                      _tipoBienLabel(item.tipoBien),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${item.cantidadActual.toStringAsFixed(2)} ${item.unidadMedidaCodigo}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: item.stockBajo ? theme.colorScheme.error : null,
                    ),
                  ),
                  const Gap(AppSpacing.xs),
                  Text(
                    'Mín. ${item.stockMinimo.toStringAsFixed(2)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (item.stockBajo) ...[
                    const Gap(AppSpacing.xs),
                    Text(
                      'Stock bajo',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
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

String _tipoBienLabel(String value) {
  final option = inventoryInsumoTipoBienOptions
      .where((item) => item.value == value)
      .firstOrNull;
  return option?.label ?? value;
}
