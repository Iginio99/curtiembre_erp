import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/configuration/skin_types/domain/entities/skin_type_record.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class SkinTypeUpsertFormData {
  const SkinTypeUpsertFormData({
    required this.codigo,
    required this.nombre,
    this.descripcion,
  });

  final String codigo;
  final String nombre;
  final String? descripcion;
}

class SkinTypeUpsertDialog extends StatefulWidget {
  const SkinTypeUpsertDialog({
    required this.title,
    required this.submitLabel,
    required this.isSubmitting,
    this.initialSkinType,
    super.key,
  });

  final String title;
  final String submitLabel;
  final bool isSubmitting;
  final SkinTypeRecord? initialSkinType;

  @override
  State<SkinTypeUpsertDialog> createState() => _SkinTypeUpsertDialogState();
}

class _SkinTypeUpsertDialogState extends State<SkinTypeUpsertDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codigoController;
  late final TextEditingController _nombreController;
  late final TextEditingController _descripcionController;

  @override
  void initState() {
    super.initState();
    _codigoController =
        TextEditingController(text: widget.initialSkinType?.codigo ?? '');
    _nombreController =
        TextEditingController(text: widget.initialSkinType?.nombre ?? '');
    _descripcionController = TextEditingController(
      text: widget.initialSkinType?.descripcion ?? '',
    );
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      SkinTypeUpsertFormData(
        codigo: _codigoController.text.trim(),
        nombre: _nombreController.text.trim(),
        descripcion: _descripcionController.text.trim().isEmpty
            ? null
            : _descripcionController.text.trim(),
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
                  'Define el codigo, nombre y descripcion operativa del tipo de piel.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Gap(AppSpacing.xl),
                TextFormField(
                  controller: _codigoController,
                  decoration: const InputDecoration(
                    labelText: 'Codigo',
                    hintText: 'Ej. VACUNO',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return 'Ingresa el codigo del tipo de piel.';
                    }
                    return null;
                  },
                ),
                const Gap(AppSpacing.lg),
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    hintText: 'Ej. Vacuno',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return 'Ingresa el nombre del tipo de piel.';
                    }
                    return null;
                  },
                ),
                const Gap(AppSpacing.lg),
                TextFormField(
                  controller: _descripcionController,
                  minLines: 3,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Descripcion',
                    hintText: 'Opcional',
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
