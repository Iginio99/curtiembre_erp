import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/repositories/ordenes_produccion_repository.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/buttons/app_button.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class FinalizarOrdenDialogResult {
  const FinalizarOrdenDialogResult({required this.input});

  final FinalizarOrdenProduccionInput input;
}

class FinalizarOrdenDialog extends StatefulWidget {
  const FinalizarOrdenDialog({
    super.key,
    required this.isSubmitting,
    required this.procesosFinalizados,
    required this.procesosTotales,
    required this.tieneProductoTerminado,
    required this.cantidadLadosClasificados,
  });

  final bool isSubmitting;
  final int procesosFinalizados;
  final int procesosTotales;
  final bool tieneProductoTerminado;
  final double cantidadLadosClasificados;

  @override
  State<FinalizarOrdenDialog> createState() => _FinalizarOrdenDialogState();
}

class _FinalizarOrdenDialogState extends State<FinalizarOrdenDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _cantidadController;
  final _observacionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cantidadController = TextEditingController(
      text: widget.cantidadLadosClasificados.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _observacionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final cantidad = double.tryParse(
      _cantidadController.text.trim().replaceAll(',', '.'),
    );
    if (cantidad == null || cantidad < 0) {
      return;
    }

    Navigator.of(context).pop(
      FinalizarOrdenDialogResult(
        input: FinalizarOrdenProduccionInput(
          cantidadLados: cantidad,
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

    return Dialog(
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
                Text('Finalizar orden', style: theme.textTheme.headlineSmall),
                const Gap(AppSpacing.sm),
                Text(
                  'Antes de cerrar, confirma la cantidad de lados finales que ingresaran como producto terminado.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Gap(AppSpacing.lg),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Checklist visible',
                        style: theme.textTheme.titleMedium,
                      ),
                      const Gap(AppSpacing.md),
                      Text(
                        'Procesos finalizados: ${widget.procesosFinalizados}/${widget.procesosTotales}',
                      ),
                      const Gap(AppSpacing.xs),
                      Text(
                        widget.tieneProductoTerminado
                            ? 'La orden ya tiene producto terminado registrado.'
                            : 'Aun no existe producto terminado para esta orden.',
                      ),
                    ],
                  ),
                ),
                const Gap(AppSpacing.xl),
                TextFormField(
                  controller: _cantidadController,
                  readOnly: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Lados de producto terminado',
                    hintText: '0.00',
                    helperText: 'Calculado automáticamente: A + B + C.',
                  ),
                  validator: (value) {
                    final parsed = double.tryParse(
                      (value ?? '').trim().replaceAll(',', '.'),
                    );
                    if (parsed == null || parsed < 0) {
                      return 'Ingresa una cantidad valida.';
                    }
                    return null;
                  },
                ),
                const Gap(AppSpacing.lg),
                TextFormField(
                  controller: _observacionController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Observacion final',
                    hintText: 'Resumen breve del cierre de la orden',
                  ),
                ),
                const Gap(AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppButton.secondary(
                      label: 'Cancelar',
                      onPressed: widget.isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                    ),
                    const Gap(AppSpacing.md),
                    AppButton.primary(
                      label: 'Finalizar orden',
                      icon: Icons.task_alt_outlined,
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
