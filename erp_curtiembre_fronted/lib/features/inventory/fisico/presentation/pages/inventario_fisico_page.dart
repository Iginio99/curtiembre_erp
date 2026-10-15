import 'package:erp_curtiembre_fronted/core/di/service_locator.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_state.dart';
import 'package:erp_curtiembre_fronted/features/inventory/fisico/domain/entities/inventario_fisico_detail.dart';
import 'package:erp_curtiembre_fronted/features/inventory/fisico/domain/entities/inventario_fisico_record.dart';
import 'package:erp_curtiembre_fronted/features/inventory/fisico/presentation/cubit/inventario_fisico_cubit.dart';
import 'package:erp_curtiembre_fronted/features/inventory/fisico/presentation/cubit/inventario_fisico_state.dart';
import 'package:erp_curtiembre_fronted/features/inventory/fisico/presentation/widgets/inventario_fisico_close_dialog.dart';
import 'package:erp_curtiembre_fronted/features/inventory/fisico/presentation/widgets/inventario_fisico_counts_dialog.dart';
import 'package:erp_curtiembre_fronted/features/inventory/fisico/presentation/widgets/inventario_fisico_create_dialog.dart';
import 'package:erp_curtiembre_fronted/features/security/presentation/cubit/security_access_cubit.dart';
import 'package:erp_curtiembre_fronted/shared/navigation/app_access_routes.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/buttons/app_button.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/feedback/app_message_card.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/layout/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:talker_flutter/talker_flutter.dart';

// Solo presentación. No modifica Cubit, repositorios, entidades ni rutas.
// Los indicadores del inventario seleccionado permanecen EN EL DETALLE.
// Se omite expresamente la fila de tarjetas KPI superiores.

class InventarioFisicoPage extends StatefulWidget {
  const InventarioFisicoPage({super.key});

  @override
  State<InventarioFisicoPage> createState() => _InventarioFisicoPageState();
}

class _InventarioFisicoPageState extends State<InventarioFisicoPage> {
  final _yearController = TextEditingController();
  final _countsSearchController = TextEditingController();
  final Talker _talker = getIt<Talker>();

  String? _lastSyncedYear;
  String _listSearch = '';
  String _countsSearch = '';
  bool _newestFirst = true;
  int _countsPage = 0;

  @override
  void initState() {
    super.initState();
    _talker.ui('Se abrio la pantalla de inventario fisico.');
  }

  @override
  void dispose() {
    _yearController.dispose();
    _countsSearchController.dispose();
    super.dispose();
  }

