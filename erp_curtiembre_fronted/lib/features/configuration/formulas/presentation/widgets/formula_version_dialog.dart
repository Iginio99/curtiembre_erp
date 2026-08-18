import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/configuration/formulas/domain/entities/formula_record.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class FormulaVersionFormData {
  const FormulaVersionFormData({
    required this.numeroVersion,
    required this.fechaInicioVigencia,
    this.fechaFinVigencia,
    this.observacion,
    this.clonarDesdeVersionId,
  });

  final int numeroVersion;
  final DateTime fechaInicioVigencia;
  final DateTime? fechaFinVigencia;
  final String? observacion;
  final int? clonarDesdeVersionId;
}

class FormulaVersionDialog extends StatefulWidget {
  const FormulaVersionDialog({
    super.key,
    required this.title,
    required this.submitLabel,
    required this.isSubmitting,
    this.initialVersion,
    this.cloneOptions = const [],
  });

  final String title;
  final String submitLabel;
  final bool isSubmitting;
  final FormulaVersionRecord? initialVersion;
  final List<FormulaVersionRecord> cloneOptions;

  @override
  State<FormulaVersionDialog> createState() => _FormulaVersionDialogState();
}

class _FormulaVersionDialogState extends State<FormulaVersionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _numeroVersionController;
  late final TextEditingController _fechaInicioController;
  late final TextEditingController _fechaFinController;
  late final TextEditingController _observacionController;
  late DateTime _fechaInicioVigencia;
  DateTime? _fechaFinVigencia;
  int? _clonarDesdeVersionId;

  bool get _isEditing => widget.initialVersion != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialVersion;
    _fechaInicioVigencia = initial?.fechaInicioVigencia ?? DateTime.now();
    _fechaFinVigencia = initial?.fechaFinVigencia;
    _numeroVersionController = TextEditingController(
      text: initial?.numeroVersion.toString() ?? '',
    );
    _fechaInicioController = TextEditingController(text: _formatDate(_fechaInicioVigencia));
    _fechaFinController = TextEditingController(
      text: _fechaFinVigencia == null ? '' : _formatDate(_fechaFinVigencia!),
    );
    _observacionController = TextEditingController(text: initial?.observacion ?? '');
  }

  @override
  void dispose() {
    _numeroVersionController.dispose();
    _fechaInicioController.dispose();
    _fechaFinController.dispose();
    _observacionController.dispose();
    super.dispose();
  }

  Future<void> _pickFechaInicio() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaInicioVigencia,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _fechaInicioVigencia = picked;
      _fechaInicioController.text = _formatDate(picked);
      if (_fechaFinVigencia != null && _fechaFinVigencia!.isBefore(picked)) {
        _fechaFinVigencia = null;
        _fechaFinController.clear();
      }
    });
  }

  Future<void> _pickFechaFin() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaFinVigencia ?? _fechaInicioVigencia,
      firstDate: _fechaInicioVigencia,
      lastDate: DateTime(2100),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _fechaFinVigencia = picked;
      _fechaFinController.text = _formatDate(picked);
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      FormulaVersionFormData(
        numeroVersion: int.parse(_numeroVersionController.text.trim()),
        fechaInicioVigencia: _fechaInicioVigencia,
        fechaFinVigencia: _fechaFinVigencia,
        observacion: _observacionController.text.trim().isEmpty
            ? null
            : _observacionController.text.trim(),
        clonarDesdeVersionId: _clonarDesdeVersionId,
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
                  controller: _numeroVersionController,
                  enabled: !_isEditing && !widget.isSubmitting,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Numero de version',
                    hintText: 'Ej. 1',
                  ),
                  validator: (value) {
                    final parsed = int.tryParse(value?.trim() ?? '');
                    if (parsed == null || parsed <= 0) {
                      return 'Ingresa un numero valido.';
                    }
                    return null;
                  },
                ),
                const Gap(AppSpacing.lg),
                TextFormField(
                  controller: _fechaInicioController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Vigente desde',
                    suffixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  onTap: widget.isSubmitting ? null : _pickFechaInicio,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Selecciona la fecha inicial.';
                    }
                    return null;
                  },
                ),
                const Gap(AppSpacing.lg),
                TextFormField(
                  controller: _fechaFinController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Vigente hasta',
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_fechaFinVigencia != null)
                          IconButton(
                            onPressed: widget.isSubmitting
                                ? null
                                : () => setState(() {
                                      _fechaFinVigencia = null;
                                      _fechaFinController.clear();
                                    }),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        const Icon(Icons.calendar_today_outlined),
                      ],
                    ),
                  ),
                  onTap: widget.isSubmitting ? null : _pickFechaFin,
                ),
                if (!_isEditing && widget.cloneOptions.isNotEmpty) ...[
                  const Gap(AppSpacing.lg),
                  DropdownButtonFormField<int?>(
                    initialValue: _clonarDesdeVersionId,
                    decoration: const InputDecoration(
                      labelText: 'Clonar detalles desde',
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Crear desde cero'),
                      ),
                      ...widget.cloneOptions.map(
                        (option) => DropdownMenuItem<int?>(
                          value: option.id,
                          child: Text('Version ${option.numeroVersion}'),
                        ),
                      ),
                    ],
                    onChanged: widget.isSubmitting
                        ? null
                        : (value) => setState(() => _clonarDesdeVersionId = value),
                  ),
                ],
                const Gap(AppSpacing.lg),
                TextFormField(
                  controller: _observacionController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Observacion',
                    hintText: 'Notas operativas de esta version.',
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

  String _formatDate(DateTime value) => DateFormat('dd/MM/yyyy').format(value);
}
