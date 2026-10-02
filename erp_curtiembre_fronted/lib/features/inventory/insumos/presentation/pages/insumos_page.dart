
import 'dart:async';
import 'dart:math' as math;

import 'package:erp_curtiembre_fronted/core/di/service_locator.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_state.dart';
import 'package:erp_curtiembre_fronted/features/inventory/insumos/domain/constants/insumo_tipo_bien_options.dart';
import 'package:erp_curtiembre_fronted/features/inventory/insumos/domain/entities/insumo_record.dart';
import 'package:erp_curtiembre_fronted/features/inventory/insumos/presentation/cubit/insumos_cubit.dart';
import 'package:erp_curtiembre_fronted/features/inventory/insumos/presentation/cubit/insumos_state.dart';
import 'package:erp_curtiembre_fronted/features/inventory/insumos/presentation/widgets/insumo_upsert_dialog.dart';
import 'package:erp_curtiembre_fronted/features/security/presentation/cubit/security_access_cubit.dart';
import 'package:erp_curtiembre_fronted/shared/navigation/app_access_routes.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/layout/app_shell.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:talker_flutter/talker_flutter.dart';

// =============================================================
// COLORES DEL MODULO
// =============================================================

const Color _orange = Color(0xFFE8590C);
const Color _brown = Color(0xFF482A1C);
const Color _brownLight = Color(0xFF98502A);
const Color _green = Color(0xFF148548);
const Color _greenSoft = Color(0xFFE0F5E7);
const Color _orangeSoft = Color(0xFFFFE9DC);

// =============================================================
// PAGINA PRINCIPAL
// =============================================================

class InsumosPage extends StatefulWidget {
  const InsumosPage({super.key});

  @override
  State<InsumosPage> createState() => _InsumosPageState();
}

class _InsumosPageState extends State<InsumosPage> {
  final TextEditingController _searchController =
      TextEditingController();

  final Talker _talker = getIt<Talker>();

  Timer? _searchDebounce;

  int _page = 0;
  int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _talker.ui('Se abrio la pantalla de insumos.');
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ===========================================================
  // BUSQUEDA
  // ===========================================================

  void _searchAsYouType(String value) {
    _searchDebounce?.cancel();

    setState(() {
      _page = 0;
    });

    _searchDebounce = Timer(
      const Duration(milliseconds: 350),
      () {
        if (!mounted) return;

        final term = value.trim();
        final cubit = context.read<InsumosCubit>();

        if (term == cubit.state.searchTerm) return;

        _talker.ui(
          'Busqueda de insumos: ${term.length} caracteres.',
          logLevel: LogLevel.debug,
        );

        cubit.load(searchTerm: term);
      },
    );
  }

  void _applySearch() {
    _searchDebounce?.cancel();

    if (!mounted) return;

    setState(() {
      _page = 0;
    });

    context.read<InsumosCubit>().load(
      searchTerm: _searchController.text.trim(),
    );
  }

  // ===========================================================
  // SELECCIONAR INSUMO
  // ===========================================================

