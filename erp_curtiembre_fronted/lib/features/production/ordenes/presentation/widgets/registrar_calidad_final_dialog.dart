import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/repositories/ordenes_produccion_repository.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/buttons/app_button.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class RegistrarCalidadFinalDialogResult {
  const RegistrarCalidadFinalDialogResult({required this.input});

  final RegistrarCalidadFinalInput input;
}

class RegistrarCalidadFinalDialog extends StatefulWidget {
  const RegistrarCalidadFinalDialog({
    super.key,
    required this.isSubmitting,
  });

  final bool isSubmitting;

  @override
  State<RegistrarCalidadFinalDialog> createState() => _RegistrarCalidadFinalDialogState();
}

class _RegistrarCalidadFinalDialogState extends State<RegistrarCalidadFinalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _observacionController = TextEditingController();

  int? _calidadProductoId;
  String _resultado = 'APROBADO';

  @override
  void dispose() {
    _observacionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate() || _calidadProductoId == null) {
      return;
    }

    Navigator.of(context).pop(
      RegistrarCalidadFinalDialogResult(
        input: RegistrarCalidadFinalInput(
          calidadProductoId: _calidadProductoId!,
          resultado: _resultado,
          observacion: _observacionController.text.trim().isEmpty
              ? null
              : _observacionController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const options = [
      _CalidadUiOption(id: 1, code: 'A', title: 'Calidad A', description: 'Producto de mejor calidad.'),
      _CalidadUiOption(id: 2, code: 'B', title: 'Calidad B', description: 'Producto de calidad intermedia.'),
      _CalidadUiOption(id: 3, code: 'C', title: 'Calidad C', description: 'Producto con observaciones.'),
    ];

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Registrar calidad final', style: theme.textTheme.headlineSmall),
                const Gap(AppSpacing.sm),
                Text(
                  'Evalua el resultado final de la orden antes de generar producto terminado y cerrar el flujo.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Gap(AppSpacing.xl),
                Text('Clasificacion de calidad', style: theme.textTheme.titleMedium),
                const Gap(AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: options
                      .map(
                        (option) => _CalidadOptionCard(
                          option: option,
                          isSelected: _calidadProductoId == option.id,
                          onTap: () => setState(() => _calidadProductoId = option.id),
                        ),
                      )
                      .toList(growable: false),
                ),
                if (_calidadProductoId == null) ...[
                  const Gap(AppSpacing.sm),
                  Text(
                    'Selecciona una calidad para continuar.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
                const Gap(AppSpacing.xl),
                DropdownButtonFormField<String>(
                  initialValue: _resultado,
                  decoration: const InputDecoration(labelText: 'Resultado'),
                  items: const [
                    DropdownMenuItem(value: 'APROBADO', child: Text('Aprobado')),
                    DropdownMenuItem(value: 'OBSERVADO', child: Text('Observado')),
                    DropdownMenuItem(value: 'RECHAZADO', child: Text('Rechazado')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _resultado = value);
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
                    hintText: 'Resume hallazgos, observaciones o criterio de aprobacion',
                  ),
                ),
                const Gap(AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppButton.secondary(
                      label: 'Cancelar',
                      onPressed: widget.isSubmitting ? null : () => Navigator.of(context).pop(),
                    ),
                    const Gap(AppSpacing.md),
                    AppButton.primary(
                      label: 'Registrar calidad',
                      icon: Icons.verified_outlined,
                      expand: false,
                      isLoading: widget.isSubmitting,
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

class _CalidadUiOption {
  const _CalidadUiOption({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
  });

  final int id;
  final String code;
  final String title;
  final String description;
}

class _CalidadOptionCard extends StatelessWidget {
  const _CalidadOptionCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final _CalidadUiOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          width: 210,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.72)
                : theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(option.code, style: theme.textTheme.headlineSmall),
              const Gap(AppSpacing.sm),
              Text(option.title, style: theme.textTheme.titleMedium),
              const Gap(AppSpacing.sm),
              Text(
                option.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
