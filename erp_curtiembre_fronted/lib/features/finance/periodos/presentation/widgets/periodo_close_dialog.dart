import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/finance/periodos/domain/entities/periodo_costo_record.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class PeriodoCloseDialogResult {
  const PeriodoCloseDialogResult({this.observacion});

  final String? observacion;
}

class PeriodoCloseDialog extends StatefulWidget {
  const PeriodoCloseDialog({
    required this.periodo,
    required this.isSubmitting,
    super.key,
  });

  final PeriodoCostoRecord periodo;
  final bool isSubmitting;

  @override
  State<PeriodoCloseDialog> createState() => _PeriodoCloseDialogState();
}

class _PeriodoCloseDialogState extends State<PeriodoCloseDialog> {
  final _observacionController = TextEditingController();

  @override
  void dispose() {
    _observacionController.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(
      PeriodoCloseDialogResult(
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cerrar periodo', style: theme.textTheme.headlineSmall),
              const Gap(AppSpacing.sm),
              Text(
                'Vas a cerrar el periodo ${widget.periodo.codigo}. Despues de esto no deberia aceptar nuevas cargas operativas.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Gap(AppSpacing.xl),
              TextFormField(
                controller: _observacionController,
                minLines: 3,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Observacion de cierre',
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
                        : const Icon(Icons.lock_clock_outlined),
                    label: const Text('Cerrar periodo'),
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
