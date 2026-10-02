import 'dart:async';
import 'dart:math' as math;

import 'package:erp_curtiembre_fronted/core/di/service_locator.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_state.dart';
import 'package:erp_curtiembre_fronted/features/inventory/proveedores/domain/entities/proveedor_record.dart';
import 'package:erp_curtiembre_fronted/features/inventory/proveedores/presentation/cubit/proveedores_cubit.dart';
import 'package:erp_curtiembre_fronted/features/inventory/proveedores/presentation/cubit/proveedores_state.dart';
import 'package:erp_curtiembre_fronted/features/inventory/proveedores/presentation/widgets/proveedor_upsert_dialog.dart';
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
const Color _orangeSoft = Color(0xFFFFE8DA);

const Color _brown = Color(0xFF362016);
const Color _brownMedium = Color(0xFF71371E);
const Color _brownLight = Color(0xFFA4512B);

const Color _greenSoft = Color(0xFFE0F5E7);

const Color _graySoft = Color(0xFFEEEEF0);

// =============================================================
// PAGINA PRINCIPAL
// =============================================================

class ProveedoresPage extends StatefulWidget {
  const ProveedoresPage({super.key});

  @override
  State<ProveedoresPage> createState() => _ProveedoresPageState();
}

class _ProveedoresPageState extends State<ProveedoresPage> {
  final TextEditingController _searchController = TextEditingController();

  final Talker _talker = getIt<Talker>();

  Timer? _debounce;

  int _page = 0;
  int _pageSize = 10;

  @override
  void initState() {
    super.initState();

    _talker.ui('Se abrio la pantalla de proveedores.');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();

    super.dispose();
  }

  // ===========================================================
  // BUSQUEDA INCREMENTAL
  // ===========================================================

  void _searchAsYouType(String value) {
    _debounce?.cancel();

    setState(() {
      _page = 0;
    });

    _debounce = Timer(const Duration(milliseconds: 380), () {
      if (!mounted) return;

      final searchTerm = value.trim();

      final cubit = context.read<ProveedoresCubit>();

      if (searchTerm == cubit.state.searchTerm) {
        return;
      }

      _talker.ui(
        'Busqueda de proveedores: ${searchTerm.length} caracteres.',
        logLevel: LogLevel.debug,
      );

      cubit.load(searchTerm: searchTerm);
    });
  }

  void _applySearch() {
    _debounce?.cancel();

    if (!mounted) return;

    setState(() {
      _page = 0;
    });

    context.read<ProveedoresCubit>().load(
      searchTerm: _searchController.text.trim(),
    );
  }

  // ===========================================================
  // SELECCIONAR PROVEEDOR
  // ===========================================================

