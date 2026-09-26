import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/production/clientes/domain/entities/cliente_option.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/lote_option.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/personal_empresa_option.dart';
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
    required this.responsableNombre,
    required this.responsableCargo,
  });

  final int loteId;
  final int clienteId;
  final double cantidadPieles;
  final DateTime? fechaInicioPlanificada;
  final DateTime fechaFinEstimada;
  final String? observacion;
  final String responsableNombre;
  final String responsableCargo;
}

class OrdenUpsertDialog extends StatefulWidget {
  const OrdenUpsertDialog({
    required this.title,
    required this.submitLabel,
    required this.isSubmitting,
    required this.clienteOptions,
    required this.loteOptions,
    this.responsableOptions = const [],
    this.onAddPersonal,
    super.key,
  });

  final String title;
  final String submitLabel;
  final bool isSubmitting;
  final List<ClienteOption> clienteOptions;
  final List<LoteOption> loteOptions;
  final List<PersonalEmpresaOption> responsableOptions;
  final Future<PersonalEmpresaOption?> Function()? onAddPersonal;

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
  late final TextEditingController _responsableNombreController;
  late final TextEditingController _responsableCargoController;
  late List<PersonalEmpresaOption> _personalOptions;
  int? _selectedPersonalId;

  @override
  void initState() {
    super.initState();
    _fechaFinEstimada = DateTime.now().add(const Duration(days: 7));
    _cantidadController = TextEditingController();
    _observacionController = TextEditingController();
    _responsableNombreController = TextEditingController();
    _responsableCargoController = TextEditingController();
    _personalOptions = List.of(widget.responsableOptions);
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _observacionController.dispose();
    _responsableNombreController.dispose();
    _responsableCargoController.dispose();
    super.dispose();
  }

  List<LoteOption> get _filteredLotes {
    if (_selectedClienteId == null) {
      return widget.loteOptions;
    }

    return widget.loteOptions
        .where((lote) => lote.clienteId == _selectedClienteId)
        .toList();
  }

  LoteOption? get _selectedLote {
    final loteId = _selectedLoteId;
    if (loteId == null) {
      return null;
    }

    for (final lote in widget.loteOptions) {
      if (lote.id == loteId) {
        return lote;
      }
    }
    return null;
  }

  String _formatCantidad(double value) =>
      value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2);

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
        responsableNombre: _responsableNombreController.text.trim(),
        responsableCargo: _responsableCargoController.text.trim(),
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
                                !_filteredLotes.any(
                                  (lote) => lote.id == _selectedLoteId,
                                )) {
                              _selectedLoteId = null;
                            }
                          });
                        },
                  validator: (value) =>
                      value == null ? 'Selecciona un cliente.' : null,
                ),
                const Gap(AppSpacing.md),
                DropdownButtonFormField<int>(
                  initialValue: _selectedLoteId,
                  decoration: const InputDecoration(
                    labelText: 'Lote disponible',
                  ),
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
                  validator: (value) =>
                      value == null ? 'Selecciona un lote.' : null,
                ),
                if (_selectedLote case final lote?) ...[
                  const Gap(AppSpacing.sm),
                  Text(
                    'Cantidad disponible: ${_formatCantidad(lote.cantidadPielesDisponible)} pieles',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
                const Gap(AppSpacing.md),
                if (_personalOptions.isNotEmpty ||
                    widget.onAddPersonal != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _selectedPersonalId,
                          decoration: const InputDecoration(
                            labelText: 'Responsable',
                          ),
                          items: _personalOptions
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item.id,
                                  child: Text(item.label),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: widget.isSubmitting
                              ? null
                              : (id) {
                                  final item = _personalOptions.firstWhere(
                                    (x) => x.id == id,
                                  );
                                  setState(() => _selectedPersonalId = item.id);
                                  _responsableNombreController.text =
                                      item.nombre;
                                  _responsableCargoController.text = item.cargo;
                                },
                        ),
                      ),
                      if (widget.onAddPersonal != null) ...[
                        const Gap(AppSpacing.sm),
                        IconButton.filledTonal(
                          tooltip: 'Agregar personal',
                          onPressed: () async {
                            final item = await widget.onAddPersonal!();
                            if (item == null || !mounted) return;
                            setState(() {
                              _personalOptions = [
                                ..._personalOptions.where(
                                  (option) => option.id != item.id,
                                ),
                                item,
                              ]..sort((a, b) => a.nombre.compareTo(b.nombre));
                              _selectedPersonalId = item.id;
                            });
                            _responsableNombreController.text = item.nombre;
                            _responsableCargoController.text = item.cargo;
                          },
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ],
                  ),
                  const Gap(AppSpacing.md),
                ],
                Offstage(
                  child: TextFormField(
                    controller: _responsableNombreController,
                    enabled: !widget.isSubmitting,
                    maxLength: 150,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del responsable',
                      hintText: 'Ej. Juan Pérez',
                    ),
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? 'Ingresa el nombre del responsable.'
                        : null,
                  ),
                ),
                Offstage(
                  child: TextFormField(
                    controller: _responsableCargoController,
                    enabled: !widget.isSubmitting,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      labelText: 'Cargo',
                      hintText: 'Ej. Supervisor de producción',
                    ),
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? 'Ingresa el cargo del responsable.'
                        : null,
                  ),
                ),
                const Gap(AppSpacing.md),
                TextFormField(
                  controller: _cantidadController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: _selectedLote == null
                        ? 'Cantidad de pieles'
                        : 'Cantidad de pieles (max. ${_formatCantidad(_selectedLote!.cantidadPielesDisponible)})',
                    hintText: 'Ej. 80',
                  ),
                  validator: (value) {
                    final number = double.tryParse((value ?? '').trim());
                    if (number == null || number <= 0) {
                      return 'Ingresa una cantidad valida mayor a cero.';
                    }
                    final disponible = _selectedLote?.cantidadPielesDisponible;
                    if (disponible != null && number > disponible) {
                      return 'La cantidad maxima disponible es ${_formatCantidad(disponible)}.';
                    }
                    return null;
                  },
                ),
                const Gap(AppSpacing.md),
                InkWell(
                  onTap: widget.isSubmitting
                      ? null
                      : _pickFechaInicioPlanificada,
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
          onPressed: widget.isSubmitting
              ? null
              : () => Navigator.of(context).pop(),
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
