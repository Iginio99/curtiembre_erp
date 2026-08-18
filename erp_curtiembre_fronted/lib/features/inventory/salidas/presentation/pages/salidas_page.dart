import 'package:erp_curtiembre_fronted/core/di/service_locator.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_breakpoints.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_state.dart';
import 'package:erp_curtiembre_fronted/features/inventory/salidas/domain/entities/salida_detail.dart';
import 'package:erp_curtiembre_fronted/features/inventory/salidas/domain/entities/salida_record.dart';
import 'package:erp_curtiembre_fronted/features/inventory/salidas/presentation/cubit/salidas_cubit.dart';
import 'package:erp_curtiembre_fronted/features/inventory/salidas/presentation/cubit/salidas_state.dart';
import 'package:erp_curtiembre_fronted/features/inventory/salidas/presentation/widgets/salida_upsert_dialog.dart';
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

class SalidasPage extends StatefulWidget {
  const SalidasPage({super.key});

  @override
  State<SalidasPage> createState() => _SalidasPageState();
}

class _SalidasPageState extends State<SalidasPage> {
  final _searchController = TextEditingController();
  final Talker _talker = getIt<Talker>();

  @override
  void initState() {
    super.initState();
    _talker.ui('Se abrio la pantalla de salidas.');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applySearch() {
    FocusScope.of(context).unfocus();
    _talker.ui(
      'Se aplico la busqueda de salidas con texto=${_describeText(_searchController.text)}.',
    );
    context.read<SalidasCubit>().load(
      searchTerm: _searchController.text.trim(),
    );
  }

  void _selectSalida(int id, {required bool openMobileDetail}) {
    _talker.ui(
      'Se selecciono la salida $id desde el listado.',
      logLevel: LogLevel.debug,
    );
    context.read<SalidasCubit>().selectSalida(id);
    if (!openMobileDetail) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BlocProvider.value(
        value: context.read<SalidasCubit>(),
        child: const _MobileSalidaDetailSheet(),
      ),
    );
  }

  Future<void> _openDialog(SalidaDraftType type, SalidasState state) async {
    final (title, helperText) = switch (type) {
      SalidaDraftType.general => (
        'Registrar salida general',
        'Usa este flujo para consumos internos que no dependen de una orden de produccion.',
      ),
      SalidaDraftType.devolucionProveedor => (
        'Registrar devolucion a proveedor',
        'Documenta el retorno de material y deja trazabilidad por insumo.',
      ),
      SalidaDraftType.ajusteNegativo => (
        'Registrar ajuste negativo como salida',
        'Este flujo sigue disponible para regularizaciones operativas directas.',
      ),
    };
    _talker.ui(
      'Se abrio el dialogo para ${_describeDraftType(type)}.',
      logLevel: LogLevel.warning,
    );

    final payload = await showDialog<SalidaUpsertFormData>(
      context: context,
      builder: (_) => SalidaUpsertDialog(
        title: title,
        helperText: helperText,
        insumos: state.insumos,
        isSubmitting: state.isSubmittingAction,
      ),
    );

    if (payload == null || !mounted) {
      _talker.ui(
        'Se cerro el dialogo de ${_describeDraftType(type)} sin confirmar.',
        logLevel: LogLevel.debug,
      );
      return;
    }
    _talker.ui(
      'Se confirmo ${_describeDraftType(type)} con motivo=${_describeText(payload.motivo)} y ${payload.detalles.length} detalles.',
      logLevel: LogLevel.warning,
    );

    final cubit = context.read<SalidasCubit>();
    final result = switch (type) {
      SalidaDraftType.general => await cubit.registerGeneral(
        motivo: payload.motivo,
        observacion: payload.observacion,
        detalles: payload.detalles,
      ),
      SalidaDraftType.devolucionProveedor => await cubit.registerSupplierReturn(
        motivo: payload.motivo,
        observacion: payload.observacion,
        detalles: payload.detalles,
      ),
      SalidaDraftType.ajusteNegativo => await cubit.registerNegativeAdjustment(
        motivo: payload.motivo,
        observacion: payload.observacion,
        detalles: payload.detalles,
      ),
    };

    if (!mounted) return;
    _showActionResult(result);
  }

