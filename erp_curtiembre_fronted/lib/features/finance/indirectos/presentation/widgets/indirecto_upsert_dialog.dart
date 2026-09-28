import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/finance/periodos/domain/entities/periodo_costo_record.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class IndirectoUpsertFormData {
  const IndirectoUpsertFormData({
    required this.periodoCostoId,
    required this.tipoCosto,
    required this.monto,
    this.descripcion,
  });

  final int periodoCostoId;
  final String tipoCosto;
  final double monto;
  final String? descripcion;
}

class IndirectoUpsertDialog extends StatefulWidget {
  const IndirectoUpsertDialog({
    required this.periodos,
    required this.isSubmitting,
    super.key,
  });

  final List<PeriodoCostoRecord> periodos;
  final bool isSubmitting;

  @override
  State<IndirectoUpsertDialog> createState() => _IndirectoUpsertDialogState();
}

class _IndirectoUpsertDialogState extends State<IndirectoUpsertDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _montoController;
  late final TextEditingController _descripcionController;
  int? _periodoCostoId;
  String _tipoCosto = 'MANO_DE_OBRA';

  @override
  void initState() {
    super.initState();
    _montoController = TextEditingController();
    _descripcionController = TextEditingController();
    final openPeriods = widget.periodos.where((item) => item.isOpen).toList(growable: false);
    _periodoCostoId = (openPeriods.isNotEmpty ? openPeriods.first : widget.periodos.firstOrNull)?.id;
  }

  @override
  void dispose() {
    _montoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      IndirectoUpsertFormData(
        periodoCostoId: _periodoCostoId!,
        tipoCosto: _tipoCosto,
        monto: double.parse(_montoController.text.trim()),
        descripcion: _descripcionController.text.trim().isEmpty
            ? null
            : _descripcionController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final openPeriods = widget.periodos.where((item) => item.isOpen).toList(growable: false);

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
                Text('Registrar gasto mensual', style: theme.textTheme.headlineSmall),
                const Gap(AppSpacing.sm),
                Text(
                  'Registra sueldos, servicios u otros gastos del mes. El sistema los reparte entre las pieles trabajadas.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Gap(AppSpacing.xl),
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  initialValue: _periodoCostoId,
                  decoration: const InputDecoration(labelText: 'Periodo de costo'),
                  items: openPeriods
                      .map(
                        (item) => DropdownMenuItem<int>(
                          value: item.id,
                          child: Text('${item.codigo} · ${item.estado}'),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: openPeriods.isEmpty
                      ? null
                      : (value) => setState(() => _periodoCostoId = value),
                  validator: (value) {
                    if (value == null) {
                      return 'Selecciona un periodo abierto.';
                    }
                    return null;
                  },
                ),
                const Gap(AppSpacing.lg),
                DropdownButtonFormField<String>(
                  initialValue: _tipoCosto,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de gasto',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'MANO_DE_OBRA', child: Text('Mano de obra / planilla')),
                    DropdownMenuItem(value: 'SERVICIOS', child: Text('Servicios (agua, luz, gas)')),
                    DropdownMenuItem(value: 'ALQUILER', child: Text('Alquiler')),
                    DropdownMenuItem(value: 'MANTENIMIENTO', child: Text('Mantenimiento')),
                    DropdownMenuItem(value: 'OTROS', child: Text('Otros gastos')),
                  ],
                  onChanged: (value) => setState(() => _tipoCosto = value ?? 'OTROS'),
                ),
                const Gap(AppSpacing.lg),
                TextFormField(
                  controller: _montoController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Monto',
                    hintText: 'Ej. 450.00',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    final parsed = double.tryParse(text);
                    if (parsed == null) {
                      return 'Ingresa un monto valido.';
                    }
                    if (parsed < 0) {
                      return 'El monto no puede ser negativo.';
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
                      onPressed:
                          widget.isSubmitting ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    const Gap(AppSpacing.md),
                    FilledButton.icon(
                      onPressed: widget.isSubmitting || openPeriods.isEmpty ? null : _submit,
                      icon: widget.isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.request_quote_outlined),
                      label: const Text('Registrar gasto'),
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
