import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/configuration/formulas/domain/entities/formula_record.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class FormulaUpsertFormData {
  const FormulaUpsertFormData({
    required this.codigo,
    required this.nombre,
    required this.procesoProductivoId,
    this.descripcion,
  });

  final String codigo;
  final String nombre;
  final int procesoProductivoId;
  final String? descripcion;
}

class FormulaUpsertDialog extends StatefulWidget {
  const FormulaUpsertDialog({
    super.key,
    required this.title,
    required this.submitLabel,
    required this.processOptions,
    required this.isSubmitting,
    this.initialFormula,
  });

  final String title;
  final String submitLabel;
  final List<ProcesoProductivoOption> processOptions;
  final bool isSubmitting;
  final FormulaRecord? initialFormula;

  @override
  State<FormulaUpsertDialog> createState() => _FormulaUpsertDialogState();
}

class _FormulaUpsertDialogState extends State<FormulaUpsertDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codigoController;
  late final TextEditingController _nombreController;
  late final TextEditingController _descripcionController;
  int? _procesoProductivoId;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialFormula;
    _codigoController = TextEditingController(text: initial?.codigo ?? '');
    _nombreController = TextEditingController(text: initial?.nombre ?? '');
    _descripcionController = TextEditingController(text: initial?.descripcion ?? '');
    _procesoProductivoId = initial?.procesoProductivoId ??
        (widget.processOptions.isEmpty ? null : widget.processOptions.first.id);
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final procesoProductivoId = _procesoProductivoId;
    if (procesoProductivoId == null) {
      return;
    }

    Navigator.of(context).pop(
      FormulaUpsertFormData(
        codigo: _codigoController.text.trim(),
        nombre: _nombreController.text.trim(),
        procesoProductivoId: procesoProductivoId,
        descripcion: _descripcionController.text.trim().isEmpty
            ? null
            : _descripcionController.text.trim(),
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
                TextFormField(
                  controller: _codigoController,
                  decoration: const InputDecoration(
                    labelText: 'Codigo',
                    hintText: 'Ej. FOR-REM-001',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa un codigo.';
                    }
                    return null;
                  },
                ),
                const Gap(AppSpacing.lg),
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    hintText: 'Ej. Formula base de remojo',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa un nombre.';
                    }
                    return null;
                  },
                ),
                const Gap(AppSpacing.lg),
                DropdownButtonFormField<int>(
                  initialValue: _procesoProductivoId,
                  decoration: const InputDecoration(
                    labelText: 'Proceso productivo',
                  ),
                  items: widget.processOptions
                      .map(
                        (option) => DropdownMenuItem<int>(
                          value: option.id,
                          child: Text(option.displayName),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: widget.isSubmitting
                      ? null
                      : (value) => setState(() => _procesoProductivoId = value),
                  validator: (value) => value == null ? 'Selecciona un proceso.' : null,
                ),
                const Gap(AppSpacing.lg),
                TextFormField(
                  controller: _descripcionController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Descripcion',
                    hintText: 'Describe cuando se usa esta formula.',
                  ),
                ),
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