  void _showActionResult(SalidasActionResult result) {
    _talker.ui(
      result.success
          ? 'Accion en salidas completada correctamente.'
          : 'La accion en salidas fallo: ${result.message}',
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
      title: 'Salidas',
      currentPath: '/inventario/salidas',
      breadcrumbs: const ['Inicio', 'Inventario', 'Salidas'],
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
                child: BlocBuilder<SalidasCubit, SalidasState>(
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

                    final listPanel = _SalidasListPanel(
                      state: state,
                      onRetry: () {
                        _talker.ui(
                          'Se solicito reintentar la carga del listado de salidas.',
                        );
                        context.read<SalidasCubit>().initialize();
                      },
                      onSelectSalida: (id) =>
                          _selectSalida(id, openMobileDetail: isMobile),
                    );

                    final detailPanel = _SalidaDetailPanel(
                      state: state,
                      onRetry: () {
                        _talker.ui(
                          'Se solicito reintentar el detalle de la salida seleccionada.',
                        );
                        context.read<SalidasCubit>().retryDetail();
                      },
                    );

                    final headerAndFilters = <Widget>[
                      Text(
                        'Registra y consulta consumos, devoluciones y ajustes negativos con trazabilidad por insumo.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Gap(AppSpacing.xl),
                      _SalidasFiltersCard(
                        state: state,
                        controller: _searchController,
                        onSearch: _applySearch,
                        onTipoSalidaChanged: (value) {
                          _talker.ui(
                            'Se cambio el filtro de tipo de salida a ${_describeType(value)}.',
                            logLevel: LogLevel.debug,
                          );
                          context.read<SalidasCubit>().load(
                            tipoSalidaFilter: value,
                          );
                        },
                        onCreateGeneral: () =>
                            _openDialog(SalidaDraftType.general, state),
                        onCreateSupplierReturn: () => _openDialog(
                          SalidaDraftType.devolucionProveedor,
                          state,
                        ),
                        onCreateNegativeAdjustment: () =>
                            _openDialog(SalidaDraftType.ajusteNegativo, state),
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
                            SizedBox(height: 560, child: listPanel),
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

  String _describeDraftType(SalidaDraftType value) {
    return switch (value) {
      SalidaDraftType.general => 'registrar salida general',
      SalidaDraftType.devolucionProveedor => 'registrar devolucion a proveedor',
      SalidaDraftType.ajusteNegativo => 'registrar ajuste negativo',
    };
  }
}

class _SalidasFiltersCard extends StatelessWidget {
  const _SalidasFiltersCard({
    required this.state,
    required this.controller,
    required this.onSearch,
    required this.onTipoSalidaChanged,
    required this.onCreateGeneral,
    required this.onCreateSupplierReturn,
    required this.onCreateNegativeAdjustment,
  });

  final SalidasState state;
  final TextEditingController controller;
  final VoidCallback onSearch;
  final ValueChanged<String?> onTipoSalidaChanged;
  final VoidCallback onCreateGeneral;
  final VoidCallback onCreateSupplierReturn;
  final VoidCallback onCreateNegativeAdjustment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Operaciones disponibles', style: theme.textTheme.titleLarge),
          const Gap(AppSpacing.sm),
          Text(
            'Filtra por codigo o tipo de salida y registra nuevos movimientos desde el mismo panel.',
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
                    labelText: 'Buscar salida',
                    hintText: 'Ej. SI-000001',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
              SizedBox(
                width: 260,
                child: DropdownButtonFormField<String?>(
                  initialValue: state.tipoSalidaFilter,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de salida',
                  ),
                  items: const [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Todas'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'GENERAL',
                      child: Text('General'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'DEVOLUCION_PROVEEDOR',
                      child: Text('Devolucion proveedor'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'AJUSTE_NEGATIVO',
                      child: Text('Ajuste negativo'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'PROCESO',
                      child: Text('Proceso'),
                    ),
                  ],
                  onChanged: onTipoSalidaChanged,
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
                label: 'Salida general',
                icon: Icons.outbox_outlined,
                expand: false,
                onPressed: state.isSubmittingAction ? null : onCreateGeneral,
              ),
              AppButton.secondary(
                label: 'Devolucion a proveedor',
                icon: Icons.assignment_return_outlined,
                onPressed: state.isSubmittingAction
                    ? null
                    : onCreateSupplierReturn,
              ),
              AppButton.secondary(
                label: 'Ajuste negativo',
                icon: Icons.remove_circle_outline,
                onPressed: state.isSubmittingAction
                    ? null
                    : onCreateNegativeAdjustment,
              ),
              Tooltip(
                message: 'Pendiente de integracion real con Produccion.',
                child: AppButton.secondary(
                  label: 'Salida por proceso',
                  icon: Icons.settings_input_component_outlined,
                  onPressed: null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SalidasListPanel extends StatelessWidget {
  const _SalidasListPanel({
    required this.state,
    required this.onRetry,
    required this.onSelectSalida,
  });

  final SalidasState state;
  final VoidCallback onRetry;
  final ValueChanged<int> onSelectSalida;

  @override
  Widget build(BuildContext context) {
    if (state.status == SalidasStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == SalidasStatus.error) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppMessageCard.error(
            title: 'No pudimos cargar las salidas',
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
        title: 'Sin salidas registradas',
        message:
            'Todavia no hay movimientos que coincidan con los filtros actuales.',
      );
    }

    return AppSurfaceCard(
      padding: EdgeInsets.zero,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: state.items.length,
        separatorBuilder: (_, index) => const Gap(AppSpacing.md),
        itemBuilder: (context, index) {
          final item = state.items[index];
          final selected = state.selectedSalidaId == item.id;
          return _SalidaListTile(
            item: item,
            selected: selected,
            onTap: () => onSelectSalida(item.id),
          );
        },
      ),
    );
  }
}

class _SalidaListTile extends StatelessWidget {
  const _SalidaListTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final SalidaRecord item;
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
                _StatusPill(label: item.tipoSalida),
              ],
            ),
            const Gap(AppSpacing.sm),
            Text(
              item.motivo ?? 'Sin motivo registrado',
              style: theme.textTheme.bodyLarge,
            ),
            const Gap(AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              children: [
                _InfoChip(
                  label: DateFormat('dd/MM/yyyy').format(item.fechaSalida),
                ),
                _InfoChip(label: '${item.totalItems} items'),
                _InfoChip(
                  label: 'Cant. ${item.cantidadTotal.toStringAsFixed(2)}',
                ),
                _InfoChip(label: 'Monto ${item.montoTotal.toStringAsFixed(2)}'),
                _InfoChip(label: item.estado),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileSalidaDetailSheet extends StatelessWidget {
  const _MobileSalidaDetailSheet();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return FractionallySizedBox(
      heightFactor: 0.88,
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
                const Gap(AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Detalle de la salida',
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
                const Gap(AppSpacing.sm),
                Expanded(
                  child: BlocBuilder<SalidasCubit, SalidasState>(
                    builder: (context, state) => _SalidaDetailPanel(
                      state: state,
                      onRetry: () => context.read<SalidasCubit>().retryDetail(),
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

class _SalidaDetailPanel extends StatelessWidget {
  const _SalidaDetailPanel({required this.state, required this.onRetry});

  final SalidasState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detail = state.selectedSalida;

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
        title: 'Selecciona una salida',
        message:
            'Elige un movimiento para revisar su detalle y las lineas afectadas.',
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
              _StatusPill(label: detail.estado),
            ],
          ),
          const Gap(AppSpacing.sm),
          Text(
            detail.motivo ?? 'Sin motivo',
            style: theme.textTheme.titleMedium,
          ),
          const Gap(AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              _InfoChip(label: detail.tipoSalida),
              _InfoChip(
                label: DateFormat(
                  'dd/MM/yyyy HH:mm',
                ).format(detail.fechaSalida),
              ),
              if (detail.ordenProduccionId != null)
                _InfoChip(label: 'OP ${detail.ordenProduccionId}'),
              if (detail.ordenProcesoId != null)
                _InfoChip(label: 'Proceso ${detail.ordenProcesoId}'),
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
          Text('Lineas afectadas', style: theme.textTheme.titleLarge),
          const Gap(AppSpacing.md),
          Expanded(
            child: ListView.separated(
              itemCount: detail.detalles.length,
              separatorBuilder: (_, index) => const Gap(AppSpacing.md),
              itemBuilder: (context, index) =>
                  _SalidaDetailLineTile(line: detail.detalles[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SalidaDetailLineTile extends StatelessWidget {
  const _SalidaDetailLineTile({required this.line});

  final SalidaDetalleLine line;

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
              _InfoChip(
                label: 'Costo ${line.costoUnitario.toStringAsFixed(2)}',
              ),
              _InfoChip(label: 'Total ${line.costoTotal.toStringAsFixed(2)}'),
              _InfoChip(label: 'Stock ${line.stockActual.toStringAsFixed(2)}'),
            ],
          ),
          if (line.observacion != null &&
              line.observacion!.trim().isNotEmpty) ...[
            const Gap(AppSpacing.sm),
            Text(
              line.observacion!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
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
