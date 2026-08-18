import 'package:erp_curtiembre_fronted/core/di/service_locator.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:erp_curtiembre_fronted/features/finance/pricing/presentation/cubit/rentabilidad_cubit.dart';
import 'package:erp_curtiembre_fronted/features/finance/pricing/presentation/cubit/rentabilidad_state.dart';
import 'package:erp_curtiembre_fronted/features/finance/pricing/presentation/widgets/precio_sugerido_dialogs.dart';
import 'package:erp_curtiembre_fronted/features/finance/shared/presentation/widgets/finance_ui.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/buttons/app_button.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/feedback/app_message_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:talker_flutter/talker_flutter.dart';

class RentabilidadPage extends StatefulWidget {
  const RentabilidadPage({super.key});

  @override
  State<RentabilidadPage> createState() => _RentabilidadPageState();
}

class _RentabilidadPageState extends State<RentabilidadPage> {
  final Talker _talker = getIt<Talker>();

  @override
  void initState() {
    super.initState();
    _talker.ui('Se abrio la pantalla de rentabilidad.');
  }

  Future<void> _openPriceDialog(
    BuildContext context,
    RentabilidadState state,
  ) async {
    _talker.ui(
      'Se abrio el dialogo para calcular rentabilidad.',
      logLevel: LogLevel.warning,
    );
    final payload = await showDialog<PrecioVentaDialogResult>(
      context: context,
      builder: (_) => PrecioVentaInputDialog(
        title: 'Calcular rentabilidad',
        submitLabel: 'Calcular',
        isSubmitting: state.isSubmittingAction,
        initialPrecioVenta: state.detail?.precioVenta,
      ),
    );

    if (payload == null || !context.mounted) {
      _talker.ui(
        'Se cerro el calculo de rentabilidad sin confirmar.',
        logLevel: LogLevel.debug,
      );
      return;
    }
    _talker.ui(
      'Se confirmo el calculo de rentabilidad con precioVenta=${payload.precioVenta}.',
      logLevel: LogLevel.warning,
    );

    final result = await context.read<RentabilidadCubit>().calculate(
      payload.precioVenta,
    );
    if (!context.mounted) return;
    _showActionResult(context, result.success, result.message);
  }

  void _showActionResult(BuildContext context, bool success, String message) {
    _talker.ui(
      success
          ? 'Accion en rentabilidad completada correctamente.'
          : 'La accion en rentabilidad fallo: $message',
      logLevel: success ? LogLevel.debug : LogLevel.error,
    );
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: success ? null : const Color(0xFF8A2F22),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.select((AuthCubit cubit) => cubit.state.session);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rentabilidad'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: TextButton.icon(
              onPressed: () {
                _talker.ui('Se regreso desde rentabilidad al panel principal.');
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
              constraints: const BoxConstraints(maxWidth: 1160),
              child: BlocBuilder<RentabilidadCubit, RentabilidadState>(
                builder: (context, state) {
                  if (state.status == RentabilidadStatus.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.status == RentabilidadStatus.error) {
                    return FinanceCenteredMessage(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppMessageCard.error(
                            title:
                                'No pudimos preparar la vista de rentabilidad',
                            message:
                                state.errorMessage ??
                                'Intenta nuevamente para cargar el bloque financiero.',
                          ),
                          const Gap(AppSpacing.lg),
                          AppButton.secondary(
                            label: 'Reintentar',
                            icon: Icons.refresh_rounded,
                            onPressed: () {
                              _talker.ui(
                                'Se solicito reintentar la carga de rentabilidad.',
                              );
                              context.read<RentabilidadCubit>().initialize();
                            },
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
                            'Mide utilidad y margen real por orden una vez definido el precio de venta.',
                        description:
                            'Este bloque te deja contrastar el costo total contra el precio de mercado para validar si la orden realmente es rentable.',
                        badgeLabel: 'Ordenes disponibles',
                        badgeValue: '${state.orderOptions.length}',
                        sessionUserName: session?.userName,
                      ),
                      const Gap(AppSpacing.xl),
                      FinanceSurfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Orden y calculo',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const Gap(AppSpacing.sm),
                            Text(
                              'Selecciona una orden, consulta el ultimo calculo y recalcula rentabilidad con el precio de venta real.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            const Gap(AppSpacing.lg),
                            Wrap(
                              spacing: AppSpacing.lg,
                              runSpacing: AppSpacing.lg,
                              children: [
                                SizedBox(
                                  width: 420,
                                  child: DropdownButtonFormField<int?>(
                                    initialValue: state.selectedOrderId,
                                    decoration: const InputDecoration(
                                      labelText: 'Orden de produccion',
                                    ),
                                    items: state.orderOptions
                                        .map(
                                          (item) => DropdownMenuItem<int?>(
                                            value: item.id,
                                            child: Text(
                                              '${item.codigo} | ${item.clienteRazonSocial}',
                                            ),
                                          ),
                                        )
                                        .toList(growable: false),
                                    onChanged: (value) {
                                      _talker.ui(
                                        'Se selecciono la orden ${value ?? 'ninguna'} en rentabilidad.',
                                        logLevel: LogLevel.debug,
                                      );
                                      context
                                          .read<RentabilidadCubit>()
                                          .selectOrder(value);
                                    },
                                  ),
                                ),
                                AppButton.secondary(
                                  label: 'Calcular rentabilidad',
                                  icon: Icons.trending_up_outlined,
                                  isLoading: state.isSubmittingAction,
                                  onPressed: state.selectedOrderId == null
                                      ? null
                                      : () => _openPriceDialog(context, state),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Gap(AppSpacing.xl),
                      Expanded(
                        child: FinanceSurfaceCard(
                          child: Builder(
                            builder: (context) {
                              if (state.isDetailLoading) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              if (state.detailErrorMessage != null) {
                                return FinanceCenteredMessage(
                                  child: AppMessageCard.info(
                                    title: 'Sin rentabilidad calculada',
                                    message: state.detailErrorMessage!,
                                  ),
                                );
                              }

                              final detail = state.detail;
                              if (detail == null) {
                                return const FinanceCenteredMessage(
                                  child: AppMessageCard.info(
                                    title: 'Selecciona una orden',
                                    message:
                                        'Cuando elijas una orden y exista un calculo previo, apareceran aqui precio de venta, costo total, utilidad y margen.',
                                  ),
                                );
                              }

                              return SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      detail.ordenProduccionCodigo,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.headlineSmall,
                                    ),
                                    const Gap(AppSpacing.xs),
                                    Text(
                                      'Calculado el ${formatFinanceDateTime(detail.calculadoEn)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                    const Gap(AppSpacing.xl),
                                    Wrap(
                                      spacing: AppSpacing.lg,
                                      runSpacing: AppSpacing.lg,
                                      children: [
                                        FinanceDetailCard(
                                          title: 'Venta y costo',
                                          lines: [
                                            'Precio de venta: S/ ${detail.precioVenta.toStringAsFixed(2)}',
                                            'Costo total: S/ ${detail.costoTotal.toStringAsFixed(2)}',
                                            'Utilidad: S/ ${detail.utilidad.toStringAsFixed(2)}',
                                          ],
                                        ),
                                        FinanceDetailCard(
                                          title: 'Margen',
                                          lines: [
                                            'Margen %: ${detail.margenPorcentaje?.toStringAsFixed(2) ?? 'Sin registro'}',
                                            'Orden ID: ${detail.ordenProduccionId}',
                                            'Registro ID: ${detail.id}',
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
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
