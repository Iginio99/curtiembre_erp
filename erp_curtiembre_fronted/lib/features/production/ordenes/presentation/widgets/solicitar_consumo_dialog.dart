import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/domain/entities/insumo_lookup.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/orden_proceso_record.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/repositories/ordenes_produccion_repository.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/buttons/app_button.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class SolicitarConsumoDialogResult {
  const SolicitarConsumoDialogResult({
    required this.ordenProcesoId,
    this.motivo,
    this.observacion,
    required this.detalles,
  });

  final int ordenProcesoId;
  final String? motivo;
  final String? observacion;
  final List<SolicitarConsumoProduccionDetalleInput> detalles;
}

class SolicitarConsumoDialog extends StatefulWidget {
  const SolicitarConsumoDialog({
    super.key,
    required this.proceso,
    required this.insumos,
    required this.isSubmitting,
  });

  final OrdenProcesoRecord proceso;
  final List<InsumoLookup> insumos;
  final bool isSubmitting;

  @override
  State<SolicitarConsumoDialog> createState() => _SolicitarConsumoDialogState();
}

class _SolicitarConsumoDialogState extends State<SolicitarConsumoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _motivoController = TextEditingController();
  final _observacionController = TextEditingController();
  final List<_ConsumoDetalleDraft> _drafts = [_ConsumoDetalleDraft()];

  @override
  void dispose() {
    _motivoController.dispose();
    _observacionController.dispose();
    for (final draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  void _addDraft() {
    setState(() => _drafts.add(_ConsumoDetalleDraft()));
  }

  void _removeDraft(int index) {
    if (_drafts.length == 1) {
      return;
    }

    setState(() {
      final draft = _drafts.removeAt(index);
      draft.dispose();
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final details = <SolicitarConsumoProduccionDetalleInput>[];
    for (final draft in _drafts) {
      final insumoId = draft.insumoId;
      final cantidad = double.tryParse(
        draft.cantidadController.text.trim().replaceAll(',', '.'),
      );

      if (insumoId == null || cantidad == null || cantidad <= 0) {
        continue;
      }

      details.add(
        SolicitarConsumoProduccionDetalleInput(
          insumoId: insumoId,
          cantidad: cantidad,
          observacion: draft.observacionController.text.trim().isEmpty
              ? null
              : draft.observacionController.text.trim(),
        ),
      );
    }

    if (details.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega al menos un insumo valido para registrar consumo.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).pop(
      SolicitarConsumoDialogResult(
        ordenProcesoId: widget.proceso.id,
        motivo: _motivoController.text.trim().isEmpty
            ? null
            : _motivoController.text.trim(),
        observacion: _observacionController.text.trim().isEmpty
            ? null
            : _observacionController.text.trim(),
        detalles: details,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Solicitar consumo real', style: theme.textTheme.headlineSmall),
                const Gap(AppSpacing.sm),
                Text(
                  'Registra los insumos consumidos por el proceso seleccionado y deja trazabilidad del movimiento real.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Gap(AppSpacing.lg),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Wrap(
                    spacing: AppSpacing.lg,
                    runSpacing: AppSpacing.md,
                    children: [
                      _ProcesoInfo(
                        label: 'Proceso',
                        value:
                            '${widget.proceso.secuencia}. ${widget.proceso.procesoNombre}',
                      ),
                      _ProcesoInfo(
                        label: 'Codigo',
                        value: widget.proceso.procesoCodigo,
                      ),
                      _ProcesoInfo(
                        label: 'Estado',
                        value: widget.proceso.estado,
                      ),
                    ],
                  ),
                ),
                const Gap(AppSpacing.xl),
                TextFormField(
                  controller: _motivoController,
                  decoration: const InputDecoration(
                    labelText: 'Motivo',
                    hintText: 'Ej. Consumo operativo del proceso',
                  ),
                ),
                const Gap(AppSpacing.lg),
                TextFormField(
                  controller: _observacionController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Observacion general',
                    hintText: 'Detalle breve de la solicitud de consumo',
                  ),
                ),
                const Gap(AppSpacing.xl),
                Row(
                  children: [
                    Text('Detalle de insumos', style: theme.textTheme.titleLarge),
                    const Spacer(),
                    AppButton.secondary(
                      label: 'Agregar linea',
                      icon: Icons.add_rounded,
                      onPressed: _addDraft,
                    ),
                  ],
                ),
                const Gap(AppSpacing.md),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (var index = 0; index < _drafts.length; index++) ...[
                          _ConsumoDetalleDraftCard(
                            key: ValueKey(_drafts[index]),
                            index: index,
                            draft: _drafts[index],
                            insumos: widget.insumos,
                            onRemove: _drafts.length == 1
                                ? null
                                : () => _removeDraft(index),
                          ),
                          if (index < _drafts.length - 1) const Gap(AppSpacing.md),
                        ],
                      ],
                    ),
                  ),
                ),
                const Gap(AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppButton.secondary(
                      label: 'Cancelar',
                      onPressed: widget.isSubmitting ? null : () => Navigator.of(context).pop(),
                    ),
                    const Gap(AppSpacing.md),
                    AppButton.primary(
                      label: 'Solicitar consumo',
                      icon: Icons.inventory_2_outlined,
                      expand: false,
                      isLoading: widget.isSubmitting,
                      onPressed: widget.isSubmitting ? null : _submit,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConsumoDetalleDraftCard extends StatelessWidget {
  const _ConsumoDetalleDraftCard({
    super.key,
    required this.index,
    required this.draft,
    required this.insumos,
    this.onRemove,
  });

  final int index;
  final _ConsumoDetalleDraft draft;
  final List<InsumoLookup> insumos;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Linea ${index + 1}', style: theme.textTheme.titleMedium),
              const Spacer(),
              if (onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  tooltip: 'Quitar linea',
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
            ],
          ),
          const Gap(AppSpacing.md),
          DropdownButtonFormField<int?>(
            initialValue: draft.insumoId,
            decoration: const InputDecoration(labelText: 'Insumo'),
            items: insumos
                .map(
                  (item) => DropdownMenuItem<int?>(
                    value: item.id,
                    child: Text('${item.codigo} - ${item.nombre}'),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) => draft.insumoId = value,
            validator: (value) => value == null ? 'Selecciona un insumo.' : null,
          ),
          const Gap(AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: draft.cantidadController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Cantidad consumida',
                    hintText: '0.00',
                  ),
                  validator: (value) {
                    final parsed = double.tryParse(
                      (value ?? '').trim().replaceAll(',', '.'),
                    );
                    if (parsed == null || parsed <= 0) {
                      return 'Cantidad invalida.';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const Gap(AppSpacing.md),
          TextFormField(
            controller: draft.observacionController,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Observacion de linea',
              hintText: 'Opcional',
            ),
          ),
        ],
      ),
    );
  }
}

class _ProcesoInfo extends StatelessWidget {
  const _ProcesoInfo({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 220,
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
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ConsumoDetalleDraft {
  int? insumoId;
  final TextEditingController cantidadController = TextEditingController();
  final TextEditingController observacionController = TextEditingController();

  void dispose() {
    cantidadController.dispose();
    observacionController.dispose();
  }
}
