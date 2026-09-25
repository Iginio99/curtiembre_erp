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
          content: Text(
            'Agrega al menos un insumo valido para registrar consumo.',
          ),
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
    final isWide = MediaQuery.sizeOf(context).width >= 760;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 1040,
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Solicitar consumo real',
                  style: theme.textTheme.headlineSmall,
                ),
                const Gap(AppSpacing.sm),
                Text(
                  'Registra los insumos consumidos por el proceso seleccionado y deja trazabilidad del movimiento real.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Gap(AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
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
                const Gap(AppSpacing.md),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _motivoController,
                          decoration: const InputDecoration(
                            labelText: 'Motivo',
                            hintText: 'Ej. Consumo operativo',
                          ),
                        ),
                      ),
                      const Gap(AppSpacing.md),
                      Expanded(
                        child: TextFormField(
                          controller: _observacionController,
                          decoration: const InputDecoration(
                            labelText: 'Observacion general',
                            hintText: 'Opcional',
                          ),
                        ),
                      ),
                    ],
                  )
                else ...[
                  TextFormField(
                    controller: _motivoController,
                    decoration: const InputDecoration(labelText: 'Motivo'),
                  ),
                  const Gap(AppSpacing.md),
                  TextFormField(
                    controller: _observacionController,
                    decoration: const InputDecoration(
                      labelText: 'Observacion general',
                    ),
                  ),
                ],
                const Gap(AppSpacing.lg),
                Row(
                  children: [
                    Text(
                      'Detalle de insumos',
                      style: theme.textTheme.titleMedium,
                    ),
                    const Spacer(),
                    AppButton.secondary(
                      label: 'Agregar linea',
                      icon: Icons.add_rounded,
                      onPressed: _addDraft,
                    ),
                  ],
                ),
                const Gap(AppSpacing.sm),
                Flexible(
                  child: SingleChildScrollView(
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Column(
                        children: [
                          for (var index = 0; index < _drafts.length; index++)
                            _ConsumoDetalleDraftCard(
                              key: ValueKey(_drafts[index]),
                              draft: _drafts[index],
                              insumos: widget.insumos,
                              compact: isWide,
                              showDivider: index < _drafts.length - 1,
                              onChanged: () => setState(() {}),
                              onRemove: _drafts.length == 1
                                  ? null
                                  : () => _removeDraft(index),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Gap(AppSpacing.md),
                Divider(height: 1, color: theme.colorScheme.outlineVariant),
                const Gap(AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppButton.secondary(
                      label: 'Cancelar',
                      onPressed: widget.isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
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
    required this.draft,
    required this.insumos,
    required this.compact,
    required this.showDivider,
    required this.onChanged,
    this.onRemove,
  });

  final _ConsumoDetalleDraft draft;
  final List<InsumoLookup> insumos;
  final bool compact;
  final bool showDivider;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(color: theme.colorScheme.outlineVariant),
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (compact)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 4, child: _buildInsumoField()),
                const Gap(AppSpacing.md),
                Expanded(flex: 2, child: _buildCantidadField()),
                const Gap(AppSpacing.md),
                Expanded(flex: 3, child: _buildObservacionField()),
                if (onRemove != null) ...[
                  const Gap(AppSpacing.sm),
                  IconButton(
                    onPressed: onRemove,
                    tooltip: 'Quitar insumo',
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ],
            )
          else ...[
            if (onRemove != null)
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: onRemove,
                  tooltip: 'Quitar insumo',
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ),
            _buildInsumoField(),
            const Gap(AppSpacing.md),
            _buildCantidadField(),
            const Gap(AppSpacing.md),
            _buildObservacionField(),
          ],
        ],
      ),
    );
  }

  InsumoLookup? get _selectedInsumo {
    for (final item in insumos) {
      if (item.id == draft.insumoId) return item;
    }
    return null;
  }

  String _stockLabel(InsumoLookup item) {
    return item.stockActual.toStringAsFixed(2);
  }

  Widget _buildInsumoField() => DropdownButtonFormField<int?>(
    initialValue: draft.insumoId,
    isExpanded: true,
    decoration: InputDecoration(
      labelText: 'Insumo',
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      helperText: _selectedInsumo == null
          ? null
          : 'Stock disponible: ${_stockLabel(_selectedInsumo!)}',
      helperStyle: const TextStyle(fontSize: 11),
    ),
    items: insumos
        .map(
          (item) => DropdownMenuItem<int?>(
            value: item.id,
            child: Text(
              '${item.codigo} - ${item.nombre} · ${_stockLabel(item)}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        )
        .toList(growable: false),
    onChanged: (value) {
      draft.insumoId = value;
      onChanged();
    },
    validator: (value) => value == null ? 'Selecciona un insumo.' : null,
  );

  Widget _buildCantidadField() => TextFormField(
    controller: draft.cantidadController,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    style: const TextStyle(fontSize: 13),
    decoration: const InputDecoration(
      labelText: 'Cantidad',
      hintText: '0.00',
      isDense: true,
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
    ),
    validator: (value) {
      final parsed = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
      return parsed == null || parsed <= 0 ? 'Cantidad invalida.' : null;
    },
  );

  Widget _buildObservacionField() => TextFormField(
    controller: draft.observacionController,
    style: const TextStyle(fontSize: 13),
    decoration: const InputDecoration(
      labelText: 'Observacion',
      hintText: 'Opcional',
      isDense: true,
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
    ),
  );
}

class _ProcesoInfo extends StatelessWidget {
  const _ProcesoInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 190,
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
