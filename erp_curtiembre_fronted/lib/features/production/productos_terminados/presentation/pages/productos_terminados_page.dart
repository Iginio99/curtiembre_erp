import 'package:erp_curtiembre_fronted/core/di/service_locator.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_state.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/producto_terminado_record.dart';
import 'package:erp_curtiembre_fronted/features/production/productos_terminados/presentation/cubit/productos_terminados_cubit.dart';
import 'package:erp_curtiembre_fronted/features/production/productos_terminados/presentation/cubit/productos_terminados_state.dart';
import 'package:erp_curtiembre_fronted/features/security/presentation/cubit/security_access_cubit.dart';
import 'package:erp_curtiembre_fronted/shared/navigation/app_access_routes.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/buttons/app_button.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/feedback/app_message_card.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/layout/app_shell.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/layout/app_surface_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:talker_flutter/talker_flutter.dart';

class ProductosTerminadosPage extends StatefulWidget {
  const ProductosTerminadosPage({super.key});

  @override
  State<ProductosTerminadosPage> createState() =>
      _ProductosTerminadosPageState();
}

class _ProductosTerminadosPageState extends State<ProductosTerminadosPage> {
  final _searchController = TextEditingController();
  final Talker _talker = getIt<Talker>();

  @override
  void initState() {
    super.initState();
    _talker.ui('Se abrio la pantalla de productos terminados.');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      title: 'Productos terminados',
      currentPath: '/produccion/productos-terminados',
      breadcrumbs: const ['Inicio', 'Producción', 'Productos terminados'],
      userName: session.nombreCompleto,
      roleName: session.rolNombre,
      accessibleRoutes: AppAccessRoutes.forPermissions(permissionCodes),
      onSignOut: isSigningOut
          ? () {}
          : () => context.read<AuthCubit>().signOut(),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1480),
            child: BlocBuilder<ProductosTerminadosCubit, ProductosTerminadosState>(
              builder: (context, state) {
                final isWide = MediaQuery.sizeOf(context).width >= 1040;
                if (_searchController.text != state.searchTerm) {
                  _searchController.value = TextEditingValue(
                    text: state.searchTerm,
                    selection: TextSelection.collapsed(
                      offset: state.searchTerm.length,
                    ),
                  );
                }

                final listPanel = _ProductosListPanel(
                  state: state,
                  onRetry: () {
                    _talker.ui(
                      'Se solicito reintentar la carga de productos terminados.',
                    );
                    context.read<ProductosTerminadosCubit>().initialize();
                  },
                  onSelect: (id) {
                    _talker.ui(
                      'Se selecciono el producto terminado $id desde el listado.',
                      logLevel: LogLevel.debug,
                    );
                    context.read<ProductosTerminadosCubit>().selectItem(id);
                  },
                );

                final detailPanel = _ProductoDetailPanel(
                  item: state.selectedItem,
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Consulta lo que ya ingreso como producto terminado y valida calidad, cantidades y trazabilidad de cierre.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Gap(AppSpacing.xl),
                    AppSurfaceCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: TextField(
                        controller: _searchController,
                        onChanged: context
                            .read<ProductosTerminadosCubit>()
                            .applySearch,
                        decoration: const InputDecoration(
                          labelText: 'Buscar producto terminado',
                          hintText: 'Ej. PT-0001, OP-0001 o calidad A',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                      ),
                    ),
                    const Gap(AppSpacing.xl),
                    Expanded(
                      child: isWide
                          ? Row(
                              children: [
                                Expanded(flex: 8, child: listPanel),
                                const Gap(AppSpacing.xl),
                                Expanded(flex: 9, child: detailPanel),
                              ],
                            )
                          : Column(
                              children: [
                                Expanded(child: listPanel),
                                const Gap(AppSpacing.xl),
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
      ),
    );
  }
}

class _ProductosListPanel extends StatelessWidget {
  const _ProductosListPanel({
    required this.state,
    required this.onRetry,
    required this.onSelect,
  });

  final ProductosTerminadosState state;
  final VoidCallback onRetry;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Listado', style: theme.textTheme.titleLarge),
          const Gap(AppSpacing.lg),
          Expanded(
            child: switch (state.status) {
              ProductosTerminadosStatus.loading => const Center(
                child: CircularProgressIndicator(),
              ),
              ProductosTerminadosStatus.error => _CenteredMessage(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppMessageCard.error(
                      title: 'No pudimos cargar productos terminados',
                      message: state.errorMessage ?? 'Intenta nuevamente.',
                    ),
                    const Gap(AppSpacing.lg),
                    AppButton.secondary(
                      label: 'Reintentar',
                      icon: Icons.refresh_rounded,
                      onPressed: onRetry,
                    ),
                  ],
                ),
              ),
              ProductosTerminadosStatus.success =>
                state.filteredItems.isEmpty
                    ? const _CenteredMessage(
                        child: AppMessageCard.info(
                          title: 'Sin resultados',
                          message:
                              'No encontramos productos terminados con ese criterio.',
                        ),
                      )
                    : ListView.separated(
                        itemCount: state.filteredItems.length,
                        separatorBuilder: (_, _) => const Gap(AppSpacing.md),
                        itemBuilder: (context, index) {
                          final item = state.filteredItems[index];
                          return _ProductoListTile(
                            item: item,
                            isSelected: state.selectedItem?.id == item.id,
                            onTap: () => onSelect(item.id),
                          );
                        },
                      ),
            },
          ),
        ],
      ),
    );
  }
}

