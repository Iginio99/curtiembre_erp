import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/inventory/fisico/domain/entities/inventario_fisico_detail.dart';
import 'package:erp_curtiembre_fronted/features/inventory/fisico/domain/repositories/inventario_fisico_repository.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/domain/entities/insumo_lookup.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/buttons/app_button.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class InventarioFisicoCountsFormData {
  const InventarioFisicoCountsFormData({
    required this.detalles,
  });

  final List<RegistrarConteoInventarioFisicoDetalleInput> detalles;
}

class InventarioFisicoCountsDialog extends StatefulWidget {
  const InventarioFisicoCountsDialog({
    super.key,
    required this.insumos,
    required this.existingDetails,
    required this.isSubmitting,
  });

  final List<InsumoLookup> insumos;
  final List<InventarioFisicoConteoLine> existingDetails;
  final bool isSubmitting;

  @override
  State<InventarioFisicoCountsDialog> createState() =>
      _InventarioFisicoCountsDialogState();
}

class _InventarioFisicoCountsDialogState
    extends State<InventarioFisicoCountsDialog> {
  final _formKey = GlobalKey<FormState>();
  late final List<_ConteoDraft> _drafts;

  @override
  void initState() {
    super.initState();
    _drafts = widget.existingDetails.isEmpty
        ? [_ConteoDraft()]
        : widget.existingDetails
            .map(
              (item) => _ConteoDraft(
                insumoId: item.insumoId,
                stockContado: item.stockContado.toStringAsFixed(2),
                observacion: item.observacion ?? '',
              ),
            )
            .toList(growable: true);
  }

  @override
  void dispose() {
    for (final draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  void _addDraft() {
    setState(() => _drafts.add(_ConteoDraft()));
  }

  void _removeDraft(int index) {
    if (_drafts.length == 1) return;
    setState(() {
      final removed = _drafts.removeAt(index);
      removed.dispose();
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final usedIds = <int>{};
    final details = <RegistrarConteoInventarioFisicoDetalleInput>[];

    for (final draft in _drafts) {
      final insumoId = draft.insumoId;
      final stockContado = double.tryParse(
        draft.stockContadoController.text.trim().replaceAll(',', '.'),
      );

      if (insumoId == null || stockContado == null || stockContado < 0) {
        continue;
      }

      if (!usedIds.add(insumoId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No repitas el mismo insumo en el conteo.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      details.add(
        RegistrarConteoInventarioFisicoDetalleInput(
          insumoId: insumoId,
          stockContado: stockContado,
          observacion: draft.observacionController.text.trim().isEmpty
              ? null
              : draft.observacionController.text.trim(),
        ),
      );
    }

    if (details.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega al menos una linea de conteo valida.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).pop(InventarioFisicoCountsFormData(detalles: details));
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
                Text('Registrar conteos', style: theme.textTheme.headlineSmall),
                const Gap(AppSpacing.sm),
                Text(
                  'Carga el stock contado por insumo. Puedes actualizar lineas ya registradas o agregar nuevas.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Gap(AppSpacing.xl),
                Row(
                  children: [
                    Text('Detalle', style: theme.textTheme.titleLarge),
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
                          _ConteoDraftCard(
                            key: ValueKey(_drafts[index]),
                            index: index,
                            draft: _drafts[index],
                            insumos: widget.insumos,
                            onRemove: _drafts.length == 1 ? null : () => _removeDraft(index),
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
                      onPressed:
                          widget.isSubmitting ? null : () => Navigator.of(context).pop(),
                    ),
                    const Gap(AppSpacing.md),
                    AppButton.primary(
                      label: 'Guardar conteos',
                      icon: Icons.check_circle_outline,
                      isLoading: widget.isSubmitting,
                      expand: false,
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

class _ConteoDraftCard extends StatelessWidget {
  const _ConteoDraftCard({
    super.key,
    required this.index,
    required this.draft,
    required this.insumos,
    this.onRemove,
  });

  final int index;
  final _ConteoDraft draft;
  final List<InsumoLookup> insumos;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = draft.insumoId == null
        ? null
        : insumos.cast<InsumoLookup?>().firstWhere(
              (item) => item?.id == draft.insumoId,
              orElse: () => null,
            );

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
          if (selected != null) ...[
            const Gap(AppSpacing.sm),
            Text(
              'Stock actual referencial: ${selected.stockActual.toStringAsFixed(2)} ${selected.unidadMedidaCodigo}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const Gap(AppSpacing.md),
          TextFormField(
            controller: draft.stockContadoController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Stock contado',
              hintText: '0.00',
            ),
            validator: (value) {
              final parsed = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
              if (parsed == null || parsed < 0) {
                return 'Ingresa un stock contado valido.';
              }
              return null;
            },
          ),
          const Gap(AppSpacing.md),
          TextFormField(
            controller: draft.observacionController,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Observacion',
            ),
          ),
        ],
      ),
    );
  }
}

class _ConteoDraft {
  _ConteoDraft({
    this.insumoId,
    String stockContado = '',
    String observacion = '',
  })  : stockContadoController = TextEditingController(text: stockContado),
        observacionController = TextEditingController(text: observacion);

  int? insumoId;
  final TextEditingController stockContadoController;
  final TextEditingController observacionController;

  void dispose() {
    stockContadoController.dispose();
    observacionController.dispose();
  }
}
