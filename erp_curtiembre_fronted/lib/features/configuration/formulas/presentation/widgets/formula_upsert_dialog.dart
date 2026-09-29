import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/configuration/formulas/domain/entities/formula_record.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/domain/entities/insumo_lookup.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class FormulaUpsertFormData {
  const FormulaUpsertFormData({
    required this.codigo,
    required this.nombre,
    required this.procesoProductivoId,
    required this.tipoProducto,
    required this.color,
    this.descripcion,
    this.detalles = const [],
  });

  final String codigo;
  final String nombre;
  final int procesoProductivoId;
  final String tipoProducto;
  final String color;
  final String? descripcion;
  final List<FormulaRecipeLine> detalles;
}

class FormulaRecipeLine {
  const FormulaRecipeLine({
    required this.insumoId,
    required this.porcentaje,
    this.observacion,
  });
  final int insumoId;
  final double porcentaje;
  final String? observacion;
}

class FormulaUpsertDialog extends StatefulWidget {
  const FormulaUpsertDialog({
    super.key,
    required this.title,
    required this.submitLabel,
    required this.processOptions,
    required this.isSubmitting,
    required this.insumoOptions,
    this.initialFormula,
  });

  final String title;
  final String submitLabel;
  final List<ProcesoProductivoOption> processOptions;
  final bool isSubmitting;
  final List<InsumoLookup> insumoOptions;
  final FormulaRecord? initialFormula;

  @override
  State<FormulaUpsertDialog> createState() => _FormulaUpsertDialogState();
}

class _FormulaUpsertDialogState extends State<FormulaUpsertDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codigoController;
  late final TextEditingController _nombreController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _tipoProductoController;
  late final TextEditingController _colorController;
  int? _procesoProductivoId;
  final List<_RecipeDraft> _details = [_RecipeDraft()];

  String? get _selectedProcessCode => widget.processOptions
      .where((option) => option.id == _procesoProductivoId)
      .map((option) => option.codigo)
      .firstOrNull;

  bool get _colorIsOptional =>
      _selectedProcessCode == 'REMOJO_PELAMBRE' ||
      _selectedProcessCode == 'CURTIDO';

  @override
  void initState() {
    super.initState();
    final initial = widget.initialFormula;
    _codigoController = TextEditingController(text: initial?.codigo ?? '');
    _nombreController = TextEditingController(text: initial?.nombre ?? '');
    _descripcionController = TextEditingController(
      text: initial?.descripcion ?? '',
    );
    _tipoProductoController = TextEditingController(
      text: initial?.tipoProducto ?? '',
    );
    _colorController = TextEditingController(text: initial?.color ?? '');
    _procesoProductivoId =
        initial?.procesoProductivoId ??
        (widget.processOptions.isEmpty ? null : widget.processOptions.first.id);
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _descripcionController.dispose();
    _tipoProductoController.dispose();
    _colorController.dispose();
    for (final detail in _details) {
      detail.dispose();
    }
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

    final detalles = <FormulaRecipeLine>[];
    if (widget.initialFormula == null) {
      for (final detail in _details) {
        final percentage = double.tryParse(
          detail.percentage.text.trim().replaceAll(',', '.'),
        );
        if (detail.insumoId != null && percentage != null && percentage > 0) {
          detalles.add(
            FormulaRecipeLine(
              insumoId: detail.insumoId!,
              porcentaje: percentage,
              observacion: detail.note.text.trim().isEmpty
                  ? null
                  : detail.note.text.trim(),
            ),
          );
        }
      }
      if (detalles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La receta debe tener al menos un insumo.'),
          ),
        );
        return;
      }
    }
    Navigator.of(context).pop(
      FormulaUpsertFormData(
        codigo: _codigoController.text.trim(),
        nombre: _nombreController.text.trim(),
        procesoProductivoId: procesoProductivoId,
        tipoProducto: _tipoProductoController.text.trim(),
        color: _colorController.text.trim(),
        descripcion: _descripcionController.text.trim().isEmpty
            ? null
            : _descripcionController.text.trim(),
        detalles: detalles,
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
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _tipoProductoController,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de producto',
                          hintText: 'Ej. Graso, napa, gamuza',
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Ingresa el tipo de producto.'
                            : null,
                      ),
                    ),
                    const Gap(AppSpacing.md),
                    Expanded(
                      child: TextFormField(
                        controller: _colorController,
                        decoration: InputDecoration(
                          labelText: _colorIsOptional
                              ? 'Color (opcional)'
                              : 'Color',
                          hintText: _colorIsOptional
                              ? 'No aplica para este proceso'
                              : 'Ej. Negro',
                        ),
                        validator: (value) {
                          if (!_colorIsOptional &&
                              (value == null || value.trim().isEmpty)) {
                            return 'Ingresa el color.';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
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
                  isExpanded: true,
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
                      : (value) => setState(() {
                          _procesoProductivoId = value;
                          if (_colorIsOptional) {
                            _colorController.clear();
                          }
                        }),
                  validator: (value) =>
                      value == null ? 'Selecciona un proceso.' : null,
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
                if (widget.initialFormula == null) ...[
                  const Gap(AppSpacing.xl),
                  Row(
                    children: [
                      Text(
                        'Insumos de la receta',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () =>
                            setState(() => _details.add(_RecipeDraft())),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Agregar insumo'),
                      ),
                    ],
                  ),
                  const Gap(AppSpacing.sm),
                  ...List.generate(_details.length, (index) {
                    final detail = _details[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 4,
                            child: DropdownButtonFormField<int>(
                              isExpanded: true,
                              initialValue: detail.insumoId,
                              decoration: const InputDecoration(
                                labelText: 'Insumo',
                              ),
                              items: widget.insumoOptions
                                  .map(
                                    (x) => DropdownMenuItem(
                                      value: x.id,
                                      child: Text(
                                        x.displayName,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => detail.insumoId = v),
                              validator: (v) =>
                                  v == null ? 'Selecciona un insumo.' : null,
                            ),
                          ),
                          const Gap(AppSpacing.sm),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: detail.percentage,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Porcentaje %',
                              ),
                              validator: (v) =>
                                  (double.tryParse(
                                            (v ?? '').replaceAll(',', '.'),
                                          ) ??
                                          0) <=
                                      0
                                  ? 'Porcentaje invalido.'
                                  : null,
                            ),
                          ),
                          const Gap(AppSpacing.sm),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: detail.note,
                              decoration: const InputDecoration(
                                labelText: 'Observacion',
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _details.length == 1
                                ? null
                                : () {
                                    setState(() {
                                      final removed = _details.removeAt(index);
                                      removed.dispose();
                                    });
                                  },
                            icon: const Icon(Icons.delete_outline_rounded),
                            tooltip: 'Quitar insumo',
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.isSubmitting
              ? null
              : () => Navigator.of(context).pop(),
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

class _RecipeDraft {
  int? insumoId;
  final percentage = TextEditingController();
  final note = TextEditingController();
  void dispose() {
    percentage.dispose();
    note.dispose();
  }
}
