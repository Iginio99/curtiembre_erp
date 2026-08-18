import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/inventory/insumos/domain/constants/insumo_tipo_bien_options.dart';
import 'package:erp_curtiembre_fronted/features/inventory/insumos/domain/entities/insumo_record.dart';
import 'package:erp_curtiembre_fronted/features/inventory/insumos/domain/entities/unidad_medida_option.dart';
import 'package:flutter/material.dart';
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
    _codigoController = TextEditingController(text: initialInsumo?.codigo ?? '');
    _nombreController = TextEditingController(text: initialInsumo?.nombre ?? '');
    _presentacionController =
        TextEditingController(text: initialInsumo?.presentacion ?? '');
    _stockMinimoController = TextEditingController(
      text: initialInsumo == null ? '' : initialInsumo.stockMinimo.toStringAsFixed(2),
    );
    _tipoBien = initialInsumo?.tipoBien ?? inventoryInsumoTipoBienOptions.first.value;
    _unidadMedidaId = initialInsumo?.unidadMedidaId ??
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

    final normalizedStock = _stockMinimoController.text.trim().replaceAll(',', '.');

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
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _codigoController,
                  maxLength: 50,
                  decoration: const InputDecoration(
                    labelText: 'Codigo',
                    hintText: 'Ej. INS-001',
                  ),
                  validator: (value) {
                    if ((value?.trim() ?? '').isEmpty) {
                      return 'Ingresa el codigo del insumo.';
                    }
                    return null;
                  },
                ),
                const Gap(AppSpacing.md),
                TextFormField(
                  controller: _nombreController,
                  maxLength: 150,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    hintText: 'Ej. Sulfuro de sodio',
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
                TextFormField(
                  controller: _stockMinimoController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Stock minimo',
                    hintText: 'Ej. 10 o 10.50',
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
                  ),
                ),
                const Gap(AppSpacing.md),
                SwitchListTile.adaptive(
                  value: _requiereLote,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Requiere lote'),
                  subtitle: const Text(
                    'Activalo si el insumo debe trazarse por lote en movimientos.',
                  ),
                  onChanged: (value) => setState(() => _requiereLote = value),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.isSubmitting ? null : () => Navigator.of(context).pop(),
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