  void _syncYearField(InventarioFisicoState state) {
    final text = state.periodoAnioFilter?.toString() ?? '';
    if (_lastSyncedYear == text) return;
    _lastSyncedYear = text;
    _yearController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _applyYearFilter() {
    final raw = _yearController.text.trim();
    final parsed = raw.isEmpty ? null : int.tryParse(raw);
    if (raw.isNotEmpty && (parsed == null || parsed < 1)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ingresa un año válido.')));
      return;
    }
    _talker.ui('Se aplico el filtro de anio: ${parsed ?? 'todos'}.');
    context.read<InventarioFisicoCubit>().load(periodoAnioFilter: parsed);
  }

  Future<void> _openCreateDialog(InventarioFisicoState state) async {
    _talker.ui('Se abrio el dialogo para crear una toma fisica.');
    final payload = await showDialog<InventarioFisicoCreateFormData>(
      context: context,
      builder: (_) =>
          InventarioFisicoCreateDialog(isSubmitting: state.isSubmittingAction),
    );
    if (payload == null || !mounted) {
      _talker.ui(
        'Se cerro la creacion de inventario fisico sin confirmar.',
        logLevel: LogLevel.debug,
      );
      return;
    }
    _talker.ui(
      'Se confirmo la creacion de inventario fisico para periodo='
      '${payload.periodoMes}/${payload.periodoAnio}.',
    );
    final result = await context
        .read<InventarioFisicoCubit>()
        .createInventarioFisico(
          periodoAnio: payload.periodoAnio,
          periodoMes: payload.periodoMes,
          observacion: payload.observacion,
        );
    if (!mounted) return;
    _showActionResult(result);
  }

  Future<void> _openCountsDialog(InventarioFisicoState state) async {
    final detail = state.selectedInventario;
    if (detail == null) return;
    _talker.ui(
      'Se abrio el dialogo para registrar conteos del inventario fisico ${detail.id}.',
      logLevel: LogLevel.warning,
    );
    final payload = await showDialog<InventarioFisicoCountsFormData>(
      context: context,
      builder: (_) => InventarioFisicoCountsDialog(
        insumos: state.insumos,
        existingDetails: detail.detalles,
        isSubmitting: state.isSubmittingAction,
      ),
    );
    if (payload == null || !mounted) {
      _talker.ui(
        'Se cerro el registro de conteos del inventario fisico ${detail.id} sin confirmar.',
        logLevel: LogLevel.debug,
      );
      return;
    }
    _talker.ui(
      'Se confirmo el registro de conteos del inventario fisico ${detail.id} '
      'con ${payload.detalles.length} detalles.',
      logLevel: LogLevel.warning,
    );
    final result = await context.read<InventarioFisicoCubit>().registerCounts(
      inventarioFisicoId: detail.id,
      detalles: payload.detalles,
    );
    if (!mounted) return;
    _showActionResult(result);
  }

  Future<void> _openCloseDialog(InventarioFisicoState state) async {
    _talker.ui(
      'Se abrio el dialogo para cerrar el inventario fisico seleccionado.',
      logLevel: LogLevel.warning,
    );
    final payload = await showDialog<String>(
      context: context,
      builder: (_) =>
          InventarioFisicoCloseDialog(isSubmitting: state.isSubmittingAction),
    );
    if (!mounted || payload == null) {
      _talker.ui(
        'Se cerro el cierre de inventario fisico sin confirmar.',
        logLevel: LogLevel.debug,
      );
      return;
    }
    _talker.ui(
      'Se confirmo el cierre de inventario fisico con observacion='
      '${_describeText(payload)}.',
      logLevel: LogLevel.warning,
    );
    final result = await context.read<InventarioFisicoCubit>().closeSelected(
      observacion: payload.isEmpty ? null : payload,
    );
    if (!mounted) return;
    _showActionResult(result);
  }

  void _showActionResult(InventarioFisicoActionResult result) {
    _talker.ui(
      result.success
          ? 'Accion en inventario fisico completada correctamente.'
          : 'La accion en inventario fisico fallo: ${result.message}',
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

  void _selectInventario(int id) {
    _talker.ui(
      'Se selecciono el inventario fisico $id.',
      logLevel: LogLevel.debug,
    );
    _countsSearchController.clear();
    setState(() {
      _countsPage = 0;
      _countsSearch = '';
    });
    context.read<InventarioFisicoCubit>().selectInventario(id);
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
      title: 'Inventario físico',
      currentPath: '/inventario/fisico',
      breadcrumbs: const ['Inicio', 'Inventario', 'Inventario físico'],
      userName: session.nombreCompleto,
      roleName: session.rolNombre,
      accessibleRoutes: AppAccessRoutes.forPermissions(permissionCodes),
      onSignOut: isSigningOut
          ? () {}
          : () => context.read<AuthCubit>().signOut(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 980;
          final panelHeight = constraints.maxHeight.isFinite
              ? (constraints.maxHeight - 175).clamp(630.0, 1100.0).toDouble()
              : 740.0;
          final margin = constraints.maxWidth < 620 ? 12.0 : 20.0;

          return SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                // Mantiene el mismo ancho útil que las demás pantallas de
                // inventario (por ejemplo, Salidas).
                constraints: const BoxConstraints(),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(margin, 18, margin, 26),
                  child: BlocBuilder<InventarioFisicoCubit, InventarioFisicoState>(
                    builder: (context, state) {
                      _syncYearField(state);
                      final listPanel = _InventarioFisicoListPanel(
                        state: state,
                        searchQuery: _listSearch,
                        newestFirst: _newestFirst,
                        onToggleSort: () =>
                            setState(() => _newestFirst = !_newestFirst),
                        onRetry: () {
                          _talker.ui('Se solicito recargar inventario fisico.');
                          context.read<InventarioFisicoCubit>().initialize();
                        },
                        onSelectInventario: _selectInventario,
                      );
                      final detailPanel = _InventarioFisicoDetailPanel(
                        state: state,
                        countsSearch: _countsSearch,
                        countsSearchController: _countsSearchController,
                        countsPage: _countsPage,
                        onCountsSearchChanged: (value) => setState(() {
                          _countsSearch = value;
                          _countsPage = 0;
                        }),
                        onCountsPageChanged: (value) =>
                            setState(() => _countsPage = value),
                        onRetry: () {
                          _talker.ui('Se solicito recargar el detalle.');
                          context.read<InventarioFisicoCubit>().retryDetail();
                        },
                        onRegisterCounts: () => _openCountsDialog(state),
                        onCloseInventory: () => _openCloseDialog(state),
                      );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InventarioFisicoFiltersCard(
                            state: state,
                            yearController: _yearController,
                            onSearchChanged: (value) =>
                                setState(() => _listSearch = value),
                            onApplyYear: _applyYearFilter,
                            onMonthChanged: (value) {
                              _talker.ui(
                                'Se cambio filtro mes a ${value ?? 'todos'}.',
                                logLevel: LogLevel.debug,
                              );
                              context.read<InventarioFisicoCubit>().load(
                                periodoMesFilter: value,
                              );
                            },
                            onEstadoChanged: (value) {
                              _talker.ui(
                                'Se cambio filtro estado a ${value ?? 'todos'}.',
                                logLevel: LogLevel.debug,
                              );
                              context.read<InventarioFisicoCubit>().load(
                                estadoFilter: value,
                              );
                            },
                            onCreate: () => _openCreateDialog(state),
                          ),
                          const SizedBox(height: 16),
                          // SIN tarjetas KPI superiores: comienza directamente
                          // la lista de tomas y el detalle del inventario.
                          if (wide)
                            SizedBox(
                              height: panelHeight,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(flex: 35, child: listPanel),
                                  const SizedBox(width: 16),
                                  Expanded(flex: 65, child: detailPanel),
                                ],
                              ),
                            )
                          else ...[
                            SizedBox(height: 390, child: listPanel),
                            const SizedBox(height: 14),
                            SizedBox(height: 720, child: detailPanel),
                          ],
                        ],
                      );
                    },
                  ),
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
    return normalized == null || normalized.isEmpty
        ? 'vacio'
        : '${normalized.length} caracteres';
  }
}

