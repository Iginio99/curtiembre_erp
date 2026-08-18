import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/buttons/app_button.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class InventarioFisicoCloseDialog extends StatefulWidget {
  const InventarioFisicoCloseDialog({
    super.key,
    required this.isSubmitting,
  });

  final bool isSubmitting;

  @override
  State<InventarioFisicoCloseDialog> createState() =>
      _InventarioFisicoCloseDialogState();
}

class _InventarioFisicoCloseDialogState
    extends State<InventarioFisicoCloseDialog> {
  final _observacionController = TextEditingController();

  @override
  void dispose() {
    _observacionController.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(
      _observacionController.text.trim().isEmpty
          ? ''
          : _observacionController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cerrar inventario fisico', style: theme.textTheme.headlineSmall),
              const Gap(AppSpacing.sm),
              Text(
                'Al cerrar la toma se generaran los ajustes correspondientes segun las diferencias registradas.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Gap(AppSpacing.xl),
              TextField(
                controller: _observacionController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Observacion de cierre',
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
                    label: 'Cerrar inventario',
                    icon: Icons.lock_outline,
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
    );
  }
}
