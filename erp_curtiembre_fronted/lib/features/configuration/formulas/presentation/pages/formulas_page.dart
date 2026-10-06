import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';

import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';

import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_state.dart';

import 'package:erp_curtiembre_fronted/features/configuration/formulas/domain/entities/formula_record.dart';

import 'package:erp_curtiembre_fronted/features/configuration/formulas/presentation/cubit/formulas_cubit.dart';

import 'package:erp_curtiembre_fronted/features/configuration/formulas/presentation/cubit/formulas_state.dart';

import 'package:erp_curtiembre_fronted/features/configuration/formulas/presentation/widgets/formula_detail_dialog.dart';

import 'package:erp_curtiembre_fronted/features/configuration/formulas/presentation/widgets/formula_upsert_dialog.dart';

import 'package:erp_curtiembre_fronted/features/security/presentation/cubit/security_access_cubit.dart';

import 'package:erp_curtiembre_fronted/shared/navigation/app_access_routes.dart';

import 'package:erp_curtiembre_fronted/shared/widgets/buttons/app_button.dart';

import 'package:erp_curtiembre_fronted/shared/widgets/feedback/app_message_card.dart';

import 'package:erp_curtiembre_fronted/shared/widgets/layout/app_shell.dart';

import 'package:erp_curtiembre_fronted/shared/widgets/layout/app_surface_card.dart';

import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gap/gap.dart';

import 'package:intl/intl.dart';

class FormulasPage extends StatefulWidget {
  const FormulasPage({super.key});

  @override
  State<FormulasPage> createState() => _FormulasPageState();
}

