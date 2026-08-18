import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/finance/periodos/domain/entities/periodo_costo_record.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class DepreciacionCalculateDialogResult {
  const DepreciacionCalculateDialogResult({required this.periodoId});

  final int periodoId;
}

class DepreciacionCalculateDialog extends StatefulWidget {
  const DepreciacionCalculateDialog({
    required this.periodos,
    required this.isSubmitting,
    super.key,
  });

  final List<PeriodoCostoRecord> periodos;
  final bool isSubmitting;

  @override
  State<DepreciacionCalculateDialog> createState() => _DepreciacionCalculateDialogState();
}

class _DepreciacionCalculateDialogState extends State<DepreciacionCalculateDialog> {
  int? _periodoId;

  @override
  void initState() {
    super.initState();
    _periodoId = widget.periodos.firstOrNull?.id;
  }

  void _submit() {
    if (_periodoId == null) return;
    Navigator.of(context).pop(DepreciacionCalculateDialogResult(periodoId: _periodoId!));
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
              Text('Calcular depreciacion', style: theme.textTheme.headlineSmall),
              const Gap(AppSpacing.sm),
              Text(
                'Selecciona el periodo sobre el cual quieres generar la depreciacion mensual de los activos elegibles.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Gap(AppSpacing.xl),
              DropdownButtonFormField<int>(
                initialValue: _periodoId,
                decoration: const InputDecoration(labelText: 'Periodo'),
                items: widget.periodos
                    .map(
                      (item) => DropdownMenuItem<int>(
                        value: item.id,
                        child: Text('${item.codigo} · ${item.estado}'),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) => setState(() => _periodoId = value),
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
                        : const Icon(Icons.calculate_outlined),
                    label: const Text('Calcular'),
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
