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
  State<OrdenCompraUpsertDialog> createState() =>
      _OrdenCompraUpsertDialogState();
}

class _OrdenCompraUpsertDialogState extends State<OrdenCompraUpsertDialog> {
  final _formKey = GlobalKey<FormState>();
  final _observacionController = TextEditingController();

  DateTime _fechaEmision = DateTime.now();
  int? _proveedorId;

  final _detalles = <_OrdenCompraDetalleDraft>[];

  @override
  void initState() {
    super.initState();

    _proveedorId = widget.proveedores.isNotEmpty
        ? widget.proveedores.first.id
        : null;

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
      setState(() {
        _fechaEmision = selected;
      });
    }
  }

  void _addDetail() {
    setState(() {
      _detalles.add(_OrdenCompraDetalleDraft());
    });
  }

  void _removeDetail(int index) {
    if (_detalles.length == 1) return;

    setState(() {
      _detalles.removeAt(index).dispose();
    });
  }

  double get _total {
    return _detalles.fold(0, (total, item) {
      final cantidad =
          double.tryParse(
            item.cantidadController.text.trim().replaceAll(',', '.'),
          ) ??
          0;

      final costo =
          double.tryParse(
            item.costoController.text.trim().replaceAll(',', '.'),
          ) ??
          0;

      return total + (cantidad * costo);
    });
  }

  Future<void> _editObservation(_OrdenCompraDetalleDraft draft) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Observación del producto'),
          content: SizedBox(
            width: 420,
            child: TextFormField(
              controller: draft.observacionController,
              autofocus: true,
              maxLength: 300,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Agrega una observación si es necesaria',
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: const Text('Listo'),
            ),
          ],
        );
      },
    );

    if (mounted) {
      setState(() {});
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final mapped = _detalles
        .map((item) {
          final costo = item.costoController.text.trim().replaceAll(',', '.');

          return CreateOrdenCompraDetalleInput(
            insumoId: item.insumoId!,
            cantidadSolicitada: double.parse(
              item.cantidadController.text.trim().replaceAll(',', '.'),
            ),
            costoUnitarioEstimado: costo.isEmpty ? null : double.parse(costo),
            observacion: item.observacionController.text.trim().isEmpty
                ? null
                : item.observacionController.text.trim(),
          );
        })
        .toList(growable: false);

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
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 940,
          maxHeight: screenHeight * 0.92,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /*
            ═══════════════════════════════════
            HEADER
            ═══════════════════════════════════
            */
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 22, 18, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Nueva orden de compra',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                  ),

                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: widget.isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            /*
            ═══════════════════════════════════
            CONTENIDO
            ═══════════════════════════════════
            */
            Flexible(
              fit: FlexFit.loose,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 8, 28, 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /*
                      ─────────────────────────
                      PROVEEDOR + FECHA
                      ─────────────────────────
                      */
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final proveedor = DropdownButtonFormField<int>(
                            isExpanded: true,
                            initialValue: _proveedorId,
                            decoration: const InputDecoration(
                              labelText: 'Proveedor',
                            ),
                            items: widget.proveedores
                                .map(
                                  (x) => DropdownMenuItem(
                                    value: x.id,
                                    child: Text(
                                      x.displayName,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: widget.proveedores.isEmpty
                                ? null
                                : (value) {
                                    setState(() {
                                      _proveedorId = value;
                                    });
                                  },
                            validator: (value) {
                              return value == null
                                  ? 'Selecciona un proveedor.'
                                  : null;
                            },
                          );

                          final fecha = InkWell(
                            onTap: _pickDate,
                            borderRadius: BorderRadius.circular(12),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Fecha de emisión',
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat(
                                      'dd/MM/yyyy',
                                    ).format(_fechaEmision),
                                  ),
                                  const Icon(Icons.calendar_month_outlined),
                                ],
                              ),
                            ),
                          );

                          if (constraints.maxWidth < 650) {
                            return Column(
                              children: [
                                proveedor,
                                const Gap(AppSpacing.md),
                                fecha,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(flex: 5, child: proveedor),
                              const Gap(18),
                              Expanded(flex: 4, child: fecha),
                            ],
                          );
                        },
                      ),

                      const Gap(14),

                      /*
                      ─────────────────────────
                      OBSERVACIÓN GENERAL
                      ─────────────────────────
                      */
                      TextFormField(
                        controller: _observacionController,
                        maxLines: 1,
                        maxLength: 500,
                        decoration: const InputDecoration(
                          labelText: 'Observación general',
                          hintText: 'Ej. Compra para mantenimiento de planta',
                        ),
                      ),

                      const Gap(20),

                      /*
                      ─────────────────────────
                      CABECERA DETALLE
                      ─────────────────────────
                      */
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Detalle de la compra',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),

                          Text(
                            '${_detalles.length} '
                            '${_detalles.length == 1 ? 'producto' : 'productos'}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),

                      const Gap(12),

                      /*
                      ─────────────────────────
                      TABLA
                      ─────────────────────────
                      */
                      _DetalleTable(
                        detalles: _detalles,
                        insumos: widget.insumos,
                        onRemove: _removeDetail,
                        onAdd: _addDetail,
                        onObservation: _editObservation,
                        onChanged: () {
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            /*
            ═══════════════════════════════════
            FOOTER
            ═══════════════════════════════════
            */
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final totalWidget = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total estimado:',
                        style: theme.textTheme.titleSmall,
                      ),
                      const Gap(10),
                      Text(
                        NumberFormat.currency(
                          locale: 'es_PE',
                          symbol: 'S/ ',
                          decimalDigits: 2,
                        ).format(_total),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  );

                  final actions = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton(
                        onPressed: widget.isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),

                      const Gap(12),

                      FilledButton.icon(
                        onPressed: widget.isSubmitting ? null : _submit,
                        icon: widget.isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.shopping_cart_checkout_outlined),
                        label: const Text('Crear orden'),
                      ),
                    ],
                  );

                  if (constraints.maxWidth < 650) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        totalWidget,
                        const Gap(14),
                        Align(alignment: Alignment.centerRight, child: actions),
                      ],
                    );
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [totalWidget, actions],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/*
══════════════════════════════════════════
TABLA DE DETALLE
══════════════════════════════════════════
*/