  void _selectInsumo(
    int insumoId, {
    required bool openMobileDetail,
  }) {
    _talker.ui(
      'Se selecciono el insumo $insumoId.',
      logLevel: LogLevel.debug,
    );

    context.read<InsumosCubit>().selectInsumo(insumoId);

    if (!openMobileDetail) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) {
        return BlocProvider.value(
          value: context.read<InsumosCubit>(),
          child: _MobileInsumoDetailSheet(
            onEdit: () {
              final state = context.read<InsumosCubit>().state;
              final insumo = state.selectedInsumo;

              if (insumo != null) {
                Navigator.of(context).pop();
                _openEditDialog(state, insumo);
              }
            },
            onToggleState: () {
              final insumo =
                  context.read<InsumosCubit>().state.selectedInsumo;

              if (insumo != null) {
                _toggleState(insumo);
              }
            },
          ),
        );
      },
    );
  }

  // ===========================================================
  // CREAR INSUMO
  // ===========================================================

  Future<void> _openCreateDialog(InsumosState state) async {
    _talker.ui('Se abrio el formulario para crear un insumo.');

    final payload = await showDialog<InsumoUpsertFormData>(
      context: context,
      builder: (_) => InsumoUpsertDialog(
        title: 'Nuevo insumo',
        submitLabel: 'Crear insumo',
        unitOptions: state.unitOptions,
        isSubmitting: state.isSubmittingAction,
      ),
    );

    if (payload == null || !mounted) return;

    final result = await context.read<InsumosCubit>().createInsumo(
      codigo: payload.codigo,
      nombre: payload.nombre,
      tipoBien: payload.tipoBien,
      presentacion: payload.presentacion,
      unidadMedidaId: payload.unidadMedidaId,
      stockMinimo: payload.stockMinimo,
      requiereLote: payload.requiereLote,
    );

    if (!mounted) return;

    _showActionResult(result);
  }

  // ===========================================================
  // EDITAR INSUMO
  // ===========================================================

  Future<void> _openEditDialog(
    InsumosState state,
    InsumoRecord insumo,
  ) async {
    _talker.ui(
      'Se abrio la edicion del insumo ${insumo.id}.',
      logLevel: LogLevel.warning,
    );

    final payload = await showDialog<InsumoUpsertFormData>(
      context: context,
      builder: (_) => InsumoUpsertDialog(
        title: 'Editar insumo',
        submitLabel: 'Guardar cambios',
        unitOptions: state.unitOptions,
        isSubmitting: state.isSubmittingAction,
        initialInsumo: insumo,
      ),
    );

    if (payload == null || !mounted) return;

    final result =
        await context.read<InsumosCubit>().updateSelectedInsumo(
          codigo: payload.codigo,
          nombre: payload.nombre,
          tipoBien: payload.tipoBien,
          presentacion: payload.presentacion,
          unidadMedidaId: payload.unidadMedidaId,
          stockMinimo: payload.stockMinimo,
          requiereLote: payload.requiereLote,
        );

    if (!mounted) return;

    _showActionResult(result);
  }

  // ===========================================================
  // ACTIVAR / INACTIVAR
  // ===========================================================

  Future<void> _toggleState(InsumoRecord insumo) async {
    if (context.read<InsumosCubit>().state.isSubmittingAction) {
      return;
    }

    _talker.ui(
      'Cambio de estado solicitado para insumo ${insumo.id}.',
      logLevel: LogLevel.warning,
    );

    final result =
        await context.read<InsumosCubit>().setSelectedInsumoActive(
          !insumo.activo,
        );

    if (!mounted) return;

    _showActionResult(result);
  }

  void _showActionResult(InsumosActionResult result) {
    _talker.ui(
      result.success
          ? 'Accion de insumos completada correctamente.'
          : 'Error en insumos: ${result.message}',
      logLevel: result.success
          ? LogLevel.debug
          : LogLevel.error,
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

  // ===========================================================
  // CONSTRUCCION DE PANTALLA
  // ===========================================================

  @override
  Widget build(BuildContext context) {
    final session = context.select(
      (AuthCubit cubit) => cubit.state.session,
    );

    final signingOut = context.select(
      (AuthCubit cubit) =>
          cubit.state.status == AuthStatus.signingOut,
    );

    final permissions = context.select(
      (SecurityAccessCubit cubit) =>
          cubit.state.snapshot?.userPermissionCodes.toSet() ??
          const <String>{},
    );

    if (session == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return AppShell(
      title: 'Insumos',
      currentPath: '/inventario/insumos',
      breadcrumbs: const [
        'Inicio',
        'Inventario',
        'Insumos',
      ],
      userName: session.nombreCompleto,
      roleName: session.rolNombre,
      accessibleRoutes:
          AppAccessRoutes.forPermissions(permissions),
      onSignOut: signingOut
          ? () {}
          : () => context.read<AuthCubit>().signOut(),
      child: BlocBuilder<InsumosCubit, InsumosState>(
        builder: (context, state) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final mobile = constraints.maxWidth < 760;
              final sideBySide = constraints.maxWidth >= 1100;

              final total = state.items.length;

              final pages = math.max(
                1,
                (total / _pageSize).ceil(),
              );

              final safePage = _page.clamp(0, pages - 1).toInt();

              final start = safePage * _pageSize;

              final end = math.min(
                start + _pageSize,
                total,
              );

              final visibleItems = state.items.sublist(
                start,
                end,
              );

              final listPanel = _InsumosListPanel(
                items: visibleItems,
                total: total,
                status: state.status,
                error: state.errorMessage,
                selectedId: state.selectedInsumoId,
                page: safePage,
                totalPages: pages,
                pageSize: _pageSize,
                start: start,
                end: end,
                compact: mobile,
                onSelect: (id) => _selectInsumo(
                  id,
                  openMobileDetail: mobile,
                ),
                onRetry: () =>
                    context.read<InsumosCubit>().initialize(),
                onPage: (value) {
                  setState(() => _page = value);
                },
                onPageSize: (value) {
                  setState(() {
                    _pageSize = value;
                    _page = 0;
                  });
                },
              );

              final detailPanel = _InsumoDetailPanel(
                state: state,
                onRetry: () =>
                    context.read<InsumosCubit>().retryDetail(),
                onEdit: state.selectedInsumo == null ||
                        state.isSubmittingAction
                    ? null
                    : () => _openEditDialog(
                          state,
                          state.selectedInsumo!,
                        ),
                onToggleState: state.selectedInsumo == null ||
                        state.isSubmittingAction
                    ? null
                    : () => _toggleState(
                          state.selectedInsumo!,
                        ),
              );

              return Padding(
                padding: EdgeInsets.fromLTRB(
                  mobile ? 12 : 18,
                  mobile ? 12 : 14,
                  mobile ? 12 : 18,
                  mobile ? 12 : 16,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 1600,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [
                        _InsumosFilters(
                          state: state,
                          controller: _searchController,
                          mobile: mobile,
                          onChanged: _searchAsYouType,
                          onSearch: _applySearch,
                          onCreate: () =>
                              _openCreateDialog(state),
                          onActivity: (value) {
                            setState(() => _page = 0);

                            context.read<InsumosCubit>().load(
                              activityFilter: value,
                            );
                          },
                          onType: (value) {
                            setState(() => _page = 0);

                            context.read<InsumosCubit>().load(
                              tipoBienFilter: value,
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        Expanded(
                          child: sideBySide
                              ? Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      flex: 12,
                                      child: listPanel,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      flex: 8,
                                      child: detailPanel,
                                    ),
                                  ],
                                )
                              : mobile
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
                                            height: 600,
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

// =============================================================
// FILTROS
// =============================================================

class _InsumosFilters extends StatelessWidget {
  const _InsumosFilters({
    required this.state,
    required this.controller,
    required this.mobile,
    required this.onChanged,
    required this.onSearch,
    required this.onCreate,
    required this.onActivity,
    required this.onType,
  });

  final InsumosState state;
  final TextEditingController controller;
  final bool mobile;

  final ValueChanged<String> onChanged;
  final VoidCallback onSearch;
  final VoidCallback onCreate;

  final ValueChanged<InsumoActivityFilter> onActivity;
  final ValueChanged<String?> onType;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final search = TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: (_) => onSearch(),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Buscar por código o nombre de insumo...',
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 21,
        ),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (controller.text.isNotEmpty)
              IconButton(
                tooltip: 'Limpiar búsqueda',
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
                icon: const Icon(
                  Icons.close_rounded,
                  size: 19,
                ),
              ),
            if (state.status == InsumosStatus.loading)
              const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              )
            else
              IconButton(
                tooltip: 'Buscar',
                onPressed: onSearch,
                icon: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 20,
                ),
              ),
          ],
        ),
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: colors.outlineVariant,
          ),
        ),
      ),
    );

    final typeFilter = DropdownMenu<String>(
      key: ValueKey(
        state.tipoBienFilter ?? '__all_types__',
      ),
      width: mobile ? 220 : 210,
      menuHeight: 280,
      enableFilter: true,
      enableSearch: true,
      requestFocusOnTap: true,
      initialSelection:
          state.tipoBienFilter ?? '__all_types__',
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        isDense: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: colors.outlineVariant,
          ),
        ),
      ),
      dropdownMenuEntries: [
        const DropdownMenuEntry(
          value: '__all_types__',
          label: 'Todos los tipos',
        ),
        ...inventoryInsumoTipoBienOptions.map(
          (option) => DropdownMenuEntry(
            value: option.value,
            label: option.label,
          ),
        ),
      ],
      onSelected: (value) {
        if (value == null) return;

        onType(
          value == '__all_types__' ? null : value,
        );
      },
    );

    final activity = SegmentedButton<InsumoActivityFilter>(
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? _orange
              : null,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : colors.onSurface,
        ),
      ),
      segments: const [
        ButtonSegment(
          value: InsumoActivityFilter.all,
          label: Text('Todos'),
        ),
        ButtonSegment(
          value: InsumoActivityFilter.active,
          label: Text('Activos'),
        ),
        ButtonSegment(
          value: InsumoActivityFilter.inactive,
          label: Text('Inactivos'),
        ),
      ],
      selected: {state.activityFilter},
      onSelectionChanged: (selection) {
        onActivity(selection.first);
      },
    );

    final createButton = FilledButton.icon(
      onPressed: state.unitOptions.isEmpty ||
              state.isSubmittingAction
          ? null
          : onCreate,
      icon: const Icon(
        Icons.add_circle_outline_rounded,
        size: 20,
      ),
      label: const Text('Nuevo insumo'),
      style: FilledButton.styleFrom(
        backgroundColor: _orange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: 19,
          vertical: 17,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );

    return _Surface(
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 1080) {
            return Row(
              children: [
                Expanded(child: search),
                const SizedBox(width: 12),
                typeFilter,
                const SizedBox(width: 12),
                activity,
                const SizedBox(width: 12),
                createButton,
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
                runSpacing: 10,
                crossAxisAlignment:
                    WrapCrossAlignment.center,
                children: [
                  typeFilter,
                  activity,
                  createButton,
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

// =============================================================
// LISTADO DE INSUMOS
// =============================================================

class _InsumosListPanel extends StatelessWidget {
  const _InsumosListPanel({
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

  final List<InsumoRecord> items;
  final int total;
  final InsumosStatus status;
  final String? error;
  final int? selectedId;

  final int page;
  final int totalPages;
  final int pageSize;
  final int start;
  final int end;

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
          // ENCABEZADO
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 13,
            ),
            child: Row(
              children: [
                const _SectionIcon(
                  Icons.inventory_2_outlined,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Lista de insumos',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  '$total ${total == 1 ? 'resultado' : 'resultados'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: scheme.outlineVariant,
          ),

          // CONTENIDO
          Expanded(
            child: switch (status) {
              InsumosStatus.loading => const Center(
                  child: CircularProgressIndicator(),
                ),
              InsumosStatus.error => _EmptyMessage(
                  icon: Icons.error_outline_rounded,
                  title: 'No pudimos cargar los insumos',
                  description: error ?? 'Intenta nuevamente.',
                  onRetry: onRetry,
                ),
              InsumosStatus.success => total == 0
                  ? const _EmptyMessage(
                      icon: Icons.search_off_rounded,
                      title: 'Sin resultados',
                      description:
                          'No encontramos registros con los filtros actuales.',
                    )
                  : compact
                      ? ListView.separated(
                          itemCount: items.length,
                          padding: const EdgeInsets.all(10),
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = items[index];

                            return _InsumoMobileTile(
                              item: item,
                              selected:
                                  item.id == selectedId,
                              onTap: () => onSelect(item.id),
                            );
                          },
                        )
                      : _buildTable(context),
            },
          ),

          Divider(
            height: 1,
            color: scheme.outlineVariant,
          ),

          _buildPagination(context),
        ],
      ),
    );
  }

  // ===========================================================
  // TABLA DE ESCRITORIO
  // ===========================================================

  Widget _buildTable(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: math.max(
              720,
              constraints.maxWidth,
            ),
            child: Column(
              children: [
                _buildTableHeader(context),
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return _buildTableRow(
                        context,
                        items[index],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static const List<int> _widths = [
    100,
    205,
    145,
    145,
    105,
    80,
  ];

  Widget _buildTableHeader(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    const headers = [
      'Código',
      'Insumo',
      'Tipo de bien',
      'Unidad',
      'Estado',
      'Acciones',
    ];

    return Container(
      color: colors.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 13,
      ),
      child: Row(
        children: [
          for (int i = 0; i < headers.length; i++)
            Expanded(
              flex: _widths[i],
              child: Text(
                headers[i],
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                  fontSize: 11.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTableRow(
    BuildContext context,
    InsumoRecord item,
  ) {
    final colors = Theme.of(context).colorScheme;
    final selected = item.id == selectedId;

    Widget cell(
      String text,
      int index, {
      bool bold = false,
      Color? textColor,
    }) {
      return Expanded(
        flex: _widths[index],
        child: Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight:
                  bold ? FontWeight.w700 : FontWeight.w500,
              color: textColor ?? colors.onSurface,
            ),
          ),
        ),
      );
    }

    return Material(
      color: selected
          ? _orange.withValues(alpha: 0.085)
          : Colors.transparent,
      child: InkWell(
        onTap: () => onSelect(item.id),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            10,
            12,
            10,
            12,
          ),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: selected ? _orange : Colors.transparent,
                width: 3,
              ),
              bottom: BorderSide(
                color: colors.outlineVariant.withValues(
                  alpha: 0.65,
                ),
              ),
            ),
          ),
          child: Row(
            children: [
              cell(
                item.codigo,
                0,
                bold: true,
                textColor: selected ? _orange : null,
              ),
              cell(
                item.nombre,
                1,
                bold: true,
              ),
              Expanded(
                flex: _widths[2],
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _TypePill(
                    _tipoBienLabel(item.tipoBien),
                  ),
                ),
              ),
              cell(
                '${item.unidadMedidaNombre} (${item.unidadMedidaCodigo})',
                3,
              ),
              Expanded(
                flex: _widths[4],
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _StatusPill(
                    item.activo ? 'Activo' : 'Inactivo',
                    active: item.activo,
                  ),
                ),
              ),
              Expanded(
                flex: _widths[5],
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    tooltip: 'Ver detalle de ${item.nombre}',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => onSelect(item.id),
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================
  // PAGINACION
  // ===========================================================

  Widget _buildPagination(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 10,
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Mostrar',
                style: TextStyle(fontSize: 11.5),
              ),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: pageSize,
                isDense: true,
                underline: const SizedBox.shrink(),
                items: const [10, 20, 50]
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text('$value'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    onPageSize(value);
                  }
                },
              ),
              const SizedBox(width: 7),
              const Text(
                'por página',
                style: TextStyle(fontSize: 11.5),
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
                  fontSize: 11.5,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 9),
              IconButton.outlined(
                tooltip: 'Anterior',
                visualDensity: VisualDensity.compact,
                onPressed:
                    page == 0 ? null : () => onPage(page - 1),
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  size: 19,
                ),
              ),
              const SizedBox(width: 5),
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${page + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              IconButton.outlined(
                tooltip: 'Siguiente',
                visualDensity: VisualDensity.compact,
                onPressed: page + 1 >= totalPages
                    ? null
                    : () => onPage(page + 1),
                icon: const Icon(
                  Icons.chevron_right_rounded,
                  size: 19,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================
// TARJETA PARA MOVILES
// =============================================================

class _InsumoMobileTile extends StatelessWidget {
  const _InsumoMobileTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final InsumoRecord item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: selected
                ? _orange.withValues(alpha: 0.08)
                : colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: selected
                  ? _orange.withValues(alpha: 0.55)
                  : colors.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              const _SectionIcon(
                Icons.science_outlined,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.codigo,
                      style: const TextStyle(
                        color: _orange,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _tipoBienLabel(item.tipoBien),
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusPill(
                item.activo ? 'Activo' : 'Inactivo',
                active: item.activo,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================
// PANEL DE DETALLE
// =============================================================

class _InsumoDetailPanel extends StatelessWidget {
  const _InsumoDetailPanel({
    required this.state,
    required this.onRetry,
    required this.onEdit,
    required this.onToggleState,
  });

  final InsumosState state;

  final VoidCallback onRetry;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleState;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final insumo = state.selectedInsumo;

    return _Surface(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ENCABEZADO
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 12,
            ),
            child: Row(
              children: [
                const _SectionIcon(
                  Icons.folder_copy_outlined,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Detalle del insumo',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (insumo != null &&
                    !state.isDetailLoading)
                  OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 16,
                    ),
                    label: const Text('Editar'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: colors.onSurface,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
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
            child: state.isDetailLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : state.detailErrorMessage != null
                    ? _EmptyMessage(
                        icon: Icons.error_outline,
                        title: 'No pudimos cargar el detalle',
                        description:
                            state.detailErrorMessage!,
                        onRetry: onRetry,
                      )
                    : insumo == null
                        ? const _EmptyMessage(
                            icon: Icons.touch_app_outlined,
                            title: 'Selecciona un insumo',
                            description:
                                'Escoge un registro de la lista para consultar su ficha.',
                          )
                        : SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                              children: [
                                _buildLeatherHeader(
                                  context,
                                  insumo,
                                ),
                                _buildInsumoInformation(
                                  context,
                                  insumo,
                                ),
                              ],
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  // CABECERA COLOR CUERO
  // ===========================================================

  Widget _buildLeatherHeader(
    BuildContext context,
    InsumoRecord insumo,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 19,
        vertical: 24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.bottomRight,
          colors: [
            _brown,
            Color(0xFF713B23),
            _brownLight,
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 62,
            height: 62,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.science_outlined,
              size: 33,
              color: _orange,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'CÓDIGO: ${insumo.codigo}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.65,
                    color: Color(0xFFEAD4C6),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  insumo.nombre,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 9),
                _StatusPill(
                  insumo.activo ? 'Activo' : 'Inactivo',
                  active: insumo.activo,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  // INFORMACION DEL INSUMO
  // ===========================================================

  Widget _buildInsumoInformation(
    BuildContext context,
    InsumoRecord insumo,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _DetailTitle(
            icon: Icons.folder_open_outlined,
            label: 'Información general',
          ),

          const SizedBox(height: 13),

          _InformationGrid(
            children: [
              _InfoItem(
                label: 'Tipo de bien',
                value: _tipoBienLabel(
                  insumo.tipoBien,
                ),
                highlight: true,
              ),
              _InfoItem(
                label: 'Unidad de medida',
                value:
                    '${insumo.unidadMedidaNombre} (${insumo.unidadMedidaCodigo})',
              ),
              _InfoItem(
                label: 'Presentación',
                value:
                    insumo.presentacion?.trim().isNotEmpty == true
                        ? insumo.presentacion!
                        : 'Sin presentación',
              ),
              _InfoItem(
                label: 'Control de lote',
                value: insumo.requiereLote
                    ? 'Requerido'
                    : 'No requerido',
              ),
              _InfoItem(
                label: 'Fecha de creación',
                value: _formatDateTime(
                  insumo.creadoEn,
                ),
              ),
              _InfoItem(
                label: 'Última actualización',
                value: _formatOptionalDate(
                  insumo.actualizadoEn,
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          const _DetailTitle(
            icon: Icons.check_circle_outline_rounded,
            label: 'Estado',
          ),

          const SizedBox(height: 12),

          _buildStateCard(context, insumo),

          const SizedBox(height: 17),

          // ACCION REAL DEL CUBIT
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onToggleState,
              icon: Icon(
                insumo.activo
                    ? Icons.block_outlined
                    : Icons.check_circle_outline_rounded,
                size: 18,
              ),
              label: Text(
                insumo.activo
                    ? 'Inactivar insumo'
                    : 'Activar insumo',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    insumo.activo ? colorsForState(context) : _green,
                padding: const EdgeInsets.symmetric(
                  vertical: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color colorsForState(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  Widget _buildStateCard(
    BuildContext context,
    InsumoRecord insumo,
  ) {
    final active = insumo.activo;

    final background = active
        ? const Color(0xFFEAF8EF)
        : const Color(0xFFF1F1F3);

    final foreground = active
        ? _green
        : const Color(0xFF6F7177);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: foreground.withValues(alpha: 0.13),
        ),
      ),
      child: Row(
        children: [
          Icon(
            active
                ? Icons.check_circle_rounded
                : Icons.block_rounded,
            color: foreground,
            size: 23,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  active
                      ? 'Insumo activo'
                      : 'Insumo inactivo',
                  style: TextStyle(
                    color: foreground,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  active
                      ? 'Este insumo se encuentra habilitado para su uso.'
                      : 'Este insumo se encuentra deshabilitado.',
                  style: TextStyle(
                    color: foreground.withValues(
                      alpha: 0.85,
                    ),
                    fontSize: 11.5,
                    height: 1.5,
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

// =============================================================
// PANEL DE INFORMACION ORGANIZADA
// =============================================================

class _InformationGrid extends StatelessWidget {
  const _InformationGrid({
    required this.children,
  });

  final List<_InfoItem> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colors.outlineVariant,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns =
              constraints.maxWidth >= 350 ? 2 : 1;

          return Column(
            children: [
              for (
                var start = 0;
                start < children.length;
                start += columns
              )
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      for (
                        var col = 0;
                        col < columns;
                        col++
                      ) ...[
                        if (col > 0)
                          VerticalDivider(
                            width: 1,
                            thickness: 1,
                            color: colors.outlineVariant,
                          ),
                        Expanded(
                          child: start + col < children.length
                              ? children[start + col]
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colors.outlineVariant.withValues(
              alpha: 0.6,
            ),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 10.8,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.8,
              fontWeight: FontWeight.w700,
              color: highlight
                  ? _orange
                  : colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// DETALLE EMERGENTE PARA MOVIL
// =============================================================

class _MobileInsumoDetailSheet extends StatelessWidget {
  const _MobileInsumoDetailSheet({
    required this.onEdit,
    required this.onToggleState,
  });

  final VoidCallback onEdit;
  final VoidCallback onToggleState;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.88,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          12,
          10,
          12,
          12,
        ),
        child: Column(
          children: [
            Container(
              height: 4,
              width: 42,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .outlineVariant,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Detalle del insumo',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar',
                  onPressed: () =>
                      Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: BlocBuilder<InsumosCubit, InsumosState>(
                builder: (context, state) {
                  return _InsumoDetailPanel(
                    state: state,
                    onRetry: () => context
                        .read<InsumosCubit>()
                        .retryDetail(),
                    onEdit:
                        state.selectedInsumo == null ||
                                state.isSubmittingAction
                            ? null
                            : onEdit,
                    onToggleState:
                        state.selectedInsumo == null ||
                                state.isSubmittingAction
                            ? null
                            : onToggleState,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// COMPONENTES VISUALES
// =============================================================

class _Surface extends StatelessWidget {
  const _Surface({
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
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: colors.outlineVariant,
        ),
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
      width: 33,
      height: 33,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _orangeSoft,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(
        icon,
        size: 18,
        color: _orange,
      ),
    );
  }
}

class _DetailTitle extends StatelessWidget {
  const _DetailTitle({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: _orange,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(
    this.label, {
    required this.active,
  });

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final background =
        active ? _greenSoft : const Color(0xFFECEDEF);

    final foreground =
        active ? const Color(0xFF146739) : const Color(0xFF656971);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
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
          fontSize: 10.8,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _TypePill extends StatelessWidget {
  const _TypePill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 140,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF2FA),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: const Color(0xFFDCE5F3),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF455974),
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({
    required this.icon,
    required this.title,
    required this.description,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 38,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: colors.onSurfaceVariant,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 18,
                ),
                label: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// =============================================================
// FUNCIONES AUXILIARES
// =============================================================

String _tipoBienLabel(String value) {
  final option = inventoryInsumoTipoBienOptions
      .where((item) => item.value == value)
      .firstOrNull;

  return option?.label ?? value;
}

String _formatDateTime(DateTime value) {
  return DateFormat(
    'dd/MM/yyyy hh:mm a',
  ).format(value.toLocal());
}

String _formatOptionalDate(DateTime? value) {
  if (value == null) {
    return 'Sin registro';
  }

  return _formatDateTime(value);
}
