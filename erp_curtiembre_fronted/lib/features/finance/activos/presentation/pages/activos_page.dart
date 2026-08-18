import 'package:erp_curtiembre_fronted/core/di/service_locator.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_breakpoints.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:erp_curtiembre_fronted/features/finance/activos/domain/entities/activo_depreciable_record.dart';
import 'package:erp_curtiembre_fronted/features/finance/activos/presentation/cubit/activos_cubit.dart';
import 'package:erp_curtiembre_fronted/features/finance/activos/presentation/cubit/activos_state.dart';
import 'package:erp_curtiembre_fronted/features/finance/activos/presentation/widgets/activo_upsert_dialog.dart';
import 'package:erp_curtiembre_fronted/features/finance/shared/presentation/widgets/finance_ui.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/buttons/app_button.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/feedback/app_message_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:talker_flutter/talker_flutter.dart';

class ActivosPage extends StatefulWidget {
  const ActivosPage({super.key});

  @override
  State<ActivosPage> createState() => _ActivosPageState();
}

class _ActivosPageState extends State<ActivosPage> {
  final _searchController = TextEditingController();
  final Talker _talker = getIt<Talker>();

  @override
  void initState() {
    super.initState();
    _talker.ui('Se abrio la pantalla de activos depreciables.');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applySearch() {
    FocusScope.of(context).unfocus();
    _talker.ui(
      'Se aplico la busqueda de activos depreciables con texto=${_describeText(_searchController.text)}.',
    );
    context.read<ActivosCubit>().load(
      searchTerm: _searchController.text.trim(),
    );
  }

  Future<void> _openCreateDialog(ActivosState state) async {
    _talker.ui('Se abrio el dialogo para crear un activo depreciable.');
    final payload = await showDialog<ActivoUpsertFormData>(
      context: context,
      builder: (_) => ActivoUpsertDialog(
        title: 'Registrar activo depreciable',
        submitLabel: 'Registrar',
        isSubmitting: state.isSubmittingAction,
      ),
    );

    if (payload == null || !mounted) {
      _talker.ui(
        'Se cerro la creacion de activo depreciable sin confirmar.',
        logLevel: LogLevel.debug,
      );
      return;
    }
    _talker.ui(
      'Se confirmo la creacion de un activo depreciable con codigo=${_describeText(payload.codigo)}, nombre=${_describeText(payload.nombre)}.',
    );

    final result = await context.read<ActivosCubit>().createActivo(
      codigo: payload.codigo,
      nombre: payload.nombre,
      valorCompra: payload.valorCompra,
      fechaCompra: payload.fechaCompra,
      vidaUtilMeses: payload.vidaUtilMeses,
      valorResidual: payload.valorResidual,
      activo: payload.activo,
    );

    if (!mounted) {
      return;
    }
    _showActionResult(result.success, result.message);
  }

  Future<void> _openEditDialog(ActivosState state) async {
    final selected = state.selectedActivo;
    if (selected == null) {
      _talker.ui(
        'Se intento abrir la edicion de un activo depreciable sin seleccion previa.',
        logLevel: LogLevel.warning,
      );
      _showActionResult(false, 'Selecciona un activo para editar.');
      return;
    }

    _talker.ui(
      'Se abrio el dialogo para editar el activo depreciable ${selected.id}.',
      logLevel: LogLevel.warning,
    );
    final payload = await showDialog<ActivoUpsertFormData>(
      context: context,
      builder: (_) => ActivoUpsertDialog(
        title: 'Editar activo depreciable',
        submitLabel: 'Guardar cambios',
        isSubmitting: state.isSubmittingAction,
        initialActivo: selected,
      ),
    );

    if (payload == null || !mounted) {
      _talker.ui(
        'Se cerro la edicion del activo depreciable ${selected.id} sin confirmar.',
        logLevel: LogLevel.debug,
      );
      return;
    }
    _talker.ui(
      'Se confirmo la edicion del activo depreciable ${selected.id}.',
      logLevel: LogLevel.warning,
    );

    final result = await context.read<ActivosCubit>().updateSelectedActivo(
      codigo: payload.codigo,
      nombre: payload.nombre,
      valorCompra: payload.valorCompra,
      fechaCompra: payload.fechaCompra,
      vidaUtilMeses: payload.vidaUtilMeses,
      valorResidual: payload.valorResidual,
      activo: payload.activo,
    );

    if (!mounted) {
      return;
    }
    _showActionResult(result.success, result.message);
  }

  void _showActionResult(bool success, String message) {
    _talker.ui(
      success
          ? 'Accion en activos depreciables completada correctamente.'
          : 'La accion en activos depreciables fallo: $message',
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
        title: const Text('Activos depreciables'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: TextButton.icon(
              onPressed: () {
                _talker.ui(
                  'Se regreso desde activos depreciables al panel principal.',
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
                  child: BlocBuilder<ActivosCubit, ActivosState>(
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

                      final listPanel = _ActivosListPanel(
                        state: state,
                        onRetry: () {
                          _talker.ui(
                            'Se solicito reintentar la carga del listado de activos depreciables.',
                          );
                          context.read<ActivosCubit>().initialize();
                        },
                        onSelectItem: (id) {
                          _talker.ui(
                            'Se selecciono el activo depreciable $id desde el listado.',
                            logLevel: LogLevel.debug,
                          );
                          context.read<ActivosCubit>().selectActivo(id);
                        },
                      );

                      final detailPanel = _ActivosDetailPanel(
                        state: state,
                        onRetry: () {
                          _talker.ui(
                            'Se solicito reintentar el detalle del activo depreciable seleccionado.',
                          );
                          context.read<ActivosCubit>().retryDetail();
                        },
                        onEdit: () => _openEditDialog(state),
                      );

                      final headerAndFilters = <Widget>[
                        FinanceHeroCard(
                          title:
                              'Registra los activos base que luego entraran al calculo mensual de depreciacion.',
                          description:
                              'Aqui controlas vigencia, valor de compra, residual y vida util para que el periodo financiero pueda distribuir el desgaste real.',
                          badgeLabel: 'Activos visibles',
                          badgeValue: '${state.items.length}',
                          sessionUserName: session?.userName,
                        ),
                        const Gap(AppSpacing.xl),
                        _ActivosFiltersCard(
                          state: state,
                          controller: _searchController,
                          isLoading: state.status == ActivosStatus.loading,
                          onSearch: _applySearch,
                          onFilterChanged: (value) {
                            _talker.ui(
                              'Se cambio el filtro de actividad de activos depreciables a ${_describeActivityFilter(value)}.',
                              logLevel: LogLevel.debug,
                            );
                            context.read<ActivosCubit>().load(filter: value);
                          },
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

  String _describeActivityFilter(ActivoActivityFilter value) {
    return switch (value) {
      ActivoActivityFilter.active => 'activos',
      ActivoActivityFilter.inactive => 'inactivos',
      ActivoActivityFilter.all => 'todos',
    };
  }
}

class _ActivosFiltersCard extends StatelessWidget {
  const _ActivosFiltersCard({
    required this.state,
    required this.controller,
    required this.isLoading,
    required this.onSearch,
    required this.onFilterChanged,
    required this.onCreate,
  });

  final ActivosState state;
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSearch;
  final ValueChanged<ActivoActivityFilter> onFilterChanged;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FinanceSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Busqueda y mantenimiento', style: theme.textTheme.titleLarge),
          const Gap(AppSpacing.sm),
          Text(
            'Busca por codigo o nombre, filtra por vigencia y actualiza el activo seleccionado cuando sea necesario.',
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
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => onSearch(),
                  decoration: const InputDecoration(
                    labelText: 'Buscar activo',
                    hintText: 'Ej. ACT-001 o Bombo',
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
                label: 'Nuevo activo',
                icon: Icons.add_business_outlined,
                isLoading: state.isSubmittingAction,
                onPressed: onCreate,
              ),
            ],
          ),
          const Gap(AppSpacing.lg),
          SegmentedButton<ActivoActivityFilter>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment<ActivoActivityFilter>(
                value: ActivoActivityFilter.active,
                label: Text('Activos'),
                icon: Icon(Icons.verified_outlined),
              ),
              ButtonSegment<ActivoActivityFilter>(
                value: ActivoActivityFilter.inactive,
                label: Text('Inactivos'),
                icon: Icon(Icons.block_outlined),
              ),
              ButtonSegment<ActivoActivityFilter>(
                value: ActivoActivityFilter.all,
                label: Text('Todos'),
                icon: Icon(Icons.memory_outlined),
              ),
            ],
            selected: {state.filter},
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

class _ActivosListPanel extends StatelessWidget {
  const _ActivosListPanel({
    required this.state,
    required this.onRetry,
    required this.onSelectItem,
  });

  final ActivosState state;
  final VoidCallback onRetry;
  final ValueChanged<int> onSelectItem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FinanceSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Listado de activos', style: theme.textTheme.titleLarge),
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
              ActivosStatus.loading => const Center(
                child: CircularProgressIndicator(),
              ),
              ActivosStatus.error => FinanceCenteredMessage(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppMessageCard.error(
                      title: 'No pudimos cargar los activos',
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
              ActivosStatus.success =>
                state.items.isEmpty
                    ? const FinanceCenteredMessage(
                        child: AppMessageCard.info(
                          title: 'Sin resultados',
                          message:
                              'No encontramos activos con los filtros actuales.',
                        ),
                      )
                    : ListView.separated(
                        itemCount: state.items.length,
                        separatorBuilder: (_, _) => const Gap(AppSpacing.md),
                        itemBuilder: (context, index) {
                          final item = state.items[index];
                          return _ActivoListTile(
                            item: item,
                            isSelected: item.id == state.selectedActivoId,
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

class _ActivosDetailPanel extends StatelessWidget {
  const _ActivosDetailPanel({
    required this.state,
    required this.onRetry,
    required this.onEdit,
  });

  final ActivosState state;
  final VoidCallback onRetry;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = state.selectedActivo;

    return FinanceSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Detalle del activo', style: theme.textTheme.titleLarge),
          const Gap(AppSpacing.xs),
          Text(
            'Revisa la base monetaria, la vida util y la depreciacion mensual estimada.',
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
                      title: 'Selecciona un activo',
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
                            item.nombre,
                            style: theme.textTheme.headlineSmall,
                          ),
                          FinanceStatusPill(
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
                      const Gap(AppSpacing.xs),
                      Text(
                        item.codigo,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const Gap(AppSpacing.lg),
                      AppButton.secondary(
                        label: 'Editar activo',
                        icon: Icons.edit_outlined,
                        isLoading: state.isSubmittingAction,
                        onPressed: onEdit,
                      ),
                      const Gap(AppSpacing.xl),
                      Wrap(
                        spacing: AppSpacing.lg,
                        runSpacing: AppSpacing.lg,
                        children: [
                          FinanceDetailCard(
                            title: 'Base economica',
                            lines: [
                              'Compra: S/ ${item.valorCompra.toStringAsFixed(2)}',
                              'Residual: S/ ${item.valorResidual.toStringAsFixed(2)}',
                              'Depreciacion mensual: S/ ${(item.depreciacionMensual ?? 0).toStringAsFixed(2)}',
                            ],
                          ),
                          FinanceDetailCard(
                            title: 'Vigencia',
                            lines: [
                              'Fecha compra: ${formatFinanceDate(item.fechaCompra)}',
                              'Vida util: ${item.vidaUtilMeses} mes(es)',
                              'Creado: ${formatFinanceDateTime(item.creadoEn)}',
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

class _ActivoListTile extends StatelessWidget {
  const _ActivoListTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final ActivoDepreciableRecord item;
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
                  FinanceStatusPill(
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
              const Gap(AppSpacing.xs),
              Text(
                item.codigo,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const Gap(AppSpacing.md),
              Text(
                'Compra: S/ ${item.valorCompra.toStringAsFixed(2)} | Vida: ${item.vidaUtilMeses} meses',
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
