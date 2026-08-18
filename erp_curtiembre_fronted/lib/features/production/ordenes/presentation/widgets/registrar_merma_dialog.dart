import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/orden_proceso_record.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/repositories/ordenes_produccion_repository.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/buttons/app_button.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class RegistrarMermaDialogResult {
  const RegistrarMermaDialogResult({
    required this.procesoId,
    required this.input,
  });

  final int procesoId;
  final RegistrarMermaProcesoInput input;
}

class RegistrarMermaDialog extends StatefulWidget {
  const RegistrarMermaDialog({
    super.key,
    required this.proceso,
    required this.isSubmitting,
  });

  final OrdenProcesoRecord proceso;
  final bool isSubmitting;

  @override
  State<RegistrarMermaDialog> createState() => _RegistrarMermaDialogState();
}

class _RegistrarMermaDialogState extends State<RegistrarMermaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cantidadController = TextEditingController();
  final _motivoController = TextEditingController();
  final _observacionController = TextEditingController();

  @override
  void dispose() {
    _cantidadController.dispose();
    _motivoController.dispose();
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
    if (cantidad == null || cantidad <= 0) {
      return;
    }

    Navigator.of(context).pop(
      RegistrarMermaDialogResult(
        procesoId: widget.proceso.id,
        input: RegistrarMermaProcesoInput(
          cantidadPerdida: cantidad,
          motivo: _motivoController.text.trim().isEmpty
              ? null
              : _motivoController.text.trim(),
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
                Text('Registrar merma', style: theme.textTheme.headlineSmall),
                const Gap(AppSpacing.sm),
                Text(
                  'Proceso: ${widget.proceso.secuencia}. ${widget.proceso.procesoNombre}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const Gap(AppSpacing.lg),
                TextFormField(
                  controller: _cantidadController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Cantidad perdida',
                    hintText: '0.00',
                  ),
                  validator: (value) {
                    final parsed =
                        double.tryParse((value ?? '').trim().replaceAll(',', '.'));
                    if (parsed == null || parsed <= 0) {
                      return 'Ingresa una cantidad valida.';
                    }
                    return null;
                  },
                ),
                const Gap(AppSpacing.lg),
                TextFormField(
                  controller: _motivoController,
                  decoration: const InputDecoration(
                    labelText: 'Motivo',
                    hintText: 'Ej. Defecto de proceso o corte dañado',
                  ),
                ),
                const Gap(AppSpacing.lg),
                TextFormField(
                  controller: _observacionController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Observacion',
                    hintText: 'Describe el contexto de la merma',
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
                      label: 'Registrar merma',
                      icon: Icons.content_cut_outlined,
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