  void _selectProveedor(int proveedorId, {required bool openMobileDetail}) {
    _talker.ui(
      'Se selecciono el proveedor $proveedorId.',
      logLevel: LogLevel.debug,
    );

    context.read<ProveedoresCubit>().selectProveedor(proveedorId);

    if (!openMobileDetail) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) {
        return BlocProvider.value(
          value: context.read<ProveedoresCubit>(),
          child: _MobileProveedorDetailSheet(
            onEdit: () {
              final state = context.read<ProveedoresCubit>().state;

              final proveedor = state.selectedProveedor;

              if (proveedor != null) {
                Navigator.of(context).pop();
                _openEditDialog(state, proveedor);
              }
            },
            onToggleState: () {
              final proveedor = context
                  .read<ProveedoresCubit>()
                  .state
                  .selectedProveedor;

              if (proveedor != null) {
                _toggleState(proveedor);
              }
            },
          ),
        );
      },
    );
  }

  // ===========================================================
  // NUEVO PROVEEDOR
  // ===========================================================

  Future<void> _openCreateDialog(ProveedoresState state) async {
    _talker.ui('Se abrio el formulario para crear un proveedor.');

    final payload = await showDialog<ProveedorUpsertFormData>(
      context: context,
      builder: (_) => ProveedorUpsertDialog(
        title: 'Nuevo proveedor',
        submitLabel: 'Crear proveedor',
        isSubmitting: state.isSubmittingAction,
      ),
    );

    if (payload == null || !mounted) return;

    final result = await context.read<ProveedoresCubit>().createProveedor(
      rucDocumento: payload.rucDocumento,
      razonSocial: payload.razonSocial,
      direccion: payload.direccion,
      telefono: payload.telefono,
      correo: payload.correo,
      contacto: payload.contacto,
    );

    if (!mounted) return;

    _showActionResult(result);
  }

  // ===========================================================
  // EDITAR PROVEEDOR
  // ===========================================================

  Future<void> _openEditDialog(
    ProveedoresState state,
    ProveedorRecord proveedor,
  ) async {
    _talker.ui(
      'Se abrio la edicion del proveedor ${proveedor.id}.',
      logLevel: LogLevel.warning,
    );

    final payload = await showDialog<ProveedorUpsertFormData>(
      context: context,
      builder: (_) => ProveedorUpsertDialog(
        title: 'Editar proveedor',
        submitLabel: 'Guardar cambios',
        isSubmitting: state.isSubmittingAction,
        initialProveedor: proveedor,
      ),
    );

    if (payload == null || !mounted) return;

    final result = await context
        .read<ProveedoresCubit>()
        .updateSelectedProveedor(
          rucDocumento: payload.rucDocumento,
          razonSocial: payload.razonSocial,
          direccion: payload.direccion,
          telefono: payload.telefono,
          correo: payload.correo,
          contacto: payload.contacto,
        );

    if (!mounted) return;

    _showActionResult(result);
  }

  // ===========================================================
  // ACTIVAR / INACTIVAR PROVEEDOR
  // ===========================================================

  Future<void> _toggleState(ProveedorRecord proveedor) async {
    if (context.read<ProveedoresCubit>().state.isSubmittingAction) {
      return;
    }

    _talker.ui(
      'Se solicito el cambio de estado del proveedor ${proveedor.id}.',
      logLevel: LogLevel.warning,
    );

    final result = await context
        .read<ProveedoresCubit>()
        .setSelectedProveedorActive(!proveedor.activo);

    if (!mounted) return;

    _showActionResult(result);
  }

  // ===========================================================
  // RESULTADO DE LAS OPERACIONES
  // ===========================================================

  void _showActionResult(ProveedoresActionResult result) {
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

  // ===========================================================
  // CONSTRUCCION DE LA PANTALLA
  // ===========================================================

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
      title: 'Proveedores',
      currentPath: '/inventario/proveedores',
      breadcrumbs: const ['Inicio', 'Inventario', 'Proveedores'],
      userName: session.nombreCompleto,
      roleName: session.rolNombre,
      accessibleRoutes: AppAccessRoutes.forPermissions(permissionCodes),
      onSignOut: signingOut ? () {} : () => context.read<AuthCubit>().signOut(),
      child: BlocBuilder<ProveedoresCubit, ProveedoresState>(
        builder: (context, state) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final mobile = constraints.maxWidth < 760;

              final sideBySide = constraints.maxWidth >= 1080;

              final total = state.items.length;

              final totalPages = math.max(1, (total / _pageSize).ceil());

              final safePage = _page.clamp(0, totalPages - 1).toInt();

              final start = safePage * _pageSize;

              final end = math.min(start + _pageSize, total);

              final visibleItems = state.items.sublist(start, end);

              // ===========================================
              // LISTADO
              // ===========================================

              final listPanel = _ProveedoresListPanel(
                items: visibleItems,
                total: total,
                status: state.status,
                error: state.errorMessage,
                selectedId: state.selectedProveedorId,
                page: safePage,
                totalPages: totalPages,
                pageSize: _pageSize,
                start: start,
                end: end,
                compact: mobile,
                onSelect: (id) =>
                    _selectProveedor(id, openMobileDetail: mobile),
                onRetry: () => context.read<ProveedoresCubit>().initialize(),
                onPage: (value) {
                  setState(() {
                    _page = value;
                  });
                },
                onPageSize: (value) {
                  setState(() {
                    _pageSize = value;
                    _page = 0;
                  });
                },
              );

              // ===========================================
              // DETALLE
              // ===========================================

              final detailPanel = _ProveedorDetailPanel(
                state: state,
                onRetry: () => context.read<ProveedoresCubit>().retryDetail(),
                onEdit:
                    state.selectedProveedor == null || state.isSubmittingAction
                    ? null
                    : () => _openEditDialog(state, state.selectedProveedor!),
                onToggleState:
                    state.selectedProveedor == null || state.isSubmittingAction
                    ? null
                    : () => _toggleState(state.selectedProveedor!),
              );

              // ===========================================
              // DISTRIBUCION GENERAL
              // ===========================================

              return Padding(
                padding: EdgeInsets.fromLTRB(
                  mobile ? 12 : 18,
                  mobile ? 12 : 14,
                  mobile ? 12 : 18,
                  mobile ? 12 : 16,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ProveedoresFilters(
                          state: state,
                          controller: _searchController,
                          mobile: mobile,
                          onChanged: _searchAsYouType,
                          onSearch: _applySearch,
                          onCreate: () => _openCreateDialog(state),
                          onActivity: (value) {
                            setState(() {
                              _page = 0;
                            });

                            context.read<ProveedoresCubit>().load(
                              filter: value,
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
                                    Expanded(flex: 12, child: listPanel),

                                    const SizedBox(width: 14),

                                    Expanded(flex: 8, child: detailPanel),
                                  ],
                                )
                              : mobile
                              ? listPanel
                              : SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      SizedBox(height: 480, child: listPanel),

                                      const SizedBox(height: 14),

                                      SizedBox(height: 650, child: detailPanel),
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
// BARRA DE BUSQUEDA Y FILTROS
// =============================================================

class _ProveedoresFilters extends StatelessWidget {
  const _ProveedoresFilters({
    required this.state,
    required this.controller,
    required this.mobile,
    required this.onChanged,
    required this.onSearch,
    required this.onCreate,
    required this.onActivity,
  });

  final ProveedoresState state;
  final TextEditingController controller;
  final bool mobile;

  final ValueChanged<String> onChanged;
  final VoidCallback onSearch;
  final VoidCallback onCreate;

  final ValueChanged<ProveedorActivityFilter> onActivity;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // ===========================================
    // BUSCADOR
    // ===========================================

    final search = TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: (_) => onSearch(),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Buscar por RUC, razón social o contacto...',
        prefixIcon: const Icon(Icons.search_rounded, size: 21),
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
                icon: const Icon(Icons.close_rounded, size: 19),
              ),

            if (state.status == ProveedoresStatus.loading)
              const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              IconButton(
                tooltip: 'Aplicar búsqueda',
                onPressed: onSearch,
                icon: const Icon(Icons.arrow_forward_rounded, size: 20),
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
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
      ),
    );

    // ===========================================
    // FILTRO DE ESTADO
    // ===========================================

    final activity = SegmentedButton<ProveedorActivityFilter>(
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? _orange : null,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : colors.onSurface,
        ),
      ),
      segments: const [
        ButtonSegment(value: ProveedorActivityFilter.all, label: Text('Todos')),
        ButtonSegment(
          value: ProveedorActivityFilter.active,
          label: Text('Activos'),
        ),
        ButtonSegment(
          value: ProveedorActivityFilter.inactive,
          label: Text('Inactivos'),
        ),
      ],
      selected: {state.filter},
      onSelectionChanged: (selection) {
        onActivity(selection.first);
      },
    );

    // ===========================================
    // NUEVO PROVEEDOR
    // ===========================================

    final createButton = FilledButton.icon(
      onPressed: state.isSubmittingAction ? null : onCreate,
      icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
      label: const Text('Nuevo proveedor'),
      style: FilledButton.styleFrom(
        backgroundColor: _orange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 17),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    // ===========================================
    // DISTRIBUCION RESPONSIVE
    // ===========================================

    return _PanelSurface(
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 900) {
            return Row(
              children: [
                Expanded(child: search),
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
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [activity, createButton],
              ),
            ],
          );
        },
      ),
    );
  }
}

