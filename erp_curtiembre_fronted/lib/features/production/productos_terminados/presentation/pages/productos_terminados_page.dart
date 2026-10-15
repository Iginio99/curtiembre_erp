import 'package:erp_curtiembre_fronted/core/di/service_locator.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_state.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/producto_terminado_record.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/entrega_producto_terminado_record.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/repositories/ordenes_produccion_repository.dart';
import 'package:erp_curtiembre_fronted/features/production/productos_terminados/presentation/cubit/productos_terminados_cubit.dart';
import 'package:erp_curtiembre_fronted/features/production/productos_terminados/presentation/cubit/productos_terminados_state.dart';
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

class ProductosTerminadosPage extends StatefulWidget {
  const ProductosTerminadosPage({super.key});

  @override
  State<ProductosTerminadosPage> createState() =>
      _ProductosTerminadosPageState();
}

class _ProductosTerminadosPageState extends State<ProductosTerminadosPage> {
  final _searchController = TextEditingController();
  final Talker _talker = getIt<Talker>();
  String _statusFilter = 'Todos';
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _talker.ui('Se abrio la pantalla de productos terminados.');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      title: 'Productos terminados',
      currentPath: '/produccion/productos-terminados',
      breadcrumbs: const ['Inicio', 'Producción', 'Productos terminados'],
      userName: session.nombreCompleto,
      roleName: session.rolNombre,
      accessibleRoutes: AppAccessRoutes.forPermissions(permissionCodes),
      onSignOut: isSigningOut
          ? () {}
          : () => context.read<AuthCubit>().signOut(),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1480),
            child: BlocBuilder<ProductosTerminadosCubit, ProductosTerminadosState>(
              builder: (context, state) {
                final isWide = MediaQuery.sizeOf(context).width >= 1240;
                if (_searchController.text != state.searchTerm) {
                  _searchController.value = TextEditingValue(
                    text: state.searchTerm,
                    selection: TextSelection.collapsed(
                      offset: state.searchTerm.length,
                    ),
                  );
                }

                final groupedItems = _groupByOrder(state.filteredItems);
                final visibleItems = groupedItems.values
                    .where((items) {
                      final delivered = items.fold<double>(0, (sum, item) => sum + item.cantidadLadosEntregados);
                      final pending = items.fold<double>(0, (sum, item) => sum + item.cantidadLadosPendientes);
                      final status = pending <= 0 ? 'Entregado' : delivered > 0 ? 'Entrega parcial' : 'Pendiente de entrega';
                      final matchesStatus = _statusFilter == 'Todos' || status == _statusFilter;
                      final date = items.map((item) => item.fechaTerminacionOrden ?? item.fechaIngreso).reduce((a, b) => a.isAfter(b) ? a : b).toLocal();
                      final day = DateTime(date.year, date.month, date.day);
                      final matchesFrom = _fromDate == null || !day.isBefore(DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day));
                      final matchesTo = _toDate == null || !day.isAfter(DateTime(_toDate!.year, _toDate!.month, _toDate!.day));
                      return matchesStatus && matchesFrom && matchesTo;
                    })
                    .expand((items) => items)
                    .toList(growable: false);
                final selectedMatches = visibleItems.where((row) => row.ordenProduccionId == state.selectedItem?.ordenProduccionId);
                final selected = selectedMatches.isEmpty ? (visibleItems.isEmpty ? null : visibleItems.first) : selectedMatches.first;
                final visibleOrders = _groupByOrder(visibleItems);

                final listPanel = _ProductosListPanel(
                  state: state,
                  visibleOrders: visibleOrders,
                  selectedOrderId: selected?.ordenProduccionId,
                  onRetry: () {
                    _talker.ui(
                      'Se solicito reintentar la carga de productos terminados.',
                    );
                    context.read<ProductosTerminadosCubit>().initialize();
                  },
                  onSelect: (id) {
                    _talker.ui(
                      'Se selecciono el producto terminado $id desde el listado.',
                      logLevel: LogLevel.debug,
                    );
                    context.read<ProductosTerminadosCubit>().selectItem(id);
                  },
                );

                final detailPanel = _ProductoDetailPanel(
                  item: selected,
                  orderItems: selected == null
                      ? const []
                      : state.items
                          .where((item) =>
                              item.ordenProduccionId ==
                              selected.ordenProduccionId)
                          .toList(growable: false),
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FiltersBar(
                      controller: _searchController,
                      status: _statusFilter,
                      fromDate: _fromDate,
                      toDate: _toDate,
                      onSearch: context
                          .read<ProductosTerminadosCubit>()
                          .applySearch,
                      onStatusChanged: (value) => setState(
                        () => _statusFilter = value,
                      ),
                      onFromDateChanged: (value) => setState(
                        () => _fromDate = value,
                      ),
                      onToDateChanged: (value) => setState(
                        () => _toDate = value,
                      ),
                      onClear: () {
                        setState(() {
                          _searchController.clear();
                          _statusFilter = 'Todos';
                          _fromDate = null;
                          _toDate = null;
                        });
                        context
                            .read<ProductosTerminadosCubit>()
                            .applySearch('');
                      },
                    ),
                    const Gap(AppSpacing.md),
                    Expanded(
                      child: isWide
                          ? Row(
                              children: [
                                Expanded(flex: 8, child: listPanel),
                                const Gap(AppSpacing.md),
                                Expanded(flex: 9, child: detailPanel),
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
      ),
    );
  }
}

class _FiltersBar extends StatelessWidget {
  const _FiltersBar({
    required this.controller,
    required this.status,
    required this.fromDate,
    required this.toDate,
    required this.onSearch,
    required this.onStatusChanged,
    required this.onFromDateChanged,
    required this.onToDateChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String status;
  final DateTime? fromDate;
  final DateTime? toDate;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<DateTime?> onFromDateChanged;
  final ValueChanged<DateTime?> onToDateChanged;
  final VoidCallback onClear;

  Future<void> _pickDate(BuildContext context, {required bool isFrom}) async {
    final current = isFrom ? fromDate : toDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    if (isFrom) {
      onFromDateChanged(picked);
    } else {
      onToDateChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final search = TextField(
      controller: controller,
      onChanged: onSearch,
      decoration: const InputDecoration(
        hintText: 'Buscar por producto, orden o cliente',
        prefixIcon: Icon(Icons.search_rounded),
        isDense: true,
      ),
    );
    final state = SizedBox(
      width: 170,
      child: DropdownButtonFormField<String>(
        value: status,
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down_rounded),
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.filter_alt_outlined),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
        ),
        items: const [
          ('Todos', 'Todos'),
          ('Pendiente de entrega', 'Pendiente'),
          ('Entrega parcial', 'Parcial'),
          ('Entregado', 'Entregado'),
        ].map((option) => DropdownMenuItem(
          value: option.$1,
          child: Text(option.$2, maxLines: 1, overflow: TextOverflow.ellipsis),
        )).toList(),
        onChanged: (value) => onStatusChanged(value ?? 'Todos'),
      ),
    );
    final from = OutlinedButton.icon(
      onPressed: () => _pickDate(context, isFrom: true),
      icon: const Icon(Icons.calendar_today_outlined, size: 18),
      label: Text(fromDate == null ? 'Desde' : _formatDate(fromDate!)),
    );
    final to = OutlinedButton.icon(
      onPressed: () => _pickDate(context, isFrom: false),
      icon: const Icon(Icons.calendar_today_outlined, size: 18),
      label: Text(toDate == null ? 'Hasta' : _formatDate(toDate!)),
    );
    final clear = TextButton.icon(
      onPressed: onClear,
      icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
      label: const Text('Limpiar'),
    );

    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 1050) {
            return Row(children: [
              Expanded(child: search),
              const Gap(AppSpacing.sm),
              state,
              const Gap(AppSpacing.sm),
              from,
              const Gap(AppSpacing.sm),
              to,
              const Gap(AppSpacing.xs),
              clear,
            ]);
          }
          return Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(width: constraints.maxWidth, child: search),
              state,
              from,
              to,
              clear,
            ],
          );
        },
      ),
    );
  }
}

