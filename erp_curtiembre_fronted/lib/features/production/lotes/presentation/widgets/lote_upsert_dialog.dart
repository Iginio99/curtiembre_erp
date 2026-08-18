import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/production/clientes/domain/entities/cliente_option.dart';
import 'package:erp_curtiembre_fronted/features/production/lotes/domain/entities/lote_record.dart';
import 'package:erp_curtiembre_fronted/features/production/lotes/domain/entities/tipo_piel_option.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class LoteUpsertFormData {
  const LoteUpsertFormData({
    required this.clienteId,
    required this.tipoPielId,
    required this.fechaIngreso,
    required this.cantidadPielesInicial,
    required this.clienteTraeLote,
    required this.costoPielesTotal,
    this.observacion,
  });

  final int clienteId;
  final int tipoPielId;
  final DateTime fechaIngreso;
  final double cantidadPielesInicial;
  final bool clienteTraeLote;
  final double costoPielesTotal;
  final String? observacion;
}

class LoteUpsertDialog extends StatefulWidget {
  const LoteUpsertDialog({
    required this.title,
    required this.submitLabel,
    required this.isSubmitting,
    required this.clienteOptions,
    required this.tipoPielOptions,
    this.initialLote,
    super.key,
  });

  final String title;
  final String submitLabel;
  final bool isSubmitting;
  final List<ClienteOption> clienteOptions;
  final List<TipoPielOption> tipoPielOptions;
  final LoteRecord? initialLote;

  @override
  State<LoteUpsertDialog> createState() => _LoteUpsertDialogState();
}

class _LoteUpsertDialogState extends State<LoteUpsertDialog> {
  final _formKey = GlobalKey<FormState>();
  late int? _selectedClienteId;
  late int? _selectedTipoPielId;
  late DateTime _fechaIngreso;
  late bool _clienteTraeLote;
  late final TextEditingController _cantidadController;
  late final TextEditingController _costoController;
  late final TextEditingController _observacionController;

  @override
  void initState() {
    super.initState();
    final initialLote = widget.initialLote;
    _selectedClienteId = initialLote?.clienteId;
    _selectedTipoPielId = initialLote?.tipoPielId;
    _fechaIngreso = initialLote?.fechaIngreso ?? DateTime.now();
    _clienteTraeLote = initialLote?.clienteTraeLote ?? false;
    _cantidadController = TextEditingController(
      text: _formatNumber(initialLote?.cantidadPielesInicial),
    );
    _costoController = TextEditingController(
      text: _formatNumber(initialLote?.costoPielesTotal),
    );
    _observacionController = TextEditingController(text: initialLote?.observacion ?? '');
    _syncCostoTraeLote();
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _costoController.dispose();
    _observacionController.dispose();
    super.dispose();
  }

  String _formatNumber(double? value) {
    if (value == null) {
      return '';
    }

    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(2);
  }

  Future<void> _pickFechaIngreso() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _fechaIngreso,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selected != null) {
      setState(() => _fechaIngreso = selected);
    }
  }

  void _syncCostoTraeLote() {
    if (_clienteTraeLote) {
      _costoController.text = '0';
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedClienteId == null || _selectedTipoPielId == null) {
      return;
    }

    Navigator.of(context).pop(
      LoteUpsertFormData(
        clienteId: _selectedClienteId!,
        tipoPielId: _selectedTipoPielId!,
        fechaIngreso: _fechaIngreso,
        cantidadPielesInicial: double.parse(_cantidadController.text.trim()),
        clienteTraeLote: _clienteTraeLote,
        costoPielesTotal: double.parse(_costoController.text.trim()),
        observacion: _normalizeOptional(_observacionController.text),
      ),
    );
  }

  String? _normalizeOptional(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('dd/MM/yyyy').format(_fechaIngreso);

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _selectedClienteId,
                  items: widget.clienteOptions
                      .map(
                        (option) => DropdownMenuItem<int>(
                          value: option.id,
                          child: Text(option.label),
                        ),
                      )
                      .toList(growable: false),
                  decoration: const InputDecoration(labelText: 'Cliente'),
                  onChanged: widget.isSubmitting
                      ? null
                      : (value) => setState(() => _selectedClienteId = value),
                  validator: (value) =>
                      value == null ? 'Selecciona un cliente activo.' : null,
                ),
                const Gap(AppSpacing.md),
                DropdownButtonFormField<int>(
                  initialValue: _selectedTipoPielId,
                  items: widget.tipoPielOptions
                      .map(
                        (option) => DropdownMenuItem<int>(
                          value: option.id,
                          child: Text(option.label),
                        ),
                      )
                      .toList(growable: false),
                  decoration: const InputDecoration(labelText: 'Tipo de piel'),
                  onChanged: widget.isSubmitting
                      ? null
                      : (value) => setState(() => _selectedTipoPielId = value),
                  validator: (value) =>
                      value == null ? 'Selecciona un tipo de piel activo.' : null,
                ),
                const Gap(AppSpacing.md),
                InkWell(
                  onTap: widget.isSubmitting ? null : _pickFechaIngreso,
                  borderRadius: BorderRadius.circular(16),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha de ingreso',
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(dateLabel),
                  ),
                ),
                const Gap(AppSpacing.md),
                TextFormField(
                  controller: _cantidadController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Cantidad de pieles inicial',
                    hintText: 'Ej. 120',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    final number = double.tryParse(text);
                    if (number == null || number <= 0) {
                      return 'Ingresa una cantidad valida mayor a cero.';
                    }
                    return null;
                  },
                ),
                const Gap(AppSpacing.md),
                SwitchListTile.adaptive(
                  value: _clienteTraeLote,
                  onChanged: widget.isSubmitting
                      ? null
                      : (value) {
                          setState(() {
                            _clienteTraeLote = value;
                            _syncCostoTraeLote();
                          });
                        },
                  title: const Text('El cliente trae su propio lote'),
                  subtitle: const Text(
                    'Si esta activo, el costo de pieles debe quedar en cero.',
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                const Gap(AppSpacing.sm),
                TextFormField(
                  controller: _costoController,
                  enabled: !_clienteTraeLote,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Costo total de pieles',
                    hintText: 'Ej. 3500.00',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    final number = double.tryParse(text);
                    if (number == null || number < 0) {
                      return 'Ingresa un costo valido.';
                    }
                    if (_clienteTraeLote && number != 0) {
                      return 'Cuando el cliente trae lote, el costo debe ser 0.';
                    }
                    return null;
                  },
                ),
                const Gap(AppSpacing.md),
                TextFormField(
                  controller: _observacionController,
                  maxLength: 500,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Observacion',
                    hintText: 'Detalle adicional del lote',
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
          icon: widget.isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: Text(widget.submitLabel),
        ),
      ],
    );
  }
}
