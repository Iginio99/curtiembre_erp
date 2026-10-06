import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:erp_curtiembre_fronted/features/production/solicitudes_insumos/domain/entities/solicitud_insumo_detail.dart';
import 'package:erp_curtiembre_fronted/features/production/solicitudes_insumos/domain/entities/solicitud_insumo_record.dart';
import 'package:erp_curtiembre_fronted/features/production/solicitudes_insumos/presentation/cubit/solicitudes_insumos_cubit.dart';
import 'package:erp_curtiembre_fronted/features/production/solicitudes_insumos/presentation/cubit/solicitudes_insumos_state.dart';
import 'package:erp_curtiembre_fronted/features/security/presentation/cubit/security_access_cubit.dart';
import 'package:erp_curtiembre_fronted/shared/navigation/app_access_routes.dart';
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
  Widget build(BuildContext context) {
    return AppShell(
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
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: _Content(state: state),
          );
        },
      ),
    );
  }
}

/*
════════════════════════════════════════════════════
CONTENIDO PRINCIPAL
════════════════════════════════════════════════════
*/

class _Content extends StatelessWidget {
  const _Content({required this.state});

  final SolicitudesInsumosState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SolicitudesInsumosCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /*
        ──────────────────────────────
        FILTROS
        ──────────────────────────────
        */

        LayoutBuilder(
          builder: (context, constraints) {
            final filters = Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                ChoiceChip(
                  label: const Text('Pendientes'),
                  selected: state.estado == 'SOLICITADA',
                  onSelected: (_) {
                    cubit.load(estado: 'SOLICITADA');
                  },
                ),

                ChoiceChip(
                  label: const Text('Aprobadas'),
                  selected: state.estado == 'APROBADA',
                  onSelected: (_) {
                    cubit.load(estado: 'APROBADA');
                  },
                ),

                ChoiceChip(
                  label: const Text('Todas'),
                  selected: state.estado == null,
                  onSelected: (_) {
                    cubit.load(estado: null);
                  },
                ),
              ],
            );

            final refresh = OutlinedButton.icon(
              onPressed: () {
                cubit.load(estado: state.estado);
              },
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: const Text('Actualizar'),
            );

            if (constraints.maxWidth < 620) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [filters, const Gap(AppSpacing.sm), refresh],
              );
            }

            return Row(
              children: [
                Expanded(child: filters),

                const Gap(AppSpacing.md),

                refresh,
              ],
            );
          },
        ),

        const Gap(AppSpacing.md),

        /*
        ──────────────────────────────
        ESTADOS
        ──────────────────────────────
        */
        if (state.status == SolicitudesInsumosStatus.loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (state.status == SolicitudesInsumosStatus.error)
          AppMessageCard.error(
            title: 'No pudimos cargar las solicitudes',
            message: state.errorMessage ?? 'Intenta actualizar la bandeja.',
          )
        else if (state.items.isEmpty)
          const AppMessageCard.info(
            title: 'Todo al día',
            message: 'No hay solicitudes que atender con el filtro actual.',
          )
        else
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,

              itemCount: state.items.length,

              separatorBuilder: (_, _) => const Gap(AppSpacing.sm),

              itemBuilder: (context, index) {
                return _SolicitudCard(
                  item: state.items[index],
                  isDelivering: state.isDelivering,
                );
              },
            ),
          ),
      ],
    );
  }
}

/*
════════════════════════════════════════════════════
TARJETA DE SOLICITUD
════════════════════════════════════════════════════
*/

class _SolicitudCard extends StatefulWidget {
  const _SolicitudCard({required this.item, required this.isDelivering});

  final SolicitudInsumoRecord item;
  final bool isDelivering;

  @override
  State<_SolicitudCard> createState() => _SolicitudCardState();
}

class _SolicitudCardState extends State<_SolicitudCard> {
  late final Future<SolicitudInsumoDetail> _detailFuture;

  SolicitudInsumoRecord get item => widget.item;

  bool get isDelivering => widget.isDelivering;

