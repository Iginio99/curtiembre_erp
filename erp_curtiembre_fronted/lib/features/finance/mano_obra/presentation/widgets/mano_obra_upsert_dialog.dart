import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/orden_proceso_record.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/orden_produccion_record.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class ManoObraUpsertFormData {
  const ManoObraUpsertFormData({
    required this.ordenProduccionId,
    required this.ordenProcesoId,
    required this.monto,
    this.descripcion,
  });

  final int ordenProduccionId;
  final int ordenProcesoId;
  final double monto;
  final String? descripcion;
}

class ManoObraUpsertDialog extends StatefulWidget {
  const ManoObraUpsertDialog({
    required this.ordenes,
    required this.processesByOrder,
    required this.isSubmitting,
    super.key,
  });

  final List<OrdenProduccionRecord> ordenes;
  final List<OrdenProcesoRecord> Function(int? orderId) processesByOrder;
  final bool isSubmitting;

  @override
  State<ManoObraUpsertDialog> createState() => _ManoObraUpsertDialogState();
}

class _ManoObraUpsertDialogState extends State<ManoObraUpsertDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _montoController;
  late final TextEditingController _descripcionController;
  int? _ordenProduccionId;
  int? _ordenProcesoId;

  @override
  void initState() {
    super.initState();
    _montoController = TextEditingController();
    _descripcionController = TextEditingController();
    _ordenProduccionId = widget.ordenes.firstOrNull?.id;
    _ordenProcesoId = widget.processesByOrder(_ordenProduccionId).firstOrNull?.id;
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
      ManoObraUpsertFormData(
        ordenProduccionId: _ordenProduccionId!,
        ordenProcesoId: _ordenProcesoId!,
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
    final processes = widget.processesByOrder(_ordenProduccionId);

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
                Text('Registrar mano de obra', style: theme.textTheme.headlineSmall),
                const Gap(AppSpacing.sm),
                Text(
                  'Asocia el monto a una orden y proceso real para que luego entre al costo del modulo financiero.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Gap(AppSpacing.xl),
                DropdownButtonFormField<int>(
                  initialValue: _ordenProduccionId,
                  decoration: const InputDecoration(labelText: 'Orden de produccion'),
                  items: widget.ordenes
                      .map(
                        (item) => DropdownMenuItem<int>(
                          value: item.id,
                          child: Text('${item.codigo} · ${item.clienteRazonSocial}'),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    setState(() {
                      _ordenProduccionId = value;
                      _ordenProcesoId = widget.processesByOrder(value).firstOrNull?.id;
                    });
                  },
                  validator: (value) => value == null ? 'Selecciona una orden.' : null,
                ),
                const Gap(AppSpacing.lg),
                DropdownButtonFormField<int>(
                  initialValue: _ordenProcesoId,
                  decoration: const InputDecoration(labelText: 'Proceso'),
                  items: processes
                      .map(
                        (item) => DropdownMenuItem<int>(
                          value: item.id,
                          child: Text('${item.procesoCodigo} · ${item.procesoNombre}'),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) => setState(() => _ordenProcesoId = value),
                  validator: (value) => value == null ? 'Selecciona un proceso.' : null,
                ),
                const Gap(AppSpacing.lg),
                TextFormField(
                  controller: _montoController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Monto',
                    hintText: 'Ej. 120.00',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    final parsed = double.tryParse(text);
                    if (parsed == null) return 'Ingresa un monto valido.';
                    if (parsed < 0) return 'El monto no puede ser negativo.';
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
                      onPressed: widget.isSubmitting ? null : _submit,
                      icon: widget.isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.payments_outlined),
                      label: const Text('Registrar'),
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
