
import 'dart:async';
import 'dart:math' as math;

import 'package:erp_curtiembre_fronted/core/di/service_locator.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_state.dart';
import 'package:erp_curtiembre_fronted/features/inventory/compras/domain/entities/orden_compra_detail.dart';
import 'package:erp_curtiembre_fronted/features/inventory/compras/domain/entities/orden_compra_record.dart';
import 'package:erp_curtiembre_fronted/features/inventory/compras/presentation/cubit/compras_cubit.dart';
import 'package:erp_curtiembre_fronted/features/inventory/compras/presentation/cubit/compras_state.dart';
import 'package:erp_curtiembre_fronted/features/inventory/compras/presentation/widgets/orden_compra_decision_dialog.dart';
import 'package:erp_curtiembre_fronted/features/inventory/compras/presentation/widgets/orden_compra_upsert_dialog.dart';
import 'package:erp_curtiembre_fronted/features/security/presentation/cubit/security_access_cubit.dart';
import 'package:erp_curtiembre_fronted/shared/navigation/app_access_routes.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/layout/app_shell.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:talker_flutter/talker_flutter.dart';

// ============================================================
// COLORES
// ============================================================

const _accent = Color(0xFFE8590C);
const _accentSoft = Color(0xFFFFE9DC);
const _green = Color(0xFF16834A);
const _red = Color(0xFFC74640);
const _brown = Color(0xFF51301F);

// ============================================================
// PAGINA DE COMPRAS
// ============================================================

class ComprasPage extends StatefulWidget {
  const ComprasPage({super.key});

  @override
  State<ComprasPage> createState() => _ComprasPageState();
}

class _ComprasPageState extends State<ComprasPage> {
  final _searchController = TextEditingController();
  final Talker _talker = getIt<Talker>();

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _talker.ui('Se abrio la pantalla de compras.');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ==========================================================
  // BUSQUEDA
  // ==========================================================

  void _searchAsYouType(String value) {
    _debounce?.cancel();

    _debounce = Timer(
      const Duration(milliseconds: 380),
      () {
        if (!mounted) return;

        final term = value.trim();
        final cubit = context.read<ComprasCubit>();

        if (term == cubit.state.searchTerm) return;

        cubit.load(searchTerm: term);
      },
    );
  }

  void _applySearch() {
    _debounce?.cancel();

    context.read<ComprasCubit>().load(
      searchTerm: _searchController.text.trim(),
    );
  }

  // ==========================================================
  // SELECCIONAR ORDEN
  // ==========================================================

