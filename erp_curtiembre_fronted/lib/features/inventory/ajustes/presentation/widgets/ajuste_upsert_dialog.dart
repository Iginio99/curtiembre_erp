import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/inventory/ajustes/domain/repositories/ajustes_repository.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/domain/entities/insumo_lookup.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/buttons/app_button.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

enum AjusteDraftType {
  positivo,
  negativo,
}

class AjusteUpsertFormData {
  const AjusteUpsertFormData({
    required this.motivo,
    this.observacion,
    required this.detalles,
  });

  final String motivo;
  final String? observacion;
  final List<RegistrarAjusteDetalleInput> detalles;
}

class AjusteUpsertDialog extends StatefulWidget {
  const AjusteUpsertDialog({
    super.key,
    required this.title,
    required this.helperText,
    required this.insumos,
    required this.isSubmitting,
    required this.requiresCost,
  });

  final String title;
  final String helperText;
  final List<InsumoLookup> insumos;
  final bool isSubmitting;
  final bool requiresCost;

  @override
  State<AjusteUpsertDialog> createState() => _AjusteUpsertDialogState();
}

class _AjusteUpsertDialogState extends State<AjusteUpsertDialog> {
  final _formKey = GlobalKey<FormState>();
  final _motivoController = TextEditingController();
  final _observacionController = TextEditingController();
  final List<_AjusteDetalleDraft> _drafts = [_AjusteDetalleDraft()];

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
    setState(() => _drafts.add(_AjusteDetalleDraft()));
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

    final details = <RegistrarAjusteDetalleInput>[];
    for (final draft in _drafts) {
      final insumoId = draft.insumoId;
      final cantidad = double.tryParse(
        draft.cantidadController.text.trim().replaceAll(',', '.'),
      );
      final costoText = draft.costoController.text.trim();
      final costo = costoText.isEmpty
          ? null
          : double.tryParse(costoText.replaceAll(',', '.'));
      if (insumoId == null || cantidad == null || cantidad <= 0) {
        continue;
      }

      details.add(
        RegistrarAjusteDetalleInput(
          insumoId: insumoId,
          cantidad: cantidad,
          costoUnitario: costo,
        ),
      );
    }

    if (details.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega al menos un insumo valido.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).pop(
      AjusteUpsertFormData(
        motivo: _motivoController.text.trim(),
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
        constraints: const BoxConstraints(maxWidth: 880),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: theme.textTheme.headlineSmall),
                const Gap(AppSpacing.sm),
                Text(
                  widget.helperText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Gap(AppSpacing.xl),
                TextFormField(
                  controller: _motivoController,
                  decoration: const InputDecoration(
                    labelText: 'Motivo',
                    hintText: 'Ej. regularizacion o diferencia de conteo',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa un motivo.';
                    }
                    return null;
                  },
                ),
                const Gap(AppSpacing.lg),
                TextFormField(
                  controller: _observacionController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Observacion',
                    hintText: 'Agrega el contexto del ajuste',
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
                          _AjusteDetalleDraftCard(
                            key: ValueKey(_drafts[index]),
                            index: index,
                            draft: _drafts[index],
                            insumos: widget.insumos,
                            requiresCost: widget.requiresCost,
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
                      onPressed: widget.isSubmitting ? null : () => Navigator.of(context).pop(),
                    ),
                    const Gap(AppSpacing.md),
                    AppButton.primary(
                      label: 'Registrar ajuste',
                      icon: Icons.rule_folder_outlined,
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

class _AjusteDetalleDraftCard extends StatelessWidget {
  const _AjusteDetalleDraftCard({
    super.key,
    required this.index,
    required this.draft,
    required this.insumos,
    required this.requiresCost,
    this.onRemove,
  });

  final int index;
  final _AjusteDetalleDraft draft;
  final List<InsumoLookup> insumos;
  final bool requiresCost;
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
                    labelText: 'Cantidad',
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
              const Gap(AppSpacing.md),
              Expanded(
                child: TextFormField(
                  controller: draft.costoController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: requiresCost ? 'Costo unitario' : 'Costo unitario opcional',
                    hintText: '0.00',
                  ),
                  validator: (value) {
                    final text = (value ?? '').trim();
                    if (!requiresCost && text.isEmpty) {
                      return null;
                    }
                    final parsed = double.tryParse(text.replaceAll(',', '.'));
                    if (parsed == null || parsed < 0) {
                      return 'Costo invalido.';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AjusteDetalleDraft {
  _AjusteDetalleDraft();

  int? insumoId;
  final TextEditingController cantidadController = TextEditingController();
  final TextEditingController costoController = TextEditingController();

  void dispose() {
    cantidadController.dispose();
    costoController.dispose();
  }
}