class _ProductosListPanel extends StatelessWidget {
  const _ProductosListPanel({
    required this.state,
    required this.visibleOrders,
    required this.selectedOrderId,
    required this.onRetry,
    required this.onSelect,
  });

  final ProductosTerminadosState state;
  final Map<int, List<ProductoTerminadoRecord>> visibleOrders;
  final int? selectedOrderId;
  final VoidCallback onRetry;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
            child: Row(children: [
              Expanded(child: Text('Listado de productos terminados', style: theme.textTheme.titleMedium)),
              Text('${visibleOrders.length} órdenes', style: theme.textTheme.labelMedium),
            ]),
          ),
          const Gap(AppSpacing.lg),
          Expanded(
            child: switch (state.status) {
              ProductosTerminadosStatus.loading => const Center(
                child: CircularProgressIndicator(),
              ),
              ProductosTerminadosStatus.error => _CenteredMessage(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppMessageCard.error(
                      title: 'No pudimos cargar productos terminados',
                      message: state.errorMessage ?? 'Intenta nuevamente.',
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
              ProductosTerminadosStatus.success =>
                visibleOrders.isEmpty
                    ? const _CenteredMessage(
                        child: AppMessageCard.info(
                          title: 'Sin resultados',
                          message:
                              'No encontramos productos terminados con ese criterio.',
                        ),
                      )
                    : ListView.separated(
                        itemCount: visibleOrders.length,
                        separatorBuilder: (_, _) => const Gap(AppSpacing.md),
                        itemBuilder: (context, index) {
                          final items = visibleOrders.values.elementAt(index);
                          final item = items.first;
                          return _OrdenTerminadoListTile(
                            item: item,
                            items: items,
                            isSelected: selectedOrderId == item.ordenProduccionId,
                            onTap: () => onSelect(item.id),
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

Map<int, List<ProductoTerminadoRecord>> _groupByOrder(
  List<ProductoTerminadoRecord> items,
) {
  final result = <int, List<ProductoTerminadoRecord>>{};
  for (final item in items) {
    (result[item.ordenProduccionId] ??= []).add(item);
  }
  return result;
}

class _ProductoDetailPanel extends StatefulWidget {
  const _ProductoDetailPanel({required this.item, required this.orderItems});

  final ProductoTerminadoRecord? item;
  final List<ProductoTerminadoRecord> orderItems;

  @override
  State<_ProductoDetailPanel> createState() => _ProductoDetailPanelState();
}

class _ProductoDetailPanelState extends State<_ProductoDetailPanel> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final rows = widget.orderItems;
    final theme = Theme.of(context);
    final programados = rows.fold<double>(0, (sum, row) => sum + row.cantidadLadosProgramados);
    final terminados = rows.fold<double>(0, (sum, row) => sum + row.cantidadLadosCalculada);
    final entregados = rows.fold<double>(0, (sum, row) => sum + row.cantidadLadosEntregados);
    final pendientes = rows.fold<double>(0, (sum, row) => sum + row.cantidadLadosPendientes);

    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: item == null
          ? const _CenteredMessage(child: AppMessageCard.info(
              title: 'Selecciona una orden',
              message: 'El detalle de sus productos y entregas aparecerá aquí.',
            ))
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Orden ${item.ordenCodigo}', style: theme.textTheme.headlineSmall),
                  Text(item.clienteNombre ?? 'Cliente no registrado', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ])),
                AppButton.primary(
                  label: 'Registrar entrega',
                  icon: Icons.local_shipping_outlined,
                  expand: false,
                  onPressed: pendientes <= 0 ? null : () => _showDeliveryDialog(context, item, rows),
                ),
              ]),
              const Gap(AppSpacing.md),
              Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
                _OrderMetric('Productos', '${rows.length}'),
                _OrderMetric('Programado', '${_formatDecimal(programados)} lados'),
                _OrderMetric('Terminado', '${_formatDecimal(terminados)} lados'),
                _OrderMetric('Entregado', '${_formatDecimal(entregados)} lados'),
                _OrderMetric('Por entregar', '${_formatDecimal(pendientes)} lados'),
              ]),
              const Gap(AppSpacing.md),
              Row(children: [
                _DetailTab(label: 'Productos', selected: _tab == 0, onTap: () => setState(() => _tab = 0)),
                _DetailTab(label: 'Entregas', selected: _tab == 1, onTap: () => setState(() => _tab = 1)),
                _DetailTab(label: 'Trazabilidad', selected: _tab == 2, onTap: () => setState(() => _tab = 2)),
              ]),
              const Divider(height: 1),
              const Gap(AppSpacing.md),
              Expanded(child: switch (_tab) {
                0 => _ProductsTable(rows: rows),
                1 => _DeliveryHistory(orderId: item.ordenProduccionId),
                _ => _OrderTraceability(item: item, rows: rows),
              }),
            ]),
    );
  }
}

