import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_state.dart';
import 'package:erp_curtiembre_fronted/features/configuration/formulas/domain/entities/formula_record.dart';
import 'package:erp_curtiembre_fronted/features/configuration/formulas/presentation/cubit/formulas_cubit.dart';
import 'package:erp_curtiembre_fronted/features/configuration/formulas/presentation/cubit/formulas_state.dart';
import 'package:erp_curtiembre_fronted/features/configuration/formulas/presentation/widgets/formula_detail_dialog.dart';
import 'package:erp_curtiembre_fronted/features/configuration/formulas/presentation/widgets/formula_upsert_dialog.dart';
import 'package:erp_curtiembre_fronted/features/configuration/formulas/presentation/widgets/formula_version_dialog.dart';
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

  void _applySearch() {
    FocusScope.of(context).unfocus();
    context.read<FormulasCubit>().load(
      searchTerm: _searchController.text.trim(),
    );
  }

  Future<void> _openCreateFormulaDialog(FormulasState state) async {
    final payload = await showDialog<FormulaUpsertFormData>(
      context: context,
      builder: (_) => FormulaUpsertDialog(
        title: 'Nueva formula',
        submitLabel: 'Crear formula',
        processOptions: state.processOptions,
        isSubmitting: state.isSubmittingAction,
      ),
    );

    if (payload == null || !mounted) {
      return;
    }

    final result = await context.read<FormulasCubit>().createFormula(
      codigo: payload.codigo,
      nombre: payload.nombre,
      procesoProductivoId: payload.procesoProductivoId,
      descripcion: payload.descripcion,
    );

    if (mounted) {
      _showActionResult(result);
    }
  }

  Future<void> _openEditFormulaDialog(
    FormulasState state,
    FormulaRecord formula,
  ) async {
    final payload = await showDialog<FormulaUpsertFormData>(
      context: context,
      builder: (_) => FormulaUpsertDialog(
        title: 'Editar formula',
        submitLabel: 'Guardar cambios',
        processOptions: state.processOptions,
        isSubmitting: state.isSubmittingAction,
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
      descripcion: payload.descripcion,
    );

    if (mounted) {
      _showActionResult(result);
    }
  }

  Future<void> _openCreateVersionDialog(FormulasState state) async {
    final payload = await showDialog<FormulaVersionFormData>(
      context: context,
      builder: (_) => FormulaVersionDialog(
        title: 'Nueva version',
        submitLabel: 'Crear version',
        isSubmitting: state.isSubmittingAction,
        cloneOptions: state.versions,
      ),
    );

    if (payload == null || !mounted) {
      return;
    }

    final result = await context.read<FormulasCubit>().createVersion(
      numeroVersion: payload.numeroVersion,
      fechaInicioVigencia: payload.fechaInicioVigencia,
      fechaFinVigencia: payload.fechaFinVigencia,
      observacion: payload.observacion,
      clonarDesdeVersionId: payload.clonarDesdeVersionId,
    );

    if (mounted) {
      _showActionResult(result);
    }
  }

  Future<void> _openEditVersionDialog(
    FormulasState state,
    FormulaVersionRecord version,
  ) async {
    final payload = await showDialog<FormulaVersionFormData>(
      context: context,
      builder: (_) => FormulaVersionDialog(
        title: 'Editar version',
        submitLabel: 'Guardar cambios',
        isSubmitting: state.isSubmittingAction,
        initialVersion: version,
      ),
    );

    if (payload == null || !mounted) {
      return;
    }

    final result = await context.read<FormulasCubit>().updateSelectedVersion(
      fechaInicioVigencia: payload.fechaInicioVigencia,
      fechaFinVigencia: payload.fechaFinVigencia,
      observacion: payload.observacion,
    );

    if (mounted) {
      _showActionResult(result);
    }
  }

  Future<void> _openCreateDetailDialog(FormulasState state) async {
    final payload = await showDialog<FormulaDetailFormData>(
      context: context,
      builder: (_) => FormulaDetailDialog(
        title: 'Nuevo detalle',
        submitLabel: 'Agregar detalle',
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

  Future<void> _openEditDetailDialog(
    FormulasState state,
    FormulaDetailRecord detail,
  ) async {
    final payload = await showDialog<FormulaDetailFormData>(
      context: context,
      builder: (_) => FormulaDetailDialog(
        title: 'Editar detalle',
        submitLabel: 'Guardar detalle',
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

  Future<void> _toggleFormulaState(FormulaRecord formula) async {
    final result = await context.read<FormulasCubit>().setSelectedFormulaActive(
      !formula.activo,
    );
    if (mounted) {
      _showActionResult(result);
    }
  }

  Future<void> _activateVersion() async {
    final result = await context
        .read<FormulasCubit>()
        .activateSelectedVersion();
    if (mounted) {
      _showActionResult(result);
    }
  }

  Future<void> _deleteDetail(int detailId) async {
    final result = await context.read<FormulasCubit>().deleteDetail(detailId);
    if (mounted) {
      _showActionResult(result);
    }
  }

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
      currentPath: '/configuracion/formulas',
      breadcrumbs: const ['Inicio', 'Configuración', 'Fórmulas'],
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
                constraints: const BoxConstraints(maxWidth: 1480),
                child: BlocBuilder<FormulasCubit, FormulasState>(
                  builder: (context, state) {
                    final isWide = constraints.maxWidth >= 1040;
                    final compactHeight = constraints.maxHeight < 900;

                    if (_searchController.text != state.searchTerm) {
                      _searchController.value = TextEditingValue(
                        text: state.searchTerm,
                        selection: TextSelection.collapsed(
                          offset: state.searchTerm.length,
                        ),
                      );
                    }

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
                      onCreateVersion: state.selectedFormula == null
                          ? null
                          : () => _openCreateVersionDialog(state),
                      onEditVersion: state.selectedVersion == null
                          ? null
                          : () => _openEditVersionDialog(
                              state,
                              state.selectedVersion!,
                            ),
                      onActivateVersion: state.selectedVersion == null
                          ? null
                          : _activateVersion,
                      onSelectVersion: (id) =>
                          context.read<FormulasCubit>().selectVersion(id),
                      onCreateDetail: state.selectedVersion == null
                          ? null
                          : () => _openCreateDetailDialog(state),
                      onEditDetail: (detail) =>
                          _openEditDetailDialog(state, detail),
                      onDeleteDetail: _deleteDetail,
                    );

                    final headerAndFilters = <Widget>[
                      Text(
                        'Administra fórmulas, versiones vigentes y proporciones de insumos para cada proceso productivo.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Gap(AppSpacing.xl),
                      _FormulasFiltersCard(
                        controller: _searchController,
                        state: state,
                        isLoading: state.status == FormulasStatus.loading,
                        onSearch: _applySearch,
                        onCreateFormula: () => _openCreateFormulaDialog(state),
                        onActivityFilterChanged: (filter) => context
                            .read<FormulasCubit>()
                            .load(activityFilter: filter),
                        onProcessFilterChanged: (value) => context
                            .read<FormulasCubit>()
                            .load(processFilterId: value),
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
                                height: 700,
                                child: Row(
                                  children: [
                                    Expanded(flex: 7, child: listPanel),
                                    const Gap(AppSpacing.xl),
                                    Expanded(flex: 10, child: detailPanel),
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
                            SizedBox(height: 760, child: detailPanel),
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
                                    Expanded(flex: 7, child: listPanel),
                                    const Gap(AppSpacing.xl),
                                    Expanded(flex: 10, child: detailPanel),
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
    );
  }
}

class _FormulasFiltersCard extends StatelessWidget {
  const _FormulasFiltersCard({
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
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Busqueda, proceso y vigencia',
            style: theme.textTheme.titleLarge,
          ),
          const Gap(AppSpacing.sm),
          Text(
            'Filtra por texto y proceso, luego selecciona una formula para trabajar sus versiones y detalles.',
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
                    labelText: 'Buscar formula',
                    hintText: 'Ej. Remojo o FOR-REM-001',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
              SizedBox(
                width: 320,
                child: DropdownButtonFormField<int?>(
                  initialValue: state.processFilterId,
                  decoration: const InputDecoration(labelText: 'Proceso'),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Todos los procesos'),
                    ),
                    ...state.processOptions.map(
                      (option) => DropdownMenuItem<int?>(
                        value: option.id,
                        child: Text(option.displayName),
                      ),
                    ),
                  ],
                  onChanged: onProcessFilterChanged,
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
                label: 'Nueva formula',
                icon: Icons.science_outlined,
                isLoading: state.isSubmittingAction,
                onPressed: onCreateFormula,
              ),
            ],
          ),
          const Gap(AppSpacing.lg),
          SegmentedButton<FormulaActivityFilter>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment<FormulaActivityFilter>(
                value: FormulaActivityFilter.active,
                label: Text('Activas'),
                icon: Icon(Icons.verified_outlined),
              ),
              ButtonSegment<FormulaActivityFilter>(
                value: FormulaActivityFilter.inactive,
                label: Text('Inactivas'),
                icon: Icon(Icons.block_outlined),
              ),
              ButtonSegment<FormulaActivityFilter>(
                value: FormulaActivityFilter.all,
                label: Text('Todas'),
                icon: Icon(Icons.account_tree_outlined),
              ),
            ],
            selected: {state.activityFilter},
            onSelectionChanged: (selection) {
              final filter = selection.isEmpty ? null : selection.first;
              if (filter != null) {
                onActivityFilterChanged(filter);
              }
            },
          ),
        ],
      ),
    );
  }
}

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
          Text('Listado de formulas', style: theme.textTheme.titleLarge),
          const Gap(AppSpacing.xs),
          Text(
            '${state.items.length} resultado(s) en la vista actual.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(AppSpacing.lg),
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
                      title: 'No pudimos cargar las formulas',
                      message:
                          state.errorMessage ??
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
              FormulasStatus.success =>
                state.items.isEmpty
                    ? const _FormulaCenteredMessage(
                        child: AppMessageCard.info(
                          title: 'Sin resultados',
                          message:
                              'No encontramos formulas con los filtros actuales.',
                        ),
                      )
                    : ListView.separated(
                        itemCount: state.items.length,
                        separatorBuilder: (_, _) => const Gap(AppSpacing.md),
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

class _FormulaDetailPanel extends StatelessWidget {
  const _FormulaDetailPanel({
    required this.state,
    required this.onRetryFormula,
    required this.onRetryVersion,
    required this.onEditFormula,
    required this.onToggleFormulaState,
    required this.onCreateVersion,
    required this.onEditVersion,
    required this.onActivateVersion,
    required this.onSelectVersion,
    required this.onCreateDetail,
    required this.onEditDetail,
    required this.onDeleteDetail,
  });

  final FormulasState state;
  final VoidCallback onRetryFormula;
  final VoidCallback onRetryVersion;
  final VoidCallback? onEditFormula;
  final VoidCallback? onToggleFormulaState;
  final VoidCallback? onCreateVersion;
  final VoidCallback? onEditVersion;
  final VoidCallback? onActivateVersion;
  final ValueChanged<int> onSelectVersion;
  final VoidCallback? onCreateDetail;
  final ValueChanged<FormulaDetailRecord> onEditDetail;
  final ValueChanged<int> onDeleteDetail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formula = state.selectedFormula;
    final version = state.selectedVersion;

    return AppSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Detalle de la formula', style: theme.textTheme.titleLarge),
          const Gap(AppSpacing.xs),
          Text(
            'Administra su vigencia y construye el detalle de insumos que luego consumira Produccion.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(AppSpacing.lg),
          Expanded(
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
                          title: 'No pudimos cargar el detalle de la formula',
                          message: state.formulaDetailErrorMessage!,
                        ),
                        const Gap(AppSpacing.lg),
                        AppButton.secondary(
                          label: 'Reintentar detalle',
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
                      title: 'Selecciona una formula',
                      message:
                          'Escoge un registro del listado para revisar sus versiones y detalle.',
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
                            formula.nombre,
                            style: theme.textTheme.headlineSmall,
                          ),
                          _FormulaStatusBadge(
                            label: formula.activo ? 'Activa' : 'Inactiva',
                            icon: formula.activo
                                ? Icons.verified_outlined
                                : Icons.block_outlined,
                            background: formula.activo
                                ? theme.colorScheme.primaryContainer
                                : theme.colorScheme.surfaceContainerHighest,
                            foreground: formula.activo
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          if (formula.versionVigente != null)
                            _FormulaStatusBadge(
                              label:
                                  'Vigente: v${formula.versionVigente!.numeroVersion}',
                              icon: Icons.bolt_outlined,
                              background: theme.colorScheme.secondaryContainer,
                              foreground:
                                  theme.colorScheme.onSecondaryContainer,
                            ),
                        ],
                      ),
                      const Gap(AppSpacing.xs),
                      Text(
                        '${formula.codigo} · ${formula.processLabel}',
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
                            label: 'Editar formula',
                            icon: Icons.edit_outlined,
                            isLoading: state.isSubmittingAction,
                            onPressed: onEditFormula,
                          ),
                          AppButton.secondary(
                            label: formula.activo
                                ? 'Inactivar formula'
                                : 'Activar formula',
                            icon: formula.activo
                                ? Icons.block_outlined
                                : Icons.check_circle_outline,
                            isLoading: state.isSubmittingAction,
                            onPressed: onToggleFormulaState,
                          ),
                          AppButton.secondary(
                            label: 'Nueva version',
                            icon: Icons.copy_all_outlined,
                            isLoading: state.isSubmittingAction,
                            onPressed: onCreateVersion,
                          ),
                        ],
                      ),
                      const Gap(AppSpacing.xl),
                      Wrap(
                        spacing: AppSpacing.lg,
                        runSpacing: AppSpacing.lg,
                        children: [
                          _FormulaInfoCard(
                            title: 'Identidad',
                            lines: [
                              'ID: ${formula.id}',
                              'Codigo: ${formula.codigo}',
                              'Proceso: ${formula.processLabel}',
                            ],
                          ),
                          _FormulaInfoCard(
                            title: 'Descripcion',
                            lines: [
                              formula.descripcion?.isNotEmpty == true
                                  ? formula.descripcion!
                                  : 'Sin descripcion registrada.',
                            ],
                          ),
                          _FormulaInfoCard(
                            title: 'Trazabilidad',
                            lines: [
                              'Creada: ${_formatDateTime(formula.creadoEn)}',
                              'Version vigente: ${formula.versionVigente == null ? 'Sin vigencia' : 'v${formula.versionVigente!.numeroVersion}'}',
                            ],
                          ),
                        ],
                      ),
                      const Gap(AppSpacing.xl),
                      Text('Versiones', style: theme.textTheme.titleLarge),
                      const Gap(AppSpacing.sm),
                      if (state.versions.isEmpty)
                        const AppMessageCard.info(
                          title: 'Sin versiones registradas',
                          message:
                              'Crea una primera version para poder cargar detalle y activar vigencia.',
                        )
                      else
                        Wrap(
                          spacing: AppSpacing.md,
                          runSpacing: AppSpacing.md,
                          children: state.versions
                              .map(
                                (item) => _FormulaVersionCard(
                                  item: item,
                                  isSelected:
                                      item.id == state.selectedVersionId,
                                  onTap: () => onSelectVersion(item.id),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      const Gap(AppSpacing.xl),
                      Text(
                        'Version seleccionada',
                        style: theme.textTheme.titleLarge,
                      ),
                      const Gap(AppSpacing.sm),
                      if (state.isVersionDetailLoading)
                        const Padding(
                          padding: EdgeInsets.all(AppSpacing.xl),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (state.versionDetailErrorMessage != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppMessageCard.error(
                              title: 'No pudimos cargar la version',
                              message: state.versionDetailErrorMessage!,
                            ),
                            const Gap(AppSpacing.lg),
                            AppButton.secondary(
                              label: 'Reintentar version',
                              icon: Icons.refresh_rounded,
                              onPressed: onRetryVersion,
                            ),
                          ],
                        )
                      else if (version == null)
                        const AppMessageCard.info(
                          title: 'Selecciona una version',
                          message:
                              'Escoge una version para revisar vigencia y administrar su detalle.',
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: AppSpacing.md,
                              runSpacing: AppSpacing.md,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  'Version ${version.numeroVersion}',
                                  style: theme.textTheme.headlineSmall,
                                ),
                                _FormulaStatusBadge(
                                  label: version.vigente
                                      ? 'Vigente'
                                      : 'Historica',
                                  icon: version.vigente
                                      ? Icons.bolt_outlined
                                      : Icons.history_outlined,
                                  background: version.vigente
                                      ? theme.colorScheme.secondaryContainer
                                      : theme
                                            .colorScheme
                                            .surfaceContainerHighest,
                                  foreground: version.vigente
                                      ? theme.colorScheme.onSecondaryContainer
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                            const Gap(AppSpacing.md),
                            Wrap(
                              spacing: AppSpacing.md,
                              runSpacing: AppSpacing.md,
                              children: [
                                AppButton.secondary(
                                  label: 'Editar version',
                                  icon: Icons.edit_note_outlined,
                                  isLoading: state.isSubmittingAction,
                                  onPressed: onEditVersion,
                                ),
                                AppButton.secondary(
                                  label: 'Activar vigencia',
                                  icon: Icons.bolt_outlined,
                                  isLoading: state.isSubmittingAction,
                                  onPressed: version.vigente
                                      ? null
                                      : onActivateVersion,
                                ),
                                AppButton.secondary(
                                  label: 'Agregar detalle',
                                  icon: Icons.add_circle_outline,
                                  isLoading: state.isSubmittingAction,
                                  onPressed: onCreateDetail,
                                ),
                              ],
                            ),
                            const Gap(AppSpacing.lg),
                            Wrap(
                              spacing: AppSpacing.lg,
                              runSpacing: AppSpacing.lg,
                              children: [
                                _FormulaInfoCard(
                                  title: 'Vigencia',
                                  lines: [
                                    'Desde: ${_formatDate(version.fechaInicioVigencia)}',
                                    'Hasta: ${version.fechaFinVigencia == null ? 'Abierta' : _formatDate(version.fechaFinVigencia!)}',
                                    'Detalles activos: ${version.detalles.where((item) => item.activo).length}',
                                  ],
                                ),
                                _FormulaInfoCard(
                                  title: 'Observacion',
                                  lines: [
                                    version.observacion?.isNotEmpty == true
                                        ? version.observacion!
                                        : 'Sin observacion registrada.',
                                  ],
                                ),
                              ],
                            ),
                            const Gap(AppSpacing.xl),
                            Text(
                              'Detalle de insumos',
                              style: theme.textTheme.titleLarge,
                            ),
                            const Gap(AppSpacing.sm),
                            if (version.detalles.isEmpty)
                              const AppMessageCard.warning(
                                title: 'Version sin detalle',
                                message:
                                    'Agrega insumos y porcentajes antes de activar esta version para produccion.',
                              )
                            else
                              Column(
                                children: version.detalles
                                    .map(
                                      (detail) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: AppSpacing.md,
                                        ),
                                        child: _FormulaDetailCard(
                                          detail: detail,
                                          onEdit: () => onEditDetail(detail),
                                          onDelete: () =>
                                              onDeleteDetail(detail.id),
                                        ),
                                      ),
                                    )
                                    .toList(growable: false),
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
                  _FormulaMiniPill(
                    label: item.activo ? 'Activa' : 'Inactiva',
                    background: item.activo
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    foreground: item.activo
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  if (item.versionVigente != null)
                    _FormulaMiniPill(
                      label: 'v${item.versionVigente!.numeroVersion}',
                      background: theme.colorScheme.secondaryContainer,
                      foreground: theme.colorScheme.onSecondaryContainer,
                    ),
                ],
              ),
              const Gap(AppSpacing.sm),
              Text(
                '${item.codigo} · ${item.processLabel}',
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

class _FormulaVersionCard extends StatelessWidget {
  const _FormulaVersionCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final FormulaVersionRecord item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          width: 220,
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
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  Text(
                    'Version ${item.numeroVersion}',
                    style: theme.textTheme.titleMedium,
                  ),
                  _FormulaMiniPill(
                    label: item.vigente ? 'Vigente' : 'Historica',
                    background: item.vigente
                        ? theme.colorScheme.secondaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    foreground: item.vigente
                        ? theme.colorScheme.onSecondaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const Gap(AppSpacing.sm),
              Text(
                'Desde ${_formatDate(item.fechaInicioVigencia)}',
                style: theme.textTheme.bodyMedium,
              ),
              const Gap(AppSpacing.xs),
              Text(
                item.fechaFinVigencia == null
                    ? 'Hasta abierta'
                    : 'Hasta ${_formatDate(item.fechaFinVigencia!)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Gap(AppSpacing.sm),
              Text(
                'Detalles activos: ${item.detallesActivos}',
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

class _FormulaDetailCard extends StatelessWidget {
  const _FormulaDetailCard({
    required this.detail,
    required this.onEdit,
    required this.onDelete,
  });

  final FormulaDetailRecord detail;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(detail.displayName, style: theme.textTheme.titleMedium),
              _FormulaMiniPill(
                label: detail.activo ? 'Activo' : 'Inactivo',
                background: detail.activo
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest,
                foreground: detail.activo
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant,
              ),
              _FormulaMiniPill(
                label: '${detail.porcentaje.toStringAsFixed(4)} %',
                background: theme.colorScheme.secondaryContainer,
                foreground: theme.colorScheme.onSecondaryContainer,
              ),
            ],
          ),
          const Gap(AppSpacing.sm),
          Text(
            detail.observacion?.isNotEmpty == true
                ? detail.observacion!
                : 'Sin observacion registrada.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              AppButton.secondary(
                label: 'Editar',
                icon: Icons.edit_outlined,
                onPressed: onEdit,
              ),
              AppButton.secondary(
                label: 'Inactivar',
                icon: Icons.block_outlined,
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FormulaInfoCard extends StatelessWidget {
  const _FormulaInfoCard({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 270,
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

class _FormulaStatusBadge extends StatelessWidget {
  const _FormulaStatusBadge({
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
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}

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

class _FormulaCenteredMessage extends StatelessWidget {
  const _FormulaCenteredMessage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: child,
      ),
    );
  }
}

String _formatDate(DateTime value) =>
    DateFormat('dd/MM/yyyy').format(value.toLocal());

String _formatDateTime(DateTime value) =>
    DateFormat('dd/MM/yyyy hh:mm a').format(value.toLocal());
