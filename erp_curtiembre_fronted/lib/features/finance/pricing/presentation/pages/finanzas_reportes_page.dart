import 'package:erp_curtiembre_fronted/core/di/service_locator.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/finance/pricing/domain/entities/finanzas_report_records.dart';
import 'package:erp_curtiembre_fronted/features/finance/pricing/presentation/cubit/finanzas_reportes_cubit.dart';
import 'package:erp_curtiembre_fronted/features/finance/pricing/presentation/cubit/finanzas_reportes_state.dart';
import 'package:erp_curtiembre_fronted/features/finance/shared/presentation/widgets/finance_ui.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/buttons/app_button.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/feedback/app_message_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:talker_flutter/talker_flutter.dart';

class FinanzasReportesPage extends StatefulWidget {
  const FinanzasReportesPage({super.key});

  @override
  State<FinanzasReportesPage> createState() => _FinanzasReportesPageState();
}

class _FinanzasReportesPageState extends State<FinanzasReportesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final Talker _talker = getIt<Talker>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _talker.ui('Se abrio la pantalla de reportes financieros.');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes financieros'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: TextButton.icon(
              onPressed: () {
                _talker.ui(
                  'Se regreso desde reportes financieros al panel principal.',
                );
                context.go('/home');
              },
              icon: const Icon(Icons.dashboard_outlined),
              label: const Text('Panel'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1480),
              child: BlocBuilder<FinanzasReportesCubit, FinanzasReportesState>(
                builder: (context, state) {
                  if (state.status == FinanzasReportesStatus.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.status == FinanzasReportesStatus.error) {
                    return FinanceCenteredMessage(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppMessageCard.error(
                            title: 'No pudimos cargar los reportes financieros',
                            message:
                                state.errorMessage ??
                                'Intenta nuevamente para consultar la base del modulo.',
                          ),
                          const Gap(AppSpacing.lg),
                          AppButton.secondary(
                            label: 'Reintentar',
                            icon: Icons.refresh_rounded,
                            onPressed: () {
                              _talker.ui(
                                'Se solicito reintentar la carga de reportes financieros.',
                              );
                              context
                                  .read<FinanzasReportesCubit>()
                                  .initialize();
                            },
                          ),
                        ],
                      ),
                    );
                  }

                  final tabsHeader = FinanceSurfaceCard(
                    padding: EdgeInsets.zero,
                    child: TabBar(
                      controller: _tabController,
                      onTap: (index) {
                        _talker.ui(
                          'Se cambio a la pestana ${index + 1} de reportes financieros.',
                          logLevel: LogLevel.debug,
                        );
                      },
                      isScrollable: true,
                      tabs: const [
                        Tab(text: 'Costo orden'),
                        Tab(text: 'Costo proceso'),
                        Tab(text: 'Costo cliente'),
                        Tab(text: 'Indirectos'),
                        Tab(text: 'Rentabilidad'),
                        Tab(text: 'Precio sugerido'),
                      ],
                    ),
                  );

                  final tabsView = TabBarView(
                    controller: _tabController,
                    children: [
                      _SimpleReportList<ReporteCostoOrdenRecord>(
                        title: 'Costo por orden',
                        subtitle:
                            '${state.costoOrden.length} registro(s) visibles.',
                        items: state.costoOrden,
                        builder: (context, item) => _ReportItemCard(
                          title: item.ordenProduccionCodigo,
                          subtitle: item.clienteRazonSocial,
                          lines: [
                            'Estado: ${item.estadoCosto}',
                            'Costo total: S/ ${item.costoTotal.toStringAsFixed(2)}',
                            'Costo por piel: ${item.costoPorPiel == null ? 'Sin registro' : 'S/ ${item.costoPorPiel!.toStringAsFixed(2)}'}',
                            'Calculado: ${formatFinanceDateTime(item.calculadoEn)}',
                          ],
                        ),
                      ),
                      _SimpleReportList<ReporteCostoProcesoRecord>(
                        title: 'Costo por proceso',
                        subtitle:
                            '${state.costoProceso.length} registro(s) visibles.',
                        items: state.costoProceso,
                        builder: (context, item) => _ReportItemCard(
                          title:
                              '${item.ordenProduccionCodigo} | ${item.procesoCodigo}',
                          subtitle: item.procesoNombre,
                          lines: [
                            'Insumos: S/ ${item.costoInsumos.toStringAsFixed(2)}',
                            'Mano de obra: S/ ${item.costoManoObra.toStringAsFixed(2)}',
                            'Total: S/ ${item.costoTotal.toStringAsFixed(2)}',
                            'Calculado: ${formatFinanceDateTime(item.calculadoEn)}',
                          ],
                        ),
                      ),
                      _SimpleReportList<ReporteCostoClienteRecord>(
                        title: 'Costo por cliente',
                        subtitle:
                            '${state.costoCliente.length} registro(s) visibles.',
                        items: state.costoCliente,
                        builder: (context, item) => _ReportItemCard(
                          title: item.clienteRazonSocial,
                          subtitle: 'Cliente ID ${item.clienteId}',
                          lines: [
                            'Ordenes costeadas: ${item.ordenesCosteadas}',
                            'Costo total: S/ ${item.costoTotal.toStringAsFixed(2)}',
                            'Costo promedio por orden: S/ ${item.costoPromedioOrden.toStringAsFixed(2)}',
                          ],
                        ),
                      ),
                      _SimpleReportList<ReporteIndirectoPeriodoRecord>(
                        title: 'Indirectos por periodo',
                        subtitle:
                            '${state.indirectosPeriodo.length} registro(s) visibles.',
                        items: state.indirectosPeriodo,
                        builder: (context, item) => _ReportItemCard(
                          title: item.periodoCodigo,
                          subtitle: item.estado,
                          lines: [
                            'Total indirectos: S/ ${item.totalIndirectos.toStringAsFixed(2)}',
                            'Registros: ${item.totalRegistros}',
                          ],
                        ),
                      ),
                      _SimpleReportList<ReporteRentabilidadRecord>(
                        title: 'Rentabilidad',
                        subtitle:
                            '${state.rentabilidad.length} registro(s) visibles.',
                        items: state.rentabilidad,
                        builder: (context, item) => _ReportItemCard(
                          title: item.ordenProduccionCodigo,
                          subtitle: item.clienteRazonSocial,
                          lines: [
                            'Precio venta: S/ ${item.precioVenta.toStringAsFixed(2)}',
                            'Costo total: S/ ${item.costoTotal.toStringAsFixed(2)}',
                            'Utilidad: S/ ${item.utilidad.toStringAsFixed(2)}',
                            'Margen: ${item.margenPorcentaje?.toStringAsFixed(2) ?? 'Sin registro'}',
                          ],
                        ),
                      ),
                      _SimpleReportList<ReportePrecioSugeridoRecord>(
                        title: 'Precio sugerido',
                        subtitle:
                            '${state.precioSugerido.length} registro(s) visibles.',
                        items: state.precioSugerido,
                        builder: (context, item) => _ReportItemCard(
                          title: item.ordenProduccionCodigo,
                          subtitle: item.clienteRazonSocial,
                          lines: [
                            'Costo base sin IGV: S/ ${item.costoBaseSinIgv.toStringAsFixed(2)}',
                            'Margen: ${item.margenPorcentaje.toStringAsFixed(2)}',
                            'Sin IGV: S/ ${item.precioSugeridoSinIgv.toStringAsFixed(2)}',
                            'Con IGV: S/ ${item.precioSugeridoConIgv.toStringAsFixed(2)}',
                          ],
                        ),
                      ),
                    ],
                  );

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final compactHeight = constraints.maxHeight < 920;

                      if (compactHeight) {
                        return SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FinanceHeroCard(
                                title:
                                    'Consulta costo, rentabilidad, indirectos y precio sugerido desde un unico hub financiero.',
                                description:
                                    'Esta vista esta pensada para lectura y control. Aqui no se recalcula nada; solo se revisan resultados ya generados por el backend.',
                                badgeLabel: 'Bloques',
                                badgeValue: '6',
                                sessionUserName: null,
                              ),
                              const Gap(AppSpacing.xl),
                              tabsHeader,
                              const Gap(AppSpacing.xl),
                              SizedBox(
                                height: constraints.maxHeight.clamp(
                                  720.0,
                                  980.0,
                                ),
                                child: tabsView,
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FinanceHeroCard(
                            title:
                                'Consulta costo, rentabilidad, indirectos y precio sugerido desde un unico hub financiero.',
                            description:
                                'Esta vista esta pensada para lectura y control. Aqui no se recalcula nada; solo se revisan resultados ya generados por el backend.',
                            badgeLabel: 'Bloques',
                            badgeValue: '6',
                            sessionUserName: null,
                          ),
                          const Gap(AppSpacing.xl),
                          tabsHeader,
                          const Gap(AppSpacing.xl),
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
      ),
    );
  }
}

class _SimpleReportList<T> extends StatelessWidget {
  const _SimpleReportList({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.builder,
  });

  final String title;
  final String subtitle;
  final List<T> items;
  final Widget Function(BuildContext context, T item) builder;

  @override
  Widget build(BuildContext context) {
    return FinanceSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const Gap(AppSpacing.xs),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(AppSpacing.lg),
          Expanded(
            child: items.isEmpty
                ? const FinanceCenteredMessage(
                    child: AppMessageCard.info(
                      title: 'Sin datos',
                      message:
                          'Todavia no hay registros disponibles para este reporte.',
                    ),
                  )
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Gap(AppSpacing.md),
                    itemBuilder: (context, index) =>
                        builder(context, items[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ReportItemCard extends StatelessWidget {
  const _ReportItemCard({
    required this.title,
    required this.subtitle,
    required this.lines,
  });

  final String title;
  final String subtitle;
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
          const Gap(AppSpacing.md),
          for (final line in lines) ...[
            Text(
              line,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Gap(AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}
