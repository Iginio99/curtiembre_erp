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

// ============================================================
// PÁGINA PRINCIPAL
// ============================================================

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

  // ==========================================================
  // BÚSQUEDA AUTOMÁTICA
  // ==========================================================

  void _searchAsYouType(String value) {
    _searchDebounce?.cancel();

    setState(() {});

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

  // ==========================================================
  // CREAR LOTE
  // ==========================================================

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
        'Se cerro el dialogo sin confirmar.',
        logLevel: LogLevel.debug,
      );
      return;
    }

    _talker.ui(
      'Se confirmo la creacion de lote '
      'para clienteId=${payload.clienteId}, '
      'tipoPielId=${payload.tipoPielId}.',
    );

    final result = await context.read<LotesCubit>().createLote(
      clienteId: payload.clienteId,
      tipoPielId: payload.tipoPielId,
      fechaIngreso: payload.fechaIngreso,
      cantidadPielesInicial: payload.cantidadPielesInicial,
      clienteTraeLote: payload.clienteTraeLote,
      costoUnitarioPiel: payload.costoUnitarioPiel,
      observacion: payload.observacion,
    );

    if (!mounted) return;

    _showActionResult(result);
  }

  // ==========================================================
  // EDITAR LOTE
  // ==========================================================

  Future<void> _openEditDialog(LotesState state, LoteRecord lote) async {
    _talker.ui(
      'Se abrio el dialogo para editar '
      'el lote ${lote.id}.',
    );

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
        'Se cerro la edicion sin confirmar.',
        logLevel: LogLevel.debug,
      );
      return;
    }

    _talker.ui('Se confirmo la edicion del lote ${lote.id}.');

    final result = await context.read<LotesCubit>().updateSelectedLote(
      clienteId: payload.clienteId,
      tipoPielId: payload.tipoPielId,
      fechaIngreso: payload.fechaIngreso,
      cantidadPielesInicial: payload.cantidadPielesInicial,
      clienteTraeLote: payload.clienteTraeLote,
      costoUnitarioPiel: payload.costoUnitarioPiel,
      observacion: payload.observacion,
    );

    if (!mounted) return;

    _showActionResult(result);
  }

  // ==========================================================
  // NOTIFICACIONES
  // ==========================================================

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

  // ==========================================================
  // BUILD
  // ==========================================================

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
          final isWide = constraints.maxWidth >= 1040;
          final compactHeight = constraints.maxHeight < 860;

          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1480),

                child: BlocBuilder<LotesCubit, LotesState>(
                  builder: (context, state) {
                    // Sincronizar la búsqueda sin interrumpir
                    // al usuario mientras escribe.

                    if (!_searchController.selection.isValid &&
                        _searchController.text != state.searchTerm) {
                      _searchController.value = TextEditingValue(
                        text: state.searchTerm,
                        selection: TextSelection.collapsed(
                          offset: state.searchTerm.length,
                        ),
                      );
                    }

                    // LISTADO

                    final listPanel = _LotesListPanel(
                      state: state,
                      onRetry: () => context.read<LotesCubit>().initialize(),
                      onSelectLote: (loteId) {
                        _talker.ui(
                          'Se selecciono el lote $loteId.',
                          logLevel: LogLevel.debug,
                        );

                        context.read<LotesCubit>().selectLote(loteId);
                      },
                    );

                    // DETALLE

                    final detailPanel = _LoteDetailPanel(
                      state: state,
                      onRetry: () => context.read<LotesCubit>().retryDetail(),
                      onEdit: state.selectedLote == null
                          ? null
                          : () => _openEditDialog(state, state.selectedLote!),
                    );

                    // BUSCADOR COMPACTO

                    final filters = _LotesFiltersCard(
                      searchController: _searchController,
                      state: state,
                      onSearchChanged: _searchAsYouType,
                      onCreate: () => _openCreateDialog(state),
                    );

                    // PANTALLAS DE ALTURA REDUCIDA

                    if (compactHeight) {
                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            filters,

                            const Gap(AppSpacing.md),

                            if (isWide)
                              SizedBox(
                                height: 640,
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(flex: 9, child: listPanel),

                                    const Gap(AppSpacing.md),

                                    Expanded(flex: 8, child: detailPanel),
                                  ],
                                ),
                              )
                            else ...[
                              SizedBox(height: 520, child: listPanel),

                              const Gap(AppSpacing.md),

                              SizedBox(height: 600, child: detailPanel),
                            ],
                          ],
                        ),
                      );
                    }

                    // PANTALLA NORMAL

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        filters,

                        const Gap(AppSpacing.md),

                        Expanded(
                          child: isWide
                              ? Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(flex: 9, child: listPanel),

                                    const Gap(AppSpacing.md),

                                    Expanded(flex: 8, child: detailPanel),
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

// ============================================================
// FILTROS Y BOTÓN NUEVO LOTE
// ============================================================

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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final search = TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Buscar por código, cliente o tipo de piel...',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Limpiar búsqueda',
                    onPressed: () {
                      searchController.clear();
                      onSearchChanged('');
                    },
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
            filled: true,
            fillColor: colors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.outlineVariant),
            ),
          ),
        );

        final createButton = FilledButton.icon(
          onPressed: state.isSubmittingAction ? null : onCreate,
          icon: state.isSubmittingAction
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add_rounded, size: 20),
          label: const Text('Nuevo lote'),
          style: FilledButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 17),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        if (constraints.maxWidth < 600) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [search, const Gap(AppSpacing.sm), createButton],
          );
        }

        return Row(
          children: [
            Expanded(child: search),

            const Gap(AppSpacing.md),

            createButton,
          ],
        );
      },
    );
  }
}

