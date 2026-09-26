import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/repositories/ordenes_produccion_repository.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/buttons/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';

class RegistrarCalidadFinalDialogResult {
  const RegistrarCalidadFinalDialogResult({required this.input});
  final RegistrarCalidadFinalInput input;
}

class RegistrarCalidadFinalDialog extends StatefulWidget {
  const RegistrarCalidadFinalDialog({
    super.key,
    required this.isSubmitting,
    required this.cantidadPieles,
  });

  final bool isSubmitting;
  final double cantidadPieles;

  @override
  State<RegistrarCalidadFinalDialog> createState() =>
      _RegistrarCalidadFinalDialogState();
}

class _RegistrarCalidadFinalDialogState
    extends State<RegistrarCalidadFinalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _aController = TextEditingController();
  final _bController = TextEditingController();
  final _cController = TextEditingController();
  final _mermaController = TextEditingController();
  final _observacionController = TextEditingController();

  double _value(TextEditingController controller) =>
      double.tryParse(controller.text.trim()) ?? 0;

  double get _totalRegistrado =>
      _value(_aController) +
      _value(_bController) +
      _value(_cController) +
      _value(_mermaController);
  double get _totalEsperado => widget.cantidadPieles * 2;

  @override
  void dispose() {
    _aController.dispose();
    _bController.dispose();
    _cController.dispose();
    _mermaController.dispose();
    _observacionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final a = _value(_aController);
    final b = _value(_bController);
    final c = _value(_cController);
    final merma = _value(_mermaController);
    if ((a + b + c + merma) != _totalEsperado) return;

    final qualityId = a >= b && a >= c ? 1 : (b >= c ? 2 : 3);
    Navigator.of(context).pop(
      RegistrarCalidadFinalDialogResult(
        input: RegistrarCalidadFinalInput(
          calidadProductoId: qualityId,
          cantidadLadosA: a,
          cantidadLadosB: b,
          cantidadLadosC: c,
          cantidadLadosMerma: merma,
          resultado: 'APROBADO',
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
    final restante = _totalEsperado - _totalRegistrado;
    final completo = restante == 0;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Registrar calidad final',
                  style: theme.textTheme.headlineSmall,
                ),
                const Gap(AppSpacing.xs),
                Text(
                  'Distribuye los lados obtenidos entre las calidades A, B, C y la merma final.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Gap(AppSpacing.lg),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Wrap(
                    spacing: AppSpacing.xl,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _Summary(
                        label: 'Pieles procesadas',
                        value: _number(widget.cantidadPieles),
                      ),
                      _Summary(
                        label: 'Lados a distribuir',
                        value: _number(_totalEsperado),
                      ),
                      _Summary(
                        label: completo
                            ? 'Distribución completa'
                            : 'Lados restantes',
                        value: _number(restante),
                        color: completo
                            ? theme.colorScheme.primary
                            : theme.colorScheme.error,
                      ),
                    ],
                  ),
                ),
                const Gap(AppSpacing.lg),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth >= 620
                        ? (constraints.maxWidth - AppSpacing.md) / 2
                        : constraints.maxWidth;
                    return Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.md,
                      children: [
                        _QualityInput(
                          width: width,
                          code: 'A',
                          label: 'Calidad superior',
                          controller: _aController,
                          onChanged: (_) => setState(() {}),
                        ),
                        _QualityInput(
                          width: width,
                          code: 'B',
                          label: 'Calidad intermedia',
                          controller: _bController,
                          onChanged: (_) => setState(() {}),
                        ),
                        _QualityInput(
                          width: width,
                          code: 'C',
                          label: 'Calidad con observaciones',
                          controller: _cController,
                          onChanged: (_) => setState(() {}),
                        ),
                        _QualityInput(
                          width: width,
                          code: 'Merma',
                          label: 'Pérdida final',
                          controller: _mermaController,
                          onChanged: (_) => setState(() {}),
                          isLoss: true,
                        ),
                      ],
                    );
                  },
                ),
                if (!completo) ...[
                  const Gap(AppSpacing.sm),
                  Text(
                    restante > 0
                        ? 'Falta distribuir ${_number(restante)} lados.'
                        : 'Excediste el total por ${_number(-restante)} lados.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
                const Gap(AppSpacing.lg),
                TextFormField(
                  controller: _observacionController,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Observación final (opcional)',
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
                      label: 'Registrar calidad',
                      icon: Icons.verified_outlined,
                      expand: false,
                      isLoading: widget.isSubmitting,
                      onPressed: widget.isSubmitting || !completo
                          ? null
                          : _submit,
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

class _QualityInput extends StatelessWidget {
  const _QualityInput({
    required this.width,
    required this.code,
    required this.label,
    required this.controller,
    required this.onChanged,
    this.isLoss = false,
  });

  final double width;
  final String code;
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool isLoss;

  @override
  Widget build(BuildContext context) {
    final lados = double.tryParse(controller.text) ?? 0;
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: '$code · $label',
          hintText: '0',
          prefixIcon: Icon(
            isLoss ? Icons.remove_circle_outline : Icons.layers_outlined,
          ),
          suffixText: '${_number(lados / 2)} pieles',
        ),
        validator: (value) {
          final parsed = double.tryParse((value ?? '').trim());
          return parsed == null || parsed < 0 ? 'Ingresa los lados.' : null;
        },
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      Text(
        value,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color),
      ),
    ],
  );
}

String _number(double value) => value == value.truncateToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);