  @override
  void initState() {
    super.initState();

    _detailFuture = context.read<SolicitudesInsumosCubit>().getDetail(item.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isApproved = item.estado == 'APROBADA';

    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.lg),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /*
          ═════════════════════════════
          CABECERA
          ═════════════════════════════
          */

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /*
              CÓDIGO
              */

              Text(
                item.codigo,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),

              const Gap(AppSpacing.xl),

              /*
              ORDEN + PROCESO
              */
              Expanded(
                child: Text(
                  '${item.ordenCodigo} · '
                  '${item.procesoCodigo} — '
                  '${item.procesoNombre}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

              const Gap(AppSpacing.md),

              /*
              ESTADO
              */
              _RequestStatus(label: item.estado, approved: isApproved),
            ],
          ),

          const Gap(AppSpacing.sm),

          /*
          ═════════════════════════════
          METADATOS
          ═════════════════════════════
          */
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: AppSpacing.xs,
            children: [
              _RequestMeta(
                text:
                    '${item.totalItems} '
                    '${item.totalItems == 1 ? 'insumo' : 'insumos'}',
              ),

              const _MetaSeparator(),

              _RequestMeta(text: '${_decimal(item.cantidadTotal)} unidades'),

              const _MetaSeparator(),

              _RequestMeta(
                text: DateFormat(
                  'dd/MM/yyyy HH:mm',
                ).format(item.solicitadoEn.toLocal()),
              ),

              const _MetaSeparator(),

              _RequestMeta(text: 'Solicitado por: ${item.solicitadoPorNombre}'),
            ],
          ),

          /*
          OBSERVACIÓN
          */
          if (item.observacion?.trim().isNotEmpty ?? false) ...[
            const Gap(AppSpacing.sm),

            Text(
              item.observacion!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],

          const Gap(AppSpacing.md),

          /*
          ═════════════════════════════
          TABLA INSUMOS
          ═════════════════════════════
          */
          FutureBuilder<SolicitudInsumoDetail>(
            future: _detailFuture,

            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: LinearProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return Text(
                  'No se pudo cargar el detalle.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                );
              }

              final lines = snapshot.data?.detalles ?? const [];

              if (lines.isEmpty) {
                return const SizedBox.shrink();
              }

              return _InsumosTable(lines: lines);
            },
          ),

          /*
          ═════════════════════════════
          BOTÓN APROBACIÓN
          ═════════════════════════════
          */
          if (item.canDeliver) ...[
            const Gap(AppSpacing.md),

            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: isDelivering ? null : () => _confirmDeliver(context),

                icon: isDelivering
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.inventory_2_outlined, size: 17),

                label: const Text('Aprobar y registrar salida'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /*
  ═══════════════════════════════════════
  CONFIRMAR ENTREGA
  ═══════════════════════════════════════
  */

  Future<void> _confirmDeliver(BuildContext context) async {
    final detail = await _loadDetail(context);

    if (detail == null || !context.mounted) {
      return;
    }

    final groupedByInsumo = <String, _GroupedInsumoLine>{};
    for (final line in detail.detalles) {
      final key =
          '${line.insumoCodigo.trim().toLowerCase()}|'
          '${line.unidadMedidaCodigo.trim().toLowerCase()}';
      final current = groupedByInsumo[key];
      groupedByInsumo[key] = _GroupedInsumoLine(
        insumoCodigo: line.insumoCodigo,
        insumoNombre: line.insumoNombre,
        unidadMedidaCodigo: line.unidadMedidaCodigo,
        cantidadSolicitada:
            (current?.cantidadSolicitada ?? 0) + line.cantidadSolicitada,
        stockDisponible: line.stockDisponible,
      );
    }
    final groupedLines = groupedByInsumo.values.toList(growable: false);
    final hasInsufficientStock = groupedLines.any(
      (line) => line.cantidadSolicitada > line.stockDisponible,
    );

    final observacionController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,

      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Aprobar ${item.codigo}'),

          content: SizedBox(
            width: 540,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Verifica los insumos. '
                  'Al aprobar se registrará la salida del inventario '
                  'y el consumo del proceso.',
                ),

                const Gap(AppSpacing.md),

                Container(
                  constraints: const BoxConstraints(maxHeight: 220),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),

                  child: ListView.separated(
                    shrinkWrap: true,

                    itemCount: groupedLines.length,

                    separatorBuilder: (_, _) => const Divider(height: 1),

                    itemBuilder: (_, index) {
                      final line = groupedLines[index];
                      final available =
                          line.stockDisponible >= line.cantidadSolicitada;

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),

                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${line.insumoCodigo} - '
                                '${line.insumoNombre}',
                              ),
                            ),

                            const Gap(AppSpacing.md),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Solicitado: ${_decimal(line.cantidadSolicitada)} '
                                  '${line.unidadMedidaCodigo}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Stock: ${_decimal(line.stockDisponible)} '
                                  '${line.unidadMedidaCodigo}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: available
                                        ? Colors.green
                                        : Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                if (hasInsufficientStock) ...[
                  const Gap(AppSpacing.sm),
                  Text(
                    'No hay stock suficiente para completar esta solicitud.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],

                const Gap(AppSpacing.md),

                TextField(
                  controller: observacionController,
                  maxLength: 500,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Observación de logística (opcional)',
                  ),
                ),
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),

            FilledButton(
              onPressed: hasInsufficientStock
                  ? null
                  : () => Navigator.pop(dialogContext, true),
              child: const Text('Aprobar y registrar salida'),
            ),
          ],
        );
      },
    );

    if (confirm != true || !context.mounted) {
      return;
    }

    final error = await context.read<SolicitudesInsumosCubit>().deliver(
      id: item.id,

      observacion: observacionController.text.trim().isEmpty
          ? null
          : observacionController.text.trim(),
    );

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ??
              '${item.codigo} fue aprobada, '
                  'se registró la salida y los insumos '
                  'quedaron asociados al proceso.',
        ),
      ),
    );
  }

  /*
  ═══════════════════════════════════════
  CARGAR DETALLE
  ═══════════════════════════════════════
  */

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

