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
  final _estadoController = TextEditingController();
  final Talker _talker = getIt<Talker>();

  @override
  void initState() {
    super.initState();
    _talker.ui('Se abrio la pantalla de lotes.');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _estadoController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    FocusScope.of(context).unfocus();
    _talker.ui(
      'Se aplicaron filtros en lotes con texto=${_describeSearchTerm(_searchController.text)} y estado=${_describeState(_estadoController.text)}.',
    );
    context.read<LotesCubit>().load(
      searchTerm: _searchController.text.trim(),
      estado: _estadoController.text.trim().isEmpty
          ? null
          : _estadoController.text.trim(),
    );
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

  String _describeSearchTerm(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return 'vacio';
    }

    return '${normalized.length} caracteres';
  }

  String _describeState(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return 'vacio';
    }

    return normalized;
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
            padding: const EdgeInsets.all(AppSpacing.xl),
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

                    if (_estadoController.text != (state.estadoFilter ?? '')) {
                      _estadoController.value = TextEditingValue(
                        text: state.estadoFilter ?? '',
                        selection: TextSelection.collapsed(
                          offset: (state.estadoFilter ?? '').length,
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
                      const Gap(AppSpacing.xl),
                      _LotesFiltersCard(
                        searchController: _searchController,
                        estadoController: _estadoController,
                        state: state,
                        onApply: _applyFilters,
                        onCreate: () => _openCreateDialog(state),
                        onClienteChanged: (value) {
                          _talker.ui(
                            'Se cambio el filtro de cliente en lotes a ${value ?? 'todos'}.',
                            logLevel: LogLevel.debug,
                          );
                          context.read<LotesCubit>().load(
                            clienteId: value,
                            resetCliente: value == null,
                          );
                        },
                        onTipoPielChanged: (value) {
                          _talker.ui(
                            'Se cambio el filtro de tipo de piel en lotes a ${value ?? 'todos'}.',
                            logLevel: LogLevel.debug,
                          );
                          context.read<LotesCubit>().load(
                            tipoPielId: value,
                            resetTipoPiel: value == null,
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
    required this.estadoController,
    required this.state,
    required this.onApply,
    required this.onCreate,
    required this.onClienteChanged,
    required this.onTipoPielChanged,
  });

  final TextEditingController searchController;
  final TextEditingController estadoController;
  final LotesState state;
  final VoidCallback onApply;
  final VoidCallback onCreate;
  final ValueChanged<int?> onClienteChanged;
  final ValueChanged<int?> onTipoPielChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Busqueda operativa', style: theme.textTheme.titleLarge),
          const Gap(AppSpacing.sm),
          Text(
            'Filtra por codigo, cliente, tipo de piel o estado para revisar rapido la disponibilidad del lote antes de crear ordenes.',
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
                  controller: searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => onApply(),
                  decoration: const InputDecoration(
                    labelText: 'Buscar lote',
                    hintText: 'Ej. LT-0001 o cliente',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
              SizedBox(
                width: 320,
                child: DropdownButtonFormField<int?>(
                  initialValue: state.selectedClienteId,
                  decoration: const InputDecoration(labelText: 'Cliente'),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Todos los clientes'),
                    ),
                    ...state.clienteOptions.map(
                      (option) => DropdownMenuItem<int?>(
                        value: option.id,
                        child: Text(option.label),
                      ),
                    ),
                  ],
                  onChanged: onClienteChanged,
                ),
              ),
              SizedBox(
                width: 320,
                child: DropdownButtonFormField<int?>(
                  initialValue: state.selectedTipoPielId,
                  decoration: const InputDecoration(labelText: 'Tipo de piel'),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Todos los tipos'),
                    ),
                    ...state.tipoPielOptions.map(
                      (option) => DropdownMenuItem<int?>(
                        value: option.id,
                        child: Text(option.label),
                      ),
                    ),
                  ],
                  onChanged: onTipoPielChanged,
                ),
              ),
              SizedBox(
                width: 220,
                child: TextField(
                  controller: estadoController,
                  onSubmitted: (_) => onApply(),
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                    hintText: 'Ej. DISPONIBLE',
                  ),
                ),
              ),
            ],
          ),
          const Gap(AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              AppButton.primary(
                label: 'Aplicar filtros',
                icon: Icons.search_rounded,
                isLoading: state.status == LotesStatus.loading,
                onPressed: onApply,
                expand: false,
              ),
              AppButton.secondary(
                label: 'Nuevo lote',
                icon: Icons.inventory_2_outlined,
                isLoading: state.isSubmittingAction,
                onPressed: onCreate,
              ),
            ],
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
      padding: EdgeInsets.zero,
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
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Detalle del lote', style: theme.textTheme.titleLarge),
          const Gap(AppSpacing.xs),
          Text(
            'Aqui revisas identidad del lote, piel disponible, tipo de piel y trazabilidad para ordenes de produccion.',
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

                final disponibilidad = state.disponibilidad;

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
                            lote.codigo,
                            style: theme.textTheme.headlineSmall,
                          ),
                          _StatusBadge(
                            label: lote.estado,
                            background: theme.colorScheme.primaryContainer,
                            foreground: theme.colorScheme.onPrimaryContainer,
                          ),
                          if (lote.clienteTraeLote)
                            _StatusBadge(
                              label: 'Lote del cliente',
                              background: theme.colorScheme.tertiaryContainer,
                              foreground: theme.colorScheme.onTertiaryContainer,
                            ),
                        ],
                      ),
                      const Gap(AppSpacing.xs),
                      Text(
                        lote.clienteRazonSocial,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const Gap(AppSpacing.lg),
                      AppButton.secondary(
                        label: 'Editar lote',
                        icon: Icons.edit_outlined,
                        isLoading: state.isSubmittingAction,
                        onPressed: onEdit,
                      ),
                      const Gap(AppSpacing.xl),
                      Wrap(
                        spacing: AppSpacing.lg,
                        runSpacing: AppSpacing.lg,
                        children: [
                          _DetailCard(
                            title: 'Identidad',
                            lines: [
                              'ID: ${lote.id}',
                              'Cliente: ${lote.clienteRazonSocial}',
                              'Tipo de piel: ${lote.tipoPielNombre}',
                              'Codigo tipo: ${lote.tipoPielCodigo}',
                            ],
                          ),
                          _DetailCard(
                            title: 'Cantidad y disponibilidad',
                            lines: [
                              'Inicial: ${_formatDecimal(lote.cantidadPielesInicial)}',
                              'Utilizada: ${_formatDecimal(lote.cantidadPielesUtilizada)}',
                              'Disponible: ${_formatDecimal(lote.cantidadPielesDisponible)}',
                              'Lados calculados: ${_formatDecimal(lote.cantidadLadosCalculada)}',
                            ],
                          ),
                          _DetailCard(
                            title: 'Ingreso y costo',
                            lines: [
                              'Fecha ingreso: ${_formatDate(lote.fechaIngreso)}',
                              'Costo pieles: ${_formatDecimal(lote.costoPielesTotal)}',
                              'Creado: ${_formatDateTime(lote.creadoEn)}',
                              'Usuario creador: ${lote.creadoPorUsuarioId?.toString() ?? 'Sin dato'}',
                            ],
                          ),
                        ],
                      ),
                      const Gap(AppSpacing.xl),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.xl),
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
                              'Disponibilidad actual',
                              style: theme.textTheme.titleMedium,
                            ),
                            const Gap(AppSpacing.md),
                            if (disponibilidad == null)
                              Text(
                                'Sin disponibilidad cargada.',
                                style: theme.textTheme.bodyMedium,
                              )
                            else
                              Wrap(
                                spacing: AppSpacing.lg,
                                runSpacing: AppSpacing.lg,
                                children: [
                                  _AvailabilityMetric(
                                    label: 'Inicial',
                                    value: _formatDecimal(
                                      disponibilidad.cantidadPielesInicial,
                                    ),
                                  ),
                                  _AvailabilityMetric(
                                    label: 'Utilizada',
                                    value: _formatDecimal(
                                      disponibilidad.cantidadPielesUtilizada,
                                    ),
                                  ),
                                  _AvailabilityMetric(
                                    label: 'Disponible',
                                    value: _formatDecimal(
                                      disponibilidad.cantidadPielesDisponible,
                                    ),
                                  ),
                                  _AvailabilityMetric(
                                    label: 'Lados',
                                    value: _formatDecimal(
                                      disponibilidad.cantidadLadosCalculada,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      if ((lote.observacion ?? '').trim().isNotEmpty) ...[
                        const Gap(AppSpacing.xl),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.xl),
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

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 280,
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

class _AvailabilityMetric extends StatelessWidget {
  const _AvailabilityMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 160,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelLarge),
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

String _formatDateTime(DateTime value) {
  return DateFormat('dd/MM/yyyy hh:mm a').format(value.toLocal());
}