class _InventarioFisicoFiltersCard extends StatelessWidget {
  const _InventarioFisicoFiltersCard({
    required this.state,
    required this.yearController,
    required this.onSearchChanged,
    required this.onApplyYear,
    required this.onMonthChanged,
    required this.onEstadoChanged,
    required this.onCreate,
  });

  final InventarioFisicoState state;
  final TextEditingController yearController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onApplyYear;
  final ValueChanged<int?> onMonthChanged;
  final ValueChanged<String?> onEstadoChanged;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return _PanelFrame(
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final year = _FilterLabeled(
                  title: 'Periodo año',
                  child: TextField(
                    controller: yearController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => onApplyYear(),
                    decoration: _compactInputDecoration(
                      context,
                      hint: 'Todos',
                      prefix: Icons.calendar_today_outlined,
                    ),
                  ),
                );
          final month = _FilterLabeled(
                  title: 'Periodo mes',
                  child: DropdownButtonFormField<int?>(
                    key: ValueKey('mes_${state.periodoMesFilter}'),
                    isExpanded: true,
                    initialValue: state.periodoMesFilter,
                    decoration: _compactInputDecoration(context),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Todos'),
                      ),
                      ...List.generate(
                        12,
                        (index) => DropdownMenuItem<int?>(
                          value: index + 1,
                          child: Text(monthLabel(index + 1)),
                        ),
                      ),
                    ],
                    onChanged: onMonthChanged,
                  ),
                );
          final status = _FilterLabeled(
                  title: 'Estado',
                  child: DropdownButtonFormField<String?>(
                    key: ValueKey('estado_${state.estadoFilter}'),
                    isExpanded: true,
                    initialValue: state.estadoFilter,
                    decoration: _compactInputDecoration(context),
                    items: const [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Todos'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'ABIERTO',
                        child: Text('Abierto'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'CERRADO',
                        child: Text('Cerrado'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'ANULADO',
                        child: Text('Anulado'),
                      ),
                    ],
                    onChanged: onEstadoChanged,
                  ),
                );
          final search = _FilterLabeled(
                  title: 'Buscar toma',
                  child: TextField(
                    // La búsqueda es local; no agrega consultas al backend.
                    onChanged: onSearchChanged,
                    decoration: _compactInputDecoration(
                      context,
                      hint: 'Buscar por código...',
                      prefix: Icons.search_rounded,
                    ),
                  ),
                );
          final apply = SizedBox(
            height: 43,
            child: AppButton.secondary(
                  label: 'Aplicar filtros',
                  icon: Icons.filter_alt_outlined,
                  onPressed: onApplyYear,
                ),
          );
          final create = SizedBox(
            height: 43,
            child: AppButton.primary(
                  label: 'Nueva toma física',
                  icon: Icons.add_circle_outline_rounded,
                  expand: false,
                  onPressed: state.isSubmittingAction ? null : onCreate,
                ),
          );

          if (width >= 1050) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(flex: 2, child: year),
                const SizedBox(width: 10),
                Expanded(flex: 2, child: month),
                const SizedBox(width: 10),
                Expanded(flex: 2, child: status),
                const SizedBox(width: 10),
                Expanded(flex: 3, child: search),
                const SizedBox(width: 10),
                SizedBox(width: 164, child: apply),
                const SizedBox(width: 10),
                SizedBox(width: 205, child: create),
              ],
            );
          }

          final fieldWidth = width >= 700 ? (width - 10) / 2 : width;
          return Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(width: fieldWidth, child: year),
              SizedBox(width: fieldWidth, child: month),
              SizedBox(width: fieldWidth, child: status),
              SizedBox(width: fieldWidth, child: search),
              SizedBox(width: 164, child: apply),
              SizedBox(width: 205, child: create),
            ],
          );
        },
      ),
    );
  }
}