class _OrderMetric extends StatelessWidget {
  const _OrderMetric(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(
        '$label:',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      const Gap(AppSpacing.xs),
      Text(value, style: Theme.of(context).textTheme.labelLarge),
    ]),
  );
}

class _DetailTab extends StatelessWidget {
  const _DetailTab({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onTap,
    style: TextButton.styleFrom(foregroundColor: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant),
    child: Text(label, style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
  );
}

class _ProductsTable extends StatelessWidget {
  const _ProductsTable({required this.rows});
  final List<ProductoTerminadoRecord> rows;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 680;
      return SingleChildScrollView(
        child: SizedBox(
          width: constraints.maxWidth,
          child: Column(
            children: [
              _ProductsTableHeader(compact: compact),
              for (final row in rows)
                _FinishedProductRow(row: row, compact: compact),
              if (rows.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Text('No hay productos terminados para esta orden.'),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _DeliveryHistory extends StatelessWidget {
  const _DeliveryHistory({required this.orderId});
  final int orderId;
  @override
  Widget build(BuildContext context) => FutureBuilder<List<EntregaProductoTerminadoRecord>>(
    future: context.read<ProductosTerminadosCubit>().cargarEntregas(orderId),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return const Center(child: Text('No se pudo cargar el historial de entregas.'));
      final deliveries = snapshot.data ?? const [];
      if (deliveries.isEmpty) return const Center(child: Text('Esta orden aún no tiene entregas registradas.'));
      final grouped = <int, List<EntregaProductoTerminadoRecord>>{};
      for (final row in deliveries) { (grouped[row.id] ??= []).add(row); }
      return ListView.separated(
        itemCount: grouped.length,
        separatorBuilder: (_, _) => const Gap(AppSpacing.sm),
        itemBuilder: (context, index) {
          final rows = grouped.values.elementAt(index);
          final first = rows.first;
          final total = rows.fold<double>(0, (sum, row) => sum + row.cantidadLados);
          return AppSurfaceCard(padding: const EdgeInsets.all(AppSpacing.md), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Expanded(child: Text(first.codigo, style: Theme.of(context).textTheme.titleMedium)), Text(_formatDateTime(first.fecha))]),
            Text('Cliente: ${first.clienteNombre} · Registró: ${first.responsable ?? 'No registrado'}${(first.recibidoPor ?? '').isEmpty ? '' : ' · Recibió: ${first.recibidoPor}'}'),
            const Gap(AppSpacing.sm),
            for (final row in rows) Text('${row.producto}: ${_formatDecimal(row.cantidadLados)} lados'),
            const Divider(),
            Text('Estado: ${first.estado} · Total: ${_formatDecimal(total)} lados', style: Theme.of(context).textTheme.titleSmall),
            if ((first.observacion ?? '').trim().isNotEmpty) Text(first.observacion!),
          ]));
        },
      );
    },
  );
}

class _OrderTraceability extends StatelessWidget {
  const _OrderTraceability({required this.item, required this.rows});
  final ProductoTerminadoRecord item;
  final List<ProductoTerminadoRecord> rows;
  @override
  Widget build(BuildContext context) => ListView(children: [
    _TraceRow(icon: Icons.person_outline, title: 'Cliente', detail: item.clienteNombre ?? 'Sin cliente asociado'),
    _TraceRow(icon: Icons.assignment_outlined, title: 'Orden', detail: '${item.ordenCodigo}${item.fechaOrden == null ? '' : ' · ${_formatDate(item.fechaOrden!)}'}'),
    for (final row in rows) _TraceRow(icon: Icons.inventory_2_outlined, title: row.productoNombre ?? row.codigo, detail: '${row.codigo} · terminado ${_formatDecimal(row.cantidadLadosCalculada)} lados${row.fechaTerminacionOrden == null ? '' : ' · ${_formatDate(row.fechaTerminacionOrden!)}'}'),
    _TraceDeliveries(orderId: item.ordenProduccionId),
  ]);
}

class _TraceDeliveries extends StatelessWidget {
  const _TraceDeliveries({required this.orderId});
  final int orderId;
  @override
  Widget build(BuildContext context) => FutureBuilder<List<EntregaProductoTerminadoRecord>>(
    future: context.read<ProductosTerminadosCubit>().cargarEntregas(orderId),
    builder: (context, snapshot) {
      final records = snapshot.data ?? const <EntregaProductoTerminadoRecord>[];
      final grouped = <int, List<EntregaProductoTerminadoRecord>>{};
      for (final row in records) { (grouped[row.id] ??= []).add(row); }
      return Column(children: [
        if (snapshot.connectionState == ConnectionState.waiting) const ListTile(dense: true, leading: Icon(Icons.local_shipping_outlined), title: Text('Cargando entregas…')),
        if (snapshot.hasError) const ListTile(dense: true, leading: Icon(Icons.error_outline), title: Text('No se pudieron consultar las entregas.')),
        for (final delivery in grouped.values) _TraceRow(
          icon: Icons.local_shipping_outlined,
          title: delivery.first.codigo,
          detail: '${_formatDate(delivery.first.fecha)} · ${_formatDecimal(delivery.fold<double>(0, (sum, row) => sum + row.cantidadLados))} lados entregados',
        ),
      ]);
    },
  );
}

class _TraceRow extends StatelessWidget {
  const _TraceRow({required this.icon, required this.title, required this.detail});
  final IconData icon;
  final String title;
  final String detail;
  @override
  Widget build(BuildContext context) => ListTile(dense: true, leading: Icon(icon, color: Theme.of(context).colorScheme.primary), title: Text(title), subtitle: Text(detail));
}

class _DeliveryStatusBadge extends StatelessWidget {
  const _DeliveryStatusBadge({required this.label, required this.complete, required this.partial});
  final String label;
  final bool complete;
  final bool partial;

  @override
  Widget build(BuildContext context) {
    final color = complete
        ? Colors.green.shade700
        : partial
            ? Theme.of(context).colorScheme.primary
            : Colors.orange.shade800;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700)),
    );
  }
}

