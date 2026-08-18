import 'package:erp_curtiembre_fronted/core/di/service_locator.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_state.dart';
import 'package:erp_curtiembre_fronted/features/inventory/ajustes/domain/entities/ajuste_detail.dart';
import 'package:erp_curtiembre_fronted/features/inventory/ajustes/domain/entities/ajuste_record.dart';
import 'package:erp_curtiembre_fronted/features/inventory/ajustes/presentation/cubit/ajustes_cubit.dart';
import 'package:erp_curtiembre_fronted/features/inventory/ajustes/presentation/cubit/ajustes_state.dart';
import 'package:erp_curtiembre_fronted/features/inventory/ajustes/presentation/widgets/ajuste_upsert_dialog.dart';
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
import 'package:talker_flutter/talker_flutter.dart';

class AjustesPage extends StatefulWidget {
  const AjustesPage({super.key});

  @override
  State<AjustesPage> createState() => _AjustesPageState();
}

class _AjustesPageState extends State<AjustesPage> {
  final _searchController = TextEditingController();
  final Talker _talker = getIt<Talker>();

  @override
  void initState() {
    super.initState();
    _talker.ui('Se abrio la pantalla de ajustes de inventario.');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applySearch() {
    FocusScope.of(context).unfocus();
    _talker.ui(
      'Se aplico una busqueda en ajustes con texto=${_describeText(_searchController.text)}.',
    );
    context.read<AjustesCubit>().load(
      searchTerm: _searchController.text.trim(),
    );
  }

  Future<void> _openDialog(AjusteDraftType type, AjustesState state) async {
    final (title, helperText, requiresCost) = switch (type) {
      AjusteDraftType.positivo => (
        'Registrar ajuste positivo',
        'Usa este flujo para regularizaciones por sobrantes, diferencias de conteo o ingresos no documentales.',
        true,
      ),
      AjusteDraftType.negativo => (
        'Registrar ajuste negativo',
        'Usa este flujo para corregir mermas o diferencias operativas con trazabilidad independiente.',
        false,
      ),
    };
    _talker.ui(
      type == AjusteDraftType.positivo
          ? 'Se abrio el dialogo para registrar un ajuste positivo.'
          : 'Se abrio el dialogo para registrar un ajuste negativo.',
      logLevel: type == AjusteDraftType.positivo
          ? LogLevel.debug
          : LogLevel.warning,
    );

    final payload = await showDialog<AjusteUpsertFormData>(
      context: context,
      builder: (_) => AjusteUpsertDialog(
        title: title,
        helperText: helperText,
        insumos: state.insumos,
        isSubmitting: state.isSubmittingAction,
        requiresCost: requiresCost,
      ),
    );

    if (payload == null || !mounted) {
      _talker.ui(
        type == AjusteDraftType.positivo
            ? 'Se cerro el ajuste positivo sin confirmar.'
            : 'Se cerro el ajuste negativo sin confirmar.',
        logLevel: LogLevel.debug,
      );
      return;
    }
    _talker.ui(
      type == AjusteDraftType.positivo
          ? 'Se confirmo el registro de ajuste positivo con ${payload.detalles.length} detalles.'
          : 'Se confirmo el registro de ajuste negativo con ${payload.detalles.length} detalles.',
      logLevel: type == AjusteDraftType.positivo
          ? LogLevel.debug
          : LogLevel.warning,
    );

    final cubit = context.read<AjustesCubit>();
    final result = switch (type) {
      AjusteDraftType.positivo => await cubit.registerPositive(
        motivo: payload.motivo,
        observacion: payload.observacion,
        detalles: payload.detalles,
      ),
      AjusteDraftType.negativo => await cubit.registerNegative(
        motivo: payload.motivo,
        observacion: payload.observacion,
        detalles: payload.detalles,
      ),
    };

    if (!mounted) return;
    _showActionResult(result);
  }

  void _showActionResult(AjustesActionResult result) {
    _talker.ui(
      result.success
          ? 'Accion en ajustes de inventario completada correctamente.'
          : 'La accion en ajustes de inventario fallo: ${result.message}',
      logLevel: result.success ? LogLevel.debug : LogLevel.error,
    );
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
      title: 'Ajustes',
      currentPath: '/inventario/ajustes',
      breadcrumbs: const ['Inicio', 'Inventario', 'Ajustes'],
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
                child: BlocBuilder<AjustesCubit, AjustesState>(
                  builder: (context, state) {
                    final isWide = constraints.maxWidth >= 1040;
                    final compactHeight = constraints.maxHeight < 860;

                    if (_searchController.text != state.searchTerm) {
                      _searchController.value = TextEditingValue(
                        text: state.searchTerm,
                        selection: TextSelection.collapsed(
                          offset: state.searchTerm.length,
                        ),
                      );
                    }

                    final listPanel = _AjustesListPanel(
                      state: state,
                      onRetry: () {
                        _talker.ui(
                          'Se solicito reintentar la carga del listado de ajustes.',
                        );
                        context.read<AjustesCubit>().initialize();
                      },
                      onSelectAjuste: (id) {
                        _talker.ui(
                          'Se selecciono el ajuste $id desde el listado.',
                          logLevel: LogLevel.debug,
                        );
                        context.read<AjustesCubit>().selectAjuste(id);
                      },
                    );

                    final detailPanel = _AjusteDetailPanel(
                      state: state,
                      onRetry: () {
                        _talker.ui(
                          'Se solicito reintentar el detalle del ajuste seleccionado.',
                        );
                        context.read<AjustesCubit>().retryDetail();
                      },
                    );

                    final headerAndFilters = <Widget>[
                      Text(
                        'Registra regularizaciones positivas o negativas con trazabilidad independiente de compras y salidas.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Gap(AppSpacing.xl),
                      _AjustesFiltersCard(
                        state: state,
                        controller: _searchController,
                        onSearch: _applySearch,
                        onTipoAjusteChanged: (value) {
                          _talker.ui(
                            'Se cambio el filtro de tipo de ajuste a ${_describeType(value)}.',
                            logLevel: LogLevel.debug,
                          );
                          context.read<AjustesCubit>().load(
                            tipoAjusteFilter: value,
                          );
                        },
                        onCreatePositive: () =>
                            _openDialog(AjusteDraftType.positivo, state),
                        onCreateNegative: () =>
                            _openDialog(AjusteDraftType.negativo, state),
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

class _AjustesFiltersCard extends StatelessWidget {
  const _AjustesFiltersCard({
    required this.state,
    required this.controller,
    required this.onSearch,
    required this.onTipoAjusteChanged,
    required this.onCreatePositive,
    required this.onCreateNegative,
  });

  final AjustesState state;
  final TextEditingController controller;
  final VoidCallback onSearch;
  final ValueChanged<String?> onTipoAjusteChanged;
  final VoidCallback onCreatePositive;
  final VoidCallback onCreateNegative;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Busqueda y registro', style: theme.textTheme.titleLarge),
          const Gap(AppSpacing.sm),
          Text(
            'Filtra por codigo o tipo de ajuste y abre el flujo adecuado segun la regularizacion que necesites hacer.',
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
                width: 300,
                child: TextField(
                  controller: controller,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => onSearch(),
                  decoration: const InputDecoration(
                    labelText: 'Buscar ajuste',
                    hintText: 'Ej. AJ-000001',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
              SizedBox(
                width: 260,
                child: DropdownButtonFormField<String?>(
                  initialValue: state.tipoAjusteFilter,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de ajuste',
                  ),
                  items: const [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Todos'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'POSITIVO',
                      child: Text('Positivo'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'NEGATIVO',
                      child: Text('Negativo'),
                    ),
                  ],
                  onChanged: onTipoAjusteChanged,
                ),
              ),
              AppButton.secondary(
                label: 'Buscar',
                icon: Icons.filter_alt_outlined,
                onPressed: onSearch,
              ),
            ],
          ),
          const Gap(AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              AppButton.primary(
                label: 'Ajuste positivo',
                icon: Icons.add_circle_outline,
                expand: false,
                onPressed: state.isSubmittingAction ? null : onCreatePositive,
              ),
              AppButton.secondary(
                label: 'Ajuste negativo',
                icon: Icons.remove_circle_outline,
                onPressed: state.isSubmittingAction ? null : onCreateNegative,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AjustesListPanel extends StatelessWidget {
  const _AjustesListPanel({
    required this.state,
    required this.onRetry,
    required this.onSelectAjuste,
  });

  final AjustesState state;
  final VoidCallback onRetry;
  final ValueChanged<int> onSelectAjuste;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (state.status == AjustesStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == AjustesStatus.error) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppMessageCard.error(
            title: 'No pudimos cargar los ajustes',
            message: state.errorMessage ?? 'Intenta nuevamente.',
          ),
          const Gap(AppSpacing.lg),
          AppButton.secondary(
            label: 'Reintentar',
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
          ),
        ],
      );
    }

    if (state.items.isEmpty) {
      return const AppMessageCard.info(
        title: 'Sin ajustes registrados',
        message:
            'Todavia no hay ajustes que coincidan con los filtros actuales.',
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: state.items.length,
        separatorBuilder: (_, index) => const Gap(AppSpacing.md),
        itemBuilder: (context, index) {
          final item = state.items[index];
          final selected = state.selectedAjusteId == item.id;
          return _AjusteListTile(
            item: item,
            selected: selected,
            onTap: () => onSelectAjuste(item.id),
          );
        },
      ),
    );
  }
}

class _AjusteListTile extends StatelessWidget {
  const _AjusteListTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AjusteRecord item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.48)
              : theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(item.codigo, style: theme.textTheme.titleMedium),
                ),
                _StatusPill(label: item.tipoAjuste),
              ],
            ),
            const Gap(AppSpacing.sm),
            Text(item.motivo, style: theme.textTheme.bodyLarge),
            const Gap(AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              children: [
                _InfoChip(
                  label: DateFormat('dd/MM/yyyy').format(item.fechaAjuste),
                ),
                _InfoChip(label: '${item.totalItems} items'),
                _InfoChip(
                  label: 'Cant. ${item.cantidadTotal.toStringAsFixed(2)}',
                ),
                _InfoChip(label: 'Monto ${item.montoTotal.toStringAsFixed(2)}'),
                _InfoChip(label: 'Resp. ${item.usuarioResponsableId}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AjusteDetailPanel extends StatelessWidget {
  const _AjusteDetailPanel({required this.state, required this.onRetry});

  final AjustesState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detail = state.selectedAjuste;

    if (state.isDetailLoading) {
      return AppSurfaceCard(
        padding: EdgeInsets.zero,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state.detailErrorMessage != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppMessageCard.error(
            title: 'No pudimos cargar el detalle',
            message: state.detailErrorMessage!,
          ),
          const Gap(AppSpacing.lg),
          AppButton.secondary(
            label: 'Reintentar',
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
          ),
        ],
      );
    }

    if (detail == null) {
      return const AppMessageCard.info(
        title: 'Selecciona un ajuste',
        message:
            'Elige un registro para revisar sus lineas y el impacto asociado.',
      );
    }

    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  detail.codigo,
                  style: theme.textTheme.headlineSmall,
                ),
              ),
              _StatusPill(label: detail.tipoAjuste),
            ],
          ),
          const Gap(AppSpacing.sm),
          Text(detail.motivo, style: theme.textTheme.titleMedium),
          const Gap(AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              _InfoChip(
                label: DateFormat(
                  'dd/MM/yyyy HH:mm',
                ).format(detail.fechaAjuste),
              ),
              _InfoChip(label: 'Resp. ${detail.usuarioResponsableId}'),
            ],
          ),
          if (detail.observacion != null &&
              detail.observacion!.trim().isNotEmpty) ...[
            const Gap(AppSpacing.lg),
            Text(
              detail.observacion!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const Gap(AppSpacing.xl),
          Text('Lineas ajustadas', style: theme.textTheme.titleLarge),
          const Gap(AppSpacing.md),
          Expanded(
            child: ListView.separated(
              itemCount: detail.detalles.length,
              separatorBuilder: (_, index) => const Gap(AppSpacing.md),
              itemBuilder: (context, index) =>
                  _AjusteDetailLineTile(line: detail.detalles[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class _AjusteDetailLineTile extends StatelessWidget {
  const _AjusteDetailLineTile({required this.line});

  final AjusteDetalleLine line;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${line.insumoCodigo} - ${line.insumoNombre}',
            style: theme.textTheme.titleMedium,
          ),
          const Gap(AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              _InfoChip(
                label:
                    '${line.cantidad.toStringAsFixed(2)} ${line.unidadMedidaCodigo}',
              ),
              if (line.costoUnitario != null)
                _InfoChip(
                  label: 'Costo ${line.costoUnitario!.toStringAsFixed(2)}',
                ),
              _InfoChip(label: 'Total ${line.costoTotal.toStringAsFixed(2)}'),
              _InfoChip(label: 'Stock ${line.stockActual.toStringAsFixed(2)}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: theme.textTheme.labelMedium),
    );
  }
}