class _FormulasPageState extends State<FormulasPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  // ============================================================

  // BÚSQUEDA

  // ============================================================

  void _applySearch() {
    FocusScope.of(context).unfocus();

    context.read<FormulasCubit>().load(
      searchTerm: _searchController.text.trim(),
    );
  }

  // ============================================================

  // CREAR FÓRMULA

  // ============================================================

  Future<void> _openCreateFormulaDialog(FormulasState state) async {
    final payload = await showDialog<FormulaUpsertFormData>(
      context: context,

      builder: (_) => FormulaUpsertDialog(
        title: 'Nueva fórmula',

        submitLabel: 'Crear fórmula',

        processOptions: state.processOptions,

        isSubmitting: state.isSubmittingAction,

        insumoOptions: state.insumoOptions,
      ),
    );

    if (payload == null || !mounted) {
      return;
    }

    final result = await context.read<FormulasCubit>().createFormula(
      codigo: payload.codigo,

      nombre: payload.nombre,

      procesoProductivoId: payload.procesoProductivoId,

      tipoProducto: payload.tipoProducto,

      color: payload.color,

      productoId: payload.productoId,

      descripcion: payload.descripcion,

      detalles: payload.detalles
          .map(
            (x) => FormulaCreationDetail(
              insumoId: x.insumoId,

              porcentaje: x.porcentaje,

              observacion: x.observacion,
            ),
          )
          .toList(),
    );

    if (mounted) {
      _showActionResult(result);
    }
  }

  // ============================================================

  // EDITAR FÓRMULA

  // ============================================================

  Future<void> _openEditFormulaDialog(
    FormulasState state,

    FormulaRecord formula,
  ) async {
    final payload = await showDialog<FormulaUpsertFormData>(
      context: context,

      builder: (_) => FormulaUpsertDialog(
        title: 'Editar fórmula',

        submitLabel: 'Guardar cambios',

        processOptions: state.processOptions,

        isSubmitting: state.isSubmittingAction,

        insumoOptions: state.insumoOptions,

        initialFormula: formula,
      ),
    );

    if (payload == null || !mounted) {
      return;
    }

    final result = await context.read<FormulasCubit>().updateSelectedFormula(
      codigo: payload.codigo,

      nombre: payload.nombre,

      procesoProductivoId: payload.procesoProductivoId,

      tipoProducto: payload.tipoProducto,

      color: payload.color,

      productoId: payload.productoId,

      descripcion: payload.descripcion,
    );

    if (mounted) {
      _showActionResult(result);
    }
  }

  // ============================================================

  // CREAR INSUMO DE FÓRMULA

  // ============================================================

  Future<void> _openCreateDetailDialog(FormulasState state) async {
    final payload = await showDialog<FormulaDetailFormData>(
      context: context,

      builder: (_) => FormulaDetailDialog(
        title: 'Agregar insumo',

        submitLabel: 'Agregar insumo',

        insumoOptions: state.insumoOptions,

        isSubmitting: state.isSubmittingAction,
      ),
    );

    if (payload == null || !mounted) {
      return;
    }

    final result = await context.read<FormulasCubit>().createDetail(
      insumoId: payload.insumoId,

      porcentaje: payload.porcentaje,

      observacion: payload.observacion,
    );

    if (mounted) {
      _showActionResult(result);
    }
  }

  // ============================================================

  // EDITAR INSUMO

  // ============================================================

  Future<void> _openEditDetailDialog(
    FormulasState state,

    FormulaDetailRecord detail,
  ) async {
    final payload = await showDialog<FormulaDetailFormData>(
      context: context,

      builder: (_) => FormulaDetailDialog(
        title: 'Editar insumo',

        submitLabel: 'Guardar cambios',

        insumoOptions: state.insumoOptions,

        isSubmitting: state.isSubmittingAction,

        initialDetail: detail,
      ),
    );

    if (payload == null || !mounted) {
      return;
    }

    final result = await context.read<FormulasCubit>().updateDetail(
      id: detail.id,

      insumoId: payload.insumoId,

      porcentaje: payload.porcentaje,

      observacion: payload.observacion,

      activo: payload.activo,
    );

    if (mounted) {
      _showActionResult(result);
    }
  }

  // ============================================================

  // ACTIVAR / INACTIVAR FÓRMULA

  // ============================================================

  Future<void> _toggleFormulaState(FormulaRecord formula) async {
    final result = await context.read<FormulasCubit>().setSelectedFormulaActive(
      !formula.activo,
    );

    if (mounted) {
      _showActionResult(result);
    }
  }

  // ============================================================

  // INACTIVAR INSUMO

  // ============================================================

  Future<void> _deleteDetail(int detailId) async {
    final result = await context.read<FormulasCubit>().deleteDetail(detailId);

    if (mounted) {
      _showActionResult(result);
    }
  }

  // ============================================================

  // MENSAJES

  // ============================================================

  void _showActionResult(FormulasActionResult result) {
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

  // ============================================================

  // BUILD

  // ============================================================

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
      title: 'Fórmulas',

      currentPath: '/produccion/formulas',

      breadcrumbs: const ['Inicio', 'Configuración', 'Fórmulas'],

      userName: session.nombreCompleto,

      roleName: session.rolNombre,

      accessibleRoutes: AppAccessRoutes.forPermissions(permissionCodes),

      onSignOut: isSigningOut
          ? () {}
          : () => context.read<AuthCubit>().signOut(),

      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1050;

          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),

            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1500),

                child: BlocBuilder<FormulasCubit, FormulasState>(
                  builder: (context, state) {
                    if (_searchController.text != state.searchTerm) {
                      _searchController.value = TextEditingValue(
                        text: state.searchTerm,

                        selection: TextSelection.collapsed(
                          offset: state.searchTerm.length,
                        ),
                      );
                    }

                    final filters = _FormulasFiltersBar(
                      controller: _searchController,

                      state: state,

                      isLoading: state.status == FormulasStatus.loading,

                      onSearch: _applySearch,

                      onCreateFormula: () => _openCreateFormulaDialog(state),

                      onActivityFilterChanged: (filter) {
                        context.read<FormulasCubit>().load(
                          activityFilter: filter,
                        );
                      },

                      onProcessFilterChanged: (value) {
                        context.read<FormulasCubit>().load(
                          processFilterId: value,
                        );
                      },
                    );

                    final listPanel = _FormulasListPanel(
                      state: state,

                      onRetry: () => context.read<FormulasCubit>().initialize(),

                      onSelectFormula: (id) =>
                          context.read<FormulasCubit>().selectFormula(id),
                    );

                    final detailPanel = _FormulaDetailPanel(
                      state: state,

                      onRetryFormula: () =>
                          context.read<FormulasCubit>().retryFormulaDetail(),

                      onRetryVersion: () =>
                          context.read<FormulasCubit>().retryVersionDetail(),

                      onEditFormula: state.selectedFormula == null
                          ? null
                          : () => _openEditFormulaDialog(
                              state,

                              state.selectedFormula!,
                            ),

                      onToggleFormulaState: state.selectedFormula == null
                          ? null
                          : () => _toggleFormulaState(state.selectedFormula!),

                      onCreateDetail: state.selectedVersion == null
                          ? null
                          : () => _openCreateDetailDialog(state),

                      onEditDetail: (detail) =>
                          _openEditDetailDialog(state, detail),

                      onDeleteDetail: _deleteDetail,
                    );

                    return Column(
                      children: [
                        filters,

                        const Gap(AppSpacing.md),

                        Expanded(
                          child: isWide
                              ? Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,

                                  children: [
                                    Expanded(flex: 34, child: listPanel),

                                    const Gap(AppSpacing.md),

                                    Expanded(flex: 66, child: detailPanel),
                                  ],
                                )
                              : Column(
                                  children: [
                                    Expanded(child: listPanel),

                                    const Gap(AppSpacing.md),

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
}

// ============================================================================

// FILTROS

// ============================================================================

class _FormulasFiltersBar extends StatelessWidget {
  const _FormulasFiltersBar({
    required this.controller,

    required this.state,

    required this.isLoading,

    required this.onSearch,

    required this.onCreateFormula,

    required this.onActivityFilterChanged,

    required this.onProcessFilterChanged,
  });

  final TextEditingController controller;

  final FormulasState state;

  final bool isLoading;

  final VoidCallback onSearch;

  final VoidCallback onCreateFormula;

  final ValueChanged<FormulaActivityFilter> onActivityFilterChanged;

  final ValueChanged<int?> onProcessFilterChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),

      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 900) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,

              children: [
                _searchField(),

                const Gap(AppSpacing.sm),

                _processField(),

                const Gap(AppSpacing.sm),

                _activityFilter(context),

                const Gap(AppSpacing.sm),

                Row(
                  children: [
                    Expanded(
                      child: AppButton.primary(
                        label: 'Aplicar búsqueda',

                        icon: Icons.search_rounded,

                        isLoading: isLoading,

                        onPressed: onSearch,
                      ),
                    ),

                    const Gap(AppSpacing.sm),

                    Expanded(child: _createButton(context)),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(flex: 27, child: _searchField()),

              const Gap(AppSpacing.md),

              Expanded(flex: 22, child: _processField()),

              const Gap(AppSpacing.md),

              Expanded(flex: 26, child: _activityFilter(context)),

              const Gap(AppSpacing.md),

              AppButton.primary(
                label: 'Aplicar búsqueda',

                icon: Icons.search_rounded,

                isLoading: isLoading,

                onPressed: onSearch,

                expand: false,
              ),

              const Gap(AppSpacing.sm),

              _createButton(context),
            ],
          );
        },
      ),
    );
  }

  Widget _searchField() {
    return TextField(
      controller: controller,

      textInputAction: TextInputAction.search,

      onSubmitted: (_) => onSearch(),

      decoration: const InputDecoration(
        hintText: 'Buscar fórmula',

        prefixIcon: Icon(Icons.search_rounded, size: 19),
      ),
    );
  }

  Widget _processField() {
    return DropdownButtonFormField<int?>(
      isExpanded: true,

      initialValue: state.processFilterId,

      decoration: const InputDecoration(labelText: 'Proceso productivo'),

      items: [
        const DropdownMenuItem<int?>(
          value: null,

          child: Text('Todos los procesos'),
        ),

        ...state.processOptions.map(
          (option) => DropdownMenuItem<int?>(
            value: option.id,

            child: Text(option.displayName, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],

      onChanged: onProcessFilterChanged,
    );
  }

  Widget _activityFilter(BuildContext context) {
    return SegmentedButton<FormulaActivityFilter>(
      showSelectedIcon: false,

      segments: const [
        ButtonSegment<FormulaActivityFilter>(
          value: FormulaActivityFilter.all,

          label: Text('Todas'),
        ),

        ButtonSegment<FormulaActivityFilter>(
          value: FormulaActivityFilter.active,

          label: Text('Activas'),
        ),

        ButtonSegment<FormulaActivityFilter>(
          value: FormulaActivityFilter.inactive,

          label: Text('Inactivas'),
        ),
      ],

      selected: {state.activityFilter},

      onSelectionChanged: (selection) {
        if (selection.isNotEmpty) {
          onActivityFilterChanged(selection.first);
        }
      },
    );
  }

  Widget _createButton(BuildContext context) {
    final theme = Theme.of(context);

    return FilledButton.icon(
      onPressed: state.isSubmittingAction ? null : onCreateFormula,

      icon: state.isSubmittingAction
          ? const SizedBox(
              width: 15,

              height: 15,

              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.add_rounded, size: 19),

      label: const Text('Nueva fórmula'),

      style: FilledButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,

        foregroundColor: theme.colorScheme.onPrimary,

        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      ),
    );
  }
}

// ============================================================================

// LISTADO

// ============================================================================

class _FormulasListPanel extends StatelessWidget {
  const _FormulasListPanel({
    required this.state,

    required this.onRetry,

    required this.onSelectFormula,
  });

  final FormulasState state;

  final VoidCallback onRetry;

  final ValueChanged<int> onSelectFormula;

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

              AppSpacing.md,

              AppSpacing.lg,

              AppSpacing.md,
            ),

            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Listado de fórmulas',

                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                _CountBadge('${state.items.length}'),
              ],
            ),
          ),

          Divider(height: 1, color: theme.colorScheme.outlineVariant),

          Expanded(
            child: switch (state.status) {
              FormulasStatus.loading => const Center(
                child: CircularProgressIndicator(),
              ),

              FormulasStatus.error => _FormulaCenteredMessage(
                child: Column(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    AppMessageCard.error(
                      title: 'No pudimos cargar las fórmulas',

                      message: state.errorMessage ?? 'Intenta nuevamente.',
                    ),

                    const Gap(AppSpacing.md),

                    AppButton.secondary(
                      label: 'Reintentar',

                      icon: Icons.refresh_rounded,

                      onPressed: onRetry,
                    ),
                  ],
                ),
              ),

              FormulasStatus.success =>
                state.items.isEmpty
                    ? const _FormulaCenteredMessage(
                        child: AppMessageCard.info(
                          title: 'Sin resultados',

                          message: 'No encontramos fórmulas.',
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.md),

                        itemCount: state.items.length,

                        separatorBuilder: (_, _) => const Gap(AppSpacing.sm),

                        itemBuilder: (context, index) {
                          final item = state.items[index];

                          return _FormulaListTileCard(
                            item: item,

                            isSelected: item.id == state.selectedFormulaId,

                            onTap: () => onSelectFormula(item.id),
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

// ============================================================================

// TARJETA DE FÓRMULA

// ============================================================================

class _FormulaListTileCard extends StatelessWidget {
  const _FormulaListTileCard({
    required this.item,

    required this.isSelected,

    required this.onTap,
  });

  final FormulaRecord item;

  final bool isSelected;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: onTap,

        borderRadius: BorderRadius.circular(12),

        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),

          decoration: BoxDecoration(
            color: isSelected
                ? colors.primary.withValues(alpha: 0.08)
                : colors.surfaceContainerLowest,

            borderRadius: BorderRadius.circular(12),

            border: Border.all(
              color: isSelected ? colors.primary : colors.outlineVariant,

              width: isSelected ? 1.3 : 1,
            ),
          ),

          child: Row(
            children: [
              Container(
                width: 44,

                height: 44,

                alignment: Alignment.center,

                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),

                  borderRadius: BorderRadius.circular(12),
                ),

                child: Text(
                  'F',

                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.primary,

                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              const Gap(AppSpacing.md),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.nombre,

                            maxLines: 1,

                            overflow: TextOverflow.ellipsis,

                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                        const Gap(AppSpacing.sm),

                        _FormulaMiniPill(
                          label: item.activo ? 'Activa' : 'Inactiva',

                          background: item.activo
                              ? const Color(0xFFE5F5E8)
                              : const Color(0xFFFFE7E7),

                          foreground: item.activo
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFB3261E),
                        ),
                      ],
                    ),

                    const Gap(3),

                    Text(
                      item.codigo,

                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.primary,

                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const Gap(2),

                    Text(
                      item.processLabel,

                      maxLines: 1,

                      overflow: TextOverflow.ellipsis,

                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================

// DETALLE PRINCIPAL

// ============================================================================

class _FormulaDetailPanel extends StatelessWidget {
  const _FormulaDetailPanel({
    required this.state,

    required this.onRetryFormula,

    required this.onRetryVersion,

    required this.onEditFormula,

    required this.onToggleFormulaState,

    required this.onCreateDetail,

    required this.onEditDetail,

    required this.onDeleteDetail,
  });

  final FormulasState state;

  final VoidCallback onRetryFormula;

  final VoidCallback onRetryVersion;

  final VoidCallback? onEditFormula;

  final VoidCallback? onToggleFormulaState;

  final VoidCallback? onCreateDetail;

  final ValueChanged<FormulaDetailRecord> onEditDetail;

  final ValueChanged<int> onDeleteDetail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    final formula = state.selectedFormula;

    final version = state.selectedVersion;

    return AppSurfaceCard(
      padding: EdgeInsets.zero,

      child: Builder(
        builder: (context) {
          if (state.isFormulaDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.formulaDetailErrorMessage != null) {
            return _FormulaCenteredMessage(
              child: Column(
                mainAxisSize: MainAxisSize.min,

                children: [
                  AppMessageCard.error(
                    title: 'No pudimos cargar el detalle',

                    message: state.formulaDetailErrorMessage!,
                  ),

                  const Gap(AppSpacing.md),

                  AppButton.secondary(
                    label: 'Reintentar',

                    icon: Icons.refresh_rounded,

                    onPressed: onRetryFormula,
                  ),
                ],
              ),
            );
          }

          if (formula == null) {
            return const _FormulaCenteredMessage(
              child: AppMessageCard.info(
                title: 'Selecciona una fórmula',

                message: 'Selecciona un registro para ver su detalle.',
              ),
            );
          }

          return Column(
            children: [
              // =================================================

              // HEADER

              // =================================================
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              Wrap(
                                spacing: AppSpacing.sm,

                                runSpacing: AppSpacing.xs,

                                crossAxisAlignment: WrapCrossAlignment.center,

                                children: [
                                  Text(
                                    formula.nombre,

                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),

                                  _FormulaMiniPill(
                                    label: formula.activo
                                        ? 'Activa'
                                        : 'Inactiva',

                                    background: formula.activo
                                        ? const Color(0xFFE5F5E8)
                                        : const Color(0xFFFFE7E7),

                                    foreground: formula.activo
                                        ? const Color(0xFF2E7D32)
                                        : const Color(0xFFB3261E),
                                  ),
                                ],
                              ),

                              const Gap(4),

                              Text(
                                '${formula.codigo} · ${formula.processLabel}',

                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colors.primary,

                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Gap(AppSpacing.md),

                        Wrap(
                          spacing: AppSpacing.sm,

                          runSpacing: AppSpacing.sm,

                          children: [
                            OutlinedButton.icon(
                              onPressed: state.isSubmittingAction
                                  ? null
                                  : onEditFormula,

                              icon: const Icon(Icons.edit_outlined, size: 17),

                              label: const Text('Editar fórmula'),
                            ),

                            OutlinedButton.icon(
                              onPressed: state.isSubmittingAction
                                  ? null
                                  : onToggleFormulaState,

                              icon: Icon(
                                formula.activo
                                    ? Icons.block_outlined
                                    : Icons.check_circle_outline,

                                size: 17,
                              ),

                              label: Text(
                                formula.activo
                                    ? 'Inactivar fórmula'
                                    : 'Activar fórmula',
                              ),

                              style: OutlinedButton.styleFrom(
                                foregroundColor: formula.activo
                                    ? colors.error
                                    : const Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const Gap(AppSpacing.lg),

                    // =================================================

                    // INFO CARDS

                    // =================================================
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final horizontal = constraints.maxWidth >= 760;

                        final identity = _FormulaInfoBlock(
                          title: 'Identidad',
                          child: Column(
                            children: [
                              _InfoRow(label: 'ID', value: '${formula.id}'),
                              _InfoRow(label: 'Código', value: formula.codigo),
                              _InfoRow(
                                label: 'Proceso',
                                value: formula.processLabel,
                              ),
                              if (formula.productoId != null) ...[
                                _InfoRow(
                                  label: 'Producto',
                                  value: _textOrFallback(formula.productoNombre),
                                ),
                                _InfoRow(
                                  label: 'Tipo',
                                  value: _textOrFallback(formula.tipoProducto),
                                ),
                                _InfoRow(
                                  label: 'Color',
                                  value: _textOrFallback(formula.color),
                                ),
                              ],
                            ],
                          ),
                        );

                        final description = _FormulaInfoBlock(
                          title: 'Descripción',
                          child: Text(
                            _textOrFallback(
                              formula.descripcion,
                              fallback: 'Sin descripción registrada.',
                            ),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                              height: 1.45,
                            ),
                          ),
                        );

                        final trace = _FormulaInfoBlock(
                          title: 'Trazabilidad',

                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              Text(
                                'Creada el',

                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),

                              const Gap(4),

                              Text(
                                _formatDateTime(formula.creadoEn),

                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );

                        if (!horizontal) {
                          return Column(
                            children: [
                              identity,

                              const Gap(AppSpacing.md),

                              description,

                              const Gap(AppSpacing.md),

                              trace,
                            ],
                          );
                        }

                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(flex: 4, child: identity),

                              const Gap(AppSpacing.md),

                              Expanded(flex: 4, child: description),

                              const Gap(AppSpacing.md),

                              Expanded(flex: 3, child: trace),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              Divider(height: 1, color: colors.outlineVariant),

              // =================================================

              // INSUMOS

              // =================================================
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Insumos de la fórmula',

                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),

                          FilledButton.icon(
                            onPressed: state.isSubmittingAction
                                ? null
                                : onCreateDetail,

                            icon: const Icon(Icons.add_rounded, size: 18),

                            label: const Text('Agregar insumo'),
                          ),
                        ],
                      ),

                      const Gap(AppSpacing.md),

                      Expanded(
                        child: Builder(
                          builder: (context) {
                            if (state.isVersionDetailLoading) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (state.versionDetailErrorMessage != null) {
                              return _FormulaCenteredMessage(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,

                                  children: [
                                    AppMessageCard.error(
                                      title: 'No pudimos cargar los insumos',

                                      message: state.versionDetailErrorMessage!,
                                    ),

                                    const Gap(AppSpacing.md),

                                    AppButton.secondary(
                                      label: 'Reintentar',

                                      icon: Icons.refresh_rounded,

                                      onPressed: onRetryVersion,
                                    ),
                                  ],
                                ),
                              );
                            }

                            if (version == null || version.detalles.isEmpty) {
                              return const _FormulaCenteredMessage(
                                child: AppMessageCard.info(
                                  title: 'Fórmula sin insumos',

                                  message:
                                      'Agrega los insumos y porcentajes que componen la fórmula.',
                                ),
                              );
                            }

                            return _FormulaDetailsTable(
                              details: version.detalles,

                              onEdit: onEditDetail,

                              onDelete: onDeleteDetail,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================================

// TABLA DE INSUMOS

// ============================================================================

class _FormulaDetailsTable extends StatelessWidget {
  const _FormulaDetailsTable({
    required this.details,

    required this.onEdit,

    required this.onDelete,
  });

  final List<FormulaDetailRecord> details;

  final ValueChanged<FormulaDetailRecord> onEdit;

  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),

        borderRadius: BorderRadius.circular(12),
      ),

      clipBehavior: Clip.antiAlias,

      child: Column(
        children: [
          // HEADER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),

            color: colors.surfaceContainerLow,

            child: const Row(
              children: [
                SizedBox(
                  width: 34,

                  child: Text(
                    '#',

                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),

                SizedBox(
                  width: 100,

                  child: Text(
                    'Código',

                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),

                Expanded(
                  flex: 3,

                  child: Text(
                    'Insumo',

                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),

                SizedBox(
                  width: 110,

                  child: Text(
                    'Porcentaje',

                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),

                Expanded(
                  flex: 3,

                  child: Text(
                    'Observación',

                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),

                SizedBox(
                  width: 95,

                  child: Text(
                    'Estado',

                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),

                SizedBox(
                  width: 95,

                  child: Text(
                    'Acciones',

                    textAlign: TextAlign.center,

                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.separated(
              itemCount: details.length,

              separatorBuilder: (_, _) =>
                  Divider(height: 1, color: colors.outlineVariant),

              itemBuilder: (context, index) {
                final detail = details[index];

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,

                    vertical: 10,
                  ),

                  child: Row(
                    children: [
                      SizedBox(width: 34, child: Text('${index + 1}')),

                      SizedBox(
                        width: 100,

                        child: Text(
                          detail.insumoCodigo,

                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),

                      Expanded(
                        flex: 3,

                        child: Text(
                          detail.insumoNombre,

                          maxLines: 1,

                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      SizedBox(
                        width: 110,

                        child: Text(
                          '${detail.porcentaje.toStringAsFixed(4)} %',
                        ),
                      ),

                      Expanded(
                        flex: 3,

                        child: Text(
                          detail.observacion?.isNotEmpty == true
                              ? detail.observacion!
                              : 'Sin observación.',

                          maxLines: 1,

                          overflow: TextOverflow.ellipsis,

                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),

                      SizedBox(
                        width: 95,

                        child: Align(
                          alignment: Alignment.centerLeft,

                          child: _FormulaMiniPill(
                            label: detail.activo ? 'Activo' : 'Inactivo',

                            background: detail.activo
                                ? const Color(0xFFE5F5E8)
                                : const Color(0xFFFFE7E7),

                            foreground: detail.activo
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFFB3261E),
                          ),
                        ),
                      ),

                      SizedBox(
                        width: 95,

                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,

                          children: [
                            IconButton(
                              tooltip: 'Editar',

                              visualDensity: VisualDensity.compact,

                              onPressed: () => onEdit(detail),

                              icon: const Icon(Icons.edit_outlined, size: 18),
                            ),

                            IconButton(
                              tooltip: 'Inactivar',

                              visualDensity: VisualDensity.compact,

                              onPressed: detail.activo
                                  ? () => onDelete(detail.id)
                                  : null,

                              color: colors.error,

                              icon: const Icon(Icons.block_outlined, size: 18),
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
      ),
    );
  }
}

// ============================================================================

// BLOQUES DE INFORMACIÓN

// ============================================================================

class _FormulaInfoBlock extends StatelessWidget {
  const _FormulaInfoBlock({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),

              const Gap(AppSpacing.sm),

              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const Gap(AppSpacing.md),

          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;

  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          SizedBox(
            width: 65,

            child: Text(
              label,

              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value,

              maxLines: 2,

              overflow: TextOverflow.ellipsis,

              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================

// BADGES

// ============================================================================

class _FormulaMiniPill extends StatelessWidget {
  const _FormulaMiniPill({
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),

      decoration: BoxDecoration(
        color: background,

        borderRadius: BorderRadius.circular(999),
      ),

      child: Text(
        label,

        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,

          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),

      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,

        borderRadius: BorderRadius.circular(999),
      ),

      child: Text('$value registros', style: theme.textTheme.labelSmall),
    );
  }
}

// ============================================================================

// MENSAJE CENTRADO

// ============================================================================

class _FormulaCenteredMessage extends StatelessWidget {
  const _FormulaCenteredMessage({required this.child});

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

// ============================================================================

// FORMATOS

// ============================================================================

String _textOrFallback(String? value, {String fallback = 'Sin especificar'}) {
  final text = value?.trim();

  return text == null || text.isEmpty ? fallback : text;
}

String _formatDateTime(DateTime value) {
  return DateFormat('dd/MM/yyyy hh:mm a').format(value.toLocal());
}
