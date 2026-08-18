import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:erp_curtiembre_fronted/features/production/solicitudes_insumos/domain/entities/solicitud_insumo_detail.dart';
import 'package:erp_curtiembre_fronted/features/production/solicitudes_insumos/domain/entities/solicitud_insumo_record.dart';
import 'package:erp_curtiembre_fronted/features/production/solicitudes_insumos/presentation/cubit/solicitudes_insumos_cubit.dart';
import 'package:erp_curtiembre_fronted/features/production/solicitudes_insumos/presentation/cubit/solicitudes_insumos_state.dart';
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

class SolicitudesInsumosPage extends StatelessWidget {
  const SolicitudesInsumosPage({super.key});

  @override
  Widget build(BuildContext context) => AppShell(
    title: 'Solicitudes de insumos',
    currentPath: '/produccion/solicitudes-insumos',
    userName: context.select(
      (AuthCubit cubit) => cubit.state.session?.nombreCompleto ?? '',
    ),
    roleName: context.select(
      (AuthCubit cubit) => cubit.state.session?.rolNombre ?? '',
    ),
    onSignOut: () => context.read<AuthCubit>().signOut(),
    accessibleRoutes: AppAccessRoutes.forPermissions(
      context.select(
        (SecurityAccessCubit cubit) =>
            cubit.state.snapshot?.userPermissionCodes.toSet() ??
            const <String>{},
      ),
    ),
    child: BlocBuilder<SolicitudesInsumosCubit, SolicitudesInsumosState>(
      builder: (context, state) => _Content(state: state),
    ),
  );
}

class _Content extends StatelessWidget {
  const _Content({required this.state});

  final SolicitudesInsumosState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SolicitudesInsumosCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            ChoiceChip(
              label: const Text('Pendientes'),
              selected: state.estado == 'SOLICITADA',
              onSelected: (_) => cubit.load(estado: 'SOLICITADA'),
            ),
            ChoiceChip(
              label: const Text('Entregadas'),
              selected: state.estado == 'ENTREGADA',
              onSelected: (_) => cubit.load(estado: 'ENTREGADA'),
            ),
            ChoiceChip(
              label: const Text('Todas'),
              selected: state.estado == null,
              onSelected: (_) => cubit.load(estado: null),
            ),
            AppButton.secondary(
              label: 'Actualizar',
              icon: Icons.refresh_rounded,
              onPressed: () => cubit.load(estado: state.estado),
            ),
          ],
        ),
        const Gap(AppSpacing.lg),
        if (state.status == SolicitudesInsumosStatus.loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (state.status == SolicitudesInsumosStatus.error)
          AppMessageCard.error(
            title: 'No pudimos cargar las solicitudes',
            message: state.errorMessage ?? 'Intenta actualizar la bandeja.',
          )
        else if (state.items.isEmpty)
          const AppMessageCard.info(
            title: 'Sin solicitudes',
            message: 'No hay solicitudes para el filtro seleccionado.',
          )
        else
          Expanded(
            child: ListView.separated(
              itemCount: state.items.length,
              separatorBuilder: (_, _) => const Gap(AppSpacing.md),
              itemBuilder: (context, index) => _SolicitudCard(
                item: state.items[index],
                isDelivering: state.isDelivering,
              ),
            ),
          ),
      ],
    );
  }
}

class _SolicitudCard extends StatelessWidget {
  const _SolicitudCard({required this.item, required this.isDelivering});

  final SolicitudInsumoRecord item;
  final bool isDelivering;

  @override
  Widget build(BuildContext context) => AppSurfaceCard(
    child: LayoutBuilder(
      builder: (context, constraints) => Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: AppSpacing.md,
        children: [
          SizedBox(
            width: constraints.maxWidth > 760
                ? constraints.maxWidth - 220
                : constraints.maxWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.codigo,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Gap(AppSpacing.xs),
                Text(
                  '${item.ordenCodigo} · ${item.procesoCodigo} — ${item.procesoNombre}',
                ),
                const Gap(AppSpacing.xs),
                Text(
                  '${item.totalItems} insumo(s) · ${_decimal(item.cantidadTotal)} unidades · ${DateFormat('dd/MM/yyyy HH:mm').format(item.solicitadoEn.toLocal())}',
                ),
                Text('Solicitado por: ${item.solicitadoPorNombre}'),
                if (item.observacion?.trim().isNotEmpty ?? false)
                  Text('Observación: ${item.observacion}'),
              ],
            ),
          ),
          if (item.canDeliver)
            AppButton.primary(
              label: 'Entregar total',
              icon: Icons.inventory_rounded,
              isLoading: isDelivering,
              onPressed: isDelivering ? null : () => _confirmDeliver(context),
            )
          else
            Chip(label: Text(item.estado)),
        ],
      ),
    ),
  );

  Future<void> _confirmDeliver(BuildContext context) async {
    final detail = await _loadDetail(context);
    if (detail == null || !context.mounted) return;
    final observacionController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Entregar ${item.codigo}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Verifica los insumos. Se realizará la salida del total solicitado; no se permiten entregas parciales.',
            ),
            const Gap(AppSpacing.md),
            SizedBox(
              width: 500,
              height: 180,
              child: ListView.separated(
                itemCount: detail.detalles.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: AppSpacing.md),
                itemBuilder: (_, index) {
                  final line = detail.detalles[index];
                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${line.insumoCodigo} · ${line.insumoNombre}',
                        ),
                      ),
                      Text(
                        '${_decimal(line.cantidadSolicitada)} ${line.unidadMedidaCodigo}',
                      ),
                    ],
                  );
                },
              ),
            ),
            TextField(
              controller: observacionController,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Observación de logística (opcional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirmar entrega'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    final error = await context.read<SolicitudesInsumosCubit>().deliver(
      id: item.id,
      observacion: observacionController.text.trim().isEmpty
          ? null
          : observacionController.text.trim(),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ??
              '${item.codigo} fue entregada y la etapa quedó lista para iniciar.',
        ),
      ),
    );
  }

  Future<SolicitudInsumoDetail?> _loadDetail(BuildContext context) async {
    try {
      return await context.read<SolicitudesInsumosCubit>().getDetail(item.id);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No pudimos cargar el detalle de la solicitud.'),
          ),
        );
      }
      return null;
    }
  }
}

String _decimal(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(2);
