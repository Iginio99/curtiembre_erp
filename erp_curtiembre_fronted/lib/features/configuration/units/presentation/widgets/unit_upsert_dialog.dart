import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/configuration/units/domain/entities/unit_record.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class UnitUpsertFormData {
  const UnitUpsertFormData({
    required this.codigo,
    required this.nombre,
    required this.permiteDecimales,
  });

  final String codigo;
  final String nombre;
  final bool permiteDecimales;
}

class UnitUpsertDialog extends StatefulWidget {
  const UnitUpsertDialog({
    required this.title,
    required this.submitLabel,
    required this.isSubmitting,
    this.initialUnit,
    super.key,
  });

  final String title;
  final String submitLabel;
  final bool isSubmitting;
  final UnitRecord? initialUnit;

  @override
  State<UnitUpsertDialog> createState() => _UnitUpsertDialogState();
}

class _UnitUpsertDialogState extends State<UnitUpsertDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codigoController;
  late final TextEditingController _nombreController;
  late bool _permiteDecimales;

  @override
  void initState() {
    super.initState();
    _codigoController = TextEditingController(text: widget.initialUnit?.codigo ?? '');
    _nombreController = TextEditingController(text: widget.initialUnit?.nombre ?? '');
    _permiteDecimales = widget.initialUnit?.permiteDecimales ?? false;
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      UnitUpsertFormData(
        codigo: _codigoController.text.trim(),
        nombre: _nombreController.text.trim(),
        permiteDecimales: _permiteDecimales,
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
                Text(widget.title, style: theme.textTheme.headlineSmall),
                const Gap(AppSpacing.sm),
                Text(
                  'Configura el codigo, nombre y comportamiento decimal de la unidad.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Gap(AppSpacing.xl),
                TextFormField(
                  controller: _codigoController,
                  decoration: const InputDecoration(
                    labelText: 'Codigo',
                    hintText: 'Ej. KG',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return 'Ingresa el codigo de la unidad.';
                    }
                    return null;
                  },
                ),
                const Gap(AppSpacing.lg),
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    hintText: 'Ej. Kilogramo',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return 'Ingresa el nombre de la unidad.';
                    }
                    return null;
                  },
                ),
                const Gap(AppSpacing.lg),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _permiteDecimales,
                  onChanged: widget.isSubmitting
                      ? null
                      : (value) => setState(() => _permiteDecimales = value),
                  title: const Text('Permite decimales'),
                  subtitle: Text(
                    _permiteDecimales
                        ? 'La unidad soporta cantidades fraccionadas.'
                        : 'La unidad solo trabaja con enteros.',
                  ),
                ),
                const Gap(AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: widget.isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
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
                          : const Icon(Icons.check_circle_outline),
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