// ============================================================
// LISTADO DE LOTES
// ============================================================

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
      padding: EdgeInsets.zero,

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CABECERA COMPACTA
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
            ),

            child: Text(
              'Lotes (${state.items.length})',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          Divider(height: 1, color: theme.colorScheme.outlineVariant),

          // CONTENIDO
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
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: state.items.length,
                        separatorBuilder: (_, _) => const Gap(AppSpacing.sm),
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

// ============================================================
// TARJETA DEL LOTE
// ============================================================

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
                ? colors.primary.withValues(alpha: 0.12)
                : colors.surfaceContainerLowest,

            borderRadius: BorderRadius.circular(12),

            border: Border.all(
              color: isSelected ? colors.primary : colors.outlineVariant,
              width: isSelected ? 1.3 : 1,
            ),
          ),

          child: Row(
            children: [
              // ÍCONO
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,

                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),

                child: Icon(
                  Icons.layers_rounded,
                  size: 23,
                  color: colors.primary,
                ),
              ),

              const Gap(AppSpacing.md),

              // DATOS
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
                          item.codigo,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        _StatusBadge(
                          label: item.estado,
                          background: colors.primaryContainer,
                          foreground: colors.onPrimaryContainer,
                        ),
                      ],
                    ),

                    const Gap(4),

                    Text(
                      item.clienteRazonSocial,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const Gap(4),

                    Text(
                      '${item.tipoPielNombre} · '
                      '${_formatDecimal(item.cantidadPielesDisponible)} disponibles',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const Gap(AppSpacing.sm),

              // FLECHA
              Icon(
                Icons.chevron_right_rounded,
                size: 21,
                color: isSelected ? colors.primary : colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// PANEL DERECHO: DETALLE DEL LOTE
// ============================================================

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
    final colors = theme.colorScheme;
    final lote = state.selectedLote;

    return AppSurfaceCard(
      padding: EdgeInsets.zero,

      child: Builder(
        builder: (context) {
          // CARGANDO

          if (state.isDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // ERROR

          if (state.detailErrorMessage != null) {
            return _CenteredMessage(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppMessageCard.error(
                    title: 'No pudimos cargar el detalle',
                    message: state.detailErrorMessage!,
                  ),

                  const Gap(AppSpacing.md),

                  AppButton.secondary(
                    label: 'Reintentar detalle',
                    icon: Icons.refresh_rounded,
                    onPressed: onRetry,
                  ),
                ],
              ),
            );
          }

          // SIN SELECCIÓN

          if (lote == null) {
            return const _CenteredMessage(
              child: AppMessageCard.info(
                title: 'Selecciona un lote',
                message: 'Escoge un lote para revisar su disponibilidad.',
              ),
            );
          }

          final inicial = lote.cantidadPielesInicial;

          final utilizada = lote.cantidadPielesUtilizada;

          final disponible = lote.cantidadPielesDisponible;

          final lados = lote.cantidadLadosCalculada;

          final progreso = inicial <= 0
              ? 0.0
              : (utilizada / inicial).clamp(0.0, 1.0).toDouble();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // =================================================
                // CABECERA DEL DETALLE
                // =================================================
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,

                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10),
                      ),

                      child: Icon(
                        Icons.layers_rounded,
                        color: colors.primary,
                        size: 23,
                      ),
                    ),

                    const Gap(AppSpacing.md),

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
                                lote.codigo,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),

                              _StatusBadge(
                                label: lote.estado,
                                background: colors.primaryContainer,
                                foreground: colors.onPrimaryContainer,
                              ),
                            ],
                          ),

                          const Gap(4),

                          Text(
                            lote.clienteRazonSocial,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Gap(AppSpacing.sm),

                    OutlinedButton.icon(
                      onPressed: state.isSubmittingAction ? null : onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 17),
                      label: const Text('Editar'),
                    ),
                  ],
                ),

                const Gap(AppSpacing.lg),

                Divider(height: 1, color: colors.outlineVariant),

                const Gap(AppSpacing.md),

                // =================================================
                // IDENTIDAD
                // =================================================
                _SectionTitle(
                  title: 'Identidad',
                  icon: Icons.description_outlined,
                ),

                const Gap(AppSpacing.md),

                _DetailRow(label: 'ID', value: '${lote.id}'),

                _DetailRow(
                  label: 'Tipo de piel',
                  value:
                      '${lote.tipoPielNombre} - '
                      '${lote.tipoPielCodigo}',
                ),

                _DetailRow(
                  label: 'Fecha de ingreso',
                  value: _formatDate(lote.fechaIngreso),
                ),

                _DetailRow(
                  label: 'Costo unitario por piel',
                  value: _formatMoney(lote.costoUnitarioPiel),
                ),

                _DetailRow(
                  label: 'Costo total de pieles',
                  value: _formatMoney(lote.costoPielesTotal),
                ),

                const Gap(AppSpacing.md),

                Divider(height: 1, color: colors.outlineVariant),

                const Gap(AppSpacing.md),

                // =================================================
                // DISPONIBILIDAD
                // =================================================
                Row(
                  children: [
                    Expanded(
                      child: _SectionTitle(
                        title: 'Disponibilidad',
                        icon: Icons.inventory_2_outlined,
                      ),
                    ),

                    Text(
                      '${_formatDecimal(utilizada)} '
                      'de ${_formatDecimal(inicial)} utilizadas',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),

                const Gap(AppSpacing.md),

                ClipRRect(
                  borderRadius: BorderRadius.circular(4),

                  child: LinearProgressIndicator(
                    value: progreso,
                    minHeight: 5,
                    backgroundColor: colors.surfaceContainerHighest,
                    color: colors.primary,
                  ),
                ),

                const Gap(AppSpacing.md),

                // TRES MÉTRICAS
                Row(
                  children: [
                    Expanded(
                      child: _LoteMetric(
                        label: 'Inicial',
                        value: _formatDecimal(inicial),
                        icon: Icons.layers_outlined,
                        accent: colors.onSurfaceVariant,
                      ),
                    ),

                    const Gap(AppSpacing.sm),

                    Expanded(
                      child: _LoteMetric(
                        label: 'Disponible',
                        value: _formatDecimal(disponible),
                        icon: Icons.inventory_2_outlined,
                        accent: const Color(0xFF3FAE76),
                      ),
                    ),

                    const Gap(AppSpacing.sm),

                    Expanded(
                      child: _LoteMetric(
                        label: 'Lados',
                        value: _formatDecimal(lados),
                        icon: Icons.view_in_ar_outlined,
                        accent: const Color(0xFF699CE0),
                      ),
                    ),
                  ],
                ),

                // =================================================
                // OBSERVACIÓN
                // =================================================
                if ((lote.observacion ?? '').trim().isNotEmpty) ...[
                  const Gap(AppSpacing.lg),

                  Divider(height: 1, color: colors.outlineVariant),

                  const Gap(AppSpacing.md),

                  _SectionTitle(
                    title: 'Observación',
                    icon: Icons.notes_rounded,
                  ),

                  const Gap(AppSpacing.sm),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),

                    decoration: BoxDecoration(
                      color: colors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.outlineVariant),
                    ),

                    child: Text(
                      lote.observacion!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// TÍTULO DE SECCIÓN
// ============================================================

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: colors.onSurfaceVariant),

        const Gap(AppSpacing.sm),

        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// FILA DEL DETALLE
// ============================================================

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),

          const Gap(AppSpacing.sm),

          Expanded(
            flex: 5,
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MÉTRICAS DE DISPONIBILIDAD
// ============================================================

class _LoteMetric extends StatelessWidget {
  const _LoteMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),

      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),

              Icon(icon, size: 17, color: accent),
            ],
          ),

          const Gap(AppSpacing.sm),

          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ESTADO DEL LOTE
// ============================================================

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),

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

// ============================================================
// MENSAJES CENTRADOS
// ============================================================

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

// ============================================================
// FORMATOS
// ============================================================

// Cantidades sin separador de miles.
// Ejemplo: 1000 y no 1.000.

String _formatDecimal(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }

  return value.toStringAsFixed(2);
}

// Dinero con formato financiero.
// Ejemplo: S/ 3,500.00

String _formatMoney(double value) {
  return NumberFormat.currency(
    locale: 'en_US',
    symbol: 'S/ ',
    decimalDigits: 2,
  ).format(value);
}

// Fecha de ingreso.

String _formatDate(DateTime value) {
  return DateFormat('dd/MM/yyyy').format(value.toLocal());
}
