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

    if (!openMobileDetail) {
      return;
    }

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
      'Se confirmo ${_describeDraftType(type)} '
      'con motivo=${_describeText(payload.motivo)} '
      'y ${payload.detalles.length} detalles.',
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

    if (!mounted) {
      return;
    }

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
            /*
            Más compacto que xl.
            */
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1440),
                child: BlocBuilder<SalidasCubit, SalidasState>(
                  builder: (context, state) {
                    final isWide = constraints.maxWidth >= 1040;

                    final isMobile =
                        constraints.maxWidth < AppBreakpoints.mobileLarge;

                    final compactHeight = constraints.maxHeight < 820;

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

                    /*
                    ═══════════════════════════════
                    FILTROS SUPERIORES
                    ═══════════════════════════════

                    Quitamos el texto explicativo
                    largo que ocupaba espacio.
                    */

                    final filters = _SalidasFiltersCard(
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
                    );

                    /*
                    ═══════════════════════════════
                    PANTALLA BAJA
                    ═══════════════════════════════
                    */

                    if (compactHeight) {
                      if (isWide) {
                        return SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              filters,

                              const Gap(AppSpacing.md),

                              SizedBox(
                                height: 610,
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(flex: 9, child: listPanel),

                                    const Gap(AppSpacing.md),

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
                            filters,

                            const Gap(AppSpacing.md),

                            SizedBox(height: 560, child: listPanel),

                            if (!isMobile) ...[
                              const Gap(AppSpacing.md),

                              SizedBox(height: 560, child: detailPanel),
                            ],
                          ],
                        ),
                      );
                    }

                    /*
                    ═══════════════════════════════
                    PANTALLA NORMAL
                    ═══════════════════════════════
                    */

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
                              : isMobile
                              ? listPanel
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

/*
══════════════════════════════════════════════════════════════
FILTROS + ACCIONES
══════════════════════════════════════════════════════════════
*/

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
      /*
      Antes AppSpacing.lg.
      */
      padding: const EdgeInsets.all(AppSpacing.md),

      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /*
          ═══════════════════════════════
          FILA FILTROS
          ═══════════════════════════════
          */
          LayoutBuilder(
            builder: (context, constraints) {
              final search = TextField(
                controller: controller,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => onSearch(),
                decoration: const InputDecoration(
                  hintText: 'Buscar salida',
                  prefixIcon: Icon(Icons.search_rounded, size: 18),
                ),
              );

              final type = DropdownButtonFormField<String?>(
                isExpanded: true,
                initialValue: state.tipoSalidaFilter,
                decoration: const InputDecoration(labelText: 'Tipo de salida'),
                items: const [
                  DropdownMenuItem<String?>(value: null, child: Text('Todas')),
                  DropdownMenuItem<String?>(
                    value: 'GENERAL',
                    child: Text('General'),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'DEVOLUCION_PROVEEDOR',
                    child: Text('Devolución proveedor'),
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
              );

              final button = FilledButton.icon(
                onPressed: onSearch,
                icon: const Icon(Icons.search_rounded, size: 17),
                label: const Text('Buscar'),
              );

              /*
              Desktop
              */

              if (constraints.maxWidth >= 760) {
                return Row(
                  children: [
                    Expanded(flex: 5, child: search),

                    const Gap(AppSpacing.md),

                    Expanded(flex: 4, child: type),

                    const Gap(AppSpacing.md),

                    SizedBox(width: 130, child: button),
                  ],
                );
              }

              /*
              Tablet/móvil
              */

              return Column(
                children: [
                  search,

                  const Gap(AppSpacing.sm),

                  type,

                  const Gap(AppSpacing.sm),

                  Align(alignment: Alignment.centerRight, child: button),
                ],
              );
            },
          ),

          const Gap(AppSpacing.sm),

          Divider(height: 1, color: theme.colorScheme.outlineVariant),

          const Gap(AppSpacing.sm),

          /*
          ═══════════════════════════════
          ACCIONES
          ═══════════════════════════════
          */
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                FilledButton(
                  onPressed: state.isSubmittingAction ? null : onCreateGeneral,
                  child: const Text('Salida general'),
                ),

                OutlinedButton(
                  onPressed: state.isSubmittingAction
                      ? null
                      : onCreateSupplierReturn,
                  child: const Text('Devolución a proveedor'),
                ),

                OutlinedButton(
                  onPressed: state.isSubmittingAction
                      ? null
                      : onCreateNegativeAdjustment,
                  child: const Text('Ajuste negativo'),
                ),

                Tooltip(
                  message: 'Pendiente de integración con Producción.',
                  child: OutlinedButton(
                    onPressed: null,
                    child: const Text('Salida por proceso'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/*
══════════════════════════════════════════════════════════════
LISTADO
══════════════════════════════════════════════════════════════
*/

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
    final theme = Theme.of(context);

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

          const Gap(AppSpacing.md),

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
        message: 'No hay movimientos que coincidan con los filtros actuales.',
      );
    }

    return AppSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          /*
          CABECERA LISTA
          */
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Listado de salidas',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                Text(
                  '${state.items.length} salidas',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: theme.colorScheme.outlineVariant),

          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: state.items.length,
              separatorBuilder: (_, _) => const Gap(AppSpacing.sm),
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
          ),
        ],
      ),
    );
  }
}

