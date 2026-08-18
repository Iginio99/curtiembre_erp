import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/production/clientes/domain/entities/cliente_option.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/lote_option.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class OrdenUpsertFormData {
  const OrdenUpsertFormData({
    required this.loteId,
    required this.clienteId,
    required this.cantidadPieles,
    this.fechaInicioPlanificada,
    required this.fechaFinEstimada,
    this.observacion,
  });

  final int loteId;
  final int clienteId;
  final double cantidadPieles;
  final DateTime? fechaInicioPlanificada;
  final DateTime fechaFinEstimada;
  final String? observacion;
}

class OrdenUpsertDialog extends StatefulWidget {
  const OrdenUpsertDialog({
    required this.title,
    required this.submitLabel,
    required this.isSubmitting,
    required this.clienteOptions,
    required this.loteOptions,
    super.key,
  });

  final String title;
  final String submitLabel;
  final bool isSubmitting;
  final List<ClienteOption> clienteOptions;
  final List<LoteOption> loteOptions;

  @override
  State<OrdenUpsertDialog> createState() => _OrdenUpsertDialogState();
}

class _OrdenUpsertDialogState extends State<OrdenUpsertDialog> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedClienteId;
  int? _selectedLoteId;
  DateTime? _fechaInicioPlanificada;
  late DateTime _fechaFinEstimada;
  late final TextEditingController _cantidadController;
  late final TextEditingController _observacionController;

  @override
  void initState() {
    super.initState();
    _fechaFinEstimada = DateTime.now().add(const Duration(days: 7));
    _cantidadController = TextEditingController();
    _observacionController = TextEditingController();
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _observacionController.dispose();
    super.dispose();
  }

  List<LoteOption> get _filteredLotes {
    if (_selectedClienteId == null) {
      return widget.loteOptions;
    }

    return widget.loteOptions.where((lote) => lote.clienteId == _selectedClienteId).toList();
  }

  Future<void> _pickFechaInicioPlanificada() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _fechaInicioPlanificada ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected != null) {
      setState(() => _fechaInicioPlanificada = selected);
    }
  }

  Future<void> _pickFechaFinEstimada() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _fechaFinEstimada,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected != null) {
      setState(() => _fechaFinEstimada = selected);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedClienteId == null || _selectedLoteId == null) {
      return;
    }

    Navigator.of(context).pop(
      OrdenUpsertFormData(
        loteId: _selectedLoteId!,
        clienteId: _selectedClienteId!,
        cantidadPieles: double.parse(_cantidadController.text.trim()),
        fechaInicioPlanificada: _fechaInicioPlanificada,
        fechaFinEstimada: _fechaFinEstimada,
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
    final inicioLabel = _fechaInicioPlanificada == null
        ? 'Sin fecha'
        : DateFormat('dd/MM/yyyy').format(_fechaInicioPlanificada!);
    final finLabel = DateFormat('dd/MM/yyyy').format(_fechaFinEstimada);

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
                  decoration: const InputDecoration(labelText: 'Cliente'),
                  items: widget.clienteOptions
                      .map(
                        (option) => DropdownMenuItem<int>(
                          value: option.id,
                          child: Text(option.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: widget.isSubmitting
                      ? null
                      : (value) {
                          setState(() {
                            _selectedClienteId = value;
                            if (_selectedLoteId != null &&
                                !_filteredLotes.any((lote) => lote.id == _selectedLoteId)) {
                              _selectedLoteId = null;
                            }
                          });
                        },
                  validator: (value) => value == null ? 'Selecciona un cliente.' : null,
                ),
                const Gap(AppSpacing.md),
                DropdownButtonFormField<int>(
                  initialValue: _selectedLoteId,
                  decoration: const InputDecoration(labelText: 'Lote disponible'),
                  items: _filteredLotes
                      .map(
                        (option) => DropdownMenuItem<int>(
                          value: option.id,
                          child: Text(option.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: widget.isSubmitting
                      ? null
                      : (value) => setState(() => _selectedLoteId = value),
                  validator: (value) => value == null ? 'Selecciona un lote.' : null,
                ),
                const Gap(AppSpacing.md),
                TextFormField(
                  controller: _cantidadController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Cantidad de pieles',
                    hintText: 'Ej. 80',
                  ),
                  validator: (value) {
                    final number = double.tryParse((value ?? '').trim());
                    if (number == null || number <= 0) {
                      return 'Ingresa una cantidad valida mayor a cero.';
                    }
                    return null;
                  },
                ),
                const Gap(AppSpacing.md),
                InkWell(
                  onTap: widget.isSubmitting ? null : _pickFechaInicioPlanificada,
                  borderRadius: BorderRadius.circular(16),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha inicio planificada',
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(inicioLabel),
                  ),
                ),
                const Gap(AppSpacing.md),
                InkWell(
                  onTap: widget.isSubmitting ? null : _pickFechaFinEstimada,
                  borderRadius: BorderRadius.circular(16),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha fin estimada',
                      suffixIcon: Icon(Icons.event_available_outlined),
                    ),
                    child: Text(finLabel),
                  ),
                ),
                const Gap(AppSpacing.md),
                TextFormField(
                  controller: _observacionController,
                  maxLength: 500,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Observacion',
                    hintText: 'Detalle operativo inicial de la orden',
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