class _ProductsTableHeader extends StatelessWidget {
  const _ProductsTableHeader({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) => compact
      ? const SizedBox.shrink()
      : Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
    ),
    child: Row(children: [
            const Expanded(flex: 30, child: _ColumnHeading('PRODUCTO')),
            const Expanded(flex: 9, child: _ColumnHeading('PROG.')),
            const Expanded(flex: 9, child: _ColumnHeading('TERM.')),
            const Expanded(flex: 9, child: _ColumnHeading('ENTREG.')),
            const Expanded(flex: 9, child: _ColumnHeading('PEND.')),
            const Expanded(flex: 12, child: _ColumnHeading('ESTADO')),
            SizedBox(
              width: 42,
              child: Text(' ', style: Theme.of(context).textTheme.labelSmall),
            ),
          ]),
  );
}

class _ColumnHeading extends StatelessWidget {
  const _ColumnHeading(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    textAlign: TextAlign.center,
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w700,
    ),
  );
}

class _OrdenTerminadoListTile extends StatelessWidget {
  const _OrdenTerminadoListTile({
    required this.item,
    required this.items,
    required this.isSelected,
    required this.onTap,
  });

  final ProductoTerminadoRecord item;
  final List<ProductoTerminadoRecord> items;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final terminados = items.fold<double>(0, (sum, row) => sum + row.cantidadLadosCalculada);
    final entregados = items.fold<double>(0, (sum, row) => sum + row.cantidadLadosEntregados);
    final pendientes = items.fold<double>(0, (sum, row) => sum + row.cantidadLadosPendientes);
    final estado = pendientes <= 0 ? 'Entregado' : entregados > 0 ? 'Entrega parcial' : 'Pendiente de entrega';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
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
              Text(
                item.ordenCodigo,
                style: theme.textTheme.titleMedium,
              ),
              if ((item.clienteNombre ?? '').isNotEmpty) ...[
                const Gap(AppSpacing.xs),
                Text(
                  item.clienteNombre!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const Gap(AppSpacing.md),
              Text(
                '${items.length} productos · ${_formatDecimal(terminados)} lados terminados',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Gap(AppSpacing.sm),
              Row(children: [
                _DeliveryStatusBadge(label: estado, complete: pendientes <= 0, partial: entregados > 0),
                const Spacer(),
                Text(_formatDate(item.fechaIngreso), style: theme.textTheme.bodySmall),
                const Icon(Icons.chevron_right_rounded),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _FinishedProductRow extends StatelessWidget {
  const _FinishedProductRow({required this.row, required this.compact});

  final ProductoTerminadoRecord row;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = row.esProductoIndividual
        ? '${row.productoNombre ?? row.codigo}${(row.productoColor ?? '').isEmpty ? '' : ' · ${row.productoColor}'}'
        : row.codigo;
    final statusLabel = row.cantidadLadosPendientes <= 0
        ? 'Entregado'
        : row.cantidadLadosEntregados > 0
            ? 'Parcial'
            : 'Pendiente';
    final statusBadge = _DeliveryStatusBadge(
      label: statusLabel,
      complete: row.cantidadLadosPendientes <= 0,
      partial: row.cantidadLadosEntregados > 0,
    );
    final deliverButton = IconButton(
      tooltip: 'Registrar entrega',
      visualDensity: VisualDensity.compact,
      onPressed: row.cantidadLadosPendientes <= 0
          ? null
          : () => _showDeliveryDialog(context, row, [row]),
      icon: const Icon(Icons.local_shipping_outlined, size: 18),
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: theme.textTheme.titleSmall),
                        Text(row.codigo, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  statusBadge,
                  deliverButton,
                ]),
                const Gap(AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _CompactQuantity('Programado', row.cantidadLadosProgramados),
                    _CompactQuantity('Terminado', row.cantidadLadosCalculada),
                    _CompactQuantity('Entregado', row.cantidadLadosEntregados),
                    _CompactQuantity('Pendiente', row.cantidadLadosPendientes),
                  ],
                ),
              ],
            )
          : Row(children: [
              Expanded(flex: 30, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall),
                Text(row.codigo, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
              ])),
              Expanded(flex: 9, child: _QuantityCell(row.cantidadLadosProgramados)),
              Expanded(flex: 9, child: _QuantityCell(row.cantidadLadosCalculada)),
              Expanded(flex: 9, child: _QuantityCell(row.cantidadLadosEntregados)),
              Expanded(flex: 9, child: _QuantityCell(row.cantidadLadosPendientes, highlight: row.cantidadLadosPendientes > 0)),
              Expanded(flex: 12, child: Center(child: statusBadge)),
              SizedBox(width: 42, child: deliverButton),
            ]),
    );
  }
}

