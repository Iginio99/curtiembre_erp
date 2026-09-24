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
                    _CostosOrdenTab(
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
              width: 320,
              child: DropdownButtonFormField<int?>(
                initialValue: state.ordenesClienteClienteId,
                decoration: const InputDecoration(labelText: 'Cliente'),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Todos'),
                  ),
                  ...state.clienteOptions.map(
                    (item) => DropdownMenuItem<int?>(
                      value: item.id,
                      child: Text(item.label),
                    ),
                  ),
                ],
                onChanged: (value) => onApply(
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
              child: DropdownButtonFormField<int?>(
                initialValue: state.consumoOrdenProduccionId,
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
                onChanged: (value) =>
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
        child: ListView.separated(
          itemCount: state.consumoProceso.length,
          separatorBuilder: (_, _) => const Gap(AppSpacing.md),
          itemBuilder: (context, index) {
            final item = state.consumoProceso[index];
            return _ReportItemCard(
              title: '${item.codigoOrden} · ${item.procesoCodigo}',
              subtitle: '${item.insumoCodigo} · ${item.insumoNombre}',
              chips: [
                _cardChip(context, item.procesoNombre),
                _cardChip(
                  context,
                  'Costo S/ ${item.costoTotal.toStringAsFixed(2)}',
                ),
              ],
              lines: [
                'Planificado: ${_formatDecimal(item.cantidadPlanificada)}',
                'Real: ${_formatDecimal(item.cantidadReal)}',
                'Desviacion: ${_formatSignedDecimal(item.cantidadDesviacion)}',
                'Costo unitario: ${item.costoUnitario == null ? 'No definido' : 'S/ ${item.costoUnitario!.toStringAsFixed(2)}'}',
              ],
            );
          },
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
              child: DropdownButtonFormField<int?>(
                initialValue: state.tiemposOrdenProduccionId,
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
        child: ListView.separated(
          itemCount: state.tiemposProceso.length,
          separatorBuilder: (_, _) => const Gap(AppSpacing.md),
          itemBuilder: (context, index) {
            final item = state.tiemposProceso[index];
            return _ReportItemCard(
              title: '${item.codigoOrden} · ${item.procesoCodigo}',
              subtitle: item.procesoNombre,
              chips: [
                _cardChip(context, item.estado),
                if (item.diasReales != null)
                  _cardChip(context, '${item.diasReales} dia(s)'),
              ],
              lines: [
                'Inicio: ${_formatOptionalDateTime(item.fechaInicio)}',
                'Fin: ${_formatOptionalDateTime(item.fechaFin)}',
                'Responsable: ${(item.responsable ?? 'Sin responsable').trim()}',
              ],
            );
          },
        ),
      ),
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleLarge),
          const Gap(AppSpacing.sm),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(AppSpacing.lg),
          child,
        ],
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
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleLarge),
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
      padding: const EdgeInsets.all(AppSpacing.lg),
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
          const Gap(AppSpacing.md),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                line,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
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
                child: DropdownButtonFormField<int>(
                  key: ValueKey(_selectedOrderId),
                  initialValue: _selectedOrderId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Orden de producción',
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('Todas las órdenes'),
                    ),
                    ...widget.state.ordenOptions.map(
                      (item) => DropdownMenuItem<int>(
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

String _ordenOptionLabel(OrdenProduccionRecord item) {
  return '${item.codigo} · ${item.clienteRazonSocial}';
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
