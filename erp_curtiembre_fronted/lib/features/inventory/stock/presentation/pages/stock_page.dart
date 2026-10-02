import 'dart:async';
import 'package:erp_curtiembre_fronted/core/di/service_locator.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_state.dart';
import 'package:erp_curtiembre_fronted/features/inventory/insumos/domain/constants/insumo_tipo_bien_options.dart';
import 'package:erp_curtiembre_fronted/features/inventory/stock/domain/entities/stock_record.dart';
import 'package:erp_curtiembre_fronted/features/inventory/stock/presentation/cubit/stock_cubit.dart';
import 'package:erp_curtiembre_fronted/features/inventory/stock/presentation/cubit/stock_state.dart';
import 'package:erp_curtiembre_fronted/features/security/presentation/cubit/security_access_cubit.dart';
import 'package:erp_curtiembre_fronted/shared/navigation/app_access_routes.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/layout/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:talker_flutter/talker_flutter.dart';

const _accent = Color(0xFFE8590C);
const _green = Color(0xFF138348);

class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  final _searchController = TextEditingController();
  final Talker _talker = getIt<Talker>();
  Timer? _debounce;
  int _page = 0;
  int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _talker.ui('Se abrio la pantalla de stock.');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    _debounce?.cancel();
    if (!mounted) return;
    setState(() => _page = 0);
    final term = _searchController.text.trim();
    _talker.ui('Busqueda de stock: ${term.length} caracteres.');
    context.read<StockCubit>().load(searchTerm: term);
  }

  void _scheduleSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 420), _search);
  }

  void _select(int insumoId, {required bool mobile}) {
    _talker.ui('Insumo seleccionado: $insumoId.', logLevel: LogLevel.debug);
    context.read<StockCubit>().selectInsumo(insumoId);
    if (!mobile) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => BlocProvider.value(
        value: context.read<StockCubit>(),
        child: const FractionallySizedBox(
          heightFactor: .85,
          child: _MobileDetailSheet(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.select((AuthCubit c) => c.state.session);
    final signingOut = context.select(
      (AuthCubit c) => c.state.status == AuthStatus.signingOut,
    );
    final permissions = context.select(
      (SecurityAccessCubit c) =>
          c.state.snapshot?.userPermissionCodes.toSet() ?? const <String>{},
    );

    if (session == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return AppShell(
      title: 'Stock actual',
      currentPath: '/inventario/stock',
      breadcrumbs: const ['Inicio', 'Inventario', 'Stock actual'],
      userName: session.nombreCompleto,
      roleName: session.rolNombre,
      accessibleRoutes: AppAccessRoutes.forPermissions(permissions),
      onSignOut: signingOut ? () {} : () => context.read<AuthCubit>().signOut(),
      child: BlocBuilder<StockCubit, StockState>(
        builder: (context, state) => LayoutBuilder(
          builder: (context, constraints) {
            final mobile = constraints.maxWidth < 760;
            final sideBySide = constraints.maxWidth >= 1080;
            final pages = state.items.isEmpty
                ? 1
                : (state.items.length / _pageSize).ceil();
            final safePage = _page.clamp(0, pages - 1).toInt();
            final start = safePage * _pageSize;
            final end = (start + _pageSize)
                .clamp(0, state.items.length)
                .toInt();
            final visible = state.items.sublist(start, end);

            Widget list = _StockListPanel(
              items: visible,
              total: state.items.length,
              status: state.status,
              error: state.errorMessage,
              selectedId: state.selectedInsumoId,
              page: safePage,
              totalPages: pages,
              pageSize: _pageSize,
              start: start,
              end: end,
              compact: !sideBySide,
              onSelect: (id) => _select(id, mobile: mobile),
              onRetry: () => context.read<StockCubit>().initialize(),
              onPage: (p) => setState(() => _page = p),
              onPageSize: (size) => setState(() {
                _pageSize = size;
                _page = 0;
              }),
            );
            final detail = _StockDetailPanel(
              state: state,
              onRetry: () => context.read<StockCubit>().retryDetail(),
            );

            return Padding(
              padding: EdgeInsets.all(mobile ? 12 : 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _StockFilters(
                        state: state,
                        controller: _searchController,
                        mobile: mobile,
                        onSearch: _search,
                        onChanged: _scheduleSearch,
                        onActivity: (value) {
                          setState(() => _page = 0);
                          context.read<StockCubit>().load(
                            activityFilter: value,
                          );
                        },
                        onType: (value) {
                          setState(() => _page = 0);
                          context.read<StockCubit>().load(
                            tipoBienFilter: value,
                          );
                        },
                        onLow: (value) {
                          setState(() => _page = 0);
                          context.read<StockCubit>().load(lowStockOnly: value);
                        },
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: sideBySide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(flex: 13, child: list),
                                  const SizedBox(width: 12),
                                  Expanded(flex: 7, child: detail),
                                ],
                              )
                            : mobile
                            ? list
                            : Column(
                                children: [
                                  Expanded(flex: 11, child: list),
                                  const SizedBox(height: 14),
                                  Expanded(flex: 9, child: detail),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StockFilters extends StatelessWidget {
  const _StockFilters({
    required this.state,
    required this.controller,
    required this.mobile,
    required this.onSearch,
    required this.onChanged,
    required this.onActivity,
    required this.onType,
    required this.onLow,
  });

  final StockState state;
  final TextEditingController controller;
  final bool mobile;
  final VoidCallback onSearch;
  final ValueChanged<String> onChanged;
  final ValueChanged<StockActivityFilter> onActivity;
  final ValueChanged<String?> onType;
  final ValueChanged<bool> onLow;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final search = TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      onSubmitted: (_) => onSearch(),
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Buscar por código o nombre de insumo...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: IconButton(
          tooltip: controller.text.isEmpty ? 'Buscar' : 'Limpiar búsqueda',
          icon: Icon(
            controller.text.isEmpty
                ? Icons.arrow_forward_rounded
                : Icons.close_rounded,
          ),
          onPressed: () {
            if (controller.text.isNotEmpty) controller.clear();
            onSearch();
          },
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 12,
        ),
      ),
    );
    final type = DropdownMenu<String>(
      width: mobile ? 260 : 190,
      enableFilter: true,
      enableSearch: true,
      requestFocusOnTap: true,
      key: ValueKey(state.tipoBienFilter ?? '__all__'),
      initialSelection: state.tipoBienFilter ?? '__all__',
      label: const Text('Tipo de bien'),
      dropdownMenuEntries: [
        const DropdownMenuEntry(value: '__all__', label: 'Todos los tipos'),
        ...inventoryInsumoTipoBienOptions.map(
          (o) => DropdownMenuEntry(value: o.value, label: o.label),
        ),
      ],
      onSelected: (value) => onType(value == '__all__' ? null : value),
    );
    final activity = SegmentedButton<StockActivityFilter>(
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? _accent : null,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : color.onSurface,
        ),
      ),
      segments: const [
        ButtonSegment(value: StockActivityFilter.all, label: Text('Todos')),
        ButtonSegment(
          value: StockActivityFilter.active,
          label: Text('Activos'),
        ),
        ButtonSegment(
          value: StockActivityFilter.inactive,
          label: Text('Inactivos'),
        ),
      ],
      selected: {state.activityFilter},
      onSelectionChanged: (values) => onActivity(values.first),
    );
    final low = InkWell(
      onTap: () => onLow(!state.lowStockOnly),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: state.lowStockOnly,
            activeThumbColor: _accent,
            onChanged: onLow,
          ),
          const Text('Solo stock bajo', style: TextStyle(fontSize: 12)),
        ],
      ),
    );

    return _Surface(
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, box) {
          if (box.maxWidth >= 1120) {
            return Row(
              children: [
                Expanded(child: search),
                const SizedBox(width: 12),
                type,
                const SizedBox(width: 12),
                activity,
                const SizedBox(width: 12),
                low,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              search,
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [type, activity, low],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StockListPanel extends StatelessWidget {
  const _StockListPanel({
    required this.items,
    required this.total,
    required this.status,
    required this.error,
    required this.selectedId,
    required this.page,
    required this.totalPages,
    required this.pageSize,
    required this.start,
    required this.end,
    required this.compact,
    required this.onSelect,
    required this.onRetry,
    required this.onPage,
    required this.onPageSize,
  });

  final List<StockRecord> items;
  final int total;
  final StockStatus status;
  final String? error;
  final int? selectedId;
  final int page, totalPages, pageSize, start, end;
  final bool compact;
  final ValueChanged<int> onSelect;
  final VoidCallback onRetry;
  final ValueChanged<int> onPage;
  final ValueChanged<int> onPageSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _Surface(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const _SectionIcon(Icons.inventory_2_outlined),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Lista de insumos',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
                Text(
                  '$total resultados',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: scheme.outlineVariant),
          Expanded(
            child: switch (status) {
              StockStatus.loading => const Center(
                child: CircularProgressIndicator(),
              ),
              StockStatus.error => _Message(
                icon: Icons.error_outline,
                title: 'No pudimos cargar el stock',
                detail: error ?? 'Intenta nuevamente.',
                onRetry: onRetry,
              ),
              StockStatus.success =>
                total == 0
                    ? const _Message(
                        icon: Icons.search_off_rounded,
                        title: 'No hay resultados',
                        detail: 'Prueba con otros filtros.',
                      )
                    : compact
                    ? ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: scheme.outlineVariant),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final selected = item.insumoId == selectedId;
                          return Material(
                            color: selected
                                ? _accent.withValues(alpha: .07)
                                : Colors.transparent,
                            child: ListTile(
                              selected: selected,
                              onTap: () => onSelect(item.insumoId),
                              title: Text(
                                item.nombre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                '${item.codigo} · ${_tipoBienLabel(item.tipoBien)}',
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${item.cantidadActual.toStringAsFixed(2)} ${item.unidadMedidaCodigo}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  _Tag(
                                    item.stockBajo ? 'Stock bajo' : 'Normal',
                                    warning: item.stockBajo,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    : LayoutBuilder(
                        builder: (context, box) => SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: box.maxWidth < 740 ? 740 : box.maxWidth,
                            child: Column(
                              children: [
                                _tableHead(context),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: items.length,
                                    itemBuilder: (context, index) =>
                                        _tableRow(context, items[index]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
            },
          ),
          Divider(height: 1, color: scheme.outlineVariant),
          _pager(context),
        ],
      ),
    );
  }

  static const widths = [95.0, 165.0, 124.0, 100.0, 85.0, 90.0, 80.0, 74.0];

  Widget _tableHead(BuildContext context) {
    final theme = Theme.of(context);
    const headers = [
      'Código',
      'Insumo',
      'Tipo de bien',
      'Actual',
      'Mín.',
      'Costo prom.',
      'Nivel',
      'Estado',
    ];
    return Container(
      color: theme.colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Row(
        children: [
          for (var i = 0; i < headers.length; i++)
            Expanded(
              flex: widths[i].round(),
              child: Text(
                headers[i],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tableRow(BuildContext context, StockRecord item) {
    final selected = item.insumoId == selectedId;
    final color = Theme.of(context).colorScheme;
    Widget cell(String value, int i, {bool bold = false}) => Expanded(
      flex: widths[i].round(),
      child: Padding(
        padding: const EdgeInsets.only(right: 5),
        child: Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: bold && selected ? _accent : color.onSurface,
          ),
        ),
      ),
    );
    return Material(
      color: selected ? _accent.withValues(alpha: .085) : Colors.transparent,
      child: InkWell(
        onTap: () => onSelect(item.insumoId),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: selected ? _accent : Colors.transparent,
                width: 3,
              ),
              bottom: BorderSide(
                color: color.outlineVariant.withValues(alpha: .65),
              ),
            ),
          ),
          child: Row(
            children: [
              cell(item.codigo, 0),
              cell(item.nombre, 1, bold: true),
              cell(_tipoBienLabel(item.tipoBien), 2),
              cell(item.cantidadActual.toStringAsFixed(2), 3, bold: true),
              cell(item.stockMinimo.toStringAsFixed(2), 4),
              cell('S/ ${item.costoPromedioActual.toStringAsFixed(2)}', 5),
              Expanded(
                flex: widths[6].round(),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _Tag(
                    item.stockBajo ? 'Bajo' : 'Normal',
                    warning: item.stockBajo,
                  ),
                ),
              ),
              Expanded(
                flex: widths[7].round(),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _Tag(
                    item.activo ? 'Activo' : 'Inactivo',
                    muted: !item.activo,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pager(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: LayoutBuilder(
        builder: (context, box) => Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          spacing: 8,
          runSpacing: 5,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Mostrar ', style: TextStyle(fontSize: 11)),
                DropdownButton<int>(
                  value: pageSize,
                  isDense: true,
                  underline: const SizedBox.shrink(),
                  items: const [10, 20, 50]
                      .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) onPageSize(v);
                  },
                ),
                const Text(' por página', style: TextStyle(fontSize: 11)),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  total == 0 ? '0 resultados' : '${start + 1}–$end de $total',
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                IconButton(
                  tooltip: 'Página anterior',
                  onPressed: page == 0 ? null : () => onPage(page - 1),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Text(
                  '${page + 1} / $totalPages',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  tooltip: 'Página siguiente',
                  onPressed: page + 1 >= totalPages
                      ? null
                      : () => onPage(page + 1),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StockDetailPanel extends StatelessWidget {
  const _StockDetailPanel({required this.state, required this.onRetry});
  final StockState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final detail = state.selectedStock;
    return _Surface(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const _SectionIcon(Icons.inventory_rounded),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Detalle del insumo',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: color.outlineVariant),
          Expanded(
            child: state.isDetailLoading
                ? const Center(child: CircularProgressIndicator())
                : state.detailErrorMessage != null
                ? _Message(
                    icon: Icons.error_outline_rounded,
                    title: 'No pudimos cargar el detalle',
                    detail: state.detailErrorMessage!,
                    onRetry: onRetry,
                  )
                : detail == null
                ? const _Message(
                    icon: Icons.touch_app_outlined,
                    title: 'Selecciona un insumo',
                    detail:
                        'Haz clic en una fila para visualizar las existencias.',
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _detailBanner(context, detail),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionTitle(
                                'Información general',
                                Icons.info_outline_rounded,
                              ),
                              const SizedBox(height: 9),
                              _attribute(
                                context,
                                'Tipo de bien',
                                _tipoBienLabel(detail.tipoBien),
                              ),
                              _attribute(
                                context,
                                'Unidad de medida',
                                '${detail.unidadMedidaNombre} (${detail.unidadMedidaCodigo})',
                              ),
                              _attribute(
                                context,
                                'Última actualización',
                                DateFormat(
                                  'dd/MM/yyyy HH:mm',
                                ).format(detail.actualizadoEn.toLocal()),
                              ),
                              const SizedBox(height: 17),
                              _sectionTitle(
                                'Existencias',
                                Icons.inventory_2_outlined,
                              ),
                              const SizedBox(height: 9),
                              Row(
                                children: [
                                  Expanded(
                                    child: _metric(
                                      context,
                                      'Stock actual',
                                      '${detail.cantidadActual.toStringAsFixed(2)} ${detail.unidadMedidaCodigo}',
                                      _accent,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _metric(
                                      context,
                                      'Stock mínimo',
                                      '${detail.stockMinimo.toStringAsFixed(2)} ${detail.unidadMedidaCodigo}',
                                      color.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              _sectionTitle(
                                'Costo promedio',
                                Icons.payments_outlined,
                              ),
                              const SizedBox(height: 9),
                              _metric(
                                context,
                                'Costo unitario vigente',
                                'S/ ${detail.costoPromedioActual.toStringAsFixed(2)}',
                                color.onSurface,
                              ),
                              const SizedBox(height: 15),
                              Row(
                                children: [
                                  const Text(
                                    'Nivel de stock',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const Spacer(),
                                  _Tag(
                                    detail.stockBajo ? 'Stock bajo' : 'Normal',
                                    warning: detail.stockBajo,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: LinearProgressIndicator(
                                  value: detail.stockMinimo <= 0
                                      ? 1
                                      : (detail.cantidadActual /
                                                detail.stockMinimo)
                                            .clamp(0.0, 1.0)
                                            .toDouble(),
                                  minHeight: 7,
                                  color: detail.stockBajo ? _accent : _green,
                                  backgroundColor: color.outlineVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _detailBanner(BuildContext context, StockRecord item) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3D261A), Color(0xFF9B4D25)],
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.science_outlined, color: _accent, size: 29),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CÓDIGO: ${item.codigo}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFFE7CBB9),
                    letterSpacing: .6,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  item.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                _Tag(item.activo ? 'Activo' : 'Inactivo', muted: !item.activo),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) => Row(
    children: [
      Icon(icon, size: 17, color: _accent),
      const SizedBox(width: 7),
      Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
      ),
    ],
  );

  Widget _attribute(BuildContext context, String label, String value) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 11.5, color: colors.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(
    BuildContext context,
    String label,
    String value,
    Color valueColor,
  ) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: colors.surfaceContainerLowest,
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 19,
                color: valueColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileDetailSheet extends StatelessWidget {
  const _MobileDetailSheet();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
    child: Column(
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Detalle de stock',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              tooltip: 'Cerrar',
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        Expanded(
          child: BlocBuilder<StockCubit, StockState>(
            builder: (context, state) => _StockDetailPanel(
              state: state,
              onRetry: () => context.read<StockCubit>().retryDetail(),
            ),
          ),
        ),
      ],
    ),
  );
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child, required this.padding});
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: padding,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.outlineVariant),
      ),
      child: child,
    );
  }
}

class _SectionIcon extends StatelessWidget {
  const _SectionIcon(this.icon);
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    width: 31,
    height: 31,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: _accent.withValues(alpha: .11),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(icon, size: 18, color: _accent),
  );
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, {this.warning = false, this.muted = false});
  final String text;
  final bool warning, muted;
  @override
  Widget build(BuildContext context) {
    final bg = warning
        ? const Color(0xFFFFE7D5)
        : muted
        ? const Color(0xFFE9E9ED)
        : const Color(0xFFDDF5E5);
    final fg = warning
        ? const Color(0xFFB54C13)
        : muted
        ? const Color(0xFF666875)
        : const Color(0xFF116A38);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.detail,
    this.onRetry,
  });
  final IconData icon;
  final String title, detail;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: c.onSurfaceVariant, size: 36),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.onSurfaceVariant, fontSize: 12),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
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

String _tipoBienLabel(String value) {
  final option = inventoryInsumoTipoBienOptions
      .where((item) => item.value == value)
      .firstOrNull;
  return option?.label ?? value;
}
