import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/inventory/insumos/domain/constants/insumo_tipo_bien_options.dart';
import 'package:erp_curtiembre_fronted/features/inventory/insumos/domain/entities/insumo_record.dart';
import 'package:erp_curtiembre_fronted/features/inventory/insumos/domain/entities/unidad_medida_option.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';

class InsumoUpsertFormData {
  const InsumoUpsertFormData({
    required this.codigo,
    required this.nombre,
    required this.tipoBien,
    required this.unidadMedidaId,
    required this.stockMinimo,
    required this.requiereLote,
    this.presentacion,
  });

  final String codigo;
  final String nombre;
  final String tipoBien;
  final int unidadMedidaId;
  final double stockMinimo;
  final bool requiereLote;
  final String? presentacion;
}

class InsumoUpsertDialog extends StatefulWidget {
  const InsumoUpsertDialog({
    required this.title,
    required this.submitLabel,
    required this.unitOptions,
    required this.isSubmitting,
    this.initialInsumo,
    super.key,
  });

  final String title;
  final String submitLabel;
  final List<UnidadMedidaOption> unitOptions;
  final bool isSubmitting;
  final InsumoRecord? initialInsumo;

  @override
  State<InsumoUpsertDialog> createState() => _InsumoUpsertDialogState();
}

class _InsumoUpsertDialogState extends State<InsumoUpsertDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codigoController;
  late final TextEditingController _nombreController;
  late final TextEditingController _presentacionController;
  late final TextEditingController _stockMinimoController;
  late String _tipoBien;
  int? _unidadMedidaId;
  late bool _requiereLote;

  @override
  void initState() {
    super.initState();
    final initialInsumo = widget.initialInsumo;
    _codigoController = TextEditingController(
      text: initialInsumo?.codigo ?? '',
    );
    _nombreController = TextEditingController(
      text: initialInsumo?.nombre ?? '',
    );
    _presentacionController = TextEditingController(
      text: initialInsumo?.presentacion ?? '',
    );
    _stockMinimoController = TextEditingController(
      text: initialInsumo == null
          ? ''
          : initialInsumo.stockMinimo.toStringAsFixed(2),
    );
    _tipoBien =
        initialInsumo?.tipoBien ?? inventoryInsumoTipoBienOptions.first.value;
    _unidadMedidaId =
        initialInsumo?.unidadMedidaId ??
        (widget.unitOptions.isNotEmpty ? widget.unitOptions.first.id : null);
    _requiereLote = initialInsumo?.requiereLote ?? false;
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _presentacionController.dispose();
    _stockMinimoController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final normalizedStock = _stockMinimoController.text.trim().replaceAll(
      ',',
      '.',
    );

    Navigator.of(context).pop(
      InsumoUpsertFormData(
        codigo: _codigoController.text.trim(),
        nombre: _nombreController.text.trim(),
        tipoBien: _tipoBien,
        presentacion: _normalizeOptional(_presentacionController.text),
        unidadMedidaId: _unidadMedidaId!,
        stockMinimo: double.parse(normalizedStock),
        requiereLote: _requiereLote,
      ),
    );
  }

  String? _normalizeOptional(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.initialInsumo != null;
    return AlertDialog(
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            foregroundColor: theme.colorScheme.primary,
            child: Icon(
              isEditing ? Icons.edit_note_rounded : Icons.inventory_2_outlined,
            ),
          ),
          const Gap(AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title),
              Text(
                isEditing
                    ? 'Informacion operativa del insumo'
                    : 'Nuevo registro de inventario',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
      content: SizedBox(
        width: 620,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.initialInsumo != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(
                        alpha: 0.45,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.tag_rounded,
                          color: theme.colorScheme.primary,
                        ),
                        const Gap(AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Codigo automatico',
                                style: theme.textTheme.labelMedium,
                              ),
                              Text(
                                _codigoController.text,
                                style: theme.textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.lock_outline_rounded, size: 20),
                      ],
                    ),
                  ),
                  const Gap(AppSpacing.md),
                ],
                Text('Informacion general', style: theme.textTheme.titleSmall),
                const Gap(AppSpacing.sm),
                TextFormField(
                  controller: _nombreController,
                  maxLength: 150,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    hintText: 'Ej. Sulfuro de sodio',
                    prefixIcon: Icon(Icons.label_outline_rounded),
                  ),
                  validator: (value) {
                    if ((value?.trim() ?? '').isEmpty) {
                      return 'Ingresa el nombre del insumo.';
                    }
                    return null;
                  },
                ),
                const Gap(AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _tipoBien,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de bien',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: inventoryInsumoTipoBienOptions
                      .map(
                        (option) => DropdownMenuItem<String>(
                          value: option.value,
                          child: Text(option.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() => _tipoBien = value);
                  },
                ),
                const Gap(AppSpacing.md),
                DropdownButtonFormField<int>(
                  initialValue: _unidadMedidaId,
                  decoration: const InputDecoration(
                    labelText: 'Unidad de medida',
                    prefixIcon: Icon(Icons.straighten_rounded),
                  ),
                  items: widget.unitOptions
                      .map(
                        (option) => DropdownMenuItem<int>(
                          value: option.id,
                          child: Text(option.displayName),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: widget.unitOptions.isEmpty
                      ? null
                      : (value) => setState(() => _unidadMedidaId = value),
                  validator: (value) {
                    if (value == null) {
                      return 'Selecciona una unidad de medida.';
                    }
                    return null;
                  },
                ),
                const Gap(AppSpacing.md),
                Text(
                  'Control de inventario',
                  style: theme.textTheme.titleSmall,
                ),
                const Gap(AppSpacing.sm),
                TextFormField(
                  controller: _stockMinimoController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*[\.,]?\d{0,4}'),
                    ),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Stock minimo',
                    hintText: 'Ej. 10 o 10.50',
                    prefixIcon: Icon(Icons.inventory_outlined),
                  ),
                  validator: (value) {
                    final normalized = value?.trim().replaceAll(',', '.') ?? '';
                    if (normalized.isEmpty) {
                      return 'Ingresa el stock minimo.';
                    }
                    final parsed = double.tryParse(normalized);
                    if (parsed == null || parsed < 0) {
                      return 'Ingresa un stock minimo valido.';
                    }
                    return null;
                  },
                ),
                const Gap(AppSpacing.md),
                TextFormField(
                  controller: _presentacionController,
                  maxLength: 150,
                  decoration: const InputDecoration(
                    labelText: 'Presentacion',
                    hintText: 'Ej. Saco 25 kg',
                    prefixIcon: Icon(Icons.widgets_outlined),
                  ),
                ),
                const Gap(AppSpacing.md),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: SwitchListTile.adaptive(
                    value: _requiereLote,
                    secondary: const Icon(Icons.qr_code_2_rounded),
                    title: const Text('Control por lote'),
                    subtitle: const Text(
                      'Activalo para trazabilidad individual.',
                    ),
                    onChanged: (value) => setState(() => _requiereLote = value),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.isSubmitting
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: widget.isSubmitting ? null : _submit,
          icon: widget.isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: Text(widget.submitLabel),
        ),
      ],
    );
  }
}