  void _selectOrder(
    int orderId, {
    required bool openMobileDetail,
  }) {
    _talker.ui(
      'Se selecciono la compra $orderId.',
      logLevel: LogLevel.debug,
    );

    context.read<ComprasCubit>().selectOrder(orderId);

    if (!openMobileDetail) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BlocProvider.value(
        value: context.read<ComprasCubit>(),
        child: _MobileCompraDetailSheet(
          onApprove: _approveOrder,
          onReject: () => _openDecisionDialog(
            title: 'Rechazar orden',
            submitLabel: 'Rechazar',
            helperText:
                'Explica por qué esta orden no debe continuar.',
            action: (motivo) => context
                .read<ComprasCubit>()
                .rejectSelectedOrder(motivo),
          ),
          onCancel: () => _openDecisionDialog(
            title: 'Anular orden',
            submitLabel: 'Anular',
            helperText:
                'Registra el motivo de anulación para mantener la trazabilidad.',
            action: (motivo) => context
                .read<ComprasCubit>()
                .cancelSelectedOrder(motivo),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // CREAR COMPRA
  // ==========================================================

  Future<void> _openCreateDialog(ComprasState state) async {
    _talker.ui('Se abrio el formulario de nueva compra.');

    final payload =
        await showDialog<OrdenCompraUpsertFormData>(
      context: context,
      builder: (_) => OrdenCompraUpsertDialog(
        proveedores: state.proveedores,
        insumos: state.insumos,
        isSubmitting: state.isSubmittingAction,
      ),
    );

    if (payload == null || !mounted) return;

    final result =
        await context.read<ComprasCubit>().createOrder(
          proveedorId: payload.proveedorId,
          fechaEmision: payload.fechaEmision,
          observacion: payload.observacion,
          detalles: payload.detalles,
        );

    if (!mounted) return;
    _showActionResult(result);
  }

  // ==========================================================
  // APROBAR
  // ==========================================================

  Future<void> _approveOrder() async {
    if (context.read<ComprasCubit>().state.isSubmittingAction) {
      return;
    }

    final result =
        await context.read<ComprasCubit>().approveSelectedOrder();

    if (!mounted) return;
    _showActionResult(result);
  }

  // ==========================================================
  // RECHAZAR / ANULAR
  // ==========================================================

  Future<void> _openDecisionDialog({
    required String title,
    required String submitLabel,
    required String helperText,
    required Future<ComprasActionResult> Function(String motivo)
        action,
  }) async {
    final state = context.read<ComprasCubit>().state;

    if (state.isSubmittingAction) return;

    final payload =
        await showDialog<OrdenCompraDecisionDialogResult>(
      context: context,
      builder: (_) => OrdenCompraDecisionDialog(
        title: title,
        submitLabel: submitLabel,
        helperText: helperText,
        isSubmitting: state.isSubmittingAction,
      ),
    );

    if (payload == null || !mounted) return;

    final result = await action(payload.motivo);

    if (!mounted) return;
    _showActionResult(result);
  }

  void _showActionResult(ComprasActionResult result) {
    _talker.ui(
      result.success
          ? 'Accion de compras completada.'
          : 'Error en compras: ${result.message}',
      logLevel:
          result.success ? LogLevel.debug : LogLevel.error,
    );

    final messenger = ScaffoldMessenger.of(context);

    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        content: Text(result.message),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            result.success ? null : const Color(0xFF8A2F22),
      ),
    );
  }

  // ==========================================================
  // VISTA PRINCIPAL
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final session = context.select(
      (AuthCubit cubit) => cubit.state.session,
    );

    final isSigningOut = context.select(
      (AuthCubit cubit) =>
          cubit.state.status == AuthStatus.signingOut,
    );

    final permissionCodes = context.select(
      (SecurityAccessCubit cubit) =>
          cubit.state.snapshot?.userPermissionCodes.toSet() ??
          const <String>{},
    );

    if (session == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return AppShell(
      title: 'Compras',
      currentPath: '/inventario/compras',
      breadcrumbs: const [
        'Inicio',
        'Inventario',
        'Compras',
      ],
      userName: session.nombreCompleto,
      roleName: session.rolNombre,
      accessibleRoutes:
          AppAccessRoutes.forPermissions(permissionCodes),
      onSignOut: isSigningOut
          ? () {}
          : () => context.read<AuthCubit>().signOut(),
      child: BlocBuilder<ComprasCubit, ComprasState>(
        builder: (context, state) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 720;
              final isWide = constraints.maxWidth >= 1100;

              final listPanel = _ComprasListPanel(
                state: state,
                onRetry: () =>
                    context.read<ComprasCubit>().initialize(),
                onSelectOrder: (id) => _selectOrder(
                  id,
                  openMobileDetail: isMobile,
                ),
              );

              final detailPanel = _CompraDetailPanel(
                state: state,
                onRetry: () =>
                    context.read<ComprasCubit>().retryDetail(),
                onApprove: _approveOrder,
                onReject: () => _openDecisionDialog(
                  title: 'Rechazar orden',
                  submitLabel: 'Rechazar',
                  helperText:
                      'Explica por qué esta orden no debe continuar.',
                  action: (motivo) => context
                      .read<ComprasCubit>()
                      .rejectSelectedOrder(motivo),
                ),
                onCancel: () => _openDecisionDialog(
                  title: 'Anular orden',
                  submitLabel: 'Anular',
                  helperText:
                      'Registra el motivo de anulación para mantener la trazabilidad.',
                  action: (motivo) => context
                      .read<ComprasCubit>()
                      .cancelSelectedOrder(motivo),
                ),
              );

              return Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 12 : 16,
                  14,
                  isMobile ? 12 : 16,
                  16,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 1700,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [
                        _ComprasFiltersCard(
                          state: state,
                          controller: _searchController,
                          isCompact: isMobile,
                          onSearchChanged: _searchAsYouType,
                          onSearch: _applySearch,
                          onCreateOrder: () =>
                              _openCreateDialog(state),
                          onProveedorChanged: (value) =>
                              context
                                  .read<ComprasCubit>()
                                  .load(
                                    proveedorIdFilter: value,
                                  ),
                          onEstadoChanged: (value) =>
                              context
                                  .read<ComprasCubit>()
                                  .load(
                                    estadoFilter: value,
                                  ),
                        ),

                        const SizedBox(height: 14),

                        Expanded(
                          child: isWide
                              ? Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      flex: 9,
                                      child: listPanel,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      flex: 11,
                                      child: detailPanel,
                                    ),
                                  ],
                                )
                              : isMobile
                                  ? listPanel
                                  : SingleChildScrollView(
                                      child: Column(
                                        children: [
                                          SizedBox(
                                            height: 480,
                                            child: listPanel,
                                          ),
                                          const SizedBox(height: 14),
                                          SizedBox(
                                            height: 650,
                                            child: detailPanel,
                                          ),
                                        ],
                                      ),
                                    ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ============================================================
// FILTROS DE COMPRAS
// ============================================================

class _ComprasFiltersCard extends StatelessWidget {
  const _ComprasFiltersCard({
    required this.state,
    required this.controller,
    required this.isCompact,
    required this.onSearchChanged,
    required this.onSearch,
    required this.onCreateOrder,
    required this.onProveedorChanged,
    required this.onEstadoChanged,
  });

  final ComprasState state;
  final TextEditingController controller;
  final bool isCompact;

  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearch;
  final VoidCallback onCreateOrder;
  final ValueChanged<int?> onProveedorChanged;
  final ValueChanged<String?> onEstadoChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final search = TextField(
      controller: controller,
      onChanged: onSearchChanged,
      onSubmitted: (_) => onSearch(),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Buscar por código o proveedor...',
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 21,
        ),
        suffixIcon: state.status == ComprasStatus.loading
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              )
            : IconButton(
                tooltip: 'Buscar',
                onPressed: onSearch,
                icon: const Icon(
                  Icons.arrow_forward_rounded,
                ),
              ),
        filled: true,
        fillColor: colors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: colors.outlineVariant,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 15,
        ),
      ),
    );

    final proveedor = DropdownMenu<int>(
      key: ValueKey(
        'proveedor-${state.proveedorIdFilter}',
      ),
      width: 245,
      menuHeight: 310,
      enableFilter: true,
      enableSearch: true,
      requestFocusOnTap: true,
      initialSelection: state.proveedorIdFilter ?? -1,
      label: const Text('Proveedor'),
      dropdownMenuEntries: [
        const DropdownMenuEntry(
          value: -1,
          label: 'Todos',
        ),
        ...state.proveedores.map(
          (item) => DropdownMenuEntry(
            value: item.id,
            label: item.displayName,
          ),
        ),
      ],
      onSelected: (value) {
        if (value != null) {
          onProveedorChanged(value == -1 ? null : value);
        }
      },
    );

    const estados = <String, String>{
      '__ALL__': 'Todos',
      'PENDIENTE': 'Pendiente',
      'APROBADA': 'Aprobada',
      'PARCIALMENTE_RECIBIDA': 'Parcialmente recibida',
      'TOTALMENTE_RECIBIDA': 'Totalmente recibida',
      'RECHAZADA': 'Rechazada',
      'ANULADA': 'Anulada',
    };

    final estado = DropdownMenu<String>(
      key: ValueKey('estado-${state.estadoFilter}'),
      width: 215,
      menuHeight: 310,
      enableFilter: true,
      enableSearch: true,
      requestFocusOnTap: true,
      initialSelection: state.estadoFilter ?? '__ALL__',
      label: const Text('Estado'),
      dropdownMenuEntries: [
        for (final entry in estados.entries)
          DropdownMenuEntry(
            value: entry.key,
            label: entry.value,
          ),
      ],
      onSelected: (value) {
        if (value != null) {
          onEstadoChanged(
            value == '__ALL__' ? null : value,
          );
        }
      },
    );

    final action = FilledButton.icon(
      onPressed: state.isSubmittingAction
          ? null
          : onCreateOrder,
      style: FilledButton.styleFrom(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: 17,
          vertical: 17,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9),
        ),
      ),
      icon: const Icon(Icons.add_rounded, size: 19),
      label: const Text('Nueva compra'),
    );