class _DetalleTable extends StatelessWidget {
  const _DetalleTable({
    required this.detalles,
    required this.insumos,
    required this.onRemove,
    required this.onAdd,
    required this.onObservation,
    required this.onChanged,
  });

  final List<_OrdenCompraDetalleDraft> detalles;
  final List<InsumoLookup> insumos;

  final ValueChanged<int> onRemove;
  final VoidCallback onAdd;

  final Future<void> Function(_OrdenCompraDetalleDraft) onObservation;

  final VoidCallback onChanged;

  Widget _buildRow(int index) {
    return _DetalleRow(
      draft: detalles[index],
      insumos: insumos,
      canRemove: detalles.length > 1,
      onRemove: () => onRemove(index),
      onObservation: () {
        onObservation(detalles[index]);
      },
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    /*
    ═══════════════════════════════════
    HASTA 5 PRODUCTOS:
    CRECE NATURALMENTE
    ═══════════════════════════════════
    */

    final compactRows = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < detalles.length; i++) ...[
          _buildRow(i),

          if (i < detalles.length - 1)
            Divider(
              height: 1,
              thickness: 1,
              color: theme.colorScheme.outlineVariant,
            ),
        ],
      ],
    );

    /*
    ═══════════════════════════════════
    MÁS DE 5:
    SCROLL INTERNO
    ═══════════════════════════════════
    */

    final scrollRows = ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: detalles.length,
      separatorBuilder: (_, _) {
        return Divider(
          height: 1,
          thickness: 1,
          color: theme.colorScheme.outlineVariant,
        );
      },
      itemBuilder: (_, index) {
        return _buildRow(index);
      },
    );

    /*
    ═══════════════════════════════════
    CONTENIDO COMPLETO DE TABLA
    ═══════════════════════════════════
    */

    final tableContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        /*
        ─────────────────────────────
        HEADER
        ─────────────────────────────
        */
        Container(
          width: double.infinity,
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          color: theme.colorScheme.surfaceContainerHighest,
          child: Row(children: _headers(context)),
        ),

        /*
        ─────────────────────────────
        FILAS
        ─────────────────────────────
        */
        if (detalles.length > 5)
          SizedBox(height: 295, child: scrollRows)
        else
          compactRows,

        /*
        ─────────────────────────────
        AGREGAR PRODUCTO
        ─────────────────────────────
        */
        Divider(
          height: 1,
          thickness: 1,
          color: theme.colorScheme.outlineVariant,
        ),

        SizedBox(
          width: double.infinity,
          child: Center(
            child: TextButton.icon(
              onPressed: onAdd,
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 13,
                ),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text(
                'Agregar producto',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );

    /*
    ═══════════════════════════════════
    CONTENEDOR EXTERIOR
    ═══════════════════════════════════
    */

    return SizedBox(
      width: double.infinity,
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            /*
            Desktop normal:
            ocupa TODO el ancho.
            */

            if (constraints.maxWidth >= 700) {
              return tableContent;
            }

            /*
            Pantalla pequeña:
            conserva formato horizontal
            mediante scroll lateral.
            */

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(width: 700, child: tableContent),
            );
          },
        ),
      ),
    );
  }

  /*
  ═══════════════════════════════════
  HEADER DE COLUMNAS
  MISMAS MEDIDAS QUE LA FILA
  ═══════════════════════════════════
  */

  List<Widget> _headers(BuildContext context) {
    final theme = Theme.of(context);

    Widget header(String text, {TextAlign align = TextAlign.left}) {
      return Text(
        text,
        textAlign: align,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 10.5,
        ),
      );
    }

    return [
      Expanded(flex: 5, child: header('Producto *')),

      const Gap(10),

      Expanded(flex: 2, child: header('Cantidad *')),

      const Gap(10),

      Expanded(flex: 2, child: header('Costo estimado *')),

      const Gap(8),

      SizedBox(
        width: 52,
        child: Center(child: header('Obs.', align: TextAlign.center)),
      ),

      SizedBox(
        width: 58,
        child: Center(child: header('Acción', align: TextAlign.center)),
      ),
    ];
  }
}

