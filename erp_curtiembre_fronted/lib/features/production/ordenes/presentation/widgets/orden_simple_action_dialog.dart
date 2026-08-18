import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class OrdenSimpleActionFormData {
  const OrdenSimpleActionFormData({
    this.observacion,
    this.motivo,
    this.pesoBaseKg,
    this.fechaFinEstimada,
  });

  final String? observacion;
  final String? motivo;
  final double? pesoBaseKg;
  final DateTime? fechaFinEstimada;
}

class OrdenSimpleActionDialog extends StatefulWidget {
  const OrdenSimpleActionDialog({
    required this.title,
    required this.submitLabel,
    required this.labelText,
    required this.hintText,
    this.requireValue = false,
    this.requireStagePlanning = false,
    this.initialValue,
    super.key,
  });

  final String title;
  final String submitLabel;
  final String labelText;
  final String hintText;
  final bool requireValue;
  final bool requireStagePlanning;
  final String? initialValue;

  @override
  State<OrdenSimpleActionDialog> createState() =>
      _OrdenSimpleActionDialogState();
}

class _OrdenSimpleActionDialogState extends State<OrdenSimpleActionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _valueController;
  late final TextEditingController _pesoController;
  late DateTime _fechaFinEstimada;

  @override
  void initState() {
    super.initState();
    _valueController = TextEditingController(text: widget.initialValue ?? '');
    _pesoController = TextEditingController();
    _fechaFinEstimada = DateTime.now();
  }

  @override
  void dispose() {
    _valueController.dispose();
    _pesoController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final value = _valueController.text.trim();
    Navigator.of(context).pop(
      OrdenSimpleActionFormData(
        observacion: value.isEmpty ? null : value,
        motivo: value.isEmpty ? null : value,
        pesoBaseKg: widget.requireStagePlanning
            ? double.parse(_pesoController.text.trim())
            : null,
        fechaFinEstimada: widget.requireStagePlanning
            ? _fechaFinEstimada
            : null,
      ),
    );
  }

  Future<void> _pickFechaFinEstimada() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _fechaFinEstimada,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (selected != null) {
      setState(() => _fechaFinEstimada = selected);
    }
  }

  String get _fechaFinLabel {
    final day = _fechaFinEstimada.day.toString().padLeft(2, '0');
    final month = _fechaFinEstimada.month.toString().padLeft(2, '0');
    return '$day/$month/${_fechaFinEstimada.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _valueController,
                maxLength: 800,
                minLines: 3,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: widget.labelText,
                  hintText: widget.hintText,
                ),
                validator: (value) {
                  if (widget.requireValue && (value?.trim() ?? '').isEmpty) {
                    return 'Este campo es obligatorio.';
                  }
                  return null;
                },
              ),
              if (widget.requireStagePlanning) ...[
                const Gap(AppSpacing.md),
                TextFormField(
                  controller: _pesoController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Peso base de la etapa (kg)',
                    hintText: 'Ej. 1250.50',
                  ),
                  validator: (value) {
                    final peso = double.tryParse(value?.trim() ?? '');
                    if (peso == null || peso <= 0) {
                      return 'Ingresa un peso mayor que 0 kg.';
                    }
                    return null;
                  },
                ),
                const Gap(AppSpacing.md),
                InkWell(
                  onTap: _pickFechaFinEstimada,
                  borderRadius: BorderRadius.circular(16),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha estimada de termino',
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(_fechaFinLabel),
                  ),
                ),
              ],
              const Gap(AppSpacing.sm),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.check_circle_outline),
          label: Text(widget.submitLabel),
        ),
      ],
    );
  }
}
