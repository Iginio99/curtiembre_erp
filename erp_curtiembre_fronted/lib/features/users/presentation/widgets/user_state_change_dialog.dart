import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class UserStateChangeDialogResult {
  const UserStateChangeDialogResult({
    this.motivo,
  });

  final String? motivo;
}

class UserStateChangeDialog extends StatefulWidget {
  const UserStateChangeDialog({
    required this.userName,
    required this.activate,
    required this.isSubmitting,
    super.key,
  });

  final String userName;
  final bool activate;
  final bool isSubmitting;

  @override
  State<UserStateChangeDialog> createState() => _UserStateChangeDialogState();
}

class _UserStateChangeDialogState extends State<UserStateChangeDialog> {
  final _motivoController = TextEditingController();

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(
      UserStateChangeDialogResult(
        motivo: _motivoController.text.trim().isEmpty ? null : _motivoController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.activate ? 'Reactivar usuario' : 'Desactivar usuario';
    final description = widget.activate
        ? 'Registra un motivo opcional para reactivar a @${widget.userName}.'
        : 'Registra un motivo opcional para desactivar a @${widget.userName}.';

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.headlineSmall),
              const Gap(AppSpacing.sm),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Gap(AppSpacing.xl),
              TextField(
                controller: _motivoController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Motivo',
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
                        : Icon(
                            widget.activate
                                ? Icons.person_add_alt_1_outlined
                                : Icons.person_off_outlined,
                          ),
                    label: Text(widget.activate ? 'Reactivar' : 'Desactivar'),
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
