import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/buttons/app_button.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class InventarioFisicoCreateFormData {
  const InventarioFisicoCreateFormData({
    required this.periodoAnio,
    required this.periodoMes,
    this.observacion,
  });

  final int periodoAnio;
  final int periodoMes;
  final String? observacion;
}

class InventarioFisicoCreateDialog extends StatefulWidget {
  const InventarioFisicoCreateDialog({
    super.key,
    required this.isSubmitting,
  });

  final bool isSubmitting;

  @override
  State<InventarioFisicoCreateDialog> createState() =>
      _InventarioFisicoCreateDialogState();
}

class _InventarioFisicoCreateDialogState
    extends State<InventarioFisicoCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _anioController;
  final _observacionController = TextEditingController();
  int _periodoMes = DateTime.now().month;

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
      InventarioFisicoCreateFormData(
        periodoAnio: int.parse(_anioController.text.trim()),
        periodoMes: _periodoMes,
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Crear toma fisica', style: theme.textTheme.headlineSmall),
                const Gap(AppSpacing.sm),
                Text(
                  'Abre una nueva toma para el periodo que quieres auditar antes de registrar conteos.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Gap(AppSpacing.xl),
                TextFormField(
                  controller: _anioController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Periodo anio',
                  ),
                  validator: (value) {
                    final parsed = int.tryParse((value ?? '').trim());
                    if (parsed == null || parsed < 2000 || parsed > 9999) {
                      return 'Ingresa un anio valido.';
                    }
                    return null;
                  },
                ),
                const Gap(AppSpacing.lg),
                DropdownButtonFormField<int>(
                  initialValue: _periodoMes,
                  decoration: const InputDecoration(
                    labelText: 'Periodo mes',
                  ),
                  items: List.generate(
                    12,
                    (index) => DropdownMenuItem<int>(
                      value: index + 1,
                      child: Text(monthLabel(index + 1)),
                    ),
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _periodoMes = value);
                    }
                  },
                ),
                const Gap(AppSpacing.lg),
                TextFormField(
                  controller: _observacionController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Observacion',
                  ),
                ),
                const Gap(AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppButton.secondary(
                      label: 'Cancelar',
                      onPressed:
                          widget.isSubmitting ? null : () => Navigator.of(context).pop(),
                    ),
                    const Gap(AppSpacing.md),
                    AppButton.primary(
                      label: 'Crear toma',
                      icon: Icons.add_chart_outlined,
                      isLoading: widget.isSubmitting,
                      expand: false,
                      onPressed: widget.isSubmitting ? null : _submit,
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

String monthLabel(int month) {
  const labels = <int, String>{
    1: 'Enero',
    2: 'Febrero',
    3: 'Marzo',
    4: 'Abril',
    5: 'Mayo',
    6: 'Junio',
    7: 'Julio',
    8: 'Agosto',
    9: 'Septiembre',
    10: 'Octubre',
    11: 'Noviembre',
    12: 'Diciembre',
  };
  return labels[month] ?? 'Mes $month';
}