    return _Panel(
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, box) {
          if (box.maxWidth >= 1130) {
            return Row(
              children: [
                Expanded(child: search),
                const SizedBox(width: 12),
                proveedor,
                const SizedBox(width: 10),
                estado,
                const SizedBox(width: 10),
                action,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              search,
              const SizedBox(height: 11),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment:
                    WrapCrossAlignment.center,
                children: [
                  proveedor,
                  estado,
                  action,
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================
// LISTADO DE ORDENES
// ============================================================

class _ComprasListPanel extends StatefulWidget {
  const _ComprasListPanel({
    required this.state,
    required this.onRetry,
    required this.onSelectOrder,
  });

  final ComprasState state;
  final VoidCallback onRetry;
  final ValueChanged<int> onSelectOrder;

  @override
  State<_ComprasListPanel> createState() =>
      _ComprasListPanelState();
}

class _ComprasListPanelState
    extends State<_ComprasListPanel> {
  bool _newestFirst = true;
  int _page = 0;
  int _pageSize = 10;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final orders = [...widget.state.items];

    // Orden local por ID del registro.
    orders.sort(
      (a, b) => _newestFirst
          ? b.id.compareTo(a.id)
          : a.id.compareTo(b.id),
    );

    final total = orders.length;

    final pageCount = math.max(
      1,
      (total / _pageSize).ceil(),
    );

    final currentPage =
        _page.clamp(0, pageCount - 1).toInt();

    final start = currentPage * _pageSize;
    final end = math.min(start + _pageSize, total);

    final visible = orders.sublist(start, end);

    return _Panel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 13,
            ),
            child: Row(
              children: [
                const _SectionIcon(
                  Icons.shopping_cart_outlined,
                ),
                const SizedBox(width: 9),
                const Expanded(
                  child: Text(
                    'Órdenes de compra',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _SmallCount('$total'),
                const SizedBox(width: 8),
                PopupMenuButton<bool>(
                  tooltip: 'Ordenar compras',
                  initialValue: _newestFirst,
                  onSelected: (value) {
                    setState(() {
                      _newestFirst = value;
                      _page = 0;
                    });
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: true,
                      child: Text('Más recientes'),
                    ),
                    PopupMenuItem(
                      value: false,
                      child: Text('Más antiguas'),
                    ),
                  ],
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.sort_rounded,
                        size: 17,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _newestFirst
                            ? 'Recientes'
                            : 'Antiguas',
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: colors.outlineVariant,
          ),
          Expanded(
            child: switch (widget.state.status) {
              ComprasStatus.loading => const Center(
                  child: CircularProgressIndicator(),
                ),
              ComprasStatus.error => _EmptyView(
                  title: 'No pudimos cargar las compras',
                  description:
                      widget.state.errorMessage ??
                      'Intenta nuevamente.',
                  onRetry: widget.onRetry,
                ),
              ComprasStatus.success => total == 0
                  ? const _EmptyView(
                      title: 'Sin resultados',
                      description:
                          'No se encontraron órdenes con estos filtros.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: visible.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = visible[index];

                        return _CompraTile(
                          item: item,
                          selected: item.id ==
                              widget.state.selectedOrderId,
                          onTap: () =>
                              widget.onSelectOrder(item.id),
                        );
                      },
                    ),
            },
          ),
          Divider(
            height: 1,
            color: colors.outlineVariant,
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Mostrar',
                      style: TextStyle(fontSize: 11),
                    ),
                    const SizedBox(width: 5),
                    DropdownButton<int>(
                      value: _pageSize,
                      isDense: true,
                      underline: const SizedBox.shrink(),
                      items: const [5, 10, 20, 50]
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text('$value'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _pageSize = value;
                          _page = 0;
                        });
                      },
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'por página',
                      style: TextStyle(fontSize: 11),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      total == 0
                          ? '0 resultados'
                          : '${start + 1}–$end de $total',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Anterior',
                      visualDensity: VisualDensity.compact,
                      onPressed: currentPage == 0
                          ? null
                          : () => setState(
                                () => _page = currentPage - 1,
                              ),
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                      ),
                    ),
                    _PageNumber('${currentPage + 1}'),
                    IconButton(
                      tooltip: 'Siguiente',
                      visualDensity: VisualDensity.compact,
                      onPressed: currentPage + 1 >= pageCount
                          ? null
                          : () => setState(
                                () => _page = currentPage + 1,
                              ),
                      icon: const Icon(
                        Icons.chevron_right_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TARJETA DE UNA COMPRA
// ============================================================

class _CompraTile extends StatelessWidget {
  const _CompraTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final OrdenCompraRecord item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: selected
                ? _accent.withValues(alpha: 0.11)
                : colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? _accent
                  : colors.outlineVariant,
              width: selected ? 1.3 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionIcon(
                Icons.description_outlined,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 9,
                      runSpacing: 7,
                      crossAxisAlignment:
                          WrapCrossAlignment.center,
                      children: [
                        Text(
                          item.codigo,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        _OrderStatus(item.estado),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.proveedorRazonSocial,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _accent,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 14,
                      runSpacing: 6,
                      children: [
                        _InlineValue(
                          icon: Icons.inventory_2_outlined,
                          value: 'Ítems: ${item.totalItems}',
                        ),
                        _InlineValue(
                          icon: Icons.input_rounded,
                          value:
                              'Solicitado: ${_quantity(item.cantidadTotalSolicitada)}',
                        ),
                        _InlineValue(
                          icon: Icons.check_circle_outline_rounded,
                          value:
                              'Recibido: ${_quantity(item.cantidadTotalRecibida)}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Text(
                      'Monto estimado: ${_money(item.montoTotalEstimado)}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// PANEL DE DETALLE
// ============================================================

class _CompraDetailPanel extends StatefulWidget {
  const _CompraDetailPanel({
    required this.state,
    required this.onRetry,
    required this.onApprove,
    required this.onReject,
    required this.onCancel,
  });

  final ComprasState state;
  final VoidCallback onRetry;

  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onCancel;

  @override
  State<_CompraDetailPanel> createState() =>
      _CompraDetailPanelState();
}

class _CompraDetailPanelState
    extends State<_CompraDetailPanel> {
  int _itemsPage = 0;
  static const int _itemsPerPage = 5;

  @override
  void didUpdateWidget(covariant _CompraDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.state.selectedOrder?.id !=
        widget.state.selectedOrder?.id) {
      _itemsPage = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final detail = widget.state.selectedOrder;

    return _Panel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            child: const Text(
              'Detalle de la compra',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Divider(
            height: 1,
            color: colors.outlineVariant,
          ),
          Expanded(
            child: widget.state.isDetailLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : widget.state.detailErrorMessage != null
                    ? _EmptyView(
                        title: 'No pudimos cargar el detalle',
                        description:
                            widget.state.detailErrorMessage!,
                        onRetry: widget.onRetry,
                      )
                    : detail == null
                        ? const _EmptyView(
                            title: 'Selecciona una compra',
                            description:
                                'Escoge una orden de la izquierda para consultar sus insumos.',
                          )
                        : _buildDetail(context, detail),
          ),
        ],
      ),
    );
  }

  Widget _buildDetail(
    BuildContext context,
    OrdenCompraDetail detail,
  ) {
    final colors = Theme.of(context).colorScheme;

    final lines = detail.detalles;

    // Los importes permanecen separados de las cantidades.
    final requested = lines.fold<double>(
      0,
      (sum, item) => sum + item.cantidadSolicitada,
    );

    final received = lines.fold<double>(
      0,
      (sum, item) => sum + item.cantidadRecibida,
    );

    final estimated = lines.fold<double>(
      0,
      (sum, item) => sum + item.montoEstimado,
    );

    final totalPages = math.max(
      1,
      (lines.length / _itemsPerPage).ceil(),
    );

    final currentPage =
        _itemsPage.clamp(0, totalPages - 1).toInt();

    final start = currentPage * _itemsPerPage;

    final visible = lines
        .skip(start)
        .take(_itemsPerPage)
        .toList(growable: false);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ==========================================
          // IDENTIDAD DE LA COMPRA
          // ==========================================

          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const _SectionIcon(
                Icons.description_outlined,
              ),
              Text(
                detail.codigo,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              _OrderStatus(detail.estado),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            detail.proveedorRazonSocial,
            style: const TextStyle(
              color: _accent,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 12),

          _DataBox(
            icon: Icons.calendar_month_outlined,
            label: 'Fecha de emisión',
            value: DateFormat('dd/MM/yyyy')
                .format(detail.fechaEmision.toLocal()),
          ),

          const SizedBox(height: 13),

          // ==========================================
          // BOTONES REALES DEL FLUJO
          // ==========================================

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DecisionButton(
                label: 'Aprobar',
                icon: Icons.check_circle_outline_rounded,
                color: _green,
                onPressed: !widget.state.isSubmittingAction &&
                        detail.canApprove
                    ? widget.onApprove
                    : null,
              ),
              _DecisionButton(
                label: 'Rechazar',
                icon: Icons.cancel_outlined,
                color: _red,
                onPressed: !widget.state.isSubmittingAction &&
                        detail.canReject
                    ? widget.onReject
                    : null,
              ),
              _DecisionButton(
                label: 'Anular',
                icon: Icons.block_outlined,
                color: colors.onSurface,
                onPressed: !widget.state.isSubmittingAction &&
                        detail.canCancel
                    ? widget.onCancel
                    : null,
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ==========================================
          // METRICAS
          // ==========================================

          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 460;

              final metricCards = [
                _MetricCard(
                  icon: Icons.inventory_2_outlined,
                  label: 'Total de ítems',
                  value: '${lines.length}',
                ),
                _MetricCard(
                  icon: Icons.input_rounded,
                  label: 'Cant. solicitada',
                  value: _quantity(requested),
                ),
                _MetricCard(
                  icon: Icons.task_alt_rounded,
                  label: 'Cant. recibida',
                  value: _quantity(received),
                ),
                _MetricCard(
                  icon: Icons.payments_outlined,
                  label: 'Monto estimado',
                  value: _money(estimated),
                  highlight: true,
                ),
              ];

              if (narrow) {
                return Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  children: [
                    for (final metric in metricCards)
                      SizedBox(
                        width: constraints.maxWidth / 2 - 5,
                        child: metric,
                      ),
                  ],
                );
              }

              return Row(
                children: [
                  for (var i = 0; i < metricCards.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(child: metricCards[i]),
                  ],
                ],
              );
            },
          ),

          if ((detail.observacion ?? '').trim().isNotEmpty ||
              (detail.motivo ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            _Panel(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((detail.observacion ?? '')
                      .trim()
                      .isNotEmpty) ...[
                    const Text(
                      'Observación',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(detail.observacion!),
                  ],
                  if ((detail.motivo ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Motivo',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(detail.motivo!),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // ==========================================
          // TABLA DE INSUMOS
          // ==========================================

          Row(
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                color: _accent,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Insumos',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 9),
              _SmallCount('${lines.length} ítems'),
            ],
          ),

          const SizedBox(height: 10),

          _Panel(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: math.max(
                      700,
                      MediaQuery.sizeOf(context).width * 0.37,
                    ),
                    child: Column(
                      children: [
                        _buildTableHeader(context),

                        for (final item in visible)
                          _buildTableRow(context, item),
                      ],
                    ),
                  ),
                ),

                Divider(
                  height: 1,
                  color: colors.outlineVariant,
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          lines.isEmpty
                              ? 'Sin ítems'
                              : 'Mostrando ${start + 1}–${math.min(start + _itemsPerPage, lines.length)} de ${lines.length}',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Anterior',
                        onPressed: currentPage == 0
                            ? null
                            : () => setState(
                                  () => _itemsPage =
                                      currentPage - 1,
                                ),
                        icon: const Icon(
                          Icons.chevron_left_rounded,
                          size: 19,
                        ),
                      ),
                      _PageNumber('${currentPage + 1}'),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Siguiente',
                        onPressed: currentPage + 1 >= totalPages
                            ? null
                            : () => setState(
                                  () => _itemsPage =
                                      currentPage + 1,
                                ),
                        icon: const Icon(
                          Icons.chevron_right_rounded,
                          size: 19,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _columnFlex = [95, 150, 85, 85, 85, 80, 100];

  Widget _buildTableHeader(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    const headers = [
      'Código',
      'Nombre del insumo',
      'Solicitado',
      'Recibido',
      'Pendiente',
      'Unitario',
      'Total',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 12,
      ),
      color: colors.surfaceContainerHigh,
      child: Row(
        children: [
          for (int i = 0; i < headers.length; i++)
            Expanded(
              flex: _columnFlex[i],
              child: Text(
                headers[i],
                maxLines: 2,
                style: TextStyle(
                  fontSize: 10.5,
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTableRow(
    BuildContext context,
    OrdenCompraDetalleLine item,
  ) {
    final colors = Theme.of(context).colorScheme;

    final values = [
      item.insumoCodigo,
      item.insumoNombre,
      _quantity(item.cantidadSolicitada),
      _quantity(item.cantidadRecibida),
      _quantity(item.saldoPendiente),
      item.costoUnitarioEstimado == null
          ? 'Sin costo'
          : _money(item.costoUnitarioEstimado!),
      _money(item.montoEstimado),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colors.outlineVariant.withValues(alpha: 0.65),
          ),
        ),
      ),
      child: Row(
        children: [
          for (int i = 0; i < values.length; i++)
            Expanded(
              flex: _columnFlex[i],
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Tooltip(
                  message: values[i],
                  child: Text(
                    values[i],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.7,
                      fontWeight: i == 0 || i == 6
                          ? FontWeight.w800
                          : FontWeight.w500,
                      color: i == 6
                          ? _accent
                          : colors.onSurface,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// DETALLE MOVIL
// ============================================================

class _MobileCompraDetailSheet extends StatelessWidget {
  const _MobileCompraDetailSheet({
    required this.onApprove,
    required this.onReject,
    required this.onCancel,
  });

  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return FractionallySizedBox(
      heightFactor: 0.90,
      child: Material(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            children: [
              Container(
                height: 4,
                width: 42,
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Detalle de la compra',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () =>
                        Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: BlocBuilder<ComprasCubit, ComprasState>(
                  builder: (context, state) {
                    return _CompraDetailPanel(
                      state: state,
                      onRetry: () => context
                          .read<ComprasCubit>()
                          .retryDetail(),
                      onApprove:
                          state.selectedOrder?.canApprove == true
                              ? onApprove
                              : null,
                      onReject:
                          state.selectedOrder?.canReject == true
                              ? onReject
                              : null,
                      onCancel:
                          state.selectedOrder?.canCancel == true
                              ? onCancel
                              : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// COMPONENTES VISUALES
// ============================================================

class _Panel extends StatelessWidget {
  const _Panel({
    required this.child,
    required this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      clipBehavior: Clip.antiAlias,
      padding: padding,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: child,
    );
  }
}

class _SectionIcon extends StatelessWidget {
  const _SectionIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _accentSoft,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(
        icon,
        size: 20,
        color: _accent,
      ),
    );
  }
}

class _InlineValue extends StatelessWidget {
  const _InlineValue({
    required this.icon,
    required this.value,
  });

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final muted =
        Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: muted),
        const SizedBox(width: 5),
        Text(
          value,
          style: TextStyle(
            fontSize: 10.8,
            color: muted,
          ),
        ),
      ],
    );
  }
}

class _OrderStatus extends StatelessWidget {
  const _OrderStatus(this.status);

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, background, foreground) = switch (status) {
      'PENDIENTE' => (
          'Pendiente',
          const Color(0xFFF9E8BF),
          const Color(0xFF7A5512),
        ),
      'APROBADA' => (
          'Aprobada',
          const Color(0xFFE2F6E8),
          const Color(0xFF20633A),
        ),
      'PARCIALMENTE_RECIBIDA' => (
          'Parcialmente recibida',
          const Color(0xFFE8F2FF),
          const Color(0xFF0F4C81),
        ),
      'TOTALMENTE_RECIBIDA' => (
          'Totalmente recibida',
          const Color(0xFFDFF4F7),
          const Color(0xFF0E5C69),
        ),
      'RECHAZADA' => (
          'Rechazada',
          const Color(0xFFF7E0DF),
          const Color(0xFF8A2F22),
        ),
      'ANULADA' => (
          'Anulada',
          const Color(0xFFE7E2E0),
          const Color(0xFF5D5552),
        ),
      _ => (
          status,
          Theme.of(context).colorScheme.surfaceContainerHighest,
          Theme.of(context).colorScheme.onSurface,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 10.4,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SmallCount extends StatelessWidget {
  const _SmallCount(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PageNumber extends StatelessWidget {
  const _PageNumber(this.number);

  final String number;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 29,
      height: 29,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _accent,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        number,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DataBox extends StatelessWidget {
  const _DataBox({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return _Panel(
      padding: const EdgeInsets.all(11),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 17,
            color: _accent,
          ),
          const SizedBox(width: 9),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              color: colors.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: colors.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: highlight ? _accent : _brown,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: highlight ? _accent : colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _DecisionButton extends StatelessWidget {
  const _DecisionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(
          color: color.withValues(alpha: 0.55),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 11,
        ),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({
    required this.title,
    required this.description,
    this.onRetry,
  });

  final String title;
  final String description;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final muted =
        Theme.of(context).colorScheme.onSurfaceVariant;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 36,
              color: muted,
            ),
            const SizedBox(height: 11),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                color: muted,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 13),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// FORMATEADORES
// ============================================================

String _quantity(num value) {
  return value.toStringAsFixed(2);
}

String _money(num value) {
  return 'S/ ${value.toStringAsFixed(2)}';
}
