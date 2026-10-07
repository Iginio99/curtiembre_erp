import 'package:dio/dio.dart';
import 'package:erp_curtiembre_fronted/core/di/service_locator.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_breakpoints.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_colors.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_state.dart';
import 'package:erp_curtiembre_fronted/features/security/presentation/cubit/security_access_cubit.dart';
import 'package:erp_curtiembre_fronted/shared/navigation/app_access_routes.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/buttons/app_button.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/layout/app_shell.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/layout/app_surface_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProductosPage extends StatefulWidget {
  const ProductosPage({super.key});

  @override
  State<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends State<ProductosPage> {
  final _dio = getIt<Dio>();
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _items = const [];
  String? _error;
  bool _loading = true;
  _ProductFilter _filter = _ProductFilter.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _dio.get<List<dynamic>>(
        '/api/configuracion/productos',
      );
      if (!mounted) return;
      setState(() {
        _items = (response.data ?? const [])
            .map((x) => Map<String, dynamic>.from(x as Map))
            .toList();
        _loading = false;
      });
    } on DioException catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error =
              'No pudimos cargar los productos. Verifica la migración y el backend.';
        });
      }
    }
  }

  Future<void> _edit([Map<String, dynamic>? item]) async {
    final input = await showDialog<_ProductoInput>(
      context: context,
      builder: (_) => _ProductoDialog(
        item: item,
        suggestedCode: item == null ? _nextProductCode() : null,
      ),
    );
    if (input == null) return;
    try {
      final id = item?['id'];
      if (id == null) {
        await _dio.post('/api/configuracion/productos', data: input.toJson());
      } else {
        await _dio.put(
          '/api/configuracion/productos/$id',
          data: input.toJson(),
        );
      }
      await _load();
    } on DioException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar el producto.')),
        );
      }
    }
  }

  String _nextProductCode() {
    final sequence = RegExp(r'^PRO-(\d+)$', caseSensitive: false);
    var highest = 0;
    for (final item in _items) {
      final match = sequence.firstMatch('${item['codigo'] ?? ''}'.trim());
      if (match != null) {
        highest = highest > int.parse(match.group(1)!)
            ? highest
            : int.parse(match.group(1)!);
      }
    }
    return 'PRO-${(highest + 1).toString().padLeft(2, '0')}';
  }

  /*
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Productos')),
    floatingActionButton: FloatingActionButton.extended(onPressed: _loading ? null : () => _edit(), icon: const Icon(Icons.add), label: const Text('Nuevo producto')),
    body: _loading ? const Center(child: CircularProgressIndicator()) : _error != null ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(_error!), OutlinedButton(onPressed: _load, child: const Text('Reintentar'))])) : _items.isEmpty ? const Center(child: Text('No hay productos registrados.')) : ListView.separated(
      itemCount: _items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, index) {
        final item = _items[index];
        return ListTile(
          title: Text('${item['codigo']} · ${item['nombre']}'),
          subtitle: Text('${item['tipo']}${item['color'] == null ? '' : ' · ${item['color']}'} · ID ${item['id']}'),
          trailing: IconButton(onPressed: () => _edit(item), icon: const Icon(Icons.edit_outlined)),
        );
      },
    ),
  );
  */

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
    final query = _searchController.text.trim().toLowerCase();
    final items = _items.where((item) {
      final active = item['activo'] != false;
      final matchesFilter =
          _filter == _ProductFilter.all ||
          (_filter == _ProductFilter.active && active) ||
          (_filter == _ProductFilter.inactive && !active);
      return matchesFilter &&
          (query.isEmpty ||
              '${item['codigo']} ${item['nombre']} ${item['tipo']} ${item['color'] ?? ''}'
                  .toLowerCase()
                  .contains(query));
    }).toList();
    return AppShell(
      title: 'Productos',
      currentPath: '/produccion/productos',
      breadcrumbs: const ['Inicio', 'Producción', 'Productos'],
      userName: session.nombreCompleto,
      roleName: session.rolNombre,
      accessibleRoutes: AppAccessRoutes.forPermissions(permissionCodes),
      onSignOut: isSigningOut
          ? () {}
          : () => context.read<AuthCubit>().signOut(),
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Productos',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Catálogo de productos para producción y fórmulas.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _ProductFilters(
                      controller: _searchController,
                      filter: _filter,
                      loading: _loading,
                      onChanged: () => setState(() {}),
                      onFilterChanged: (filter) =>
                          setState(() => _filter = filter),
                      onCreate: () => _edit(),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Expanded(
                      child: _ProductsPanel(
                        items: items,
                        loading: _loading,
                        error: _error,
                        onRetry: _load,
                        onEdit: _edit,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _ProductFilter { all, active, inactive }

class _ProductFilters extends StatelessWidget {
  const _ProductFilters({
    required this.controller,
    required this.filter,
    required this.loading,
    required this.onChanged,
    required this.onFilterChanged,
    required this.onCreate,
  });
  final TextEditingController controller;
  final _ProductFilter filter;
  final bool loading;
  final VoidCallback onChanged;
  final ValueChanged<_ProductFilter> onFilterChanged;
  final VoidCallback onCreate;
  @override
  Widget build(BuildContext context) => AppSurfaceCard(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 900;
        final search = TextField(
          controller: controller,
          onChanged: (_) => onChanged(),
          decoration: const InputDecoration(
            hintText: 'Buscar por código, nombre, tipo o color',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        );
        final filters = SegmentedButton<_ProductFilter>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: _ProductFilter.all, label: Text('Todos')),
            ButtonSegment(value: _ProductFilter.active, label: Text('Activos')),
            ButtonSegment(
              value: _ProductFilter.inactive,
              label: Text('Inactivos'),
            ),
          ],
          selected: {filter},
          onSelectionChanged: (value) => onFilterChanged(value.first),
        );
        final create = AppButton.primary(
          label: 'Nuevo producto',
          icon: Icons.add_rounded,
          expand: false,
          onPressed: loading ? null : onCreate,
        );
        return compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  search,
                  const SizedBox(height: AppSpacing.md),
                  filters,
                  const SizedBox(height: AppSpacing.md),
                  Align(alignment: Alignment.centerRight, child: create),
                ],
              )
            : Row(
                children: [
                  Expanded(child: search),
                  const SizedBox(width: AppSpacing.md),
                  filters,
                  const SizedBox(width: AppSpacing.md),
                  create,
                ],
              );
      },
    ),
  );
}

