import 'dart:async';

import 'package:erp_curtiembre_fronted/core/di/service_locator.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_state.dart';
import 'package:erp_curtiembre_fronted/features/production/lotes/domain/entities/lote_record.dart';
import 'package:erp_curtiembre_fronted/features/production/lotes/presentation/cubit/lotes_cubit.dart';
import 'package:erp_curtiembre_fronted/features/production/lotes/presentation/cubit/lotes_state.dart';
import 'package:erp_curtiembre_fronted/features/production/lotes/presentation/widgets/lote_upsert_dialog.dart';
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

class LotesPage extends StatefulWidget {
  const LotesPage({super.key});

  @override
  State<LotesPage> createState() => _LotesPageState();
}

class _LotesPageState extends State<LotesPage> {
  final _searchController = TextEditingController();
  final Talker _talker = getIt<Talker>();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _talker.ui('Se abrio la pantalla de lotes.');
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _searchAsYouType(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      context.read<LotesCubit>().load(
        searchTerm: value.trim(),
        resetCliente: true,
        resetTipoPiel: true,
        resetEstado: true,
      );
    });
  }

  Future<void> _openCreateDialog(LotesState state) async {
    _talker.ui('Se abrio el dialogo para crear lote.');
    final payload = await showDialog<LoteUpsertFormData>(
      context: context,
      builder: (_) => LoteUpsertDialog(
        title: 'Nuevo lote',
        submitLabel: 'Crear lote',
        isSubmitting: state.isSubmittingAction,
        clienteOptions: state.clienteOptions,
        tipoPielOptions: state.tipoPielOptions,
      ),
    );

    if (payload == null || !mounted) {
      _talker.ui(
        'Se cerro el dialogo de creacion de lote sin confirmar.',
        logLevel: LogLevel.debug,
      );
      return;
    }
    _talker.ui(
      'Se confirmo la creacion de lote para clienteId=${payload.clienteId}, tipoPielId=${payload.tipoPielId}.',
    );

    final result = await context.read<LotesCubit>().createLote(
      clienteId: payload.clienteId,
      tipoPielId: payload.tipoPielId,
      fechaIngreso: payload.fechaIngreso,
      cantidadPielesInicial: payload.cantidadPielesInicial,
      clienteTraeLote: payload.clienteTraeLote,
      costoPielesTotal: payload.costoPielesTotal,
      observacion: payload.observacion,
    );

    if (!mounted) {
      return;
    }

    _showActionResult(result);
  }

  Future<void> _openEditDialog(LotesState state, LoteRecord lote) async {
    _talker.ui('Se abrio el dialogo para editar el lote ${lote.id}.');
    final payload = await showDialog<LoteUpsertFormData>(
      context: context,
      builder: (_) => LoteUpsertDialog(
        title: 'Editar lote',
        submitLabel: 'Guardar cambios',
        isSubmitting: state.isSubmittingAction,
        clienteOptions: state.clienteOptions,
        tipoPielOptions: state.tipoPielOptions,
        initialLote: lote,
      ),
    );

    if (payload == null || !mounted) {
      _talker.ui(
        'Se cerro la edicion del lote ${lote.id} sin confirmar.',
        logLevel: LogLevel.debug,
      );
      return;
    }
    _talker.ui(
      'Se confirmo la edicion del lote ${lote.id} para clienteId=${payload.clienteId}, tipoPielId=${payload.tipoPielId}.',
    );

    final result = await context.read<LotesCubit>().updateSelectedLote(
      clienteId: payload.clienteId,
      tipoPielId: payload.tipoPielId,
      fechaIngreso: payload.fechaIngreso,
      cantidadPielesInicial: payload.cantidadPielesInicial,
      clienteTraeLote: payload.clienteTraeLote,
      costoPielesTotal: payload.costoPielesTotal,
      observacion: payload.observacion,
    );

    if (!mounted) {
      return;
    }

    _showActionResult(result);
  }

  void _showActionResult(LotesActionResult result) {
    _talker.ui(
      result.success
          ? 'Accion en lotes completada correctamente.'
          : 'La accion en lotes fallo: ${result.message}',
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
      title: 'Lotes de producción',
      currentPath: '/produccion/lotes',
      breadcrumbs: const ['Inicio', 'Producción', 'Lotes'],
      userName: session.nombreCompleto,
      roleName: session.rolNombre,
      accessibleRoutes: AppAccessRoutes.forPermissions(permissionCodes),
      onSignOut: isSigningOut
          ? () {}
          : () => context.read<AuthCubit>().signOut(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1480),
                child: BlocBuilder<LotesCubit, LotesState>(
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

                    final listPanel = _LotesListPanel(
                      state: state,
                      onRetry: () => context.read<LotesCubit>().initialize(),
                      onSelectLote: (loteId) {
                        _talker.ui(
                          'Se selecciono el lote $loteId desde el listado.',
                          logLevel: LogLevel.debug,
                        );
                        context.read<LotesCubit>().selectLote(loteId);
                      },
                    );

                    final detailPanel = _LoteDetailPanel(
                      state: state,
                      onRetry: () => context.read<LotesCubit>().retryDetail(),
                      onEdit: state.selectedLote == null
                          ? null
                          : () => _openEditDialog(state, state.selectedLote!),
                    );

                    final headerAndFilters = <Widget>[
                      Text(
                        'Controla el ingreso de pieles, su disponibilidad y trazabilidad antes de iniciar una orden.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Gap(AppSpacing.lg),
                      _LotesFiltersCard(
                        searchController: _searchController,
                        state: state,
                        onSearchChanged: _searchAsYouType,
                        onCreate: () => _openCreateDialog(state),
                      ),
                      const Gap(AppSpacing.lg),
                    ];

                    if (compactHeight) {
                      if (isWide) {
                        return SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...headerAndFilters,
                              SizedBox(
                                height: 640,
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
                            SizedBox(height: 600, child: detailPanel),
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
}

class _LotesFiltersCard extends StatelessWidget {
  const _LotesFiltersCard({
    required this.searchController,
    required this.state,
    required this.onSearchChanged,
    required this.onCreate,
  });

  final TextEditingController searchController;
  final LotesState state;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: const InputDecoration(
                hintText: 'Buscar por codigo, cliente, piel, estado o fecha...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          const Gap(AppSpacing.md),
          AppButton.secondary(
            label: 'Nuevo lote',
            icon: Icons.inventory_2_outlined,
            isLoading: state.isSubmittingAction,
            onPressed: onCreate,
          ),
        ],
      ),
    );
  }
}

class _LotesListPanel extends StatelessWidget {
  const _LotesListPanel({
    required this.state,
    required this.onRetry,
    required this.onSelectLote,
  });

  final LotesState state;
  final VoidCallback onRetry;
  final ValueChanged<int> onSelectLote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Listado de lotes', style: theme.textTheme.titleLarge),
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
              LotesStatus.loading => const Center(
                child: CircularProgressIndicator(),
              ),
              LotesStatus.error => _CenteredMessage(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppMessageCard.error(
                      title: 'No pudimos cargar los lotes',
                      message:
                          state.errorMessage ??
                          'Intenta nuevamente para consultar la disponibilidad operativa.',
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
              LotesStatus.success =>
                state.items.isEmpty
                    ? const _CenteredMessage(
                        child: AppMessageCard.info(
                          title: 'Sin resultados',
                          message:
                              'No encontramos lotes con los filtros actuales.',
                        ),
                      )
                    : ListView.separated(
                        itemCount: state.items.length,
                        separatorBuilder: (_, _) => const Gap(AppSpacing.md),
                        itemBuilder: (context, index) {
                          final item = state.items[index];
                          return _LoteListTileCard(
                            item: item,
                            isSelected: item.id == state.selectedLoteId,
                            onTap: () => onSelectLote(item.id),
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

class _LoteDetailPanel extends StatelessWidget {
  const _LoteDetailPanel({
    required this.state,
    required this.onRetry,
    required this.onEdit,
  });

  final LotesState state;
  final VoidCallback onRetry;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lote = state.selectedLote;

    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

                if (lote == null) {
                  return const _CenteredMessage(
                    child: AppMessageCard.info(
                      title: 'Selecciona un lote',
                      message:
                          'Escoge un registro del listado para revisar su disponibilidad.',
                    ),
                  );
                }

                final inicial = lote.cantidadPielesInicial;
                final utilizada = lote.cantidadPielesUtilizada;
                final progreso = inicial <= 0
                    ? 0.0
                    : (utilizada / inicial).clamp(0.0, 1.0).toDouble();

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: AppSpacing.sm,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      lote.codigo,
                                      style: theme.textTheme.titleLarge,
                                    ),
                                    _StatusBadge(
                                      label: lote.estado,
                                      background:
                                          theme.colorScheme.primaryContainer,
                                      foreground:
                                          theme.colorScheme.onPrimaryContainer,
                                    ),
                                  ],
                                ),
                                const Gap(AppSpacing.xs),
                                Text(
                                  lote.clienteRazonSocial,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AppButton.secondary(
                            label: 'Editar',
                            icon: Icons.edit_outlined,
                            isLoading: state.isSubmittingAction,
                            onPressed: onEdit,
                          ),
                        ],
                      ),
                      const Gap(AppSpacing.lg),
                      const Divider(),
                      const Gap(AppSpacing.md),
                      Text('Identidad', style: theme.textTheme.titleSmall),
                      const Gap(AppSpacing.md),
                      _DetailRow(label: 'ID', value: '${lote.id}'),
                      _DetailRow(
                        label: 'Tipo de piel',
                        value:
                            '${lote.tipoPielNombre} - ${lote.tipoPielCodigo}',
                      ),
                      _DetailRow(
                        label: 'Fecha de ingreso',
                        value: _formatDate(lote.fechaIngreso),
                      ),
                      _DetailRow(
                        label: 'Costo de pieles',
                        value: 'S/ ${_formatDecimal(lote.costoPielesTotal)}',
                      ),
                      const Gap(AppSpacing.md),
                      const Divider(),
                      const Gap(AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Disponibilidad',
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                          Text(
                            '${_formatDecimal(utilizada)} de ${_formatDecimal(inicial)} utilizadas',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const Gap(AppSpacing.sm),
                      LinearProgressIndicator(value: progreso, minHeight: 5),
                      const Gap(AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: _LoteMetric(
                              label: 'Inicial',
                              value: _formatDecimal(inicial),
                            ),
                          ),
                          const Gap(AppSpacing.md),
                          Expanded(
                            child: _LoteMetric(
                              label: 'Disponible',
                              value: _formatDecimal(
                                lote.cantidadPielesDisponible,
                              ),
                            ),
                          ),
                          const Gap(AppSpacing.md),
                          Expanded(
                            child: _LoteMetric(
                              label: 'Lados',
                              value: _formatDecimal(
                                lote.cantidadLadosCalculada,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if ((lote.observacion ?? '').trim().isNotEmpty) ...[
                        const Gap(AppSpacing.lg),
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
                                lote.observacion!,
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
    );
  }
}

class _LoteListTileCard extends StatelessWidget {
  const _LoteListTileCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final LoteRecord item;
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
                  _MiniPill(
                    label: item.estado,
                    background: theme.colorScheme.primaryContainer,
                    foreground: theme.colorScheme.onPrimaryContainer,
                  ),
                ],
              ),
              const Gap(AppSpacing.sm),
              Text(
                item.clienteRazonSocial,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const Gap(AppSpacing.md),
              Text(
                '${item.tipoPielNombre} · Disponible ${_formatDecimal(item.cantidadPielesDisponible)}',
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _LoteMetric extends StatelessWidget {
  const _LoteMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(AppSpacing.xs),
          Text(value, style: theme.textTheme.titleLarge),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
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
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: foreground),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({
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

String _formatDecimal(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }

  return value.toStringAsFixed(2);
}

String _formatDate(DateTime value) {
  return DateFormat('dd/MM/yyyy').format(value.toLocal());
}