class _ProductoDetailPanel extends StatelessWidget {
  const _ProductoDetailPanel({required this.item});

  final ProductoTerminadoRecord? item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: item == null
          ? const _CenteredMessage(
              child: AppMessageCard.info(
                title: 'Selecciona un producto',
                message: 'Escoge un registro del listado para ver su detalle.',
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item!.codigo, style: theme.textTheme.headlineSmall),
                const Gap(AppSpacing.sm),
                Text(
                  '${item!.calidadNombre} · ${item!.calidadCodigo}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const Gap(AppSpacing.xl),
                Wrap(
                  spacing: AppSpacing.lg,
                  runSpacing: AppSpacing.lg,
                  children: [
                    _DetailCard(
                      title: 'Origen',
                      lines: [
                        'Orden: ${item!.ordenCodigo}',
                        'Estado: ${item!.estado}',
                      ],
                    ),
                    _DetailCard(
                      title: 'Clasificación final',
                      lines: [
                        'A: ${_formatDecimal(item!.cantidadLadosA)} lados (${_formatDecimal(item!.cantidadLadosA / 2)} pieles)',
                        'B: ${_formatDecimal(item!.cantidadLadosB)} lados (${_formatDecimal(item!.cantidadLadosB / 2)} pieles)',
                        'C: ${_formatDecimal(item!.cantidadLadosC)} lados (${_formatDecimal(item!.cantidadLadosC / 2)} pieles)',
                        'Merma: ${_formatDecimal(item!.cantidadLadosMerma)} lados (${_formatDecimal(item!.cantidadLadosMerma / 2)} pieles)',
                      ],
                    ),
                    _DetailCard(
                      title: 'Ingreso',
                      lines: [
                        'Fecha: ${_formatDateTime(item!.fechaIngreso)}',
                        'Calidad: ${item!.calidadCodigo}',
                      ],
                    ),
                  ],
                ),
                if ((item!.observacion ?? '').trim().isNotEmpty) ...[
                  const Gap(AppSpacing.xl),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Observacion', style: theme.textTheme.titleMedium),
                        const Gap(AppSpacing.md),
                        Text(
                          item!.observacion!,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _ProductoListTile extends StatelessWidget {
  const _ProductoListTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final ProductoTerminadoRecord item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.68)
                : theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.42)
                  : theme.colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.codigo, style: theme.textTheme.titleMedium),
              const Gap(AppSpacing.sm),
              Text(
                '${item.ordenCodigo} · ${item.calidadCodigo}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const Gap(AppSpacing.md),
              Text(
                'Lados: ${_formatDecimal(item.cantidadLadosCalculada)} · ${_formatDate(item.fechaIngreso)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 270,
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
          const Gap(AppSpacing.md),
          for (final line in lines) ...[
            Text(line, style: theme.textTheme.bodyMedium),
            const Gap(AppSpacing.sm),
          ],
        ],
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
        constraints: const BoxConstraints(maxWidth: 520),
        child: child,
      ),
    );
  }
}

String _formatDecimal(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(2);
}

String _formatDate(DateTime value) {
  return DateFormat('dd/MM/yyyy').format(value.toLocal());
}

String _formatDateTime(DateTime value) {
  return DateFormat('dd/MM/yyyy hh:mm a').format(value.toLocal());
}
