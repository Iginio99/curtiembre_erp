import 'package:erp_curtiembre_fronted/core/di/service_locator.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:erp_curtiembre_fronted/features/finance/pricing/presentation/cubit/precio_sugerido_cubit.dart';
import 'package:erp_curtiembre_fronted/features/finance/pricing/presentation/cubit/precio_sugerido_state.dart';
import 'package:erp_curtiembre_fronted/features/finance/pricing/presentation/widgets/precio_sugerido_dialogs.dart';
import 'package:erp_curtiembre_fronted/features/finance/shared/presentation/widgets/finance_ui.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/buttons/app_button.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/feedback/app_message_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:talker_flutter/talker_flutter.dart';

class PrecioSugeridoPage extends StatefulWidget {
  const PrecioSugeridoPage({super.key});

  @override
  State<PrecioSugeridoPage> createState() => _PrecioSugeridoPageState();
}

class _PrecioSugeridoPageState extends State<PrecioSugeridoPage> {
  final Talker _talker = getIt<Talker>();

  @override
  void initState() {
    super.initState();
    _talker.ui('Se abrio la pantalla de precio sugerido.');
  }

  Future<void> _openMarginDialog(
    BuildContext context,
    PrecioSugeridoState state,
  ) async {
    _talker.ui(
      'Se abrio el dialogo para calcular precio sugerido.',
      logLevel: LogLevel.warning,
    );
    final payload = await showDialog<MargenDialogResult>(
      context: context,
      builder: (_) => MargenInputDialog(
        title: 'Calcular precio sugerido',
        submitLabel: 'Calcular',
        isSubmitting: state.isSubmittingAction,
        initialMargen: state.detail?.margenPorcentaje,
      ),
    );

    if (payload == null || !context.mounted) {
      _talker.ui(
        'Se cerro el calculo de precio sugerido sin confirmar.',
        logLevel: LogLevel.debug,
      );
      return;
    }
    _talker.ui(
      'Se confirmo el calculo de precio sugerido con margen=${payload.margenPorcentaje}.',
      logLevel: LogLevel.warning,
    );

    final result = await context.read<PrecioSugeridoCubit>().calculate(
      payload.margenPorcentaje,
    );
    if (!context.mounted) return;
    _showActionResult(context, result.success, result.message);
  }

  void _showActionResult(BuildContext context, bool success, String message) {
    _talker.ui(
      success
          ? 'Accion en precio sugerido completada correctamente.'
          : 'La accion en precio sugerido fallo: $message',
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
        title: const Text('Precio sugerido'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: TextButton.icon(
              onPressed: () {
                _talker.ui(
                  'Se regreso desde precio sugerido al panel principal.',
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
              constraints: const BoxConstraints(maxWidth: 1160),
              child: BlocBuilder<PrecioSugeridoCubit, PrecioSugeridoState>(
                builder: (context, state) {
                  if (state.status == PrecioSugeridoStatus.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.status == PrecioSugeridoStatus.error) {
                    return FinanceCenteredMessage(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppMessageCard.error(
                            title: 'No pudimos preparar la vista de precios',
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
                                'Se solicito reintentar la carga de precio sugerido.',
                              );
                              context.read<PrecioSugeridoCubit>().initialize();
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
                            'Calcula un precio sugerido desde el costo real de la orden, separando margen e IGV de forma clara.',
                        description:
                            'Usa esta vista para proponer una salida comercial con base economica trazable, sin mezclarla con la pantalla de produccion.',
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
                              'Selecciona una orden, revisa el ultimo calculo y recalcula el precio sugerido con el margen que necesites.',
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
                                        'Se selecciono la orden ${value ?? 'ninguna'} en precio sugerido.',
                                        logLevel: LogLevel.debug,
                                      );
                                      context
                                          .read<PrecioSugeridoCubit>()
                                          .selectOrder(value);
                                    },
                                  ),
                                ),
                                AppButton.secondary(
                                  label: 'Calcular precio',
                                  icon: Icons.sell_outlined,
                                  isLoading: state.isSubmittingAction,
                                  onPressed: state.selectedOrderId == null
                                      ? null
                                      : () => _openMarginDialog(context, state),
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
                                    title: 'Sin precio calculado',
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
                                        'Cuando elijas una orden y exista un calculo previo, apareceran aqui el costo base, margen, IGV y precio final.',
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
                                          title: 'Base y margen',
                                          lines: [
                                            'Costo base sin IGV: S/ ${detail.costoBaseSinIgv.toStringAsFixed(2)}',
                                            'Margen %: ${detail.margenPorcentaje.toStringAsFixed(2)}',
                                            'Precio sugerido sin IGV: S/ ${detail.precioSugeridoSinIgv.toStringAsFixed(2)}',
                                          ],
                                        ),
                                        FinanceDetailCard(
                                          title: 'IGV y precio final',
                                          lines: [
                                            'IGV %: ${detail.igvPorcentaje.toStringAsFixed(2)}',
                                            'Precio sugerido con IGV: S/ ${detail.precioSugeridoConIgv.toStringAsFixed(2)}',
                                            'Orden ID: ${detail.ordenProduccionId}',
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