/*
══════════════════════════════════════════════════════════════
ITEM DEL LISTADO
══════════════════════════════════════════════════════════════
*/

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
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),

        padding: const EdgeInsets.all(AppSpacing.md),

        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer.withValues(alpha: .30)
              : theme.colorScheme.surfaceContainerLowest,

          borderRadius: BorderRadius.circular(12),

          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: selected ? 1.25 : 1,
          ),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /*
            CÓDIGO + TIPO + FLECHA
            */
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.codigo,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                _StatusPill(label: item.tipoSalida, highlighted: selected),

                const Gap(AppSpacing.xs),

                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),

            const Gap(AppSpacing.xs),

            /*
            MOTIVO
            */
            Text(
              item.motivo ?? 'Sin motivo registrado',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const Gap(AppSpacing.sm),

            /*
            METADATOS EN LÍNEA
            */
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: AppSpacing.xs,
              children: [
                _InlineInfo(
                  value: DateFormat('dd/MM/yyyy').format(item.fechaSalida),
                ),

                const _MetaDivider(),

                _InlineInfo(
                  value:
                      '${item.totalItems} '
                      '${item.totalItems == 1 ? 'ítem' : 'ítems'}',
                ),

                const _MetaDivider(),

                _InlineInfo(
                  value: 'Cant. ${item.cantidadTotal.toStringAsFixed(2)}',
                ),

                const _MetaDivider(),

                _InlineInfo(
                  value: 'Monto ${item.montoTotal.toStringAsFixed(2)}',
                ),

                const _MetaDivider(),

                _InlineInfo(value: item.estado, strong: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/*
══════════════════════════════════════════════════════════════
DETALLE MÓVIL
══════════════════════════════════════════════════════════════
*/

class _MobileSalidaDetailSheet extends StatelessWidget {
  const _MobileSalidaDetailSheet();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return FractionallySizedBox(
      heightFactor: .88,
      child: Material(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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

/*
══════════════════════════════════════════════════════════════
PANEL DETALLE
══════════════════════════════════════════════════════════════
*/

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

          const Gap(AppSpacing.md),

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
        message: 'Elige un movimiento para revisar su detalle.',
      );
    }

    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.lg),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /*
          HEADER
          */
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.codigo,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const Gap(AppSpacing.xs),

                    Text(
                      detail.motivo ?? 'Sin motivo',
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),

              _StatusPill(label: detail.estado, highlighted: true),
            ],
          ),

          const Gap(AppSpacing.lg),

          /*
          RESUMEN HORIZONTAL
          */
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,

              borderRadius: BorderRadius.circular(10),

              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),

            child: LayoutBuilder(
              builder: (context, constraints) {
                final items = <Widget>[
                  _DetailInfo(label: 'Tipo', value: detail.tipoSalida),

                  _DetailInfo(
                    label: 'Fecha',
                    value: DateFormat(
                      'dd/MM/yyyy HH:mm',
                    ).format(detail.fechaSalida),
                  ),

                  if (detail.ordenProduccionId != null)
                    _DetailInfo(
                      label: 'OP',
                      value: 'OP ${detail.ordenProduccionId}',
                    ),

                  if (detail.ordenProcesoId != null)
                    _DetailInfo(
                      label: 'Proceso',
                      value: '${detail.ordenProcesoId}',
                    ),
                ];

                if (constraints.maxWidth < 560) {
                  return Wrap(
                    spacing: AppSpacing.lg,
                    runSpacing: AppSpacing.md,
                    children: items
                        .map((item) => SizedBox(width: 145, child: item))
                        .toList(),
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int index = 0; index < items.length; index++) ...[
                      Expanded(child: items[index]),

                      if (index < items.length - 1)
                        Container(
                          width: 1,
                          height: 38,
                          margin: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          color: theme.colorScheme.outlineVariant,
                        ),
                    ],
                  ],
                );
              },
            ),
          ),

          /*
          OBSERVACIÓN
          */
          if (detail.observacion != null &&
              detail.observacion!.trim().isNotEmpty) ...[
            const Gap(AppSpacing.md),

            Text(
              detail.observacion!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],

          const Gap(AppSpacing.lg),

          /*
          LÍNEAS AFECTADAS
          */
          Row(
            children: [
              Expanded(
                child: Text(
                  'Líneas afectadas',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              Text(
                '${detail.detalles.length} '
                '${detail.detalles.length == 1 ? 'ítem' : 'ítems'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),

          const Gap(AppSpacing.md),

          Expanded(
            child: ListView.separated(
              itemCount: detail.detalles.length,

              separatorBuilder: (_, _) => const Gap(AppSpacing.sm),

              itemBuilder: (context, index) =>
                  _SalidaDetailLineTile(line: detail.detalles[index]),
            ),
          ),
        ],
      ),
    );
  }
}

/*
══════════════════════════════════════════════════════════════
LÍNEA AFECTADA
══════════════════════════════════════════════════════════════
*/

class _SalidaDetailLineTile extends StatelessWidget {
  const _SalidaDetailLineTile({required this.line});

  final SalidaDetalleLine line;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,

        borderRadius: BorderRadius.circular(12),

        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /*
          INSUMO
          */
          Text(
            '${line.insumoCodigo} - ${line.insumoNombre}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),

          const Gap(AppSpacing.md),

          /*
          DATOS
          */
          LayoutBuilder(
            builder: (context, constraints) {
              final values = <Widget>[
                _DetailInfo(
                  label: 'Cantidad',
                  value:
                      '${line.cantidad.toStringAsFixed(2)} ${line.unidadMedidaCodigo}',
                ),

                _DetailInfo(
                  label: 'Costo',
                  value: line.costoUnitario.toStringAsFixed(2),
                ),

                _DetailInfo(
                  label: 'Total',
                  value: line.costoTotal.toStringAsFixed(2),
                  strong: true,
                ),

                _DetailInfo(
                  label: 'Stock actual',
                  value: line.stockActual.toStringAsFixed(2),
                ),
              ];

              if (constraints.maxWidth < 500) {
                return Wrap(
                  spacing: AppSpacing.lg,
                  runSpacing: AppSpacing.md,
                  children: values
                      .map((item) => SizedBox(width: 120, child: item))
                      .toList(),
                );
              }

              return Row(
                children: [
                  for (int index = 0; index < values.length; index++) ...[
                    Expanded(child: values[index]),

                    if (index < values.length - 1)
                      Container(
                        width: 1,
                        height: 34,
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        color: theme.colorScheme.outlineVariant,
                      ),
                  ],
                ],
              );
            },
          ),

          if (line.observacion != null &&
              line.observacion!.trim().isNotEmpty) ...[
            const Gap(AppSpacing.sm),

            Text(
              line.observacion!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/*
══════════════════════════════════════════════════════════════
STATUS
══════════════════════════════════════════════════════════════
*/

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, this.highlighted = false});

  final String label;

  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: highlighted
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,

        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,

          color: highlighted
              ? theme.colorScheme.onPrimaryContainer
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/*
══════════════════════════════════════════════════════════════
INFO INLINE
══════════════════════════════════════════════════════════════
*/

class _InlineInfo extends StatelessWidget {
  const _InlineInfo({required this.value, this.strong = false});

  final String value;

  final bool strong;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      value,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,

        fontWeight: strong ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }
}

class _MetaDivider extends StatelessWidget {
  const _MetaDivider();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9),
      child: Container(
        width: 1,
        height: 14,
        color: theme.colorScheme.outlineVariant,
      ),
    );
  }
}

/*
══════════════════════════════════════════════════════════════
INFO DEL DETALLE
══════════════════════════════════════════════════════════════
*/

class _DetailInfo extends StatelessWidget {
  const _DetailInfo({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;

  final String value;

  final bool strong;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),

        const Gap(3),

        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: strong ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