class _FilterLabeled extends StatelessWidget {
  const _FilterLabeled({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 5),
      SizedBox(height: 43, child: child),
    ],
  );
}

InputDecoration _compactInputDecoration(
  BuildContext context, {
  String? hint,
  IconData? prefix,
}) {
  final theme = Theme.of(context);
  return InputDecoration(
    hintText: hint,
    isDense: true,
    filled: true,
    fillColor: theme.colorScheme.surface,
    prefixIcon: prefix == null ? null : Icon(prefix, size: 18),
    prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
    ),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
  );
}

class _InventarioFisicoListPanel extends StatelessWidget {
  const _InventarioFisicoListPanel({
    required this.state,
    required this.searchQuery,
    required this.newestFirst,
    required this.onToggleSort,
    required this.onRetry,
    required this.onSelectInventario,
  });

  final InventarioFisicoState state;
  final String searchQuery;
  final bool newestFirst;
  final VoidCallback onToggleSort;
  final VoidCallback onRetry;
  final ValueChanged<int> onSelectInventario;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = searchQuery.trim().toLowerCase();
    final items = state.items.where((item) {
      if (query.isEmpty) return true;
      final periodo =
          '${item.periodoMes.toString().padLeft(2, '0')}/${item.periodoAnio}';
      return item.codigo.toLowerCase().contains(query) ||
          item.estado.toLowerCase().contains(query) ||
          periodo.contains(query);
    }).toList();
    items.sort(
      (a, b) => newestFirst
          ? b.fechaInicio.compareTo(a.fechaInicio)
          : a.fechaInicio.compareTo(b.fechaInicio),
    );