// =============================================================
// LISTADO DE PROVEEDORES
// =============================================================

class _ProveedoresListPanel extends StatelessWidget {
  const _ProveedoresListPanel({
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

  final List<ProveedorRecord> items;

  final int total;
  final ProveedoresStatus status;
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
    final colors = Theme.of(context).colorScheme;

    return _PanelSurface(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // ===========================================
          // CABECERA DE LA LISTA
          // ===========================================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                const _SectionIcon(Icons.local_shipping_outlined),

                const SizedBox(width: 10),

                const Expanded(
                  child: Text(
                    'Lista de proveedores',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),

                Text(
                  '$total ${total == 1 ? 'resultado' : 'resultados'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: colors.outlineVariant),

          // ===========================================
          // RESULTADOS
          // ===========================================
          Expanded(
            child: switch (status) {
              ProveedoresStatus.loading => const Center(
                child: CircularProgressIndicator(),
              ),

              ProveedoresStatus.error => _EmptyMessage(
                icon: Icons.error_outline_rounded,
                title: 'No pudimos cargar los proveedores',
                description: error ?? 'Intenta nuevamente.',
                onRetry: onRetry,
              ),

              ProveedoresStatus.success =>
                total == 0
                    ? const _EmptyMessage(
                        icon: Icons.search_off_rounded,
                        title: 'Sin resultados',
                        description:
                            'No encontramos proveedores con los filtros actuales.',
                      )
                    : compact
                    ? _buildMobileList(context)
                    : _buildDesktopTable(context),
            },
          ),

          Divider(height: 1, color: colors.outlineVariant),

          // ===========================================
          // PIE Y PAGINACION
          // ===========================================
          _buildPagination(context),
        ],
      ),
    );
  }

  // ===========================================================
  // LISTA MOVIL
  // ===========================================================

  Widget _buildMobileList(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(10),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];

        return _ProveedorMobileTile(
          item: item,
          selected: item.id == selectedId,
          onTap: () => onSelect(item.id),
        );
      },
    );
  }

  // ===========================================================
  // TABLA ESCRITORIO
  // ===========================================================

  Widget _buildDesktopTable(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: math.max(690, constraints.maxWidth),
            child: Column(
              children: [
                _buildTableHeader(context),

                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return _buildTableRow(context, items[index]);
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

  // PROPORCIONES INTERNAS DE CADA COLUMNA
  static const List<int> _widths = [160, 285, 145, 105, 75];

  Widget _buildTableHeader(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    const headers = ['RUC', 'Razón social', 'Contacto', 'Estado', 'Acciones'];

    return Container(
      color: colors.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
      child: Row(
        children: [
          for (int i = 0; i < headers.length; i++)
            Expanded(
              flex: _widths[i],
              child: Text(
                headers[i],
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, ProveedorRecord item) {
    final colors = Theme.of(context).colorScheme;

    final selected = item.id == selectedId;

    Widget cell(
      String value,
      int index, {
      bool bold = false,
      Color? textColor,
    }) {
      return Expanded(
        flex: _widths[index],
        child: Padding(
          padding: const EdgeInsets.only(right: 7),
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.8,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: textColor ?? colors.onSurface,
            ),
          ),
        ),
      );
    }

    return Material(
      color: selected ? _orange.withValues(alpha: 0.085) : Colors.transparent,
      child: InkWell(
        onTap: () => onSelect(item.id),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 13, 10, 13),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: selected ? _orange : Colors.transparent,
                width: 3,
              ),
              bottom: BorderSide(
                color: colors.outlineVariant.withValues(alpha: 0.65),
              ),
            ),
          ),
          child: Row(
            children: [
              cell(
                item.rucDocumento,
                0,
                bold: true,
                textColor: selected ? _orange : null,
              ),

              cell(item.razonSocial, 1, bold: true),

              cell(_display(item.contacto), 2),

              Expanded(
                flex: _widths[3],
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _StatusPill(
                    item.activo ? 'Activo' : 'Inactivo',
                    active: item.activo,
                  ),
                ),
              ),

              Expanded(
                flex: _widths[4],
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    tooltip: 'Ver detalle de ${item.razonSocial}',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => onSelect(item.id),
                    icon: const Icon(Icons.more_vert_rounded, size: 20),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 8,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Mostrar', style: TextStyle(fontSize: 11.5)),

              const SizedBox(width: 8),

              DropdownButton<int>(
                value: pageSize,
                isDense: true,
                underline: const SizedBox.shrink(),
                items: const [10, 20, 50]
                    .map(
                      (value) => DropdownMenuItem<int>(
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

              const Text('por página', style: TextStyle(fontSize: 11.5)),
            ],
          ),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                total == 0 ? '0 resultados' : '${start + 1}–$end de $total',
                style: TextStyle(
                  fontSize: 11.5,
                  color: colors.onSurfaceVariant,
                ),
              ),

              const SizedBox(width: 8),

              IconButton.outlined(
                tooltip: 'Página anterior',
                visualDensity: VisualDensity.compact,
                onPressed: page == 0 ? null : () => onPage(page - 1),
                icon: const Icon(Icons.chevron_left_rounded, size: 19),
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
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              const SizedBox(width: 5),

              IconButton.outlined(
                tooltip: 'Página siguiente',
                visualDensity: VisualDensity.compact,
                onPressed: page + 1 >= totalPages
                    ? null
                    : () => onPage(page + 1),
                icon: const Icon(Icons.chevron_right_rounded, size: 19),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================
// TARJETA DE PROVEEDOR PARA MOVILES
// =============================================================

class _ProveedorMobileTile extends StatelessWidget {
  const _ProveedorMobileTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final ProveedorRecord item;
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
                  ? _orange.withValues(alpha: 0.5)
                  : colors.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              const _SectionIcon(Icons.local_shipping_outlined),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.rucDocumento,
                      style: const TextStyle(
                        color: _orange,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      item.razonSocial,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      _display(item.contacto),
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
// PANEL DE DETALLE DEL PROVEEDOR
// =============================================================

class _ProveedorDetailPanel extends StatelessWidget {
  const _ProveedorDetailPanel({
    required this.state,
    required this.onRetry,
    required this.onEdit,
    required this.onToggleState,
  });

  final ProveedoresState state;

  final VoidCallback onRetry;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleState;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final proveedor = state.selectedProveedor;

    return _PanelSurface(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ===========================================
          // CABECERA DEL PANEL
          // ===========================================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            child: Row(
              children: [
                const _SectionIcon(Icons.local_shipping_outlined),

                const SizedBox(width: 10),

                const Expanded(
                  child: Text(
                    'Detalle del proveedor',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ),

                if (proveedor != null && !state.isDetailLoading)
                  OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 16),
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

          Divider(height: 1, color: colors.outlineVariant),

          // ===========================================
          // CONTENIDO DEL DETALLE
          // ===========================================
          Expanded(
            child: state.isDetailLoading
                ? const Center(child: CircularProgressIndicator())
                : state.detailErrorMessage != null
                ? _EmptyMessage(
                    icon: Icons.error_outline_rounded,
                    title: 'No pudimos cargar el detalle',
                    description: state.detailErrorMessage!,
                    onRetry: onRetry,
                  )
                : proveedor == null
                ? const _EmptyMessage(
                    icon: Icons.touch_app_outlined,
                    title: 'Selecciona un proveedor',
                    description:
                        'Escoge un registro del listado para consultar sus datos.',
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildLeatherHeader(proveedor),

                        _buildInformation(context, proveedor),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  // CABECERA EN TONOS DE CUERO
  // ===========================================================

  Widget _buildLeatherHeader(ProveedorRecord proveedor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.bottomRight,
          colors: [_brown, _brownMedium, _brownLight],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 63,
            height: 63,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.local_shipping_outlined,
              size: 32,
              color: _orange,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  proveedor.razonSocial,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 19,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  proveedor.rucDocumento,
                  style: const TextStyle(
                    color: Color(0xFFFFA46B),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 9),

                _StatusPill(
                  proveedor.activo ? 'Activo' : 'Inactivo',
                  active: proveedor.activo,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  // INFORMACION GENERAL DEL PROVEEDOR
  // ===========================================================

  Widget _buildInformation(BuildContext context, ProveedorRecord proveedor) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ===========================================
          // BOTONES DE ACCION
          // ===========================================
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 17),
                label: const Text('Editar proveedor'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _orange,
                  side: const BorderSide(color: _orange),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 11,
                  ),
                ),
              ),

              OutlinedButton.icon(
                onPressed: onToggleState,
                icon: Icon(
                  proveedor.activo
                      ? Icons.block_outlined
                      : Icons.check_circle_outline_rounded,
                  size: 17,
                ),
                label: Text(
                  proveedor.activo
                      ? 'Inactivar proveedor'
                      : 'Activar proveedor',
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 11,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // ===========================================
          // IDENTIDAD + CONTACTO
          // ===========================================
          LayoutBuilder(
            builder: (context, constraints) {
              final identity = _InfoCard(
                icon: Icons.badge_outlined,
                title: 'Identidad',
                children: [
                  _InfoLine(label: 'ID', value: '${proveedor.id}'),
                  _InfoLine(label: 'RUC', value: proveedor.rucDocumento),
                  _InfoLine(
                    label: 'Razón social',
                    value: proveedor.razonSocial,
                  ),
                ],
              );

              final contact = _InfoCard(
                icon: Icons.phone_outlined,
                title: 'Contacto',
                children: [
                  _InfoLine(
                    label: 'Persona de contacto',
                    value: _display(proveedor.contacto),
                  ),
                  _InfoLine(
                    label: 'Teléfono',
                    value: _display(proveedor.telefono),
                  ),
                  _InfoLine(
                    label: 'Correo electrónico',
                    value: _display(proveedor.correo),
                  ),
                ],
              );

              if (constraints.maxWidth >= 410) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: identity),

                    const SizedBox(width: 9),

                    Expanded(child: contact),
                  ],
                );
              }

              return Column(
                children: [identity, const SizedBox(height: 10), contact],
              );
            },
          ),

          const SizedBox(height: 12),

          // ===========================================
          // UBICACION Y TRAZABILIDAD
          // ===========================================
          _InfoCard(
            icon: Icons.location_on_outlined,
            title: 'Ubicación y trazabilidad',
            children: [
              _InfoLine(
                label: 'Dirección',
                value: _display(proveedor.direccion),
              ),

              _InfoLine(
                label: 'Fecha de creación',
                value: _formatDateTime(proveedor.creadoEn),
              ),

              _InfoLine(
                label: 'Última actualización',
                value: _formatOptionalDate(proveedor.actualizadoEn),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================
// TARJETAS DE INFORMACION
// =============================================================

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 29,
                height: 29,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _orangeSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: _orange, size: 17),
              ),

              const SizedBox(width: 7),

              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          for (int i = 0; i < children.length; i++) ...[
            children[i],

            if (i < children.length - 1) const SizedBox(height: 9),
          ],
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              color: colors.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ),

        const SizedBox(width: 6),

        Expanded(
          flex: 5,
          child: Text(
            value,
            textAlign: TextAlign.start,
            style: const TextStyle(
              fontSize: 10.8,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================
// DETALLE EMERGENTE PARA MOVIL
// =============================================================

class _MobileProveedorDetailSheet extends StatelessWidget {
  const _MobileProveedorDetailSheet({
    required this.onEdit,
    required this.onToggleState,
  });

  final VoidCallback onEdit;
  final VoidCallback onToggleState;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return FractionallySizedBox(
      heightFactor: 0.88,
      child: Material(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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

              const SizedBox(height: 10),

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Detalle del proveedor',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Expanded(
                child: BlocBuilder<ProveedoresCubit, ProveedoresState>(
                  builder: (context, state) {
                    return _ProveedorDetailPanel(
                      state: state,
                      onRetry: () =>
                          context.read<ProveedoresCubit>().retryDetail(),
                      onEdit:
                          state.selectedProveedor == null ||
                              state.isSubmittingAction
                          ? null
                          : onEdit,
                      onToggleState:
                          state.selectedProveedor == null ||
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
      ),
    );
  }
}

// =============================================================
// COMPONENTES GENERALES
// =============================================================

class _PanelSurface extends StatelessWidget {
  const _PanelSurface({required this.child, required this.padding});

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
      width: 33,
      height: 33,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _orangeSoft,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, size: 18, color: _orange),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.label, {required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final background = active ? _greenSoft : _graySoft;

    final foreground = active
        ? const Color(0xFF146739)
        : const Color(0xFF656971);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
            Icon(icon, size: 38, color: colors.onSurfaceVariant),

            const SizedBox(height: 12),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),

            const SizedBox(height: 7),

            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
            ),

            if (onRetry != null) ...[
              const SizedBox(height: 14),

              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
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

String _display(String? value) {
  final normalized = value?.trim();

  if (normalized == null || normalized.isEmpty) {
    return 'Sin registro';
  }

  return normalized;
}

String _formatOptionalDate(DateTime? value) {
  if (value == null) {
    return 'Sin registro';
  }

  return _formatDateTime(value);
}

String _formatDateTime(DateTime value) {
  return DateFormat('dd/MM/yyyy hh:mm a').format(value.toLocal());
}