class _ProductsPanel extends StatelessWidget {
  const _ProductsPanel({
    required this.items,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.onEdit,
  });
  final List<Map<String, dynamic>> items;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final ValueChanged<Map<String, dynamic>> onEdit;
  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;
    return AppSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Listado de productos',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text(
                  '${items.length} ${items.length == 1 ? 'registro' : 'registros'}',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                ? _MessageState(
                    message: error!,
                    icon: Icons.cloud_off_rounded,
                    action: OutlinedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Reintentar'),
                    ),
                  )
                : items.isEmpty
                ? const _MessageState(
                    message: 'No hay productos que mostrar.',
                    icon: Icons.inventory_2_outlined,
                  )
                : wide
                ? _ProductsTable(items: items, onEdit: onEdit)
                : _ProductsList(items: items, onEdit: onEdit),
          ),
        ],
      ),
    );
  }
}

class _ProductsTable extends StatelessWidget {
  const _ProductsTable({required this.items, required this.onEdit});
  final List<Map<String, dynamic>> items;
  final ValueChanged<Map<String, dynamic>> onEdit;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: constraints.maxWidth),
        child: DataTable(
          horizontalMargin: AppSpacing.lg,
          columnSpacing: 56,
          headingRowHeight: 52,
          dataRowMinHeight: 64,
          dataRowMaxHeight: 64,
          columns: const [
            DataColumn(label: Text('CÓDIGO')),
            DataColumn(label: Text('PRODUCTO')),
            DataColumn(label: Text('TIPO')),
            DataColumn(label: Text('COLOR')),
            DataColumn(label: Text('ESTADO')),
            DataColumn(label: Text('ACCIONES')),
          ],
          rows: items
              .map(
                (item) => DataRow(
                  cells: [
                    DataCell(
                      Text(
                        '${item['codigo'] ?? '—'}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    DataCell(Text('${item['nombre'] ?? '—'}')),
                    DataCell(Text('${item['tipo'] ?? '—'}')),
                    DataCell(Text('${item['color'] ?? 'Sin color'}')),
                    DataCell(_StatusBadge(active: item['activo'] != false)),
                    DataCell(
                      IconButton(
                        onPressed: () => onEdit(item),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    ),
  );
}

class _ProductsList extends StatelessWidget {
  const _ProductsList({required this.items, required this.onEdit});
  final List<Map<String, dynamic>> items;
  final ValueChanged<Map<String, dynamic>> onEdit;
  @override
  Widget build(BuildContext context) => ListView.separated(
    itemCount: items.length,
    separatorBuilder: (_, _) => const Divider(height: 1),
    itemBuilder: (_, index) {
      final item = items[index];
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        title: Text('${item['codigo'] ?? '—'} · ${item['nombre'] ?? '—'}'),
        subtitle: Text(
          '${item['tipo'] ?? '—'}${item['color'] == null ? '' : ' · ${item['color']}'}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusBadge(active: item['activo'] != false),
            IconButton(
              onPressed: () => onEdit(item),
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
      );
    },
  );
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.message, required this.icon, this.action});
  final String message;
  final IconData icon;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 44,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(message, textAlign: TextAlign.center),
        if (action != null) ...[const SizedBox(height: AppSpacing.md), action!],
      ],
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.active});
  final bool active;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: active
          ? AppColors.successSoft
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      active ? 'Activo' : 'Inactivo',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: active
            ? AppColors.success
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

// ============================================================
// INPUT DEL PRODUCTO
// ============================================================

class _ProductoInput {
  const _ProductoInput(this.codigo, this.tipo, this.nombre, this.color);

  final String codigo;
  final String tipo;
  final String nombre;
  final String? color;

  Map<String, dynamic> toJson() => {
    'codigo': codigo,
    'tipo': tipo,
    'nombre': nombre,
    'color': color,
  };
}

// ============================================================
// DIALOGO NUEVO / EDITAR PRODUCTO
// ============================================================

class _ProductoDialog extends StatefulWidget {
  const _ProductoDialog({this.item, this.suggestedCode});

  final Map<String, dynamic>? item;
  final String? suggestedCode;

  @override
  State<_ProductoDialog> createState() => _ProductoDialogState();
}

class _ProductoDialogState extends State<_ProductoDialog> {
  final _form = GlobalKey<FormState>();

  late final TextEditingController _codigo = TextEditingController(
    text: widget.item?['codigo']?.toString() ?? widget.suggestedCode ?? '',
  );

  late final TextEditingController _tipo = TextEditingController(
    text: widget.item?['tipo']?.toString() ?? '',
  );

  late final TextEditingController _nombre = TextEditingController(
    text: widget.item?['nombre']?.toString() ?? '',
  );

  late final TextEditingController _color = TextEditingController(
    text: widget.item?['color']?.toString() ?? '',
  );

  bool get _isEditing => widget.item != null;

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _codigo.dispose();
    _tipo.dispose();
    _nombre.dispose();
    _color.dispose();

    super.dispose();
  }

  // ==========================================================
  // GUARDAR
  // ==========================================================

  void _submit() {
    FocusScope.of(context).unfocus();

    if (!(_form.currentState?.validate() ?? false)) {
      return;
    }

    final color = _color.text.trim();

    Navigator.of(context).pop(
      _ProductoInput(
        _codigo.text.trim(),
        _tipo.text.trim(),
        _nombre.text.trim(),
        color.isEmpty ? null : color,
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final screen = MediaQuery.sizeOf(context);

    final compact = screen.width < 760;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 24,
        vertical: 18,
      ),
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 920,
          maxHeight: screen.height * 0.90,
        ),
        child: compact
            ? _buildCompactLayout(context)
            : _buildDesktopLayout(context),
      ),
    );
  }

  // ==========================================================
  // DESKTOP
  // ==========================================================

  Widget _buildDesktopLayout(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ==================================================
          // LADO IZQUIERDO
          // ==================================================
          SizedBox(width: 285, child: _buildSidePanel(context)),

          // DIVISOR
          Container(width: 1, color: colors.outlineVariant),

          // ==================================================
          // FORMULARIO
          // ==================================================
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDesktopHeader(context),

                Divider(height: 1, color: colors.outlineVariant),

                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 22, 28, 24),
                    child: Form(key: _form, child: _buildFields(context)),
                  ),
                ),

                _buildFooter(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // PANEL IZQUIERDO
  // ==========================================================

  Widget _buildSidePanel(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(30, 34, 28, 30),
      decoration: BoxDecoration(
        color: dark
            ? AppColors.primary.withValues(alpha: 0.08)
            : const Color(0xFFFFF8F4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ICONO
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: dark ? 0.15 : 0.11),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(
              _isEditing ? Icons.inventory_2_outlined : Icons.add_box_outlined,
              color: AppColors.primary,
              size: 35,
            ),
          ),

          const SizedBox(height: 26),

          Text(
            _isEditing ? 'Editar producto' : 'Nuevo producto',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            _isEditing
                ? 'Actualiza la información básica y clasificación del producto.'
                : 'Registra la información básica del producto y su clasificación.',
            style: TextStyle(
              fontSize: 13,
              height: 1.55,
              color: colors.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 25),

          Container(
            width: 52,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(99),
            ),
          ),

          const Spacer(),

          // DECORACION INFERIOR SUAVE
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 165,
              height: 150,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: dark ? 0.07 : 0.045),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 82,
                color: AppColors.primary.withValues(alpha: dark ? 0.18 : 0.11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // HEADER DESKTOP
  // ==========================================================

  Widget _buildDesktopHeader(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 22, 16, 18),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 35,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(99),
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Text(
              'Información general',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ),

          IconButton(
            tooltip: 'Cerrar',
            onPressed: () => Navigator.of(context).pop(),
            style: IconButton.styleFrom(
              backgroundColor: colors.surfaceContainerLow,
            ),
            icon: const Icon(Icons.close_rounded, size: 21),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // MOBILE / COMPACT
  // ==========================================================

  Widget _buildCompactLayout(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // HEADER
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 17, 10, 15),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  _isEditing
                      ? Icons.inventory_2_outlined
                      : Icons.add_box_outlined,
                  color: AppColors.primary,
                  size: 23,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEditing ? 'Editar producto' : 'Nuevo producto',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _isEditing
                          ? 'Actualiza los datos del producto.'
                          : 'Registra un nuevo producto.',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(
                tooltip: 'Cerrar',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),

        Divider(height: 1, color: colors.outlineVariant),

        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Form(key: _form, child: _buildFields(context)),
          ),
        ),

        _buildFooter(context),
      ],
    );
  }

  // ==========================================================
  // CAMPOS
  // ==========================================================

  Widget _buildFields(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // CÓDIGO
        _ProductField(
          label: 'Código',
          requiredField: true,
          child: TextFormField(
            controller: _codigo,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.characters,
            decoration: _inputDecoration(
              context,
              hint: 'Ingresa el código del producto',
            ),
            validator: (value) {
              if ((value?.trim() ?? '').isEmpty) {
                return 'Código es obligatorio.';
              }

              return null;
            },
          ),
        ),

        const SizedBox(height: 17),

        // TIPO
        _ProductField(
          label: 'Tipo',
          requiredField: true,
          child: TextFormField(
            controller: _tipo,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            decoration: _inputDecoration(
              context,
              hint: 'Ingresa el tipo de producto',
            ),
            validator: (value) {
              if ((value?.trim() ?? '').isEmpty) {
                return 'Tipo es obligatorio.';
              }

              return null;
            },
          ),
        ),

        const SizedBox(height: 17),

        // NOMBRE
        _ProductField(
          label: 'Nombre',
          requiredField: true,
          child: TextFormField(
            controller: _nombre,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            decoration: _inputDecoration(
              context,
              hint: 'Ingresa el nombre del producto',
            ),
            validator: (value) {
              if ((value?.trim() ?? '').isEmpty) {
                return 'Nombre es obligatorio.';
              }

              return null;
            },
          ),
        ),

        const SizedBox(height: 17),

        // COLOR
        _ProductField(
          label: 'Color',
          helper: 'Opcional',
          child: TextFormField(
            controller: _color,
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.words,
            decoration: _inputDecoration(
              context,
              hint: 'Ingresa el color del producto',
            ),
            onFieldSubmitted: (_) => _submit(),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // FOOTER
  // ==========================================================

  Widget _buildFooter(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 17),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.onSurface,
              padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 14),
              side: BorderSide(color: colors.outlineVariant),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            child: const Text('Cancelar'),
          ),

          const SizedBox(width: 10),

          FilledButton.icon(
            onPressed: _submit,
            icon: Icon(
              _isEditing ? Icons.save_outlined : Icons.add_box_outlined,
              size: 18,
            ),
            label: Text(_isEditing ? 'Guardar cambios' : 'Guardar producto'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// BLOQUE DE CAMPO
// ============================================================

class _ProductField extends StatelessWidget {
  const _ProductField({
    required this.label,
    required this.child,
    this.requiredField = false,
    this.helper,
  });

  final String label;
  final Widget child;
  final bool requiredField;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),

            if (requiredField) ...[
              const SizedBox(width: 3),
              const Text(
                '*',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],

            if (helper != null) ...[
              const SizedBox(width: 6),
              Text(
                helper!,
                style: TextStyle(
                  fontSize: 10.5,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 7),

        child,
      ],
    );
  }
}

// ============================================================
// DECORACIÓN DEL INPUT
// ============================================================

InputDecoration _inputDecoration(BuildContext context, {required String hint}) {
  final colors = Theme.of(context).colorScheme;

  return InputDecoration(
    isDense: true,
    hintText: hint,

    hintStyle: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),

    filled: true,
    fillColor: colors.surface,

    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),

    border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),

    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: BorderSide(color: colors.outlineVariant),
    ),

    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),

    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: BorderSide(color: colors.error),
    ),

    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: BorderSide(color: colors.error, width: 1.5),
    ),
  );
}