    return _PanelFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tomas de inventario',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${items.length} toma${items.length == 1 ? '' : 's'} registrada${items.length == 1 ? '' : 's'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Tooltip(
                  message: newestFirst
                      ? 'Orden: más recientes'
                      : 'Orden: más antiguas',
                  child: OutlinedButton.icon(
                    onPressed: onToggleSort,
                    icon: const Icon(Icons.swap_vert_rounded, size: 17),
                    label: Text(newestFirst ? 'Recientes' : 'Antiguas'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
          Expanded(
            child: Builder(
              builder: (context) {
                if (state.status == InventarioFisicoStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.status == InventarioFisicoStatus.error) {
                  return Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppMessageCard.error(
                          title: 'No pudimos cargar las tomas físicas',
                          message: state.errorMessage ?? 'Intenta nuevamente.',
                        ),
                        const SizedBox(height: 12),
                        AppButton.secondary(
                          label: 'Reintentar',
                          icon: Icons.refresh_rounded,
                          onPressed: onRetry,
                        ),
                      ],
                    ),
                  );
                }
                if (items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: AppMessageCard.info(
                        title: query.isEmpty
                            ? 'Sin tomas registradas'
                            : 'Sin coincidencias',
                        message: query.isEmpty
                            ? 'Todavía no hay inventarios físicos para los filtros actuales.'
                            : 'Prueba buscando otro código o ajusta los filtros.',
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 9),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _InventarioFisicoListTile(
                      item: item,
                      selected: state.selectedInventarioId == item.id,
                      onTap: () => onSelectInventario(item.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InventarioFisicoListTile extends StatelessWidget {
  const _InventarioFisicoListTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final InventarioFisicoRecord item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.065)
                : theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? accent : theme.colorScheme.outlineVariant,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.codigo,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _StatusPill(label: item.estado),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                'Periodo ${item.periodoMes.toString().padLeft(2, '0')}/${item.periodoAnio}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 7,
                children: [
                  _InfoChip(
                    icon: Icons.calendar_today_outlined,
                    label: DateFormat('dd/MM/yyyy').format(item.fechaInicio),
                  ),
                  _InfoChip(
                    icon: Icons.inventory_2_outlined,
                    label: '${item.totalItems} ítems',
                  ),
                  _InfoChip(
                    icon: Icons.warning_amber_rounded,
                    label: '${item.itemsConDiferencia} con diferencia',
                  ),
                  _InfoChip(
                    icon: Icons.compare_arrows_rounded,
                    label:
                        'Dif. ${item.totalDiferenciaAbsoluta.toStringAsFixed(2)}',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InventarioFisicoDetailPanel extends StatelessWidget {
  const _InventarioFisicoDetailPanel({
    required this.state,
    required this.countsSearch,
    required this.countsSearchController,
    required this.countsPage,
    required this.onCountsSearchChanged,
    required this.onCountsPageChanged,
    required this.onRetry,
    required this.onRegisterCounts,
    required this.onCloseInventory,
  });

  final InventarioFisicoState state;
  final String countsSearch;
  final TextEditingController countsSearchController;
  final int countsPage;
  final ValueChanged<String> onCountsSearchChanged;
  final ValueChanged<int> onCountsPageChanged;
  final VoidCallback onRetry;
  final VoidCallback onRegisterCounts;
  final VoidCallback onCloseInventory;

  static const int _pageSize = 8;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detail = state.selectedInventario;

    return _PanelFrame(
      child: Builder(
        builder: (context) {
          if (state.isDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.detailErrorMessage != null) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppMessageCard.error(
                    title: 'No pudimos cargar el detalle',
                    message: state.detailErrorMessage!,
                  ),
                  const SizedBox(height: 12),
                  AppButton.secondary(
                    label: 'Reintentar',
                    icon: Icons.refresh_rounded,
                    onPressed: onRetry,
                  ),
                ],
              ),
            );
          }
          if (detail == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: AppMessageCard.info(
                  title: 'Selecciona una toma',
                  message:
                      'Elige un inventario físico para revisar sus conteos, '
                      'diferencias y cierre.',
                ),
              ),
            );
          }

          final query = countsSearch.trim().toLowerCase();
          final filteredLines = detail.detalles.where((line) {
            if (query.isEmpty) return true;
            return line.insumoCodigo.toLowerCase().contains(query) ||
                line.insumoNombre.toLowerCase().contains(query) ||
                line.unidadMedidaCodigo.toLowerCase().contains(query);
          }).toList();
          final totalPages = filteredLines.isEmpty
              ? 1
              : (filteredLines.length + _pageSize - 1) ~/ _pageSize;
          final page = countsPage >= totalPages ? totalPages - 1 : countsPage;
          final pageLines = filteredLines
              .skip(page * _pageSize)
              .take(_pageSize)
              .toList();
          final firstNumber = filteredLines.isEmpty ? 0 : page * _pageSize + 1;
          final lastNumber = page * _pageSize + pageLines.length;

          return LayoutBuilder(
            builder: (context, constraints) {
              final canFitActions = constraints.maxWidth >= 800;
              final veryNarrow = constraints.maxWidth < 540;
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 10,
                                runSpacing: 5,
                                children: [
                                  Text(
                                    detail.codigo,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  _StatusPill(label: detail.estado),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Periodo ${detail.periodoMes.toString().padLeft(2, '0')}/${detail.periodoAnio}',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        if (canFitActions) ...[
                          const SizedBox(width: 10),
                          _DetailActions(
                            isOpen: detail.isOpen,
                            isBusy: state.isSubmittingAction,
                            onRegisterCounts: onRegisterCounts,
                            onCloseInventory: onCloseInventory,
                          ),
                        ],
                      ],
                    ),
                    if (!canFitActions && detail.isOpen) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _DetailActions(
                          isOpen: detail.isOpen,
                          isBusy: state.isSubmittingAction,
                          onRegisterCounts: onRegisterCounts,
                          onCloseInventory: onCloseInventory,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 15,
                      runSpacing: 11,
                      children: [
                        _DetailFact(
                          icon: Icons.event_outlined,
                          caption: 'Fecha inicio',
                          value: DateFormat(
                            'dd/MM/yyyy HH:mm',
                          ).format(detail.fechaInicio),
                        ),
                        _DetailFact(
                          icon: Icons.person_outline_rounded,
                          caption: 'Responsable',
                          value: 'Resp. ${detail.ejecutadoPorUsuarioId}',
                        ),
                        if (detail.fechaCierre != null)
                          _DetailFact(
                            icon: Icons.event_available_outlined,
                            caption: 'Fecha cierre',
                            value: DateFormat(
                              'dd/MM/yyyy HH:mm',
                            ).format(detail.fechaCierre!),
                          ),
                        _DetailFact(
                          icon: Icons.notes_rounded,
                          caption: 'Observación',
                          value: detail.observacion?.trim().isNotEmpty == true
                              ? detail.observacion!
                              : 'Sin observaciones',
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    LayoutBuilder(
                      builder: (context, metricConstraints) {
                        final twoColumns = metricConstraints.maxWidth < 580;
                        final cardWidth = twoColumns
                            ? (metricConstraints.maxWidth - 8) / 2
                            : (metricConstraints.maxWidth - 24) / 4;
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _MiniMetric(
                              width: cardWidth,
                              icon: Icons.inventory_2_outlined,
                              title: 'Ítems',
                              value: detail.resumen.totalItems.toString(),
                              tint: theme.colorScheme.primary,
                            ),
                            _MiniMetric(
                              width: cardWidth,
                              icon: Icons.warning_amber_rounded,
                              title: 'Con diferencia',
                              value: detail.resumen.itemsConDiferencia
                                  .toString(),
                              tint: const Color(0xFFCA8A04),
                            ),
                            _MiniMetric(
                              width: cardWidth,
                              icon: Icons.arrow_upward_rounded,
                              title: 'Ajuste +',
                              value: detail.resumen.itemsConAjustePositivo
                                  .toString(),
                              tint: const Color(0xFF198754),
                            ),
                            _MiniMetric(
                              width: cardWidth,
                              icon: Icons.arrow_downward_rounded,
                              title: 'Ajuste -',
                              value: detail.resumen.itemsConAjusteNegativo
                                  .toString(),
                              tint: const Color(0xFFCD3939),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Divider(height: 1, color: theme.colorScheme.outlineVariant),
                    const SizedBox(height: 13),
                    if (veryNarrow) ...[
                      Text(
                        'Conteos registrados',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: countsSearchController,
                        onChanged: onCountsSearchChanged,
                        decoration: _compactInputDecoration(
                          context,
                          hint: 'Buscar insumo o código...',
                          prefix: Icons.search_rounded,
                        ),
                      ),
                    ] else
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Conteos registrados',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Detalle de insumos contados en esta toma física.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: constraints.maxWidth < 670 ? 170 : 230,
                            height: 40,
                            child: TextField(
                              controller: countsSearchController,
                              onChanged: onCountsSearchChanged,
                              decoration: _compactInputDecoration(
                                context,
                                hint: 'Buscar insumo...',
                                prefix: Icons.search_rounded,
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: filteredLines.isEmpty
                          ? Center(
                              child: AppMessageCard.info(
                                title: query.isEmpty
                                    ? 'Aún sin conteos'
                                    : 'Sin coincidencias',
                                message: query.isEmpty
                                    ? 'Registra los insumos auditados para empezar a ver diferencias.'
                                    : 'No hay insumos que coincidan con la búsqueda.',
                              ),
                            )
                          : _CountsDataTable(lines: pageLines),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Mostrando $firstNumber-$lastNumber de ${filteredLines.length} conteos',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (totalPages > 1) ...[
                          IconButton(
                            tooltip: 'Página anterior',
                            onPressed: page > 0
                                ? () => onCountsPageChanged(page - 1)
                                : null,
                            icon: const Icon(Icons.chevron_left_rounded),
                            visualDensity: VisualDensity.compact,
                          ),
                          Text(
                            '${page + 1} / $totalPages',
                            style: theme.textTheme.labelMedium,
                          ),
                          IconButton(
                            tooltip: 'Página siguiente',
                            onPressed: page + 1 < totalPages
                                ? () => onCountsPageChanged(page + 1)
                                : null,
                            icon: const Icon(Icons.chevron_right_rounded),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _DetailActions extends StatelessWidget {
  const _DetailActions({
    required this.isOpen,
    required this.isBusy,
    required this.onRegisterCounts,
    required this.onCloseInventory,
  });

  final bool isOpen;
  final bool isBusy;
  final VoidCallback onRegisterCounts;
  final VoidCallback onCloseInventory;

  @override
  Widget build(BuildContext context) {
    if (!isOpen) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        AppButton.primary(
          label: 'Registrar conteos',
          icon: Icons.edit_note_rounded,
          expand: false,
          isLoading: isBusy,
          onPressed: isBusy ? null : onRegisterCounts,
        ),
        AppButton.secondary(
          label: 'Cerrar inventario',
          icon: Icons.lock_outline_rounded,
          isLoading: isBusy,
          onPressed: isBusy ? null : onCloseInventory,
        ),
      ],
    );
  }
}

class _DetailFact extends StatelessWidget {
  const _DetailFact({
    required this.icon,
    required this.caption,
    required this.value,
  });
  final IconData icon;
  final String caption;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 230),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 29,
            height: 29,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Tooltip(
                  message: value,
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
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

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.width,
    required this.icon,
    required this.title,
    required this.value,
    required this.tint,
  });

  final double width;
  final IconData icon;
  final String title;
  final String value;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 80),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (width >= 140) ...[
            Container(
              height: 34,
              width: 34,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: tint, size: 19),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
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

class _CountsDataTable extends StatelessWidget {
  const _CountsDataTable({required this.lines});
  final List<InventarioFisicoConteoLine> lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Scrollbar(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStatePropertyAll(
                  theme.colorScheme.surfaceContainerLow,
                ),
                headingRowHeight: 42,
                dataRowMinHeight: 45,
                dataRowMaxHeight: 58,
                horizontalMargin: 12,
                columnSpacing: 19,
                showBottomBorder: true,
                dividerThickness: 0.5,
                columns: const [
                  DataColumn(label: _ColumnHead('Código')),
                  DataColumn(label: _ColumnHead('Insumo')),
                  DataColumn(label: _ColumnHead('Sistema'), numeric: true),
                  DataColumn(label: _ColumnHead('Contado'), numeric: true),
                  DataColumn(label: _ColumnHead('Diferencia'), numeric: true),
                  DataColumn(label: _ColumnHead('UM')),
                  DataColumn(label: _ColumnHead('Estado')),
                  DataColumn(label: _ColumnHead('Observación')),
                ],
                rows: lines.map((line) {
                  final diff = line.diferencia;
                  final accent = diff > 0
                      ? const Color(0xFF198754)
                      : diff < 0
                      ? const Color(0xFFCD3939)
                      : theme.colorScheme.onSurface;
                  final observation = line.observacion?.trim() ?? '';
                  return DataRow(
                    cells: [
                      DataCell(Text(line.insumoCodigo)),
                      DataCell(
                        SizedBox(
                          width: 165,
                          child: Tooltip(
                            message: line.insumoNombre,
                            child: Text(
                              line.insumoNombre,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      DataCell(Text(line.stockSistema.toStringAsFixed(2))),
                      DataCell(Text(line.stockContado.toStringAsFixed(2))),
                      DataCell(
                        Text(
                          '${diff > 0 ? '+' : ''}${diff.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: accent,
                            fontWeight: diff == 0
                                ? FontWeight.w500
                                : FontWeight.w800,
                          ),
                        ),
                      ),
                      DataCell(Text(line.unidadMedidaCodigo)),
                      DataCell(_DifferencePill(difference: diff)),
                      DataCell(
                        SizedBox(
                          width: 140,
                          child: observation.isEmpty
                              ? Text(
                                  '—',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                )
                              : Tooltip(
                                  message: observation,
                                  child: Text(
                                    observation,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ColumnHead extends StatelessWidget {
  const _ColumnHead(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
  );
}

class _DifferencePill extends StatelessWidget {
  const _DifferencePill({required this.difference});
  final double difference;

  @override
  Widget build(BuildContext context) {
    final positive = difference > 0;
    final negative = difference < 0;
    final color = positive
        ? const Color(0xFF198754)
        : negative
        ? const Color(0xFFC3422F)
        : const Color(0xFF198754);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            positive
                ? 'Sobrante'
                : negative
                ? 'Faltante'
                : 'Conciliado',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelFrame extends StatelessWidget {
  const _PanelFrame({required this.child, this.padding = EdgeInsets.zero});
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.025),
            offset: const Offset(0, 2),
            blurRadius: 12,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final normalized = label.trim().toUpperCase();
    final Color color;
    if (normalized == 'CERRADO') {
      color = const Color(0xFF198754);
    } else if (normalized == 'ANULADO') {
      color = const Color(0xFFB42318);
    } else if (normalized == 'ABIERTO') {
      color = const Color(0xFFDA5A16);
    } else {
      color = const Color(0xFFB7791F);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        normalized,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, this.icon});
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 5),
          ],
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}