class _QuantityCell extends StatelessWidget {
  const _QuantityCell(this.value, {this.highlight = false});
  final double value;
  final bool highlight;

  @override
  Widget build(BuildContext context) => Text(
    _formatDecimal(value),
    maxLines: 1,
    textAlign: TextAlign.center,
    style: highlight
        ? Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
          )
        : Theme.of(context).textTheme.bodyMedium,
  );
}

class _CompactQuantity extends StatelessWidget {
  const _CompactQuantity(this.label, this.value);
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      style: Theme.of(context).textTheme.bodySmall,
      children: [
        TextSpan(
          text: '$label: ',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        TextSpan(
          text: _formatDecimal(value),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

Future<void> _showDeliveryDialog(
  BuildContext context,
  ProductoTerminadoRecord selected,
  List<ProductoTerminadoRecord> orderItems,
) async {
  final pending = orderItems.where((item) => item.cantidadLadosPendientes > 0).toList();
  final controllers = <int, TextEditingController>{
    for (final item in pending) item.id: TextEditingController(),
  };
  final noteController = TextEditingController();
  final receiverController = TextEditingController();
  var deliveryDate = DateTime.now();
  var saving = false;
  try {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(builder: (dialogContext, setDialogState) => AlertDialog(
        title: Text('Registrar entrega · ${selected.ordenCodigo}'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Ingresa los lados a entregar. El sistema no permitirá superar el saldo disponible.'),
              const Gap(AppSpacing.lg),
              Align(alignment: Alignment.centerLeft, child: OutlinedButton.icon(
                onPressed: () async {
                  final date = await showDatePicker(context: dialogContext, initialDate: deliveryDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                  if (date != null) setDialogState(() => deliveryDate = date);
                },
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text('Fecha de entrega: ${_formatDate(deliveryDate)}'),
              )),
              const Gap(AppSpacing.sm),
              TextField(controller: receiverController, decoration: const InputDecoration(labelText: 'Persona que recibe (opcional)')),
              const Gap(AppSpacing.sm),
              for (final item in pending) Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: TextField(
                  controller: controllers[item.id],
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: '${item.productoNombre ?? item.codigo} · saldo ${_formatDecimal(item.cantidadLadosPendientes)} lados',
                    hintText: 'Cantidad de lados',
                  ),
                ),
              ),
              TextField(controller: noteController, maxLines: 2, decoration: const InputDecoration(labelText: 'Observación (opcional)')),
            ],
          )),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton.icon(
            icon: saving ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined),
            label: Text(saving ? 'Guardando…' : 'Registrar entrega'),
            onPressed: saving ? null : () async {
              final details = <RegistrarEntregaProductoTerminadoInput>[];
              for (final item in pending) {
                final value = double.tryParse(controllers[item.id]!.text.trim().replaceAll(',', '.')) ?? 0;
                if (value > 0) details.add(RegistrarEntregaProductoTerminadoInput(productoTerminadoId: item.id, cantidadLados: value));
              }
              if (details.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('Ingresa al menos una cantidad válida.')));
                return;
              }
              setDialogState(() => saving = true);
              final saved = await context.read<ProductosTerminadosCubit>().registrarEntrega(
                ordenProduccionId: selected.ordenProduccionId,
                detalles: details,
                fechaEntrega: deliveryDate,
                observacion: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                recibidoPor: receiverController.text.trim().isEmpty ? null : receiverController.text.trim(),
              );
              if (!dialogContext.mounted) return;
              if (saved) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entrega registrada correctamente.')));
              } else {
                setDialogState(() => saving = false);
                ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('No fue posible registrar la entrega. Revisa el saldo.')));
              }
            },
          ),
        ],
      )),
    );
  } finally {
    for (final controller in controllers.values) { controller.dispose(); }
    noteController.dispose();
    receiverController.dispose();
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
