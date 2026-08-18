import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/inventory/compras/domain/repositories/compras_repository.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/domain/entities/insumo_lookup.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/domain/entities/proveedor_lookup.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class OrdenCompraUpsertFormData {
  const OrdenCompraUpsertFormData({
    required this.proveedorId,
    required this.fechaEmision,
    required this.detalles,
    this.observacion,
  });

  final int proveedorId;
  final DateTime fechaEmision;
  final String? observacion;
  final List<CreateOrdenCompraDetalleInput> detalles;
}

class OrdenCompraUpsertDialog extends StatefulWidget {
  const OrdenCompraUpsertDialog({
    required this.proveedores,
    required this.insumos,
    required this.isSubmitting,
    super.key,
  });

  final List<ProveedorLookup> proveedores;
  final List<InsumoLookup> insumos;
  final bool isSubmitting;

  @override
  State<OrdenCompraUpsertDialog> createState() => _OrdenCompraUpsertDialogState();
}

class _OrdenCompraUpsertDialogState extends State<OrdenCompraUpsertDialog> {
  final _formKey = GlobalKey<FormState>();
  final _observacionController = TextEditingController();
  DateTime _fechaEmision = DateTime.now();
  int? _proveedorId;
  final List<_OrdenCompraDetalleDraft> _detalles = [];

  @override
  void initState() {
    super.initState();
    _proveedorId = widget.proveedores.isNotEmpty ? widget.proveedores.first.id : null;
    _detalles.add(_OrdenCompraDetalleDraft());
  }

  @override
  void dispose() {
    _observacionController.dispose();
    for (final item in _detalles) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _fechaEmision,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );

    if (selected != null) {
      setState(() => _fechaEmision = selected);
    }
  }

  void _addDetail() {
    setState(() => _detalles.add(_OrdenCompraDetalleDraft()));
  }

  void _removeDetail(int index) {
    if (_detalles.length == 1) return;
    setState(() {
      final item = _detalles.removeAt(index);
      item.dispose();
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final mapped = _detalles.map((item) {
      final costoText = item.costoController.text.trim().replaceAll(',', '.');
      return CreateOrdenCompraDetalleInput(
        insumoId: item.insumoId!,
        cantidadSolicitada: double.parse(
          item.cantidadController.text.trim().replaceAll(',', '.'),
        ),
        costoUnitarioEstimado:
            costoText.isEmpty ? null : double.parse(costoText),
        observacion: item.observacionController.text.trim().isEmpty
            ? null
            : item.observacionController.text.trim(),
      );
    }).toList(growable: false);

    Navigator.of(context).pop(
      OrdenCompraUpsertFormData(
        proveedorId: _proveedorId!,
        fechaEmision: _fechaEmision,
        observacion: _observacionController.text.trim().isEmpty
            ? null
            : _observacionController.text.trim(),
        detalles: mapped,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva orden de compra'),
      content: SizedBox(
        width: 860,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _proveedorId,
                        decoration: const InputDecoration(
                          labelText: 'Proveedor',
                        ),
                        items: widget.proveedores
                            .map(
                              (item) => DropdownMenuItem<int>(
                                value: item.id,
                                child: Text(item.displayName),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: widget.proveedores.isEmpty
                            ? null
                            : (value) => setState(() => _proveedorId = value),
                        validator: (value) {
                          if (value == null) return 'Selecciona un proveedor.';
                          return null;
                        },
                      ),
                    ),
                    const Gap(AppSpacing.lg),
                    Expanded(
                      child: InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Fecha de emision',
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(DateFormat('dd/MM/yyyy').format(_fechaEmision)),
                              const Icon(Icons.calendar_month_outlined),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(AppSpacing.lg),
                TextFormField(
                  controller: _observacionController,
                  minLines: 2,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'Observacion',
                    hintText: 'Compra semanal o reposicion puntual',
                  ),
                ),
                const Gap(AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Detalle de la compra',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    TextButton.icon(
                      onPressed: _addDetail,
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Agregar fila'),
                    ),
                  ],
                ),
                const Gap(AppSpacing.md),
                ...List.generate(
                  _detalles.length,
                  (index) => Padding(
                    padding: EdgeInsets.only(
                      bottom: index == _detalles.length - 1 ? 0 : AppSpacing.lg,
                    ),
                    child: _OrdenCompraDetalleCard(
                      index: index,
                      draft: _detalles[index],
                      insumos: widget.insumos,
                      canRemove: _detalles.length > 1,
                      onRemove: () => _removeDetail(index),
                    ),
                  ),
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
              : const Icon(Icons.shopping_cart_checkout_outlined),
          label: const Text('Crear orden'),
        ),
      ],
    );
  }
}

class _OrdenCompraDetalleCard extends StatefulWidget {
  const _OrdenCompraDetalleCard({
    required this.index,
    required this.draft,
    required this.insumos,
    required this.canRemove,
    required this.onRemove,
  });

  final int index;
  final _OrdenCompraDetalleDraft draft;
  final List<InsumoLookup> insumos;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  State<_OrdenCompraDetalleCard> createState() => _OrdenCompraDetalleCardState();
}

class _OrdenCompraDetalleCardState extends State<_OrdenCompraDetalleCard> {
  @override
  void initState() {
    super.initState();
    widget.draft.insumoId ??= widget.insumos.isNotEmpty ? widget.insumos.first.id : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Fila ${widget.index + 1}', style: theme.textTheme.titleSmall),
              IconButton(
                onPressed: widget.canRemove ? widget.onRemove : null,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const Gap(AppSpacing.md),
          DropdownButtonFormField<int>(
            initialValue: widget.draft.insumoId,
            decoration: const InputDecoration(labelText: 'Insumo'),
            items: widget.insumos
                .map(
                  (item) => DropdownMenuItem<int>(
                    value: item.id,
                    child: Text(item.displayName),
                  ),
                )
                .toList(growable: false),
            onChanged: widget.insumos.isEmpty
                ? null
                : (value) => setState(() => widget.draft.insumoId = value),
            validator: (value) {
              if (value == null) return 'Selecciona un insumo.';
              return null;
            },
          ),
          const Gap(AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: widget.draft.cantidadController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Cantidad solicitada',
                  ),
                  validator: (value) {
                    final parsed = double.tryParse(
                      (value ?? '').trim().replaceAll(',', '.'),
                    );
                    if (parsed == null || parsed <= 0) {
                      return 'Ingresa una cantidad valida.';
                    }
                    return null;
                  },
                ),
              ),
              const Gap(AppSpacing.lg),
              Expanded(
                child: TextFormField(
                  controller: widget.draft.costoController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Costo estimado',
                  ),
                  validator: (value) {
                    final text = (value ?? '').trim();
                    if (text.isEmpty) return null;
                    final parsed = double.tryParse(text.replaceAll(',', '.'));
                    if (parsed == null || parsed < 0) {
                      return 'Ingresa un costo valido.';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const Gap(AppSpacing.md),
          TextFormField(
            controller: widget.draft.observacionController,
            maxLength: 300,
            minLines: 2,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Observacion de la fila',
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdenCompraDetalleDraft {
  int? insumoId;
  final TextEditingController cantidadController = TextEditingController();
  final TextEditingController costoController = TextEditingController();
  final TextEditingController observacionController = TextEditingController();

  void dispose() {
    cantidadController.dispose();
    costoController.dispose();
    observacionController.dispose();
  }
}
