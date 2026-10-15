import 'dart:math' as math;

import 'package:erp_curtiembre_fronted/core/theme/app_colors.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_state.dart';
import 'package:erp_curtiembre_fronted/features/inventory/kardex/domain/entities/kardex_record.dart';
import 'package:erp_curtiembre_fronted/features/inventory/kardex/presentation/cubit/kardex_cubit.dart';
import 'package:erp_curtiembre_fronted/features/inventory/kardex/presentation/cubit/kardex_state.dart';
import 'package:erp_curtiembre_fronted/features/inventory/kardex/presentation/kardex_export.dart';
import 'package:erp_curtiembre_fronted/features/security/presentation/cubit/security_access_cubit.dart';
import 'package:erp_curtiembre_fronted/shared/navigation/app_access_routes.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/data/app_table_pagination.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/layout/app_shell.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/layout/app_surface_card.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class KardexPage extends StatefulWidget {
  const KardexPage({super.key});

  @override
  State<KardexPage> createState() => _KardexPageState();
}

class _KardexPageState extends State<KardexPage> {
  final _insumoSearchController = TextEditingController();
  final _insumoFocusNode = FocusNode();
  int? _selectedId;
  DateTime? _from;
  DateTime? _to;

  int _page = 0;
  int _pageSize = 10;
  bool _newestFirst = true;

  @override
  void initState() {
    super.initState();
    _insumoFocusNode.addListener(() {
      if (_insumoFocusNode.hasFocus) _selectInsumoText();
    });
  }

  @override
  void dispose() {
    _insumoSearchController.dispose();
    _insumoFocusNode.dispose();
    super.dispose();
  }

