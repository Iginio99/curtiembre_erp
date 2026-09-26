import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/personal_empresa_option.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class OrdenSimpleActionFormData {
  const OrdenSimpleActionFormData({
    this.observacion,
    this.motivo,
    this.pesoBaseKg,
    this.fechaFinEstimada,
    this.responsableNombre,
    this.responsableCargo,
  });

  final String? observacion;
  final String? motivo;
  final double? pesoBaseKg;
  final DateTime? fechaFinEstimada;
  final String? responsableNombre;
  final String? responsableCargo;
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
    this.responsableOptions = const [],
    this.onAddPersonal,
    super.key,
  });

  final String title;
  final String submitLabel;
  final String labelText;
  final String hintText;
  final bool requireValue;
  final bool requireStagePlanning;
  final String? initialValue;
  final List<PersonalEmpresaOption> responsableOptions;
  final Future<PersonalEmpresaOption?> Function()? onAddPersonal;

  @override
  State<OrdenSimpleActionDialog> createState() =>
      _OrdenSimpleActionDialogState();
}

class _OrdenSimpleActionDialogState extends State<OrdenSimpleActionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _valueController;
  late final TextEditingController _pesoController;
  late DateTime _fechaFinEstimada;
  final _responsableNombreController = TextEditingController();
  final _responsableCargoController = TextEditingController();
  late List<PersonalEmpresaOption> _personalOptions;
  int? _selectedPersonalId;

  @override
  void initState() {
    super.initState();
    _valueController = TextEditingController(text: widget.initialValue ?? '');
    _pesoController = TextEditingController();
    _fechaFinEstimada = DateTime.now();
    _personalOptions = List.of(widget.responsableOptions);
  }

  @override
  void dispose() {
    _valueController.dispose();
    _pesoController.dispose();
    _responsableNombreController.dispose();
    _responsableCargoController.dispose();
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
        responsableNombre: _responsableNombreController.text.trim(),
        responsableCargo: _responsableCargoController.text.trim(),
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
                          onChanged: (id) {
                            final item = _personalOptions.firstWhere(
                              (x) => x.id == id,
                            );
                            setState(() => _selectedPersonalId = item.id);
                            _responsableNombreController.text = item.nombre;
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
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo del responsable',
                    ),
                    validator: (value) => (value?.trim().isEmpty ?? true)
                        ? 'Ingresa el nombre del responsable.'
                        : null,
                  ),
                ),
                Offstage(
                  child: TextFormField(
                    controller: _responsableCargoController,
                    decoration: const InputDecoration(labelText: 'Cargo'),
                    validator: (value) => (value?.trim().isEmpty ?? true)
                        ? 'Ingresa el cargo.'
                        : null,
                  ),
                ),
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
