import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class PeriodoUpsertFormData {
  const PeriodoUpsertFormData({
    required this.anio,
    required this.mes,
    this.observacion,
  });

  final int anio;
  final int mes;
  final String? observacion;
}

class PeriodoUpsertDialog extends StatefulWidget {
  const PeriodoUpsertDialog({
    required this.isSubmitting,
    super.key,
  });

  final bool isSubmitting;

  @override
  State<PeriodoUpsertDialog> createState() => _PeriodoUpsertDialogState();
}

class _PeriodoUpsertDialogState extends State<PeriodoUpsertDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _anioController;
  final _observacionController = TextEditingController();
  int _mes = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    _anioController = TextEditingController(text: DateTime.now().year.toString());
  }

  @override
  void dispose() {
    _anioController.dispose();
    _observacionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      PeriodoUpsertFormData(
        anio: int.parse(_anioController.text.trim()),
        mes: _mes,
        observacion: _observacionController.text.trim().isEmpty
            ? null
            : _observacionController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.xl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nuevo periodo', style: theme.textTheme.headlineSmall),
                const Gap(AppSpacing.sm),
                Text(
                  'Define el anio, mes y una observacion opcional para abrir el periodo de costo.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Gap(AppSpacing.xl),
                TextFormField(
                  controller: _anioController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Anio',
                    hintText: 'Ej. 2026',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    final parsed = int.tryParse(text);
                    if (parsed == null) {
                      return 'Ingresa un anio valido.';
                    }
                    if (parsed < 2000 || parsed > 2100) {
                      return 'El anio debe estar entre 2000 y 2100.';
                    }
                    return null;
                  },
                ),
                const Gap(AppSpacing.lg),
                DropdownButtonFormField<int>(
                  initialValue: _mes,
                  decoration: const InputDecoration(labelText: 'Mes'),
                  items: List.generate(
                    12,
                    (index) => DropdownMenuItem<int>(
                      value: index + 1,
                      child: Text(_monthLabel(index + 1)),
                    ),
                  ),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _mes = value);
                  },
                ),
                const Gap(AppSpacing.lg),
                TextFormField(
                  controller: _observacionController,
                  minLines: 3,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Observacion',
                    hintText: 'Opcional',
                  ),
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
                          : const Icon(Icons.calendar_month_outlined),
                      label: const Text('Crear periodo'),
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

String _monthLabel(int month) {
  const months = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  return months[month - 1];
}