  void _selectInsumoText() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _insumoSearchController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _insumoSearchController.text.length,
      );
    });
  }

  String _normalizeInsumoSearch(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[áàäâ]'), 'a')
      .replaceAll(RegExp(r'[éèëê]'), 'e')
      .replaceAll(RegExp(r'[íìïî]'), 'i')
      .replaceAll(RegExp(r'[óòöô]'), 'o')
      .replaceAll(RegExp(r'[úùüû]'), 'u')
      .trim();

  // =========================================================
  // FILTROS Y FECHAS
  // =========================================================

  Future<void> _pickDate(bool from) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: (from ? _from : _to) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selected == null || !mounted) return;

    setState(() {
      if (from) {
        _from = selected;
      } else {
        _to = selected;
      }
    });
  }

  void _apply(KardexState state) {
    if (_from != null && _to != null && _from!.isAfter(_to!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La fecha inicial debe ser anterior a la final.'),
        ),
      );
      return;
    }

    setState(() => _page = 0);

    final selectedId = _selectedId ?? state.selectedInsumoId;

    context.read<KardexCubit>().load(
      selectedInsumoId: selectedId,
      fechaDesde: _from,
      fechaHasta: _to,
    );
  }

  // =========================================================
  // PANTALLA PRINCIPAL
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final session = context.select((AuthCubit cubit) => cubit.state.session);

    final signingOut = context.select(
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
      title: 'Kardex',
      currentPath: '/inventario/kardex',
      breadcrumbs: const ['Inicio', 'Inventario', 'Kardex'],
      userName: session.nombreCompleto,
      roleName: session.rolNombre,
      accessibleRoutes: AppAccessRoutes.forPermissions(permissionCodes),
      onSignOut: signingOut ? () {} : () => context.read<AuthCubit>().signOut(),
      child: BlocBuilder<KardexCubit, KardexState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _filters(state),

                const SizedBox(height: 14),

                if (state.status == KardexStatus.error)
                  AppSurfaceCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            state.errorMessage ?? 'Error al cargar Kardex',
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              context.read<KardexCubit>().initialize(),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  )
                else if (state.status == KardexStatus.loading)
                  const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  _summary(state),

                  const SizedBox(height: 14),

                  _movements(state),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // =========================================================
  // FILTROS COMPACTOS - SIN TÍTULO
  // =========================================================

  Widget _filters(KardexState state) {
    final selectedId = _selectedId ?? state.selectedInsumoId;

    return AppSurfaceCard(
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final insumo = DropdownMenu<int>(
            key: ValueKey(selectedId),
            initialSelection: selectedId,
            menuHeight: math.min(300, MediaQuery.sizeOf(context).height * .4),
            controller: _insumoSearchController,
            focusNode: _insumoFocusNode,
            enableFilter: true,
            enableSearch: true,
            filterCallback: (entries, query) {
              final text = _normalizeInsumoSearch(query);
              if (text.isEmpty) return entries;
              return entries
                  .where(
                    (entry) =>
                        _normalizeInsumoSearch(entry.label).contains(text),
                  )
                  .toList();
            },
            requestFocusOnTap: true,
            label: const Text('Insumo'),
            leadingIcon: const Icon(Icons.search_rounded, size: 20),
            expandedInsets: EdgeInsets.zero,
            dropdownMenuEntries: state.insumos
                .map(
                  (item) => DropdownMenuEntry<int>(
                    value: item.id,
                    label: '${item.codigo} - ${item.nombre}',
                  ),
                )
                .toList(),
            onSelected: (value) {
              setState(() {
                _selectedId = value;
              });
              _selectInsumoText();
            },
          );

          final from = _dateField('Fecha desde', _from, () => _pickDate(true));

          final to = _dateField('Fecha hasta', _to, () => _pickDate(false));

          final clearDates = IconButton(
            tooltip: 'Limpiar fechas',
            onPressed: () {
              setState(() {
                _from = null;
                _to = null;
              });
            },
            icon: const Icon(Icons.close_rounded, size: 18),
          );

          final filterButton = SizedBox(
            width: 126,
            height: 48,
            child: FilledButton.icon(
              onPressed: state.status == KardexStatus.loading
                  ? null
                  : () => _apply(state),
              icon: const Icon(Icons.filter_alt_outlined, size: 18),
              label: const Text('Filtrar'),
            ),
          );

          final exportButton = SizedBox(
            width: 184,
            height: 48,
            child: OutlinedButton.icon(
              onPressed:
                  state.status != KardexStatus.success ||
                      state.selectedInsumoId == null
                  ? null
                  : () => _export(state),
              icon: const Icon(Icons.table_view_outlined, size: 18),
              label: const Text('Exportar a Excel'),
            ),
          );

          final showClear = _from != null || _to != null;

          // ESCRITORIO: UNA FILA
          if (constraints.maxWidth >= (showClear ? 1100 : 1040)) {
            return Row(
              children: [
                Expanded(child: insumo),

                const SizedBox(width: 10),

                from,

                const SizedBox(width: 10),

                to,

                if (showClear) ...[const SizedBox(width: 4), clearDates],

                const SizedBox(width: 10),

                filterButton,

                const SizedBox(width: 10),

                exportButton,
              ],
            );
          }

          // TABLET Y MÓVIL
          final width = constraints.maxWidth;

          return Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(width: width < 620 ? width : 310, child: insumo),

              from,

              to,

              if (showClear) clearDates,

              filterButton,

              exportButton,
            ],
          );
        },
      ),
    );
  }

  // =========================================================
  // SELECTOR DE FECHA
  // =========================================================

  Widget _dateField(String label, DateTime? value, VoidCallback onTap) {
    return SizedBox(
      width: 185,
      height: 50,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 18),

            const SizedBox(width: 9),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    value == null
                        ? 'Todas'
                        : DateFormat('dd/MM/yyyy').format(value),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // RESUMEN DEL INSUMO
  // =========================================================

  Widget _summary(KardexState state) {
    final matches = state.insumos.where(
      (item) => item.id == state.selectedInsumoId,
    );

    final insumo = matches.isEmpty ? null : matches.first;

    final stock = state.stock;

    if (insumo == null) {
      return const AppSurfaceCard(
        child: Text('Selecciona un insumo para ver su kardex.'),
      );
    }

    return AppSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE9DD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.science_outlined,
              color: AppColors.primary,
              size: 26,
            ),
          ),

          SizedBox(
            width: 220,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insumo.codigo,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(insumo.nombre),
              ],
            ),
          ),

          _summaryText('Categoría', insumo.tipoBien),

          _summaryText('Unidad', insumo.unidadMedidaCodigo),

          _summaryValue(
            'Stock actual',
            '${_qty(stock?.cantidadActual ?? insumo.stockActual)} ${insumo.unidadMedidaCodigo}',
            const Color(0xFFE6F3FF),
            const Color(0xFF074987),
          ),

          _summaryValue(
            'Costo unitario',
            stock == null ? '—' : _money(stock.costoPromedioActual),
            const Color(0xFFFFF0E8),
            const Color(0xFF432A20),
          ),

          _summaryValue(
            'Valor del stock',
            stock == null
                ? '—'
                : _money(stock.cantidadActual * stock.costoPromedioActual),
            const Color(0xFFE7FBEA),
            const Color(0xFF125A29),
          ),
        ],
      ),
    );
  }

  Widget _summaryText(String title, String value) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _summaryValue(
    String title,
    String value,
    Color background,
    Color foreground,
  ) {
    return Container(
      width: 175,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, color: foreground)),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // FILTRAR REGISTROS
  // =========================================================

  List<KardexRecord> _filtered(KardexState state) {
    final rows = state.items.where((row) {
      if (state.fechaDesde != null &&
          row.fechaMovimiento.isBefore(state.fechaDesde!)) {
        return false;
      }

      if (state.fechaHasta != null &&
          row.fechaMovimiento.isAfter(
            DateTime(
              state.fechaHasta!.year,
              state.fechaHasta!.month,
              state.fechaHasta!.day,
              23,
              59,
              59,
              999,
            ),
          )) {
        return false;
      }

      return true;
    }).toList();

    rows.sort((a, b) {
      final comparison = a.fechaMovimiento.compareTo(b.fechaMovimiento);

      if (comparison != 0) {
        return _newestFirst ? -comparison : comparison;
      }

      return _newestFirst ? b.id.compareTo(a.id) : a.id.compareTo(b.id);
    });

    return rows;
  }

  // =========================================================
  // TABLA DE MOVIMIENTOS - SIN TÍTULO
  // =========================================================

  Widget _movements(KardexState state) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    final rows = _filtered(state);

    final pages = math.max(1, (rows.length / _pageSize).ceil());

    final page = math.min(_page, pages - 1);

    final start = page * _pageSize;

    final visible = rows.skip(start).take(_pageSize).toList();

    final chronological = [...rows]
      ..sort((a, b) {
        final comparison = a.fechaMovimiento.compareTo(b.fechaMovimiento);

        return comparison != 0 ? comparison : a.id.compareTo(b.id);
      });

    final entrySum = rows.fold<double>(0, (sum, row) => sum + row.entrada);

    final exitSum = rows.fold<double>(0, (sum, row) => sum + row.salida);

    final opening = chronological.isNotEmpty
        ? chronological.first.stockActual -
              chronological.first.entrada +
              chronological.first.salida
        : _balanceBeforeRange(state);

    final closing = chronological.isNotEmpty
        ? chronological.last.stockActual
        : opening;

    final inconsistent = (opening + entrySum - exitSum - closing).abs() > 0.011;

    return AppSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ORDENAMIENTO Y CONTADOR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            child: Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '${rows.length} registros',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),

                  DropdownButton<bool>(
                    value: _newestFirst,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(
                        value: true,
                        child: Text('Más recientes'),
                      ),
                      DropdownMenuItem(
                        value: false,
                        child: Text('Más antiguos'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _newestFirst = value ?? true;
                        _page = 0;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // TABLA DE MOVIMIENTOS
          LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: math.max(1100, constraints.maxWidth),
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(1.3),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(1.25),
                    3: FlexColumnWidth(1.55),
                    4: FlexColumnWidth(.7),
                    5: FlexColumnWidth(.7),
                    6: FlexColumnWidth(.8),
                    7: FlexColumnWidth(.85),
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    TableRow(
                      decoration: BoxDecoration(
                        color: dark
                            ? const Color(0xFF292D33)
                            : const Color(0xFFF4F6F8),
                      ),
                      children:
                          [
                                'INSUMO',
                                'FECHA',
                                'MOVIMIENTO',
                                'DOCUMENTO',
                                'ENTRADA',
                                'SALIDA',
                                'STOCK',
                                'COSTO',
                              ]
                              .map(
                                (label) => _cell(
                                  label,
                                  header: true,
                                  centered: const [
                                    'ENTRADA',
                                    'SALIDA',
                                    'STOCK',
                                    'COSTO',
                                  ].contains(label),
                                ),
                              )
                              .toList(),
                    ),

                    // REGISTROS REALES
                    ...visible.map(
                      (row) => TableRow(
                        decoration: BoxDecoration(
                          color:
                              row.tipoMovimiento.toUpperCase().contains(
                                'AJUSTE',
                              )
                              ? (dark
                                    ? const Color(0xFF1E354F)
                                    : const Color(0xFFEDF4FD))
                              : row.entrada > 0
                              ? (dark
                                    ? const Color(0xFF1E3A29)
                                    : const Color(0xFFEAF9ED))
                              : row.salida > 0
                              ? (dark
                                    ? const Color(0xFF432825)
                                    : const Color(0xFFFFF0EF))
                              : (dark
                                    ? const Color(0xFF1E354F)
                                    : const Color(0xFFEDF4FD)),
                          border: const Border(
                            bottom: BorderSide(color: Color(0xFFE5E8EC)),
                          ),
                        ),
                        children: [
                          _cell(
                            '${row.insumoCodigo}\n${row.insumoNombre}',
                            bold: true,
                          ),

                          _cell(
                            DateFormat(
                              'dd/MM/yyyy\nHH:mm',
                            ).format(row.fechaMovimiento),
                          ),

                          _cell(
                            row.tipoMovimiento.replaceAll('_', ' '),
                            badge: true,
                            isEntry: row.entrada > 0,
                            isAdjustment: row.tipoMovimiento
                                .toUpperCase()
                                .contains('AJUSTE'),
                          ),

                          Tooltip(
                            message:
                                'Responsable: ${row.usuarioResponsable ?? row.usuarioResponsableId?.toString() ?? 'No registrado'}\nObservación: ${row.observacion ?? 'Sin observación'}',
                            child: _cell(
                              '${row.documentoTipo ?? '—'}\n${row.documentoId ?? '—'}',
                            ),
                          ),

                          _cell(_qty(row.entrada), centered: true),

                          _cell(_qty(row.salida), centered: true),

                          _cell(
                            _qty(row.stockActual),
                            centered: true,
                            bold: true,
                          ),

                          _cell(
                            _money(row.costoTotal),
                            centered: true,
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.all(30),
              child: Center(
                child: Text('No hay movimientos para estos filtros.'),
              ),
            ),

          // PAGINACIÓN ORIGINAL
          AppTablePagination(
            page: page,
            totalPages: pages,
            start: start,
            end: math.min(start + _pageSize, rows.length),
            total: rows.length,
            pageSize: _pageSize,
            pageSizeOptions: const [10, 20, 50],
            onPageChanged: (value) {
              setState(() {
                _page = value;
              });
            },
            onPageSizeChanged: (value) {
              setState(() {
                _pageSize = value;
                _page = 0;
              });
            },
          ),

          const Divider(height: 1),

          // RESUMEN INFERIOR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final totals = [
                  _balanceTile(
                    Icons.description_outlined,
                    'Saldo anterior',
                    '${_qty(opening)} ${_unit(state)}',
                    const Color(0xFF42546C),
                  ),
                  _balanceTile(
                    Icons.arrow_upward_rounded,
                    'Entradas',
                    '${_qty(entrySum)} ${_unit(state)}',
                    const Color(0xFF168040),
                  ),
                  _balanceTile(
                    Icons.arrow_downward_rounded,
                    'Salidas',
                    '${_qty(exitSum)} ${_unit(state)}',
                    const Color(0xFFD42C26),
                  ),
                  _balanceTile(
                    Icons.inventory_2_outlined,
                    'Saldo final',
                    '${_qty(closing)} ${_unit(state)}',
                    const Color(0xFF0864BA),
                  ),
                ];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (constraints.maxWidth >= 850)
                      Row(
                        children: [
                          for (int i = 0; i < totals.length; i++) ...[
                            Expanded(child: totals[i]),

                            if (i < totals.length - 1)
                              Container(
                                width: 1,
                                height: 40,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                color: Theme.of(context).dividerColor,
                              ),
                          ],
                        ],
                      )
                    else
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: totals
                            .map((item) => SizedBox(width: 215, child: item))
                            .toList(),
                      ),

                    if (inconsistent) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'Advertencia: los movimientos no concilian con el saldo registrado.',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TARJETAS COMPACTAS DE SALDOS
  // =========================================================

  Widget _balanceTile(IconData icon, String title, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .10),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),

        const SizedBox(width: 10),

        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12)),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================
  // CÁLCULO DE SALDO ANTERIOR
  // =========================================================

  double _balanceBeforeRange(KardexState state) {
    final before =
        state.items
            .where(
              (row) =>
                  state.fechaDesde == null ||
                  row.fechaMovimiento.isBefore(state.fechaDesde!),
            )
            .toList()
          ..sort((a, b) {
            final comparison = b.fechaMovimiento.compareTo(a.fechaMovimiento);

            return comparison != 0 ? comparison : b.id.compareTo(a.id);
          });

    if (before.isNotEmpty) {
      return before.first.stockActual;
    }

    if (state.items.isNotEmpty) {
      final oldest = [...state.items]
        ..sort((a, b) {
          final comparison = a.fechaMovimiento.compareTo(b.fechaMovimiento);

          return comparison != 0 ? comparison : a.id.compareTo(b.id);
        });

      final first = oldest.first;

      return first.stockActual - first.entrada + first.salida;
    }

    return state.stock?.cantidadActual ?? 0;
  }

  String _unit(KardexState state) {
    for (final item in state.insumos) {
      if (item.id == state.selectedInsumoId) {
        return item.unidadMedidaCodigo;
      }
    }

    return '';
  }

  // =========================================================
  // CELDAS DE TABLA
  // =========================================================

  Widget _cell(
    String value, {
    bool header = false,
    bool bold = false,
    bool centered = false,
    bool badge = false,
    bool isEntry = false,
    bool isAdjustment = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Align(
        alignment: centered ? Alignment.center : Alignment.centerLeft,
        child: badge
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isAdjustment
                      ? const Color(0xFFDCEBFF)
                      : isEntry
                      ? const Color(0xFFD8F2DE)
                      : const Color(0xFFFFDAD8),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isAdjustment
                        ? const Color(0xFF18549B)
                        : isEntry
                        ? const Color(0xFF11672B)
                        : const Color(0xFFB42318),
                  ),
                ),
              )
            : Text(
                value,
                style: TextStyle(
                  fontSize: header ? 11 : 12,
                  fontWeight: header || bold
                      ? FontWeight.w700
                      : FontWeight.normal,
                  color: header ? const Color(0xFF586476) : null,
                ),
              ),
      ),
    );
  }

  // =========================================================
  // EXPORTACIÓN A EXCEL - LÓGICA ORIGINAL
  // =========================================================

  void _export(KardexState state) {
    final stock = state.stock;

    final matches = state.insumos.where(
      (item) => item.id == state.selectedInsumoId,
    );

    if (matches.isEmpty) return;

    final insumo = matches.first;

    final rows = _filtered(state);

    final chronological = [...rows]
      ..sort((a, b) {
        final comparison = a.fechaMovimiento.compareTo(b.fechaMovimiento);

        return comparison != 0 ? comparison : a.id.compareTo(b.id);
      });

    final opening = chronological.isNotEmpty
        ? chronological.first.stockActual -
              chronological.first.entrada +
              chronological.first.salida
        : _balanceBeforeRange(state);

    final closing = chronological.isNotEmpty
        ? chronological.last.stockActual
        : opening;

    exportKardex(
      insumo,
      stock,
      rows,
      state.fechaDesde,
      state.fechaHasta,
      opening: opening,
      entries: rows.fold<double>(0, (sum, row) => sum + row.entrada),
      exits: rows.fold<double>(0, (sum, row) => sum + row.salida),
      closing: closing,
    );
  }
}

// ============================================================
// FORMATO NUMÉRICO
// ============================================================

String _qty(double value) {
  return NumberFormat('#,##0.00').format(value);
}

String _money(double value) {
  return 'S/ ${_qty(value)}';
}
