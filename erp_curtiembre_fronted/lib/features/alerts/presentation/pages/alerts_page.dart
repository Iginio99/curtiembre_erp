import 'package:erp_curtiembre_fronted/core/theme/app_breakpoints.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/alerts/domain/entities/alert_record.dart';
import 'package:erp_curtiembre_fronted/features/alerts/presentation/cubit/alerts_cubit.dart';
import 'package:erp_curtiembre_fronted/features/alerts/presentation/cubit/alerts_state.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/buttons/app_button.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/feedback/app_message_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AlertsCubit, AlertsState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage && current.errorMessage != null,
      listener: (context, state) {
        final message = state.errorMessage;
        if (message == null) {
          return;
        }
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Alertas'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              child: TextButton.icon(
                onPressed: () => context.go('/home'),
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
                child: BlocBuilder<AlertsCubit, AlertsState>(
                  builder: (context, state) {
                    if (state.status == AlertsStatus.loading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state.status == AlertsStatus.error && state.summary == null) {
                      return _CenteredContent(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppMessageCard.error(
                              title: 'No pudimos cargar alertas',
                              message: state.errorMessage ??
                                  'Intenta nuevamente para consultar la bandeja.',
                            ),
                            const Gap(AppSpacing.lg),
                            AppButton.secondary(
                              label: 'Reintentar',
                              icon: Icons.refresh_rounded,
                              onPressed: () => context.read<AlertsCubit>().initialize(),
                            ),
                          ],
                        ),
                      );
                    }

                    final summary = state.summary;
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= AppBreakpoints.desktop;
                        final compactHeight = constraints.maxHeight < 920;

                        final content = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _AlertsHero(summary: summary),
                            const Gap(AppSpacing.xl),
                            _AlertsFilterCard(
                              state: state,
                              onApply: ({
                                String? estado,
                                String? severidad,
                                String? tipoAlerta,
                                String? moduloOrigen,
                              }) =>
                                  context.read<AlertsCubit>().applyFilters(
                                        estado: estado,
                                        severidad: severidad,
                                        tipoAlerta: tipoAlerta,
                                        moduloOrigen: moduloOrigen,
                                      ),
                              onClear: () => context.read<AlertsCubit>().clearFilters(),
                            ),
                            const Gap(AppSpacing.xl),
                            Expanded(
                              child: isWide
                                  ? Row(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Expanded(
                                          flex: 9,
                                          child: _AlertsListCard(state: state),
                                        ),
                                        const Gap(AppSpacing.xl),
                                        Expanded(
                                          flex: 8,
                                          child: _AlertDetailCard(state: state),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      children: [
                                        Expanded(child: _AlertsListCard(state: state)),
                                        const Gap(AppSpacing.xl),
                                        Expanded(child: _AlertDetailCard(state: state)),
                                      ],
                                    ),
                            ),
                          ],
                        );

                        if (compactHeight) {
                          final panelHeight = isWide
                              ? constraints.maxHeight.clamp(560.0, 760.0)
                              : constraints.maxHeight.clamp(420.0, 620.0);

                          return SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _AlertsHero(summary: summary),
                                const Gap(AppSpacing.xl),
                                _AlertsFilterCard(
                                  state: state,
                                  onApply: ({
                                    String? estado,
                                    String? severidad,
                                    String? tipoAlerta,
                                    String? moduloOrigen,
                                  }) =>
                                      context.read<AlertsCubit>().applyFilters(
                                            estado: estado,
                                            severidad: severidad,
                                            tipoAlerta: tipoAlerta,
                                            moduloOrigen: moduloOrigen,
                                          ),
                                  onClear: () => context.read<AlertsCubit>().clearFilters(),
                                ),
                                const Gap(AppSpacing.xl),
                                if (isWide)
                                  SizedBox(
                                    height: panelHeight,
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Expanded(
                                          flex: 9,
                                          child: _AlertsListCard(state: state),
                                        ),
                                        const Gap(AppSpacing.xl),
                                        Expanded(
                                          flex: 8,
                                          child: _AlertDetailCard(state: state),
                                        ),
                                      ],
                                    ),
                                  )
                                else ...[
                                  SizedBox(
                                    height: panelHeight,
                                    child: _AlertsListCard(state: state),
                                  ),
                                  const Gap(AppSpacing.xl),
                                  SizedBox(
                                    height: panelHeight,
                                    child: _AlertDetailCard(state: state),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }

                        return content;
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AlertsHero extends StatelessWidget {
  const _AlertsHero({required this.summary});

  final AlertsSummary? summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Wrap(
        spacing: AppSpacing.xl,
        runSpacing: AppSpacing.lg,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Centraliza alertas operativas y prioriza lo que necesita accion.',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    height: 1.12,
                  ),
                ),
                const Gap(AppSpacing.sm),
                Text(
                  'La bandeja agrupa eventos activos por severidad y modulo para que puedas revisar lo urgente sin perder contexto.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _HeroMetric(label: 'Pendientes', value: '${summary?.totalPendientes ?? 0}'),
              _HeroMetric(label: 'Alta', value: '${summary?.totalAlta ?? 0}'),
              _HeroMetric(label: 'Media', value: '${summary?.totalMedia ?? 0}'),
              _HeroMetric(label: 'Baja', value: '${summary?.totalBaja ?? 0}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
          const Gap(AppSpacing.xs),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _AlertsFilterCard extends StatefulWidget {
  const _AlertsFilterCard({
    required this.state,
    required this.onApply,
    required this.onClear,
  });

  final AlertsState state;
  final void Function({
    String? estado,
    String? severidad,
    String? tipoAlerta,
    String? moduloOrigen,
  }) onApply;
  final VoidCallback onClear;

  @override
  State<_AlertsFilterCard> createState() => _AlertsFilterCardState();
}

class _AlertsFilterCardState extends State<_AlertsFilterCard> {
  String? _estado;
  String? _severidad;
  String? _tipo;
  String? _modulo;

  @override
  void initState() {
    super.initState();
    _syncFromState();
  }

  @override
  void didUpdateWidget(covariant _AlertsFilterCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _syncFromState();
    }
  }

  void _syncFromState() {
    _estado = widget.state.estadoFilter;
    _severidad = widget.state.severidadFilter;
    _tipo = widget.state.tipoAlertaFilter;
    _modulo = widget.state.moduloOrigenFilter;
  }

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      title: 'Filtros de bandeja',
      subtitle: 'Reduce la lista por estado, severidad o modulo de origen.',
      child: Wrap(
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.lg,
        children: [
          _DropdownField(
            label: 'Estado',
            value: _estado,
            options: const ['PENDIENTE', 'LEIDA', 'CERRADA'],
            onChanged: (value) => setState(() => _estado = value),
          ),
          _DropdownField(
            label: 'Severidad',
            value: _severidad,
            options: const ['ALTA', 'MEDIA', 'BAJA'],
            onChanged: (value) => setState(() => _severidad = value),
          ),
          _DropdownField(
            label: 'Tipo',
            value: _tipo,
            options: const ['STOCK_BAJO', 'ORDEN_RETRASADA', 'COMPRA_PENDIENTE_APROBACION'],
            onChanged: (value) => setState(() => _tipo = value),
          ),
          _DropdownField(
            label: 'Modulo',
            value: _modulo,
            options: const ['Inventario', 'Produccion', 'Compras'],
            onChanged: (value) => setState(() => _modulo = value),
          ),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              AppButton.primary(
                label: 'Aplicar filtros',
                icon: Icons.filter_alt_outlined,
                isLoading: widget.state.loadingList,
                onPressed: () => widget.onApply(
                  estado: _estado,
                  severidad: _severidad,
                  tipoAlerta: _tipo,
                  moduloOrigen: _modulo,
                ),
              ),
              AppButton.secondary(
                label: 'Limpiar',
                icon: Icons.refresh_rounded,
                onPressed: () {
                  setState(() {
                    _estado = null;
                    _severidad = null;
                    _tipo = null;
                    _modulo = null;
                  });
                  widget.onClear();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: DropdownButtonFormField<String>(
        initialValue: options.contains(value) ? value : null,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: [
          const DropdownMenuItem<String>(
            value: null,
            child: Text(
              'Todos',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ...options.map(
            (option) => DropdownMenuItem<String>(
              value: option,
              child: Text(
                option,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _AlertsListCard extends StatelessWidget {
  const _AlertsListCard({required this.state});

  final AlertsState state;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      title: 'Bandeja de alertas',
      subtitle: '${state.alerts.length} registro(s) visibles.',
      child: Expanded(
        child: state.loadingList
            ? const Center(child: CircularProgressIndicator())
            : state.alerts.isEmpty
                ? const _CenteredContent(
                    child: AppMessageCard.info(
                      title: 'Sin alertas visibles',
                      message: 'No encontramos alertas para los filtros actuales.',
                    ),
                  )
                : ListView.separated(
                    itemCount: state.alerts.length,
                    separatorBuilder: (_, _) => const Gap(AppSpacing.md),
                    itemBuilder: (context, index) {
                      final item = state.alerts[index];
                      final selected = state.selectedAlert?.id == item.id;
                      return InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => context.read<AlertsCubit>().selectAlert(item.id),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: selected
                                ? Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                    .withValues(alpha: 0.55)
                                : Theme.of(context).colorScheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.outlineVariant,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.titulo,
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                  ),
                                  _SeverityChip(severidad: item.severidad),
                                ],
                              ),
                              const Gap(AppSpacing.xs),
                              Text(
                                item.mensaje,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              const Gap(AppSpacing.md),
                              Wrap(
                                spacing: AppSpacing.sm,
                                runSpacing: AppSpacing.sm,
                                children: [
                                  _MiniChip(label: item.estado),
                                  _MiniChip(label: item.moduloOrigen),
                                  _MiniChip(label: item.tipoAlerta),
                                  _MiniChip(label: _formatDateTime(item.generadaEn)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

class _AlertDetailCard extends StatelessWidget {
  const _AlertDetailCard({required this.state});

  final AlertsState state;

  @override
  Widget build(BuildContext context) {
    final detail = state.selectedAlert;

    return _SurfaceCard(
      title: 'Detalle de alerta',
      subtitle: detail == null
          ? 'Selecciona una alerta para revisar mensaje, estado e historial.'
          : '${detail.tipoAlerta} · ${detail.moduloOrigen}',
      child: Expanded(
        child: state.loadingDetail
            ? const Center(child: CircularProgressIndicator())
            : detail == null
                ? const _CenteredContent(
                    child: AppMessageCard.info(
                      title: 'Sin seleccion',
                      message: 'Escoge una alerta de la bandeja para revisar su detalle.',
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: [
                                _SeverityChip(severidad: detail.severidad),
                                _MiniChip(label: detail.estado),
                                if ((detail.entidadOrigen ?? '').isNotEmpty)
                                  _MiniChip(label: detail.entidadOrigen!),
                                if (detail.entidadOrigenId != null)
                                  _MiniChip(label: 'ID ${detail.entidadOrigenId}'),
                              ],
                            ),
                          ),
                          Wrap(
                            spacing: AppSpacing.md,
                            runSpacing: AppSpacing.md,
                            children: [
                              AppButton.secondary(
                                label: 'Marcar leida',
                                icon: Icons.mark_email_read_outlined,
                                isLoading: state.loadingAction,
                                onPressed: detail.estado.toUpperCase() == 'PENDIENTE'
                                    ? () => context.read<AlertsCubit>().markSelectedAsRead()
                                    : null,
                              ),
                              AppButton.secondary(
                                label: 'Cerrar alerta',
                                icon: Icons.task_alt_outlined,
                                isLoading: state.loadingAction,
                                onPressed: detail.estado.toUpperCase() == 'CERRADA'
                                    ? null
                                    : () => _showCloseDialog(context),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Gap(AppSpacing.lg),
                      Text(
                        detail.titulo,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Gap(AppSpacing.sm),
                      Text(
                        detail.mensaje,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              height: 1.45,
                            ),
                      ),
                      const Gap(AppSpacing.lg),
                      Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.md,
                        children: [
                          _DetailStat(label: 'Generada', value: _formatDateTime(detail.generadaEn)),
                          _DetailStat(
                            label: 'Leida',
                            value: detail.leidaEn == null
                                ? 'Pendiente'
                                : _formatDateTime(detail.leidaEn!),
                          ),
                          _DetailStat(
                            label: 'Cerrada',
                            value: detail.cerradaEn == null
                                ? 'Abierta'
                                : _formatDateTime(detail.cerradaEn!),
                          ),
                        ],
                      ),
                      const Gap(AppSpacing.xl),
                      Text(
                        'Historial',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Gap(AppSpacing.md),
                      state.history.isEmpty
                            ? const _CenteredContent(
                                child: AppMessageCard.info(
                                  title: 'Sin historial',
                                  message: 'Todavia no hay cambios registrados para esta alerta.',
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: state.history.length,
                                separatorBuilder: (_, _) => const Gap(AppSpacing.md),
                                itemBuilder: (context, index) {
                                  final item = state.history[index];
                                  return Container(
                                    padding: const EdgeInsets.all(AppSpacing.lg),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerLowest,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: Theme.of(context).colorScheme.outlineVariant,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${item.estadoAnterior ?? 'Sin estado'} -> ${item.estadoNuevo}',
                                          style: Theme.of(context).textTheme.titleSmall,
                                        ),
                                        const Gap(AppSpacing.xs),
                                        Text(
                                          item.comentario ?? 'Sin comentario.',
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                        const Gap(AppSpacing.sm),
                                        Text(
                                          '${item.cambiadoPorNombre ?? 'Sistema'} · ${_formatDateTime(item.cambiadoEn)}',
                                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                    ],
                  ),
                  ),
      ),
    );
  }

  Future<void> _showCloseDialog(BuildContext context) async {
    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cerrar alerta'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Comentario',
              hintText: 'Opcional. Agrega contexto del cierre.',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Cerrar alerta'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      await context.read<AlertsCubit>().closeSelected(
            comentario: controller.text,
          );
    }
  }
}

class _SeverityChip extends StatelessWidget {
  const _SeverityChip({required this.severidad});

  final String severidad;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalized = severidad.toUpperCase();
    final color = switch (normalized) {
      'ALTA' => theme.colorScheme.error,
      'MEDIA' => const Color(0xFFD17B0F),
      _ => theme.colorScheme.secondary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        normalized,
        style: theme.textTheme.labelLarge?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(label, style: theme.textTheme.labelMedium),
    );
  }
}

class _DetailStat extends StatelessWidget {
  const _DetailStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 180,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(AppSpacing.xs),
          Text(value, style: theme.textTheme.titleSmall),
        ],
      ),
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
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
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
          child,
        ],
      ),
    );
  }
}

class _CenteredContent extends StatelessWidget {
  const _CenteredContent({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: child,
      ),
    );
  }
}

String _formatDateTime(DateTime value) {
  return DateFormat('dd/MM/yyyy hh:mm a').format(value.toLocal());
}