/*
══════════════════════════════════════════
FILA DEL PRODUCTO
══════════════════════════════════════════
*/

class _DetalleRow extends StatefulWidget {
  const _DetalleRow({
    required this.draft,
    required this.insumos,
    required this.canRemove,
    required this.onRemove,
    required this.onObservation,
    required this.onChanged,
  });

  final _OrdenCompraDetalleDraft draft;
  final List<InsumoLookup> insumos;

  final bool canRemove;

  final VoidCallback onRemove;
  final VoidCallback onObservation;
  final VoidCallback onChanged;

  @override
  State<_DetalleRow> createState() => _DetalleRowState();
}

class _DetalleRowState extends State<_DetalleRow> {
  @override
  void initState() {
    super.initState();

    widget.draft.insumoId ??= widget.insumos.isNotEmpty
        ? widget.insumos.first.id
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    const fieldDecoration = InputDecoration(
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          /*
          ─────────────────────────────
          PRODUCTO
          ─────────────────────────────
          */
          Expanded(
            flex: 5,
            child: DropdownButtonFormField<int>(
              isExpanded: true,
              initialValue: widget.draft.insumoId,
              decoration: fieldDecoration,
              items: widget.insumos
                  .map(
                    (x) => DropdownMenuItem(
                      value: x.id,
                      child: Text(
                        x.displayName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: widget.insumos.isEmpty
                  ? null
                  : (value) {
                      setState(() {
                        widget.draft.insumoId = value;
                      });
                    },
              validator: (value) {
                return value == null ? 'Selecciona un insumo.' : null;
              },
            ),
          ),

          const Gap(10),

          /*
          ─────────────────────────────
          CANTIDAD
          ─────────────────────────────
          */
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: widget.draft.cantidadController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: fieldDecoration.copyWith(hintText: '0'),
              onChanged: (_) {
                widget.onChanged();
              },
              validator: (value) {
                final number = double.tryParse(
                  (value ?? '').trim().replaceAll(',', '.'),
                );

                if (number == null || number <= 0) {
                  return 'Cantidad inválida';
                }

                return null;
              },
            ),
          ),

          const Gap(10),

          /*
          ─────────────────────────────
          COSTO
          ─────────────────────────────
          */
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: widget.draft.costoController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: fieldDecoration.copyWith(
                prefixText: 'S/ ',
                hintText: '0.00',
              ),
              onChanged: (_) {
                widget.onChanged();
              },
              validator: (value) {
                final text = (value ?? '').trim();

                if (text.isEmpty) {
                  return null;
                }

                final number = double.tryParse(text.replaceAll(',', '.'));

                if (number == null || number < 0) {
                  return 'Costo inválido';
                }

                return null;
              },
            ),
          ),

          const Gap(8),

          /*
          ─────────────────────────────
          OBSERVACIÓN
          ─────────────────────────────
          */
          SizedBox(
            width: 52,
            child: Center(
              child: IconButton(
                tooltip: widget.draft.observacionController.text.trim().isEmpty
                    ? 'Agregar observación'
                    : 'Editar observación',
                onPressed: widget.onObservation,
                icon: Icon(
                  widget.draft.observacionController.text.trim().isEmpty
                      ? Icons.note_add_outlined
                      : Icons.sticky_note_2_outlined,
                  size: 21,
                ),
              ),
            ),
          ),

          /*
          ─────────────────────────────
          ELIMINAR
          ─────────────────────────────
          */
          SizedBox(
            width: 58,
            child: Center(
              child: IconButton(
                tooltip: 'Eliminar producto',
                onPressed: widget.canRemove ? widget.onRemove : null,
                icon: Icon(
                  Icons.delete_outline,
                  size: 21,
                  color: widget.canRemove ? theme.colorScheme.error : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/*
══════════════════════════════════════════
MODELO TEMPORAL DE FILA
══════════════════════════════════════════
*/

class _OrdenCompraDetalleDraft {
  int? insumoId;

  final cantidadController = TextEditingController();

  final costoController = TextEditingController();

  final observacionController = TextEditingController();

  void dispose() {
    cantidadController.dispose();
    costoController.dispose();
    observacionController.dispose();
  }
}
