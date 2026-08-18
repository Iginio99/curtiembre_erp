import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/configuration/formulas/domain/entities/formula_record.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/domain/entities/insumo_lookup.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class FormulaDetailFormData {
  const FormulaDetailFormData({
    required this.insumoId,
    required this.porcentaje,
    this.observacion,
    this.activo = true,
  });

  final int insumoId;
  final double porcentaje;
  final String? observacion;
  final bool activo;
}

class FormulaDetailDialog extends StatefulWidget {
  const FormulaDetailDialog({
    super.key,
    required this.title,
    required this.submitLabel,
    required this.insumoOptions,
    required this.isSubmitting,
    this.initialDetail,
  });

  final String title;
  final String submitLabel;
  final List<InsumoLookup> insumoOptions;
  final bool isSubmitting;
  final FormulaDetailRecord? initialDetail;

  @override
  State<FormulaDetailDialog> createState() => _FormulaDetailDialogState();
}

class _FormulaDetailDialogState extends State<FormulaDetailDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _porcentajeController;
  late final TextEditingController _observacionController;
  int? _insumoId;
  bool _activo = true;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDetail;
    _insumoId = initial?.insumoId ?? (widget.insumoOptions.isEmpty ? null : widget.insumoOptions.first.id);
    _activo = initial?.activo ?? true;
    _porcentajeController = TextEditingController(
      text: initial == null ? '' : initial.porcentaje.toStringAsFixed(4),
    );
    _observacionController = TextEditingController(text: initial?.observacion ?? '');
  }

  @override
  void dispose() {
    _porcentajeController.dispose();
    _observacionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final insumoId = _insumoId;
    if (insumoId == null) {
      return;
    }

    Navigator.of(context).pop(
      FormulaDetailFormData(
        insumoId: insumoId,
        porcentaje: double.parse(_porcentajeController.text.trim()),
        observacion: _observacionController.text.trim().isEmpty
            ? null
            : _observacionController.text.trim(),
        activo: _activo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _insumoId,
                  decoration: const InputDecoration(labelText: 'Insumo'),
                  items: widget.insumoOptions
                      .map(
                        (option) => DropdownMenuItem<int>(
                          value: option.id,
                          child: Text(option.displayName),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: widget.isSubmitting
                      ? null
                      : (value) => setState(() => _insumoId = value),
                  validator: (value) => value == null ? 'Selecciona un insumo.' : null,
                ),
                const Gap(AppSpacing.lg),
                TextFormField(
                  controller: _porcentajeController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Porcentaje',
                    hintText: 'Ej. 12.5000',
                  ),
                  validator: (value) {
                    final parsed = double.tryParse(value?.trim() ?? '');
                    if (parsed == null || parsed <= 0) {
                      return 'Ingresa un porcentaje valido.';
                    }
                    return null;
                  },
                ),
                const Gap(AppSpacing.lg),
                TextFormField(
                  controller: _observacionController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Observacion',
                    hintText: 'Notas opcionales para este insumo.',
                  ),
                ),
                if (widget.initialDetail != null) ...[
                  const Gap(AppSpacing.md),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Detalle activo'),
                    value: _activo,
                    onChanged: widget.isSubmitting
                        ? null
                        : (value) => setState(() => _activo = value ?? true),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: widget.isSubmitting ? null : _submit,
          icon: const Icon(Icons.save_outlined),
          label: Text(widget.submitLabel),
        ),
      ],
    );
  }
}
