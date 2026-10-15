import 'package:erp_curtiembre_fronted/core/di/service_locator.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_breakpoints.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_colors.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_state.dart';
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
import 'package:erp_curtiembre_fronted/shared/widgets/data/app_table_pagination.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:talker_flutter/talker_flutter.dart';

IconData _movementIcon(String type) => switch (type.toUpperCase()) {
  'DEVOLUCION_PROVEEDOR' => Icons.undo_rounded,
  'AJUSTE_NEGATIVO' => Icons.remove_circle_outline,
  'PROCESO' => Icons.settings_outlined,
  _ => Icons.inventory_2_outlined,
};
Widget _lineTag(String value, Color background, Color foreground) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
  decoration: BoxDecoration(
    color: background,
    borderRadius: BorderRadius.circular(8),
  ),
  child: Text(
    value,
    style: TextStyle(color: foreground, fontWeight: FontWeight.w700),
  ),
);

class SalidasPage extends StatefulWidget {
  const SalidasPage({super.key});
  @override
  State<SalidasPage> createState() => _SalidasPageState();
}

class _SalidasPageState extends State<SalidasPage> {
  final _searchController = TextEditingController();
  // Nullable backing values also keep hot reload safe after these fields are
  // added to an already mounted State object.
  int? _page;
  int? _pageSize;
  String? _dateFilter;
  bool? _newestFirst;
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
      titleIcon: Icons.inventory_2_outlined,
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
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1800),
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
                    final visibleSalidas =
                        state.items.where((item) {
                          final now = DateTime.now();
                          final date = item.fechaSalida;
                          final matchesDate = switch (_dateFilter) {
                            'today' =>
                              date.year == now.year &&
                                  date.month == now.month &&
                                  date.day == now.day,
                            'week' =>
                              now.difference(date).inDays < 7 &&
                                  !date.isAfter(now),
                            'month' =>
                              date.year == now.year && date.month == now.month,
                            _ => true,
                          };
                          return matchesDate;
                        }).toList()..sort(
                          (a, b) => (_newestFirst ?? true)
                              ? b.fechaSalida.compareTo(a.fechaSalida)
                              : a.fechaSalida.compareTo(b.fechaSalida),
                        );
                    final listPanel = _SalidasListPanel(
                      state: state,
                      items: visibleSalidas,
                      page: _page ?? 0,
                      pageSize: _pageSize ?? 10,
                      newestFirst: _newestFirst ?? true,
                      onSortChanged: (value) => setState(() {
                        _newestFirst = value;
                        _page = 0;
                      }),
                      onPageChanged: (value) => setState(() => _page = value),
                      onPageSizeChanged: (value) => setState(() {
                        _pageSize = value;
                        _page = 0;
                      }),
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
                    final filters = _SalidasFiltersCard(
                      state: state,
                      controller: _searchController,
                      onSearch: _applySearch,
                      dateFilter: _dateFilter ?? 'all',
                      onDateChanged: (value) => setState(() {
                        _dateFilter = value;
                        _page = 0;
                      }),
                      onClear: () {
                        _searchController.clear();
                        setState(() {
                          _dateFilter = 'all';
                          _page = 0;
                        });
                        context.read<SalidasCubit>().load(
                          searchTerm: '',
                          tipoSalidaFilter: null,
                        );
                      },
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
                                    Expanded(child: listPanel),
                                    const Gap(AppSpacing.md),
                                    Expanded(child: detailPanel),
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
                                    Expanded(child: listPanel),
                                    const Gap(AppSpacing.md),
                                    Expanded(child: detailPanel),
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

class _SalidasFiltersCard extends StatelessWidget {
  const _SalidasFiltersCard({
    required this.state,
    required this.controller,
    required this.onSearch,
    required this.dateFilter,
    required this.onDateChanged,
    required this.onClear,
    required this.onTipoSalidaChanged,
    required this.onCreateGeneral,
    required this.onCreateSupplierReturn,
    required this.onCreateNegativeAdjustment,
  });
  final SalidasState state;
  final TextEditingController controller;
  final VoidCallback onSearch;
  final String dateFilter;
  final ValueChanged<String> onDateChanged;
  final VoidCallback onClear;
  final ValueChanged<String?> onTipoSalidaChanged;
  final VoidCallback onCreateGeneral;
  final VoidCallback onCreateSupplierReturn;
  final VoidCallback onCreateNegativeAdjustment;
  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final search = TextField(
                controller: controller,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => onSearch(),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  hintText: 'Buscar salida, proveedor, solicitud...',
                  prefixIcon: Icon(Icons.search_rounded, size: 18),
                ),
              );
              final type = DropdownButtonFormField<String>(
                isExpanded: true,
                key: ValueKey(state.tipoSalidaFilter),
                initialValue: state.tipoSalidaFilter ?? '',
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  labelText: 'Tipo de salida',
                  prefixIcon: Icon(Icons.layers_outlined, size: 19),
                ),
                items: const [
                  DropdownMenuItem(value: '', child: Text('Todas')),
                  DropdownMenuItem(value: 'GENERAL', child: Text('General')),
                  DropdownMenuItem(
                    value: 'DEVOLUCION_PROVEEDOR',
                    child: Text('Devolución proveedor'),
                  ),
                  DropdownMenuItem(
                    value: 'AJUSTE_NEGATIVO',
                    child: Text('Ajuste negativo'),
                  ),
                  DropdownMenuItem(value: 'PROCESO', child: Text('Proceso')),
                ],
                onChanged: (value) => onTipoSalidaChanged(
                  value == null || value.isEmpty ? null : value,
                ),
              );
              final date = DropdownButtonFormField<String>(
                key: ValueKey(dateFilter),
                initialValue: dateFilter,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  labelText: 'Fecha',
                  prefixIcon: Icon(Icons.calendar_today_outlined, size: 19),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'all',
                    child: Text('Todas las fechas'),
                  ),
                  DropdownMenuItem(value: 'today', child: Text('Hoy')),
                  DropdownMenuItem(
                    value: 'week',
                    child: Text('Últimos 7 días'),
                  ),
                  DropdownMenuItem(value: 'month', child: Text('Este mes')),
                ],
                onChanged: (value) {
                  if (value != null) onDateChanged(value);
                },
              );
              final button = FilledButton.icon(
                onPressed: onSearch,
                icon: const Icon(Icons.search_rounded, size: 17),
                label: const Text('Buscar'),
              );
              final clear = OutlinedButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.filter_alt_off_outlined, size: 17),
                label: const Text('Limpiar'),
              );
              if (constraints.maxWidth >= 950) {
                return Row(
                  children: [
                    Expanded(flex: 5, child: search),
                    const Gap(AppSpacing.sm),
                    Expanded(flex: 3, child: date),
                    const Gap(AppSpacing.sm),
                    Expanded(flex: 3, child: type),
                    const Gap(AppSpacing.sm),
                    SizedBox(width: 114, height: 42, child: button),
                    const Gap(AppSpacing.sm),
                    SizedBox(width: 105, height: 42, child: clear),
                  ],
                );
              }
              final fieldWidth = constraints.maxWidth >= 760
                  ? (constraints.maxWidth - AppSpacing.sm * 2) / 3
                  : constraints.maxWidth >= 580
                  ? (constraints.maxWidth - AppSpacing.sm) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: constraints.maxWidth >= 760
                        ? constraints.maxWidth
                        : fieldWidth,
                    child: search,
                  ),
                  SizedBox(width: fieldWidth, child: date),
                  SizedBox(width: fieldWidth, child: type),
                  SizedBox(width: 114, height: 42, child: button),
                  SizedBox(width: 105, height: 42, child: clear),
                ],
              );
            },
          ),
          const Gap(AppSpacing.sm),
          const SizedBox.shrink(),
          const Gap(AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                SizedBox(
                  height: 38,
                  child: FilledButton.icon(
                    onPressed: state.isSubmittingAction
                        ? null
                        : onCreateGeneral,
                    icon: const Icon(Icons.inventory_2_outlined, size: 18),
                    label: const Text('Salida general'),
                  ),
                ),
                SizedBox(
                  height: 38,
                  child: OutlinedButton.icon(
                    onPressed: state.isSubmittingAction
                        ? null
                        : onCreateSupplierReturn,
                    icon: const Icon(Icons.undo_rounded, size: 18),
                    label: const Text('Devolución a proveedor'),
                  ),
                ),
                SizedBox(
                  height: 38,
                  child: OutlinedButton.icon(
                    onPressed: state.isSubmittingAction
                        ? null
                        : onCreateNegativeAdjustment,
                    icon: const Icon(Icons.remove_circle_outline, size: 18),
                    label: const Text('Ajuste negativo'),
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

class _SalidasListPanel extends StatelessWidget {
  const _SalidasListPanel({
    required this.state,
    required this.items,
    required this.page,
    required this.pageSize,
    required this.newestFirst,
    required this.onSortChanged,
    required this.onPageChanged,
    required this.onPageSizeChanged,
    required this.onRetry,
    required this.onSelectSalida,
  });
  final SalidasState state;
  final List<SalidaRecord> items;
  final int page;
  final int pageSize;
  final bool newestFirst;
  final ValueChanged<bool> onSortChanged;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;
  final VoidCallback onRetry;
  final ValueChanged<int> onSelectSalida;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = items.length;
    final totalPages = (total / pageSize).ceil().clamp(1, 1 << 30).toInt();
    final currentPage = page.clamp(0, totalPages - 1).toInt();
    final start = currentPage * pageSize;
    final end = (start + pageSize).clamp(0, total).toInt();
    final visibleItems = items.sublist(start, end);
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
    if (items.isEmpty) {
      return const AppMessageCard.info(
        title: 'Sin salidas registradas',
        message: 'No hay movimientos que coincidan con los filtros actuales.',
      );
    }
    return AppSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Listado de salidas',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$total salidas',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<bool>(
                  value: newestFirst,
                  isDense: true,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: true, child: Text('Más recientes')),
                    DropdownMenuItem(value: false, child: Text('Más antiguas')),
                  ],
                  onChanged: (value) {
                    if (value != null) onSortChanged(value);
                  },
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: visibleItems.length,
              separatorBuilder: (_, _) => const Gap(AppSpacing.sm),
              itemBuilder: (context, index) {
                final item = visibleItems[index];
                final selected = state.selectedSalidaId == item.id;
                return _SalidaListTile(
                  item: item,
                  selected: selected,
                  onTap: () => onSelectSalida(item.id),
                );
              },
            ),
          ),
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
          AppTablePagination(
            page: currentPage,
            totalPages: totalPages,
            start: start,
            end: end,
            total: total,
            pageSize: pageSize,
            pageSizeOptions: const [10, 20, 50],
            onPageChanged: onPageChanged,
            onPageSizeChanged: onPageSizeChanged,
          ),
        ],
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
    const orange = Color(0xFFF45100);
    final secondary = theme.colorScheme.onSurfaceVariant;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFFFF6F1)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? orange : theme.colorScheme.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFFFE9DC)
                      : const Color(0xFFF0F3F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _movementIcon(item.tipoSalida),
                  color: selected ? orange : const Color(0xFF263244),
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.codigo,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (MediaQuery.sizeOf(context).width > 1170)
                          _StatusPill(
                            label: item.tipoSalida,
                            highlighted: selected,
                          ),
                        const SizedBox(width: 8),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.motivo ?? 'Sin motivo registrado',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: secondary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: secondary,
                        ),
                        _InlineInfo(
                          value: DateFormat(
                            'dd/MM/yyyy HH:mm',
                          ).format(item.fechaSalida),
                        ),
                        const _MetaDivider(),
                        _InlineInfo(
                          value:
                              '${item.totalItems} ${item.totalItems == 1 ? 'ítem' : 'ítems'}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: selected ? orange : secondary,
              ),
            ],
          ),
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
    final movementTotal = detail.detalles.fold<double>(
      0,
      (sum, line) => sum + line.costoTotal,
    );
    final color = theme.colorScheme;
    const orange = Color(0xFFF45100);
    final observations = detail.observacion?.trim();
    return AppSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: LayoutBuilder(
          builder: (context, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBDD),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        _movementIcon(detail.tipoSalida),
                        color: orange,
                        size: 29,
                      ),
                    ),
                    const SizedBox(width: 17),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            detail.codigo,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            detail.motivo ?? 'Sin motivo',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Salida registrada en el sistema',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: color.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 17),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    color: color.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.outlineVariant),
                  ),
                  child: LayoutBuilder(
                    builder: (context, infoConstraints) {
                      final infos = <Widget>[
                        _DetailInfo(
                          label: 'Tipo de salida',
                          value: detail.tipoSalida,
                          icon: Icons.layers_outlined,
                        ),
                        _DetailInfo(
                          label: 'Fecha y hora',
                          value: DateFormat(
                            'dd/MM/yyyy HH:mm',
                          ).format(detail.fechaSalida),
                          icon: Icons.calendar_today_outlined,
                        ),
                        _DetailInfo(
                          label: 'N° de ítems',
                          value: '${detail.detalles.length}',
                          icon: Icons.format_list_bulleted_rounded,
                        ),
                        _DetailInfo(
                          label: 'Monto total',
                          value: 'S/ ${movementTotal.toStringAsFixed(2)}',
                          icon: Icons.paid_outlined,
                          strong: true,
                        ),
                      ];
                      if (infoConstraints.maxWidth < 610) {
                        return Wrap(
                          spacing: 16,
                          runSpacing: 15,
                          children: infos
                              .map(
                                (w) => SizedBox(
                                  width: (infoConstraints.maxWidth - 16) / 2,
                                  child: w,
                                ),
                              )
                              .toList(),
                        );
                      }
                      return Row(
                        children: [
                          for (var i = 0; i < infos.length; i++) ...[
                            Expanded(child: infos[i]),
                            if (i < infos.length - 1)
                              Container(
                                height: 39,
                                width: 1,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                color: color.outlineVariant,
                              ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      color: orange,
                      size: 22,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Líneas afectadas',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${detail.detalles.length} ${detail.detalles.length == 1 ? 'ítem' : 'ítems'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // La tabla ocupa solamente el alto necesario, evitando enormes huecos.
                // Si hay muchas líneas, el área es desplazable independientemente.
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 315),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: color.outlineVariant),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SingleChildScrollView(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStatePropertyAll(
                              color.surfaceContainerLow,
                            ),
                            dataRowMinHeight: 51,
                            dataRowMaxHeight: 72,
                            columnSpacing: 13,
                            horizontalMargin: 12,
                            columns: const [
                              DataColumn(label: Text('#')),
                              DataColumn(label: Text('Código')),
                              DataColumn(label: Text('Descripción')),
                              DataColumn(label: Text('Cantidad')),
                              DataColumn(label: Text('Costo unitario')),
                              DataColumn(label: Text('Total')),
                              DataColumn(label: Text('Stock actual')),
                            ],
                            rows: [
                              for (var i = 0; i < detail.detalles.length; i++)
                                DataRow(
                                  cells: [
                                    DataCell(Text('${i + 1}')),
                                    DataCell(
                                      Text(detail.detalles[i].insumoCodigo),
                                    ),
                                    DataCell(
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(detail.detalles[i].insumoNombre),
                                          if (detail.detalles[i].observacion
                                                  ?.trim()
                                                  .isNotEmpty ==
                                              true)
                                            Text(
                                              detail.detalles[i].observacion!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color:
                                                        color.onSurfaceVariant,
                                                  ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    DataCell(
                                      _lineTag(
                                        '${detail.detalles[i].cantidad.toStringAsFixed(2)} ${detail.detalles[i].unidadMedidaCodigo}',
                                        const Color(0xFFEAF3FF),
                                        const Color(0xFF1465C0),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        'S/ ${detail.detalles[i].costoUnitario.toStringAsFixed(2)}',
                                      ),
                                    ),
                                    DataCell(
                                      _lineTag(
                                        'S/ ${detail.detalles[i].costoTotal.toStringAsFixed(2)}',
                                        const Color(0xFFDCF8E8),
                                        const Color(0xFF087745),
                                      ),
                                    ),
                                    DataCell(
                                      _lineTag(
                                        '${detail.detalles[i].stockActual.toStringAsFixed(2)} ${detail.detalles[i].unidadMedidaCodigo}',
                                        const Color(0xFFF0F2F8),
                                        const Color(0xFF455472),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 19),
                Row(
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: orange,
                      size: 21,
                    ),
                    const SizedBox(width: 9),
                    Text(
                      'Observaciones',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    color: color.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    observations == null || observations.isEmpty
                        ? '—'
                        : observations,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  alignment: WrapAlignment.start,
                  children: [
                    if (detail.tipoSalida == 'DEVOLUCION_PROVEEDOR')
                      FilledButton.icon(
                        onPressed: null,
                        icon: Icon(Icons.refresh_rounded, size: 18),
                        label: Text('Generar devolución similar'),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, this.highlighted = false});
  final String label;
  final bool highlighted;
  @override
  Widget build(BuildContext context) {
    final isProcess = label.toUpperCase() == 'PROCESO';
    final foreground = isProcess
        ? const Color(0xFF1664C4)
        : highlighted
        ? const Color(0xFFE64A00)
        : const Color(0xFF445367);
    final background = isProcess
        ? const Color(0xFFEAF3FF)
        : highlighted
        ? const Color(0xFFFFEADC)
        : const Color(0xFFF1F3F6);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

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

class _DetailInfo extends StatelessWidget {
  const _DetailInfo({
    required this.label,
    required this.value,
    this.strong = false,
    this.icon,
  });
  final String label;
  final String value;
  final bool strong;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final info = Column(
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
    if (icon == null) return info;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const Gap(AppSpacing.sm),
        Flexible(child: info),
      ],
    );
  }
}
