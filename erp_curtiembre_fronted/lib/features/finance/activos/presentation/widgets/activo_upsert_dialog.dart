import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/finance/activos/domain/entities/activo_depreciable_record.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class ActivoUpsertFormData {
  const ActivoUpsertFormData({
    required this.codigo,
    required this.nombre,
    required this.valorCompra,
    required this.fechaCompra,
    required this.vidaUtilMeses,
    required this.valorResidual,
    required this.activo,
  });

  final String codigo;
  final String nombre;
  final double valorCompra;
  final DateTime fechaCompra;
  final int vidaUtilMeses;
  final double valorResidual;
  final bool activo;
}

class ActivoUpsertDialog extends StatefulWidget {
  const ActivoUpsertDialog({
    required this.title,
    required this.submitLabel,
    required this.isSubmitting,
    this.initialActivo,
    super.key,
  });

  final String title;
  final String submitLabel;
  final bool isSubmitting;
  final ActivoDepreciableRecord? initialActivo;

  @override
  State<ActivoUpsertDialog> createState() => _ActivoUpsertDialogState();
}

class _ActivoUpsertDialogState extends State<ActivoUpsertDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codigoController;
  late final TextEditingController _nombreController;
  late final TextEditingController _valorCompraController;
  late final TextEditingController _vidaUtilController;
  late final TextEditingController _valorResidualController;
  late DateTime _fechaCompra;
  bool _activo = true;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialActivo;
    _codigoController = TextEditingController(text: initial?.codigo ?? '');
    _nombreController = TextEditingController(text: initial?.nombre ?? '');
    _valorCompraController = TextEditingController(
      text: initial == null ? '' : initial.valorCompra.toStringAsFixed(2),
    );
    _vidaUtilController = TextEditingController(
      text: initial?.vidaUtilMeses.toString() ?? '',
    );
    _valorResidualController = TextEditingController(
      text: initial == null ? '' : initial.valorResidual.toStringAsFixed(2),
    );
    _fechaCompra = initial?.fechaCompra ?? DateTime.now();
    _activo = initial?.activo ?? true;
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _valorCompraController.dispose();
    _vidaUtilController.dispose();
    _valorResidualController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _fechaCompra,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected != null) {
      setState(() => _fechaCompra = selected);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      ActivoUpsertFormData(
        codigo: _codigoController.text.trim(),
        nombre: _nombreController.text.trim(),
        valorCompra: double.parse(_valorCompraController.text.trim()),
        fechaCompra: _fechaCompra,
        vidaUtilMeses: int.parse(_vidaUtilController.text.trim()),
        valorResidual: double.parse(_valorResidualController.text.trim()),
        activo: _activo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.xl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
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
                  'Registra el activo con su valor, vida util y residual para que el backend pueda calcular depreciacion mensual.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Gap(AppSpacing.xl),
                TextFormField(
                  controller: _codigoController,
                  decoration: const InputDecoration(labelText: 'Codigo'),
                  validator: (value) =>
                      (value?.trim().isEmpty ?? true) ? 'Ingresa el codigo.' : null,
                ),
                const Gap(AppSpacing.lg),
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (value) =>
                      (value?.trim().isEmpty ?? true) ? 'Ingresa el nombre.' : null,
                ),
                const Gap(AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.lg,
                  runSpacing: AppSpacing.lg,
                  children: [
                    SizedBox(
                      width: 220,
                      child: TextFormField(
                        controller: _valorCompraController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Valor compra'),
                        validator: (value) {
                          final parsed = double.tryParse(value?.trim() ?? '');
                          if (parsed == null) return 'Ingresa un valor valido.';
                          if (parsed < 0) return 'No puede ser negativo.';
                          return null;
                        },
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: TextFormField(
                        controller: _vidaUtilController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Vida util (meses)'),
                        validator: (value) {
                          final parsed = int.tryParse(value?.trim() ?? '');
                          if (parsed == null) return 'Ingresa un numero valido.';
                          if (parsed <= 0) return 'Debe ser mayor a 0.';
                          return null;
                        },
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: TextFormField(
                        controller: _valorResidualController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Valor residual'),
                        validator: (value) {
                          final residual = double.tryParse(value?.trim() ?? '');
                          final purchase = double.tryParse(_valorCompraController.text.trim());
                          if (residual == null) return 'Ingresa un valor valido.';
                          if (residual < 0) return 'No puede ser negativo.';
                          if (purchase != null && residual > purchase) {
                            return 'No debe superar el valor de compra.';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const Gap(AppSpacing.lg),
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.event_outlined),
                  label: Text('Fecha compra: ${DateFormat('dd/MM/yyyy').format(_fechaCompra)}'),
                ),
                const Gap(AppSpacing.lg),
                SwitchListTile(
                  value: _activo,
                  onChanged: (value) => setState(() => _activo = value),
                  title: const Text('Activo vigente'),
                  contentPadding: EdgeInsets.zero,
                ),
                const Gap(AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          widget.isSubmitting ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    const Gap(AppSpacing.md),
                    FilledButton.icon(
                      onPressed: widget.isSubmitting ? null : _submit,
                      icon: widget.isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.memory_outlined),
                      label: Text(widget.submitLabel),
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
