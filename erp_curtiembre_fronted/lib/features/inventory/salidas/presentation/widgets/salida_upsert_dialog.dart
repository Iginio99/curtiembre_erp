import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/inventory/salidas/domain/repositories/salidas_repository.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/domain/entities/insumo_lookup.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/buttons/app_button.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

enum SalidaDraftType { general, devolucionProveedor, ajusteNegativo }

class SalidaUpsertFormData {
  const SalidaUpsertFormData({
    required this.motivo,
    this.observacion,
    required this.detalles,
  });

  final String motivo;
  final String? observacion;
  final List<RegistrarSalidaDetalleInput> detalles;
}

class SalidaUpsertDialog extends StatefulWidget {
  const SalidaUpsertDialog({
    super.key,
    required this.title,
    required this.helperText,
    required this.insumos,
    required this.isSubmitting,
  });

  final String title;
  final String helperText;
  final List<InsumoLookup> insumos;
  final bool isSubmitting;

  @override
  State<SalidaUpsertDialog> createState() => _SalidaUpsertDialogState();
}

class _SalidaUpsertDialogState extends State<SalidaUpsertDialog> {
  final _formKey = GlobalKey<FormState>();
  final _motivoController = TextEditingController();
  final _observacionController = TextEditingController();
  final List<_SalidaDetalleDraft> _drafts = [_SalidaDetalleDraft()];

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
    setState(() => _drafts.add(_SalidaDetalleDraft()));
  }

  void _removeDraft(int index) {
    if (_drafts.length == 1) return;
    setState(() {
      final removed = _drafts.removeAt(index);
      removed.dispose();
    });
  }

  Future<void> _editLineObservation(_SalidaDetalleDraft draft) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Observación del insumo'),
        content: SizedBox(
          width: 420,
          child: TextFormField(
            controller: draft.observacionController,
            autofocus: true,
            maxLength: 300,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Agrega una observación si es necesaria',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Listo'),
          ),
        ],
      ),
    );
    if (mounted) setState(() {});
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final details = <RegistrarSalidaDetalleInput>[];
    for (final draft in _drafts) {
      final insumoId = draft.insumoId;
      final cantidad = double.tryParse(
        draft.cantidadController.text.trim().replaceAll(',', '.'),
      );
      if (insumoId == null || cantidad == null || cantidad <= 0) {
        continue;
      }

      details.add(
        RegistrarSalidaDetalleInput(
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
          content: Text('Agrega al menos un insumo valido.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).pop(
      SalidaUpsertFormData(
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
        constraints: const BoxConstraints(maxWidth: 860),
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
                    hintText: 'Ej. Consumo interno o devolucion',
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
                  maxLines: 1,
                  decoration: const InputDecoration(
                    labelText: 'Observacion',
                    hintText: 'Agrega contexto adicional si aplica',
                  ),
                ),
                const Gap(AppSpacing.xl),
                Text('Detalle', style: theme.textTheme.titleMedium),
                const Gap(AppSpacing.sm),
                _SalidaDetalleTable(
                  drafts: _drafts,
                  insumos: widget.insumos,
                  onAdd: _addDraft,
                  onRemove: _removeDraft,
                  onEditObservation: _editLineObservation,
                ),
                const Gap(AppSpacing.sm),
                Divider(color: theme.colorScheme.outlineVariant),
                const Gap(AppSpacing.sm),
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
                      label: 'Registrar salida',
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

class _SalidaDetalleTable extends StatelessWidget {
  const _SalidaDetalleTable({
    required this.drafts,
    required this.insumos,
    required this.onAdd,
    required this.onRemove,
    required this.onEditObservation,
  });

  final List<_SalidaDetalleDraft> drafts;
  final List<InsumoLookup> insumos;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final Future<void> Function(_SalidaDetalleDraft) onEditObservation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = ListView.separated(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 2),
      itemCount: drafts.length,
      separatorBuilder: (_, _) =>
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
      itemBuilder: (context, index) => _SalidaDetalleRow(
        draft: drafts[index],
        insumos: insumos,
        canRemove: drafts.length > 1,
        onRemove: () => onRemove(index),
        onEditObservation: () => onEditObservation(drafts[index]),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final content = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(11),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: Text(
                        'Insumo *',
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Cantidad *',
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      child: Text('Obs.', style: theme.textTheme.labelSmall),
                    ),
                    SizedBox(
                      width: 48,
                      child: Text('Acción', style: theme.textTheme.labelSmall),
                    ),
                  ],
                ),
              ),
              if (drafts.length > 5)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 282),
                  child: rows,
                )
              else
                rows,
              const Divider(height: 1),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Agregar producto'),
                ),
              ),
            ],
          );
          if (constraints.maxWidth >= 620) return content;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(width: 620, child: content),
          );
        },
      ),
    );
  }
}

class _SalidaDetalleRow extends StatefulWidget {
  const _SalidaDetalleRow({
    required this.draft,
    required this.insumos,
    required this.canRemove,
    required this.onRemove,
    required this.onEditObservation,
  });
  final _SalidaDetalleDraft draft;
  final List<InsumoLookup> insumos;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onEditObservation;
  @override
  State<_SalidaDetalleRow> createState() => _SalidaDetalleRowState();
}

class _SalidaDetalleRowState extends State<_SalidaDetalleRow> {
  @override
  Widget build(BuildContext context) {
    const decoration = InputDecoration(
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: DropdownButtonFormField<int?>(
              isExpanded: true,
              initialValue: widget.draft.insumoId,
              decoration: decoration,
              items: widget.insumos
                  .map(
                    (item) => DropdownMenuItem<int?>(
                      value: item.id,
                      child: Text('${item.codigo} - ${item.nombre}'),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) =>
                  setState(() => widget.draft.insumoId = value),
              validator: (value) =>
                  value == null ? 'Selecciona un insumo.' : null,
            ),
          ),
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: widget.draft.cantidadController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: decoration.copyWith(hintText: '0.00'),
              validator: (value) {
                final parsed = double.tryParse(
                  (value ?? '').trim().replaceAll(',', '.'),
                );
                return parsed == null || parsed <= 0
                    ? 'Cantidad inválida.'
                    : null;
              },
            ),
          ),
          SizedBox(
            width: 48,
            child: IconButton(
              onPressed: widget.onEditObservation,
              tooltip: 'Observación',
              icon: Icon(
                widget.draft.observacionController.text.trim().isEmpty
                    ? Icons.note_add_outlined
                    : Icons.sticky_note_2_outlined,
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: IconButton(
              onPressed: widget.canRemove ? widget.onRemove : null,
              tooltip: 'Eliminar producto',
              icon: const Icon(Icons.delete_outline),
            ),
          ),
        ],
      ),
    );
  }
}

class _SalidaDetalleDraft {
  _SalidaDetalleDraft();

  int? insumoId;
  final TextEditingController cantidadController = TextEditingController();
  final TextEditingController observacionController = TextEditingController();

  void dispose() {
    cantidadController.dispose();
    observacionController.dispose();
  }
}
