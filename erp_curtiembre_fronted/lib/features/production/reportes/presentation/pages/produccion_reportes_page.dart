import 'package:erp_curtiembre_fronted/core/di/service_locator.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_breakpoints.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_state.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/orden_proceso_record.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/orden_produccion_record.dart';
import 'package:erp_curtiembre_fronted/features/production/reportes/presentation/cubit/produccion_reportes_cubit.dart';
import 'package:erp_curtiembre_fronted/features/production/reportes/presentation/cubit/produccion_reportes_state.dart';
import 'package:erp_curtiembre_fronted/features/production/reportes/domain/entities/consumo_proceso_reporte_item.dart';
import 'package:erp_curtiembre_fronted/features/production/reportes/domain/entities/tiempo_proceso_reporte_item.dart';
import 'package:erp_curtiembre_fronted/features/security/presentation/cubit/security_access_cubit.dart';
import 'package:erp_curtiembre_fronted/shared/navigation/app_access_routes.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/buttons/app_button.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/feedback/app_message_card.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/layout/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:talker_flutter/talker_flutter.dart';

class ProduccionReportesPage extends StatefulWidget {
  const ProduccionReportesPage({super.key});

  @override
  State<ProduccionReportesPage> createState() => _ProduccionReportesPageState();
}

class _ProduccionReportesPageState extends State<ProduccionReportesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final Talker _talker = getIt<Talker>();

  @override
  void initState() {
    super.initState();
    _talker.ui('Se abrio la pantalla de reportes de produccion.');
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(_handleTabChanged);
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_handleTabChanged)
      ..dispose();
    super.dispose();
  }

  void _handleTabChanged() {
    if (_tabController.indexIsChanging) {
      return;
    }

    _talker.ui(
      'Se cambio a la pestaña ${_tabLabel(_currentTab)} de reportes de produccion.',
      logLevel: LogLevel.debug,
    );
    context.read<ProduccionReportesCubit>().ensureTabLoaded(_currentTab);
  }

  ProduccionReportesTab get _currentTab {
    return switch (_tabController.index) {
      0 => ProduccionReportesTab.ordenesActivas,
      1 => ProduccionReportesTab.ordenesCliente,
      2 => ProduccionReportesTab.consumoProceso,
      3 => ProduccionReportesTab.merma,
      4 => ProduccionReportesTab.tiemposProceso,
      _ => ProduccionReportesTab.costosOrden,
    };
  }

  Future<void> _pickDate({
    required DateTime? initialDate,
    required ValueChanged<DateTime?> onChanged,
  }) async {
    _talker.ui(
      'Se abrio un selector de fecha en reportes con valor inicial=${_describeDate(initialDate)}.',
      logLevel: LogLevel.debug,
    );
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (!mounted) {
      return;
    }
    _talker.ui(
      selected == null
          ? 'Se cerro el selector de fecha sin elegir valor.'
          : 'Se selecciono una fecha en reportes: ${_describeDate(selected)}.',
      logLevel: LogLevel.debug,
    );
    onChanged(selected);
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
      title: 'Reportes de produccion',
      currentPath: '/produccion/reportes',
      breadcrumbs: const ['Inicio', 'Produccion', 'Reportes'],
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
            child: BlocBuilder<ProduccionReportesCubit, ProduccionReportesState>(
              builder: (context, state) {
                if (state.status == ProduccionReportesStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.status == ProduccionReportesStatus.error) {
                  return _CenteredMessage(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppMessageCard.error(
                          title: 'No pudimos preparar los reportes',
                          message:
                              state.baseErrorMessage ??
                              'Intenta nuevamente para cargar la base de produccion.',
                        ),
                        const Gap(AppSpacing.lg),
                        AppButton.secondary(
                          label: 'Reintentar',
                          icon: Icons.refresh_rounded,
                          onPressed: () {
                            _talker.ui(
                              'Se solicito reintentar la carga base de reportes de produccion.',
                            );
                            context
                                .read<ProduccionReportesCubit>()
                                .initialize();
                          },
                        ),
                      ],
                    ),
                  );
                }

                final tabsView = TabBarView(
                  controller: _tabController,
                  children: [
                    _OrdenesActivasTab(
                      state: state,
                      onRefresh: () {
                        _talker.ui(
                          'Se solicito actualizar el reporte de ordenes activas.',
                        );
                        context
                            .read<ProduccionReportesCubit>()
                            .loadOrdenesActivas();
                      },
                    ),
                    _OrdenesClienteTab(
                      state: state,
                      onApply:
                          ({
                            int? clienteId,
                            String? estado,
                            DateTime? fechaDesde,
                            DateTime? fechaHasta,
                          }) {
                            _talker.ui(
                              'Se aplicaron filtros en ordenes por cliente con clienteId=$clienteId, estado=${_describeState(estado)}, fechaDesde=${_describeDate(fechaDesde)}, fechaHasta=${_describeDate(fechaHasta)}.',
                              logLevel: LogLevel.debug,
                            );
                            return context
                                .read<ProduccionReportesCubit>()
                                .loadOrdenesCliente(
                                  clienteId: clienteId,
                                  estado: estado,
                                  fechaDesde: fechaDesde,
                                  fechaHasta: fechaHasta,
                                );
                          },
                      onPickDate: _pickDate,
                      onClear: () {
                        _talker.ui(
                          'Se limpiaron los filtros del reporte de ordenes por cliente.',
                          logLevel: LogLevel.debug,
                        );
                        context
                            .read<ProduccionReportesCubit>()
                            .loadOrdenesCliente(
                              clienteId: null,
                              estado: null,
                              fechaDesde: null,
                              fechaHasta: null,
                            );
                      },
                    ),
                    _ConsumoProcesoTab(
                      state: state,
                      processOptionsForOrder: context
                          .read<ProduccionReportesCubit>()
                          .processOptionsForOrder,
                      onApply: ({int? ordenProduccionId, int? ordenProcesoId}) {
                        _talker.ui(
                          'Se aplicaron filtros en consumo por proceso con ordenProduccionId=$ordenProduccionId y ordenProcesoId=$ordenProcesoId.',
                          logLevel: LogLevel.debug,
                        );
                        return context
                            .read<ProduccionReportesCubit>()
                            .loadConsumoProceso(
                              ordenProduccionId: ordenProduccionId,
                              ordenProcesoId: ordenProcesoId,
                            );
                      },
                      onClear: () {
                        _talker.ui(
                          'Se limpiaron los filtros del reporte de consumo por proceso.',
                          logLevel: LogLevel.debug,
                        );
                        context
                            .read<ProduccionReportesCubit>()
                            .loadConsumoProceso(
                              ordenProduccionId: null,
                              ordenProcesoId: null,
                            );
                      },
                    ),
                    _MermaTab(
                      state: state,
                      processOptionsForOrder: context
                          .read<ProduccionReportesCubit>()
                          .processOptionsForOrder,
                      onApply:
                          ({
                            int? ordenProduccionId,
                            int? ordenProcesoId,
                            DateTime? fechaDesde,
                            DateTime? fechaHasta,
                          }) {
                            _talker.ui(
                              'Se aplicaron filtros en merma con ordenProduccionId=$ordenProduccionId, ordenProcesoId=$ordenProcesoId, fechaDesde=${_describeDate(fechaDesde)}, fechaHasta=${_describeDate(fechaHasta)}.',
                              logLevel: LogLevel.debug,
                            );
                            return context
                                .read<ProduccionReportesCubit>()
                                .loadMerma(
                                  ordenProduccionId: ordenProduccionId,
                                  ordenProcesoId: ordenProcesoId,
                                  fechaDesde: fechaDesde,
                                  fechaHasta: fechaHasta,
                                );
                          },
                      onPickDate: _pickDate,
                      onClear: () {
                        _talker.ui(
                          'Se limpiaron los filtros del reporte de merma.',
                          logLevel: LogLevel.debug,
                        );
                        context.read<ProduccionReportesCubit>().loadMerma(
                          ordenProduccionId: null,
                          ordenProcesoId: null,
                          fechaDesde: null,
                          fechaHasta: null,
                        );
                      },
                    ),
                    _TiemposProcesoTab(
                      state: state,
                      processOptionsForOrder: context
                          .read<ProduccionReportesCubit>()
                          .processOptionsForOrder,
                      onApply:
                          ({
                            int? ordenProduccionId,
                            int? ordenProcesoId,
                            String? estado,
                          }) {
                            _talker.ui(
                              'Se aplicaron filtros en tiempos de proceso con ordenProduccionId=$ordenProduccionId, ordenProcesoId=$ordenProcesoId, estado=${_describeState(estado)}.',
                              logLevel: LogLevel.debug,
                            );
                            return context
                                .read<ProduccionReportesCubit>()
                                .loadTiemposProceso(
                                  ordenProduccionId: ordenProduccionId,
                                  ordenProcesoId: ordenProcesoId,
                                  estado: estado,
                                );
                          },
                      onClear: () {
                        _talker.ui(
                          'Se limpiaron los filtros del reporte de tiempos de proceso.',
                          logLevel: LogLevel.debug,
                        );
                        context
                            .read<ProduccionReportesCubit>()
                            .loadTiemposProceso(
                              ordenProduccionId: null,
                              ordenProcesoId: null,
                              estado: null,
                            );
                      },
                    ),
                    _CostosOrdenTabV2(
                      state: state,
                      onApply: (ordenProduccionId) {
                        return context
                            .read<ProduccionReportesCubit>()
                            .loadCostosOrden(
                              ordenProduccionId: ordenProduccionId,
                            );
                      },
                      onClear: () {
                        return context
                            .read<ProduccionReportesCubit>()
                            .loadCostosOrden(ordenProduccionId: null);
                      },
                    ),
                  ],
                );

                final tabsHeader = Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    onTap: (_) {
                      context.read<ProduccionReportesCubit>().ensureTabLoaded(
                        _currentTab,
                      );
                    },
                    tabs: const [
                      Tab(text: 'Ordenes activas'),
                      Tab(text: 'Ordenes por cliente'),
                      Tab(text: 'Consumo por proceso'),
                      Tab(text: 'Merma'),
                      Tab(text: 'Tiempos de proceso'),
                      Tab(text: 'Costos reales'),
                    ],
                  ),
                );

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final compactHeight = constraints.maxHeight < 920;

                    if (compactHeight) {
                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            tabsHeader,
                            const Gap(AppSpacing.lg),
                            SizedBox(
                              height: constraints.maxHeight.clamp(720.0, 980.0),
                              child: tabsView,
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        tabsHeader,
                        const Gap(AppSpacing.lg),
                        Expanded(child: tabsView),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  String _tabLabel(ProduccionReportesTab tab) {
    return switch (tab) {
      ProduccionReportesTab.ordenesActivas => 'ordenes-activas',
      ProduccionReportesTab.ordenesCliente => 'ordenes-cliente',
      ProduccionReportesTab.consumoProceso => 'consumo-proceso',
      ProduccionReportesTab.merma => 'merma',
      ProduccionReportesTab.tiemposProceso => 'tiempos-proceso',
      ProduccionReportesTab.costosOrden => 'costos-orden',
    };
  }

  String _describeState(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return normalized;
  }

  String _describeDate(DateTime? value) {
    if (value == null) {
      return 'sin-fecha';
    }

    return value.toIso8601String();
  }
}

class _OrdenesActivasTab extends StatelessWidget {
  const _OrdenesActivasTab({required this.state, required this.onRefresh});

  final ProduccionReportesState state;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return _ReportTabScaffold(
      filterCard: _InfoFilterCard(
        title: 'Sin filtros obligatorios',
        description:
            'Este reporte muestra las ordenes que siguen en curso y conviene refrescarlo cuando cambie el avance operativo.',
        actions: [
          AppButton.secondary(
            label: 'Actualizar',
            icon: Icons.refresh_rounded,
            isLoading: state.loadingOrdenesActivas,
            onPressed: onRefresh,
          ),
        ],
      ),
      resultsCard: _ResultsCard(
        title: 'Ordenes activas',
        subtitle: '${state.ordenesActivas.length} registro(s) visibles.',
        itemCount: state.ordenesActivas.length,
        isLoading: state.loadingOrdenesActivas,
        errorMessage: state.ordenesActivasErrorMessage,
        onRetry: onRefresh,
        emptyTitle: 'Sin ordenes activas',
        emptyMessage:
            'Cuando existan ordenes en ejecucion apareceran aqui con cliente, responsable y fecha comprometida.',
        child: ListView.separated(
          itemCount: state.ordenesActivas.length,
          separatorBuilder: (_, _) => const Gap(AppSpacing.md),
          itemBuilder: (context, index) {
            final item = state.ordenesActivas[index];
            return _ReportItemCard(
              title: item.codigoOrden,
              subtitle: '${item.cliente} · Lote ${item.codigoLote}',
              chips: [
                _cardChip(context, item.estado),
                if ((item.responsable ?? '').trim().isNotEmpty)
                  _cardChip(context, item.responsable!),
              ],
              lines: [
                'Inicio real: ${_formatOptionalDateTime(item.fechaInicioReal)}',
                'Fin estimado: ${_formatDateTime(item.fechaFinEstimada)}',
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OrdenesClienteTab extends StatelessWidget {
  const _OrdenesClienteTab({
    required this.state,
    required this.onApply,
    required this.onPickDate,
    required this.onClear,
  });

  final ProduccionReportesState state;
  final Future<void> Function({
    int? clienteId,
    String? estado,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  })
  onApply;
  final Future<void> Function({
    required DateTime? initialDate,
    required ValueChanged<DateTime?> onChanged,
  })
  onPickDate;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return _ReportTabScaffold(
      filterCard: _SurfaceCard(
        title: 'Filtros por cliente',
        subtitle:
            'Cruza cliente, estado y fechas para revisar la carga operativa por cuenta.',
        child: Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.lg,
          children: [
            SizedBox(
              width: 520,
              child: _SearchableReportFilter<int>(
                key: ValueKey('cliente-${state.ordenesClienteClienteId}'),
                label: 'Buscar cliente',
                hint: 'Escribe nombre o documento',
                selectedValue: state.ordenesClienteClienteId,
                options: state.clienteOptions
                    .map((item) => _SearchOption(item.id, item.label))
                    .toList(growable: false),
                onSelected: (value) => onApply(
                  clienteId: value,
                  estado: state.ordenesClienteEstado,
                  fechaDesde: state.ordenesClienteFechaDesde,
                  fechaHasta: state.ordenesClienteFechaHasta,
                ),
              ),
            ),
            SizedBox(
              width: 240,
              child: DropdownButtonFormField<String?>(
                initialValue: state.ordenesClienteEstado,
                decoration: const InputDecoration(labelText: 'Estado'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Todos'),
                  ),
                  ..._availableOrderStates(state.ordenOptions).map(
                    (item) => DropdownMenuItem<String?>(
                      value: item,
                      child: Text(item),
                    ),
                  ),
                ],
                onChanged: (value) => onApply(
                  clienteId: state.ordenesClienteClienteId,
                  estado: value,
                  fechaDesde: state.ordenesClienteFechaDesde,
                  fechaHasta: state.ordenesClienteFechaHasta,
                ),
              ),
            ),
            _DateButton(
              label: 'Desde',
              value: state.ordenesClienteFechaDesde,
              onPressed: () => onPickDate(
                initialDate: state.ordenesClienteFechaDesde,
                onChanged: (value) => onApply(
                  clienteId: state.ordenesClienteClienteId,
                  estado: state.ordenesClienteEstado,
                  fechaDesde: value,
                  fechaHasta: state.ordenesClienteFechaHasta,
                ),
              ),
            ),
            _DateButton(
              label: 'Hasta',
              value: state.ordenesClienteFechaHasta,
              onPressed: () => onPickDate(
                initialDate: state.ordenesClienteFechaHasta,
                onChanged: (value) => onApply(
                  clienteId: state.ordenesClienteClienteId,
                  estado: state.ordenesClienteEstado,
                  fechaDesde: state.ordenesClienteFechaDesde,
                  fechaHasta: value,
                ),
              ),
            ),
            AppButton.secondary(
              label: 'Limpiar',
              icon: Icons.filter_alt_off_outlined,
              onPressed: onClear,
            ),
          ],
        ),
      ),
      resultsCard: _ResultsCard(
        title: 'Ordenes por cliente',
        subtitle: '${state.ordenesCliente.length} registro(s) visibles.',
        itemCount: state.ordenesCliente.length,
        isLoading: state.loadingOrdenesCliente,
        errorMessage: state.ordenesClienteErrorMessage,
        onRetry: () => onApply(
          clienteId: state.ordenesClienteClienteId,
          estado: state.ordenesClienteEstado,
          fechaDesde: state.ordenesClienteFechaDesde,
          fechaHasta: state.ordenesClienteFechaHasta,
        ),
        emptyTitle: 'Sin resultados',
        emptyMessage: 'No encontramos ordenes con los filtros actuales.',
        child: ListView.separated(
          itemCount: state.ordenesCliente.length,
          separatorBuilder: (_, _) => const Gap(AppSpacing.md),
          itemBuilder: (context, index) {
            final item = state.ordenesCliente[index];
            return _ReportItemCard(
              title: item.codigoOrden,
              subtitle: '${item.cliente} · Lote ${item.codigoLote}',
              chips: [
                _cardChip(context, item.estado),
                _cardChip(
                  context,
                  '${_formatDecimal(item.cantidadPieles)} pieles',
                ),
              ],
              lines: [
                'Inicio real: ${_formatOptionalDateTime(item.fechaInicioReal)}',
                'Fin estimado: ${_formatDateTime(item.fechaFinEstimada)}',
                'Fin real: ${_formatOptionalDateTime(item.fechaFinReal)}',
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ConsumoProcesoTab extends StatelessWidget {
  const _ConsumoProcesoTab({
    required this.state,
    required this.processOptionsForOrder,
    required this.onApply,
    required this.onClear,
  });

  final ProduccionReportesState state;
  final List<OrdenProcesoRecord> Function(int? orderId) processOptionsForOrder;
  final Future<void> Function({int? ordenProduccionId, int? ordenProcesoId})
  onApply;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final processes = processOptionsForOrder(state.consumoOrdenProduccionId);

    return _ReportTabScaffold(
      filterCard: _SurfaceCard(
        title: 'Cruce de orden y proceso',
        subtitle:
            'Sirve para comparar lo planificado contra lo real y detectar rapidamente desviaciones de insumos.',
        child: Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.lg,
          children: [
            SizedBox(
              width: 360,
              child: _SearchableReportFilter<int>(
                key: ValueKey(state.consumoOrdenProduccionId),
                label: 'Buscar orden de produccion',
                hint: 'Escribe codigo, cliente o estado',
                selectedValue: state.consumoOrdenProduccionId,
                options: state.ordenOptions
                    .map(
                      (item) => _SearchOption(item.id, _ordenOptionLabel(item)),
                    )
                    .toList(growable: false),
                onSelected: (value) =>
                    onApply(ordenProduccionId: value, ordenProcesoId: null),
              ),
            ),
            SizedBox(
              width: 320,
              child: DropdownButtonFormField<int?>(
                initialValue: state.consumoOrdenProcesoId,
                decoration: const InputDecoration(labelText: 'Proceso'),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Todos'),
                  ),
                  ...processes.map(
                    (item) => DropdownMenuItem<int?>(
                      value: item.id,
                      child: Text(
                        '${item.procesoCodigo} · ${item.procesoNombre}',
                      ),
                    ),
                  ),
                ],
                onChanged: state.consumoOrdenProduccionId == null
                    ? null
                    : (value) => onApply(
                        ordenProduccionId: state.consumoOrdenProduccionId,
                        ordenProcesoId: value,
                      ),
              ),
            ),
            AppButton.secondary(
              label: 'Limpiar',
              icon: Icons.filter_alt_off_outlined,
              onPressed: onClear,
            ),
          ],
        ),
      ),
      resultsCard: _ResultsCard(
        title: 'Consumo por proceso',
        subtitle: '${state.consumoProceso.length} registro(s) visibles.',
        itemCount: state.consumoProceso.length,
        isLoading: state.loadingConsumoProceso,
        errorMessage: state.consumoProcesoErrorMessage,
        onRetry: () => onApply(
          ordenProduccionId: state.consumoOrdenProduccionId,
          ordenProcesoId: state.consumoOrdenProcesoId,
        ),
        emptyTitle: 'Sin consumo visible',
        emptyMessage:
            'No encontramos consumos para el cruce actual de orden y proceso.',
        child: _ConsumptionGroupedList(
          items: state.consumoProceso,
          orders: state.ordenOptions,
        ),
      ),
    );
  }
}

class _MermaTab extends StatelessWidget {
  const _MermaTab({
    required this.state,
    required this.processOptionsForOrder,
    required this.onApply,
    required this.onPickDate,
    required this.onClear,
  });

  final ProduccionReportesState state;
  final List<OrdenProcesoRecord> Function(int? orderId) processOptionsForOrder;
  final Future<void> Function({
    int? ordenProduccionId,
    int? ordenProcesoId,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  })
  onApply;
  final Future<void> Function({
    required DateTime? initialDate,
    required ValueChanged<DateTime?> onChanged,
  })
  onPickDate;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final processes = processOptionsForOrder(state.mermaOrdenProduccionId);

    return _ReportTabScaffold(
      filterCard: _SurfaceCard(
        title: 'Seguimiento de merma',
        subtitle:
            'Filtra por orden, proceso o fechas para ubicar donde se concentran las perdidas.',
        child: Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.lg,
          children: [
            SizedBox(
              width: 360,
              child: DropdownButtonFormField<int?>(
                initialValue: state.mermaOrdenProduccionId,
                decoration: const InputDecoration(
                  labelText: 'Orden de produccion',
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Todas'),
                  ),
                  ...state.ordenOptions.map(
                    (item) => DropdownMenuItem<int?>(
                      value: item.id,
                      child: Text(_ordenOptionLabel(item)),
                    ),
                  ),
                ],
                onChanged: (value) => onApply(
                  ordenProduccionId: value,
                  ordenProcesoId: null,
                  fechaDesde: state.mermaFechaDesde,
                  fechaHasta: state.mermaFechaHasta,
                ),
              ),
            ),
            SizedBox(
              width: 320,
              child: DropdownButtonFormField<int?>(
                initialValue: state.mermaOrdenProcesoId,
                decoration: const InputDecoration(labelText: 'Proceso'),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Todos'),
                  ),
                  ...processes.map(
                    (item) => DropdownMenuItem<int?>(
                      value: item.id,
                      child: Text(
                        '${item.procesoCodigo} · ${item.procesoNombre}',
                      ),
                    ),
                  ),
                ],
                onChanged: state.mermaOrdenProduccionId == null
                    ? null
                    : (value) => onApply(
                        ordenProduccionId: state.mermaOrdenProduccionId,
                        ordenProcesoId: value,
                        fechaDesde: state.mermaFechaDesde,
                        fechaHasta: state.mermaFechaHasta,
                      ),
              ),
            ),
            _DateButton(
              label: 'Desde',
              value: state.mermaFechaDesde,
              onPressed: () => onPickDate(
                initialDate: state.mermaFechaDesde,
                onChanged: (value) => onApply(
                  ordenProduccionId: state.mermaOrdenProduccionId,
                  ordenProcesoId: state.mermaOrdenProcesoId,
                  fechaDesde: value,
                  fechaHasta: state.mermaFechaHasta,
                ),
              ),
            ),
            _DateButton(
              label: 'Hasta',
              value: state.mermaFechaHasta,
              onPressed: () => onPickDate(
                initialDate: state.mermaFechaHasta,
                onChanged: (value) => onApply(
                  ordenProduccionId: state.mermaOrdenProduccionId,
                  ordenProcesoId: state.mermaOrdenProcesoId,
                  fechaDesde: state.mermaFechaDesde,
                  fechaHasta: value,
                ),
              ),
            ),
            AppButton.secondary(
              label: 'Limpiar',
              icon: Icons.filter_alt_off_outlined,
              onPressed: onClear,
            ),
          ],
        ),
      ),
      resultsCard: _ResultsCard(
        title: 'Reporte de merma',
        subtitle: '${state.mermas.length} registro(s) visibles.',
        itemCount: state.mermas.length,
        isLoading: state.loadingMerma,
        errorMessage: state.mermaErrorMessage,
        onRetry: () => onApply(
          ordenProduccionId: state.mermaOrdenProduccionId,
          ordenProcesoId: state.mermaOrdenProcesoId,
          fechaDesde: state.mermaFechaDesde,
          fechaHasta: state.mermaFechaHasta,
        ),
        emptyTitle: 'Sin merma visible',
        emptyMessage:
            'No encontramos registros de merma con los filtros actuales.',
        child: ListView.separated(
          itemCount: state.mermas.length,
          separatorBuilder: (_, _) => const Gap(AppSpacing.md),
          itemBuilder: (context, index) {
            final item = state.mermas[index];
            return _ReportItemCard(
              title: '${item.codigoOrden} · ${item.procesoCodigo}',
              subtitle: item.procesoNombre,
              chips: [
                _cardChip(
                  context,
                  '${_formatDecimal(item.cantidadPerdida)} perdidas',
                ),
                if ((item.responsable ?? '').trim().isNotEmpty)
                  _cardChip(context, item.responsable!),
              ],
              lines: [
                'Registrado en: ${_formatDateTime(item.registradoEn)}',
                'Motivo: ${(item.motivo ?? 'Sin motivo').trim()}',
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TiemposProcesoTab extends StatelessWidget {
  const _TiemposProcesoTab({
    required this.state,
    required this.processOptionsForOrder,
    required this.onApply,
    required this.onClear,
  });

  final ProduccionReportesState state;
  final List<OrdenProcesoRecord> Function(int? orderId) processOptionsForOrder;
  final Future<void> Function({
    int? ordenProduccionId,
    int? ordenProcesoId,
    String? estado,
  })
  onApply;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final processes = processOptionsForOrder(state.tiemposOrdenProduccionId);

    return _ReportTabScaffold(
      filterCard: _SurfaceCard(
        title: 'Tiempos por proceso',
        subtitle:
            'Usa este cruce para revisar cuellos de botella y procesos que siguen abiertos.',
        child: Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.lg,
          children: [
            SizedBox(
              width: 360,
              child: _SearchableReportFilter<int>(
                key: ValueKey('tiempo-orden-${state.tiemposOrdenProduccionId}'),
                label: 'Orden o cliente',
                hint: 'Escribe codigo o nombre del cliente',
                selectedValue: state.tiemposOrdenProduccionId,
                options: state.ordenOptions
                    .map(
                      (item) => _SearchOption(item.id, _ordenOptionLabel(item)),
                    )
                    .toList(growable: false),
                onSelected: (value) => onApply(
                  ordenProduccionId: value,
                  ordenProcesoId: null,
                  estado: state.tiemposEstado,
                ),
              ),
            ),
            SizedBox(
              width: 320,
              child: DropdownButtonFormField<int?>(
                initialValue: state.tiemposOrdenProcesoId,
                decoration: const InputDecoration(labelText: 'Proceso'),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Todos'),
                  ),
                  ...processes.map(
                    (item) => DropdownMenuItem<int?>(
                      value: item.id,
                      child: Text(
                        '${item.procesoCodigo} · ${item.procesoNombre}',
                      ),
                    ),
                  ),
                ],
                onChanged: state.tiemposOrdenProduccionId == null
                    ? null
                    : (value) => onApply(
                        ordenProduccionId: state.tiemposOrdenProduccionId,
                        ordenProcesoId: value,
                        estado: state.tiemposEstado,
                      ),
              ),
            ),
            SizedBox(
              width: 240,
              child: DropdownButtonFormField<String?>(
                initialValue: state.tiemposEstado,
                decoration: const InputDecoration(
                  labelText: 'Estado del proceso',
                ),
                items: const [
                  DropdownMenuItem<String?>(value: null, child: Text('Todos')),
                  DropdownMenuItem<String?>(
                    value: 'PENDIENTE',
                    child: Text('PENDIENTE'),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'EN_PROCESO',
                    child: Text('EN_PROCESO'),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'FINALIZADO',
                    child: Text('FINALIZADO'),
                  ),
                ],
                onChanged: (value) => onApply(
                  ordenProduccionId: state.tiemposOrdenProduccionId,
                  ordenProcesoId: state.tiemposOrdenProcesoId,
                  estado: value,
                ),
              ),
            ),
            AppButton.secondary(
              label: 'Limpiar',
              icon: Icons.filter_alt_off_outlined,
              onPressed: onClear,
            ),
          ],
        ),
      ),
      resultsCard: _ResultsCard(
        title: 'Tiempos de proceso',
        subtitle: '${state.tiemposProceso.length} registro(s) visibles.',
        itemCount: state.tiemposProceso.length,
        isLoading: state.loadingTiemposProceso,
        errorMessage: state.tiemposProcesoErrorMessage,
        onRetry: () => onApply(
          ordenProduccionId: state.tiemposOrdenProduccionId,
          ordenProcesoId: state.tiemposOrdenProcesoId,
          estado: state.tiemposEstado,
        ),
        emptyTitle: 'Sin tiempos visibles',
        emptyMessage: 'No encontramos procesos para el filtro actual.',
        child: _TimesGroupedList(
          items: state.tiemposProceso,
          orders: state.ordenOptions,
        ),
      ),
    );
  }
}

class _TimesGroupedList extends StatelessWidget {
  const _TimesGroupedList({required this.items, required this.orders});

  final List<TiempoProcesoReporteItem> items;
  final List<OrdenProduccionRecord> orders;

  @override
  Widget build(BuildContext context) {
    final grouped = <int, List<TiempoProcesoReporteItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.ordenProduccionId, () => []).add(item);
    }
    return ListView(
      children: grouped.entries
          .map((entry) {
            final rows = entry.value;
            OrdenProduccionRecord? order;
            for (final candidate in orders) {
              if (candidate.id == entry.key) {
                order = candidate;
                break;
              }
            }
            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              child: ExpansionTile(
                initiallyExpanded: grouped.length == 1,
                title: Text(
                  '${rows.first.codigoOrden} · ${order?.clienteRazonSocial ?? 'Cliente no disponible'}',
                ),
                subtitle: Text('${rows.length} etapas productivas'),
                children: rows
                    .map(
                      (item) => ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          child: Text(item.procesoCodigo.substring(0, 1)),
                        ),
                        title: Text(
                          '${item.procesoCodigo} · ${item.procesoNombre}',
                        ),
                        subtitle: Text(
                          'Inicio: ${_formatOptionalDateTime(item.fechaInicio)}  |  Fin: ${_formatOptionalDateTime(item.fechaFin)}  |  ${(item.responsable ?? 'Sin responsable').trim()}',
                        ),
                        trailing: _cardChip(
                          context,
                          item.diasReales == null
                              ? item.estado
                              : '${item.diasReales} dias',
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

class _ConsumptionGroupedList extends StatelessWidget {
  const _ConsumptionGroupedList({required this.items, required this.orders});

  final List<ConsumoProcesoReporteItem> items;
  final List<OrdenProduccionRecord> orders;

  @override
  Widget build(BuildContext context) {
    final grouped = <int, List<ConsumoProcesoReporteItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.ordenProduccionId, () => []).add(item);
    }

    return ListView(
      children: grouped.entries
          .map((entry) {
            final rows = entry.value;
            OrdenProduccionRecord? order;
            for (final candidate in orders) {
              if (candidate.id == entry.key) {
                order = candidate;
                break;
              }
            }
            final total = rows.fold<double>(
              0,
              (sum, item) => sum + item.costoTotal,
            );
            final byProcess = <String, List<ConsumoProcesoReporteItem>>{};
            for (final item in rows) {
              byProcess.putIfAbsent(item.procesoNombre, () => []).add(item);
            }
            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                initiallyExpanded: grouped.length == 1,
                title: Text(
                  '${rows.first.codigoOrden} · ${order?.clienteRazonSocial ?? 'Cliente no disponible'}',
                ),
                subtitle: Text(
                  '${byProcess.length} procesos · ${rows.length} insumos · S/ ${total.toStringAsFixed(2)}',
                ),
                children: byProcess.entries
                    .map((process) {
                      final processTotal = process.value.fold<double>(
                        0,
                        (sum, item) => sum + item.costoTotal,
                      );
                      return ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        title: Text(process.key),
                        subtitle: Text(
                          '${process.value.length} insumos · S/ ${processTotal.toStringAsFixed(2)}',
                        ),
                        children: process.value
                            .map(
                              (item) => ListTile(
                                dense: true,
                                title: Text(
                                  '${item.insumoCodigo} · ${item.insumoNombre}',
                                ),
                                subtitle: Text(
                                  'Plan ${_formatDecimal(item.cantidadPlanificada)}  |  Real ${_formatDecimal(item.cantidadReal)}  |  Desv. ${_formatSignedDecimal(item.cantidadDesviacion)}',
                                ),
                                trailing: Text(
                                  'S/ ${item.costoTotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            )
                            .toList(growable: false),
                      );
                    })
                    .toList(growable: false),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

class _ReportTabScaffold extends StatelessWidget {
  const _ReportTabScaffold({
    required this.filterCard,
    required this.resultsCard,
  });

  final Widget filterCard;
  final Widget resultsCard;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;

    if (isWide) {
      return Column(
        children: [
          filterCard,
          const Gap(AppSpacing.lg),
          Expanded(child: resultsCard),
        ],
      );
    }

    return Column(
      children: [
        filterCard,
        const Gap(AppSpacing.lg),
        Expanded(child: resultsCard),
      ],
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compactTheme = theme.copyWith(
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 12,
        ),
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Semantics(
        label: '$title. $subtitle',
        child: Theme(data: compactTheme, child: child),
      ),
    );
  }
}

class _InfoFilterCard extends StatelessWidget {
  const _InfoFilterCard({
    required this.title,
    required this.description,
    required this.actions,
  });

  final String title;
  final String description;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      title: title,
      subtitle: description,
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        children: actions,
      ),
    );
  }
}

class _ResultsCard extends StatelessWidget {
  const _ResultsCard({
    required this.title,
    required this.subtitle,
    required this.itemCount,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.child,
  });

  final String title;
  final String subtitle;
  final int itemCount;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;
  final String emptyTitle;
  final String emptyMessage;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget content;
    if (isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (errorMessage != null) {
      content = _CenteredMessage(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppMessageCard.error(
              title: 'No pudimos cargar esta vista',
              message: errorMessage!,
            ),
            const Gap(AppSpacing.lg),
            AppButton.secondary(
              label: 'Reintentar',
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
            ),
          ],
        ),
      );
    } else {
      content = child;
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$itemCount resultados',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const Gap(AppSpacing.xs),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Gap(AppSpacing.lg),
            Expanded(
              child: Builder(
                builder: (_) {
                  if (!isLoading && errorMessage == null && itemCount == 0) {
                    return _CenteredMessage(
                      child: AppMessageCard.info(
                        title: emptyTitle,
                        message: emptyMessage,
                      ),
                    );
                  }
                  return content;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportItemCard extends StatelessWidget {
  const _ReportItemCard({
    required this.title,
    required this.subtitle,
    required this.chips,
    required this.lines,
  });

  final String title;
  final String subtitle;
  final List<Widget> chips;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const Gap(AppSpacing.xs),
          Text(
            subtitle,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          if (chips.isNotEmpty) ...[
            const Gap(AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: chips,
            ),
          ],
          const Gap(AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xl,
            runSpacing: AppSpacing.xs,
            children: lines
                .map(
                  (line) => Text(
                    line,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _SearchOption<T> {
  const _SearchOption(this.value, this.label);

  final T value;
  final String label;
}

class _SearchableReportFilter<T> extends StatelessWidget {
  const _SearchableReportFilter({
    super.key,
    required this.label,
    required this.hint,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
    this.enabled = true,
  });

  final String label;
  final String hint;
  final List<_SearchOption<T>> options;
  final T? selectedValue;
  final ValueChanged<T?> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    _SearchOption<T>? selected;
    for (final option in options) {
      if (option.value == selectedValue) {
        selected = option;
        break;
      }
    }

    return Autocomplete<_SearchOption<T>>(
      initialValue: TextEditingValue(text: selected?.label ?? ''),
      displayStringForOption: (option) => option.label,
      optionsBuilder: (value) {
        final query = value.text.trim().toLowerCase();
        if (query.isEmpty) return options;
        return options.where(
          (option) => option.label.toLowerCase().contains(query),
        );
      },
      onSelected: (option) => onSelected(option.value),
      fieldViewBuilder: (context, controller, focusNode, onSubmit) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: controller.text.isEmpty
                ? const Icon(Icons.expand_more_rounded)
                : IconButton(
                    tooltip: 'Limpiar filtro',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      controller.clear();
                      onSelected(null);
                    },
                  ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelectedOption, matches) {
        final values = matches.toList(growable: false);
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 12,
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480, maxHeight: 320),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                shrinkWrap: true,
                itemCount: values.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final option = values[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.manage_search_rounded),
                    title: Text(
                      option.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => onSelectedOption(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.onPressed,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.event_outlined),
        label: Text(
          value == null
              ? label
              : '$label: ${DateFormat('dd/MM/yyyy').format(value!.toLocal())}',
        ),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: child,
      ),
    );
  }
}

class _CostosOrdenTabV2 extends StatelessWidget {
  const _CostosOrdenTabV2({
    required this.state,
    required this.onApply,
    required this.onClear,
  });

  final ProduccionReportesState state;
  final Future<void> Function(int? ordenProduccionId) onApply;
  final Future<void> Function() onClear;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ');
    final selectedOrderId = state.costosOrdenProduccionId;
    final visibleOrders = selectedOrderId == null
        ? state.costosOrden.take(0).toList(growable: false)
        : state.costosOrden
              .where((item) => item.ordenProduccionId == selectedOrderId)
              .toList(growable: false);
    final visibleProcesses = selectedOrderId == null
        ? state.costosProceso.take(0).toList(growable: false)
        : state.costosProceso
              .where((item) => item.ordenProduccionId == selectedOrderId)
              .toList(growable: false);
    final total = visibleOrders.fold<double>(
      0,
      (sum, item) => sum + item.costoMaterialesReal + item.costoPieles,
    );
    final ordersWithCost = visibleOrders
        .where((item) => item.costoMaterialesReal > 0)
        .length;

    return _ReportTabScaffold(
      filterCard: _SurfaceCard(
        title: 'Costos reales de produccion',
        subtitle:
            'Resumen consolidado de materiales consumidos en las etapas productivas.',
        child: Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 620,
              child: _SearchableReportFilter<int>(
                key: ValueKey('costo-${state.costosOrdenProduccionId}'),
                label: 'Orden o cliente',
                hint: 'Escribe codigo de orden o nombre del cliente',
                selectedValue: state.costosOrdenProduccionId,
                options: state.ordenOptions
                    .map(
                      (item) => _SearchOption(item.id, _ordenOptionLabel(item)),
                    )
                    .toList(growable: false),
                onSelected: onApply,
              ),
            ),
            AppButton.secondary(
              label: 'Limpiar',
              icon: Icons.filter_alt_off_outlined,
              onPressed: onClear,
            ),
            if (selectedOrderId != null) ...[
              _SummaryMetric(
                label: 'Costo total de la ficha',
                value: money.format(total),
                icon: Icons.payments_outlined,
              ),
              _SummaryMetric(
                label: 'Orden seleccionada',
                value: ordersWithCost == 0 ? 'Sin consumo' : 'Con consumo',
                icon: Icons.assignment_turned_in_outlined,
              ),
            ],
          ],
        ),
      ),
      resultsCard: _ResultsCard(
        title: 'Resumen por orden y cinco procesos',
        subtitle: selectedOrderId == null
            ? 'Selecciona una orden para generar su ficha.'
            : '${visibleProcesses.map((item) => item.ordenProcesoId).toSet().length} procesos en la ficha.',
        itemCount: visibleOrders.length,
        isLoading: state.loadingCostosOrden,
        errorMessage: state.costosOrdenErrorMessage,
        onRetry: () => onApply(state.costosOrdenProduccionId),
        emptyTitle: selectedOrderId == null
            ? 'Selecciona una orden'
            : 'Sin consumos reales',
        emptyMessage: selectedOrderId == null
            ? 'Busca por codigo de orden o cliente y elige una coincidencia. Solo se mostrara esa ficha.'
            : 'Todavia no existen salidas de materiales asociadas a la orden seleccionada.',
        child: ListView.builder(
          itemCount: visibleOrders.length,
          itemBuilder: (context, index) {
            final order = visibleOrders[index];
            final stages = visibleProcesses
                .where(
                  (item) => item.ordenProduccionId == order.ordenProduccionId,
                )
                .toList(growable: false);
            final stagesGrouped = <int, List<dynamic>>{};
            for (final stage in stages) {
              stagesGrouped
                  .putIfAbsent(stage.ordenProcesoId, () => [])
                  .add(stage);
            }
            final orderTotal = order.costoMaterialesReal + order.costoPieles;
            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                initiallyExpanded: true,
                title: Text('${order.codigoOrden} · ${order.cliente}'),
                subtitle: Text(
                  '${order.codigoLote} · Pieles ${order.clienteTraeLote ? 'traidas por cliente' : money.format(order.costoPieles)} · Materiales ${money.format(order.costoMaterialesReal)}',
                ),
                trailing: Text(
                  money.format(orderTotal),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                children: [
                  _OrderCostSummary(
                    groups: stagesGrouped.values.toList(growable: false),
                    skins: order.cantidadPieles,
                    sides: order.cantidadLados,
                    total: orderTotal,
                    costPerSkin: order.costoMaterialesPorPiel,
                    costPerSide: order.costoMaterialesPorLado,
                    money: money,
                  ),
                  _CostProcessTimeline(
                    groups: stagesGrouped.values.toList(growable: false),
                    money: money,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OrderCostSummary extends StatelessWidget {
  const _OrderCostSummary({
    required this.groups,
    required this.skins,
    required this.sides,
    required this.total,
    required this.costPerSkin,
    required this.costPerSide,
    required this.money,
  });

  final List<List<dynamic>> groups;
  final double skins;
  final double sides;
  final double total;
  final double costPerSkin;
  final double costPerSide;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    final first = groups.isEmpty ? null : groups.first.first;
    final last = groups.isEmpty ? null : groups.last.first;
    final kilos = first?.pesoBaseKg as double?;
    final cells = [
      ('INICIO', _formatOptionalDate(first?.fechaInicio as DateTime?)),
      ('FIN ESTIMADO', _formatOptionalDate(last?.fechaFin as DateTime?)),
      (
        'PIELES / KILOS',
        '${_formatDecimal(skins)} · ${kilos == null ? '-' : '${_formatDecimal(kilos)} kg'}',
      ),
      ('COSTO POR PIEL', money.format(costPerSkin)),
      ('COSTO POR LADO', money.format(costPerSide)),
      ('COSTO TOTAL ORDEN', money.format(total)),
    ];
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 1180
              ? 6
              : constraints.maxWidth >= 700
              ? 3
              : 1;
          final cellWidth = constraints.maxWidth / columns;
          return Wrap(
            children: cells
                .map(
                  (cell) => SizedBox(
                    width: cellWidth,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                          width: .5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cell.$1,
                            style: Theme.of(
                              context,
                            ).textTheme.labelSmall?.copyWith(letterSpacing: 1),
                          ),
                          const Gap(AppSpacing.sm),
                          Text(
                            cell.$2,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: cell.$1.startsWith('COSTO')
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          );
        },
      ),
    );
  }
}

class _CostProcessTimeline extends StatefulWidget {
  const _CostProcessTimeline({required this.groups, required this.money});
  final List<List<dynamic>> groups;
  final NumberFormat money;

  @override
  State<_CostProcessTimeline> createState() => _CostProcessTimelineState();
}

class _CostProcessTimelineState extends State<_CostProcessTimeline> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.groups.isEmpty) return const SizedBox.shrink();
    if (selectedIndex >= widget.groups.length) selectedIndex = 0;
    final rows = widget.groups[selectedIndex];
    final stage = rows.first;
    final total = rows.fold<double>(
      0,
      (sum, item) => sum + item.costoMaterialesReal,
    );
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(widget.groups.length, (index) {
              final current = widget.groups[index].first;
              final active = index == selectedIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => setState(() => selectedIndex = index),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 17,
                        backgroundColor: active
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHigh,
                        foregroundColor: active
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        child: Text('${index + 1}'),
                      ),
                      const Gap(AppSpacing.xs),
                      Text(
                        current.procesoNombre as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: active
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: active
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const Gap(AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stage.procesoNombre as String,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const Gap(AppSpacing.xs),
                          Text(
                            'Inicio ${_formatOptionalDate(stage.fechaInicio as DateTime?)}   Fin ${_formatOptionalDate(stage.fechaFin as DateTime?)}   Pieles ${_formatDecimal(stage.cantidadPieles as double)}   Kilos ${stage.pesoBaseKg == null ? '-' : _formatDecimal(stage.pesoBaseKg as double)}',
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('COSTO PROCESO'),
                        Text(
                          widget.money.format(total),
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: AppSpacing.xl),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.sm,
                  ),
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  child: const Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          'INSUMO',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'PORCENTAJE',
                          textAlign: TextAlign.right,
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'PESO',
                          textAlign: TextAlign.right,
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'COSTO',
                          textAlign: TextAlign.right,
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
                ...rows
                    .where((item) => item.insumoId != null)
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Text(
                                '${_normalizeInsumoCode(item.insumoCodigo as String?)} · ${item.insumoNombre}',
                              ),
                            ),
                            Expanded(
                              child: Text(
                                item.porcentaje == null
                                    ? '-'
                                    : '${_formatDecimal(item.porcentaje as double)}%',
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                _formatDecimal(
                                  item.cantidadConsumida as double,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                widget.money.format(item.costoMaterialesReal),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
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

class _CostosOrdenTab extends StatefulWidget {
  const _CostosOrdenTab({
    required this.state,
    required this.onApply,
    required this.onClear,
  });

  final ProduccionReportesState state;
  final Future<void> Function(int? ordenProduccionId) onApply;
  final Future<void> Function() onClear;

  @override
  State<_CostosOrdenTab> createState() => _CostosOrdenTabState();
}

class _CostosOrdenTabState extends State<_CostosOrdenTab> {
  int? _selectedOrderId;

  @override
  void didUpdateWidget(covariant _CostosOrdenTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    _selectedOrderId = widget.state.costosOrdenProduccionId;
  }

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ');
    final theme = Theme.of(context);
    final totalGeneral = widget.state.costosOrden.fold<double>(
      0,
      (sum, item) => sum + item.costoMaterialesReal,
    );
    final etapasConCosto = widget.state.costosProceso
        .where((item) => item.costoMaterialesReal > 0)
        .length;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Costos reales por orden', style: theme.textTheme.headlineSmall),
          const Gap(AppSpacing.xs),
          Text(
            'Solo incluye los consumos reales aprobados y entregados por logística.',
            style: theme.textTheme.bodyMedium,
          ),
          const Gap(AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  key: ValueKey(_selectedOrderId),
                  initialValue: _selectedOrderId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Orden de producción',
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Todas las órdenes'),
                    ),
                    ...widget.state.ordenOptions.map(
                      (item) => DropdownMenuItem<int?>(
                        value: item.id,
                        child: Text(_ordenOptionLabel(item)),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedOrderId = value),
                ),
              ),
              const Gap(AppSpacing.md),
              AppButton.primary(
                label: 'Aplicar',
                icon: Icons.filter_alt_outlined,
                onPressed: () => widget.onApply(_selectedOrderId),
              ),
              const Gap(AppSpacing.sm),
              AppButton.secondary(
                label: 'Limpiar',
                icon: Icons.filter_alt_off_outlined,
                onPressed: widget.onClear,
              ),
            ],
          ),
          const Gap(AppSpacing.lg),
          if (!widget.state.loadingCostosOrden &&
              widget.state.costosOrdenErrorMessage == null) ...[
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                _SummaryMetric(
                  label: 'Gasto total en materiales',
                  value: money.format(totalGeneral),
                  icon: Icons.payments_outlined,
                ),
                _SummaryMetric(
                  label: 'Ordenes consideradas',
                  value: '${widget.state.costosOrden.length}',
                  icon: Icons.assignment_outlined,
                ),
                _SummaryMetric(
                  label: 'Etapas con consumo',
                  value:
                      '$etapasConCosto / ${widget.state.costosProceso.length}',
                  icon: Icons.account_tree_outlined,
                ),
              ],
            ),
            const Gap(AppSpacing.lg),
          ],
          if (widget.state.costosOrdenErrorMessage != null)
            AppMessageCard.error(
              title: 'No pudimos cargar los costos',
              message: widget.state.costosOrdenErrorMessage!,
            )
          else if (widget.state.loadingCostosOrden)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: CircularProgressIndicator(),
              ),
            )
          else if (widget.state.costosOrden.isEmpty)
            const AppMessageCard.info(
              title: 'Sin costos reales',
              message:
                  'Aún no hay consumos reales entregados para el filtro seleccionado.',
            )
          else
            Card(
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Orden / lote')),
                    DataColumn(label: Text('Cliente')),
                    DataColumn(label: Text('Pieles'), numeric: true),
                    DataColumn(label: Text('Lados'), numeric: true),
                    DataColumn(label: Text('Materiales reales'), numeric: true),
                    DataColumn(label: Text('Costo / piel'), numeric: true),
                    DataColumn(label: Text('Costo / lado'), numeric: true),
                  ],
                  rows: widget.state.costosOrden
                      .map((item) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Text('${item.codigoOrden}\n${item.codigoLote}'),
                            ),
                            DataCell(Text(item.cliente)),
                            DataCell(Text(_formatDecimal(item.cantidadPieles))),
                            DataCell(Text(_formatDecimal(item.cantidadLados))),
                            DataCell(
                              Text(money.format(item.costoMaterialesReal)),
                            ),
                            DataCell(
                              Text(money.format(item.costoMaterialesPorPiel)),
                            ),
                            DataCell(
                              Text(money.format(item.costoMaterialesPorLado)),
                            ),
                          ],
                        );
                      })
                      .toList(growable: false),
                ),
              ),
            ),
          if (widget.state.costosProceso.isNotEmpty) ...[
            const Gap(AppSpacing.xl),
            Text(
              'Desglose de materiales por etapa',
              style: theme.textTheme.titleLarge,
            ),
            const Gap(AppSpacing.md),
            Card(
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Orden')),
                    DataColumn(label: Text('Etapa')),
                    DataColumn(
                      label: Text('Costo real de materiales'),
                      numeric: true,
                    ),
                  ],
                  rows: widget.state.costosProceso
                      .map(
                        (item) => DataRow(
                          cells: [
                            DataCell(Text(item.codigoOrden)),
                            DataCell(
                              Text(
                                '${item.procesoCodigo} · ${item.procesoNombre}',
                              ),
                            ),
                            DataCell(
                              Text(money.format(item.costoMaterialesReal)),
                            ),
                          ],
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Widget _cardChip(BuildContext context, String label) {
  final theme = Theme.of(context);

  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: theme.colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onPrimaryContainer,
      ),
    ),
  );
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 260,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const Gap(AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelMedium),
                const Gap(AppSpacing.xs),
                Text(value, style: theme.textTheme.titleLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _ordenOptionLabel(OrdenProduccionRecord item) {
  return '${item.codigo} · ${item.clienteRazonSocial}';
}

String _normalizeInsumoCode(String? value) {
  final code = (value ?? '').trim().toUpperCase();
  final match = RegExp(r'^INS-?(\d+)$').firstMatch(code);
  if (match == null) return code;
  final number = int.tryParse(match.group(1)!);
  return number == null ? code : 'INS-${number.toString().padLeft(3, '0')}';
}

List<String> _availableOrderStates(List<OrdenProduccionRecord> items) {
  final states = <String>{};
  for (final item in items) {
    states.add(item.estado);
  }
  final values = states.toList(growable: false)..sort();
  return values;
}

String _formatDateTime(DateTime value) {
  return DateFormat('dd/MM/yyyy hh:mm a').format(value.toLocal());
}

String _formatOptionalDateTime(DateTime? value) {
  if (value == null) {
    return 'Sin registro';
  }
  return _formatDateTime(value);
}

String _formatOptionalDate(DateTime? value) {
  if (value == null) {
    return 'Sin registro';
  }
  return DateFormat('dd/MM/yyyy').format(value.toLocal());
}

String _formatDecimal(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(2);
}

String _formatSignedDecimal(double value) {
  final normalized = _formatDecimal(value.abs());
  if (value > 0) {
    return '+$normalized';
  }
  if (value < 0) {
    return '-$normalized';
  }
  return normalized;
}