/*
════════════════════════════════════════════════════
TABLA INSUMOS
════════════════════════════════════════════════════
*/

class _InsumosTable extends StatelessWidget {
  const _InsumosTable({required this.lines});

  final List<SolicitudInsumoDetailLine> lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final groupedByInsumo = <String, _GroupedInsumoLine>{};

    for (final line in lines) {
      final key =
          '${line.insumoCodigo.trim().toLowerCase()}|'
          '${line.unidadMedidaCodigo.trim().toLowerCase()}';
      final current = groupedByInsumo[key];

      groupedByInsumo[key] = _GroupedInsumoLine(
        insumoCodigo: line.insumoCodigo,
        insumoNombre: line.insumoNombre,
        unidadMedidaCodigo: line.unidadMedidaCodigo,
        cantidadSolicitada:
            (current?.cantidadSolicitada ?? 0) + line.cantidadSolicitada,
        stockDisponible: line.stockDisponible,
      );
    }

    final groupedLines = groupedByInsumo.values.toList();

    return Container(
      width: double.infinity,

      clipBehavior: Clip.antiAlias,

      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),

        borderRadius: BorderRadius.circular(8),
      ),

      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /*
          HEADER
          */

          Container(
            width: double.infinity,

            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),

            color: theme.colorScheme.surfaceContainerHighest,

            child: Row(
              children: [
                Expanded(
                  flex: 6,
                  child: Text(
                    'Insumo',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                Expanded(
                  flex: 2,
                  child: Text(
                    'Cantidad',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          /*
          FILAS
          */
          for (int index = 0; index < groupedLines.length; index++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),

              child: Row(
                children: [
                  Expanded(
                    flex: 6,

                    child: Text(
                      '${groupedLines[index].insumoCodigo} - '
                      '${groupedLines[index].insumoNombre}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),

                  Expanded(
                    flex: 2,

                    child: Text(
                      '${_decimal(groupedLines[index].cantidadSolicitada)} '
                      '${groupedLines[index].unidadMedidaCodigo}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (index < groupedLines.length - 1)
              Divider(height: 1, color: theme.colorScheme.outlineVariant),
          ],
        ],
      ),
    );
  }
}

class _GroupedInsumoLine {
  const _GroupedInsumoLine({
    required this.insumoCodigo,
    required this.insumoNombre,
    required this.unidadMedidaCodigo,
    required this.cantidadSolicitada,
    required this.stockDisponible,
  });

  final String insumoCodigo;
  final String insumoNombre;
  final String unidadMedidaCodigo;
  final double cantidadSolicitada;
  final double stockDisponible;
}

/*
════════════════════════════════════════════════════
ESTADO
════════════════════════════════════════════════════
*/

class _RequestStatus extends StatelessWidget {
  const _RequestStatus({required this.label, required this.approved});

  final String label;
  final bool approved;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),

      decoration: BoxDecoration(
        color: approved
            ? const Color(0xFFE1F4E3)
            : theme.colorScheme.primaryContainer,

        borderRadius: BorderRadius.circular(999),
      ),

      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,

          color: approved
              ? const Color(0xFF2E7D32)
              : theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

/*
════════════════════════════════════════════════════
METADATOS
════════════════════════════════════════════════════
*/

class _RequestMeta extends StatelessWidget {
  const _RequestMeta({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _MetaSeparator extends StatelessWidget {
  const _MetaSeparator();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),

      child: Container(
        width: 1,
        height: 14,
        color: theme.colorScheme.outlineVariant,
      ),
    );
  }
}

/*
════════════════════════════════════════════════════
FORMATEAR DECIMAL
════════════════════════════════════════════════════
*/

String _decimal(double value) {
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
}
