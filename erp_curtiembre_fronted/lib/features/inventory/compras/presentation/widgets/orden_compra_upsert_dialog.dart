import 'dart:math' as math;

import 'package:erp_curtiembre_fronted/features/inventory/compras/domain/repositories/compras_repository.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/domain/entities/insumo_lookup.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/domain/entities/proveedor_lookup.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ============================================================
// COLORES DEL FORMULARIO
// ============================================================

const Color _accent = Color(0xFFE8590C);
const Color _accentSoft = Color(0xFFFFEADF);

// ============================================================
// DATOS QUE SE ENVIAN A COMPRAS PAGE
// SE CONSERVA EL CONTRATO ORIGINAL
// ============================================================

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

// ============================================================
// DIALOGO NUEVA ORDEN DE COMPRA
// ============================================================

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

  bool _attemptedSubmit = false;

  final List<_OrdenCompraDetalleDraft> _detalles = [];

  // ==========================================================
  // INICIALIZACION
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _proveedorId = widget.proveedores.isNotEmpty
        ? widget.proveedores.first.id
        : null;

    _detalles.add(_createDraft());
  }

  _OrdenCompraDetalleDraft _createDraft() {
    return _OrdenCompraDetalleDraft(
      insumoId: widget.insumos.isNotEmpty ? widget.insumos.first.id : null,
    );
  }

  // ==========================================================
  // LIBERAR RECURSOS
  // ==========================================================

  @override
  void dispose() {
    _observacionController.dispose();

    for (final draft in _detalles) {
      draft.dispose();
    }

    super.dispose();
  }

  // ==========================================================
  // FECHA DE EMISION
  // ==========================================================

  Future<void> _pickDate() async {
    if (widget.isSubmitting) return;

    final selected = await showDatePicker(
      context: context,
      initialDate: _fechaEmision,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
      helpText: 'Selecciona la fecha de emisión',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );

    if (selected == null || !mounted) return;

    setState(() {
      _fechaEmision = selected;
    });
  }

  // ==========================================================
  // AGREGAR PRODUCTO
  // ==========================================================

  void _addDetail() {
    if (widget.isSubmitting) return;

    setState(() {
      _detalles.add(_createDraft());
    });
  }

  // ==========================================================
  // ELIMINAR PRODUCTO
  // ==========================================================

  void _removeDetail(_OrdenCompraDetalleDraft draft) {
    if (widget.isSubmitting || _detalles.length <= 1) {
      return;
    }

    setState(() {
      _detalles.remove(draft);
    });

    // Se liberan los controladores después de retirar la fila
    // del árbol de widgets para evitar errores de TextField.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      draft.dispose();
    });
  }

  // ==========================================================
  // TOTAL ESTIMADO
  // CANTIDAD x COSTO UNITARIO DE CADA PRODUCTO
  // ==========================================================

  double get _total {
    return _detalles.fold<double>(0, (total, draft) {
      final cantidad = _parseNumber(draft.cantidadController.text) ?? 0;

      final costo = _parseNumber(draft.costoController.text) ?? 0;

      return total + (cantidad * costo);
    });
  }

  double? _parseNumber(String value) {
    final normalized = value.trim().replaceAll(',', '.');

    if (normalized.isEmpty) return null;

    final parsed = double.tryParse(normalized);

    if (parsed == null || !parsed.isFinite) {
      return null;
    }

    return parsed;
  }

  // ==========================================================
  // OBSERVACION INDIVIDUAL DEL PRODUCTO
  // ==========================================================

  Future<void> _editObservation(_OrdenCompraDetalleDraft draft) async {
    if (widget.isSubmitting) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final colors = Theme.of(dialogContext).colorScheme;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Row(
            children: [
              Icon(Icons.sticky_note_2_outlined, color: _accent),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Observación del producto',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: TextFormField(
              controller: draft.observacionController,
              autofocus: true,
              maxLength: 300,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Escribe una observación para este producto...',
                alignLabelWithHint: true,
                filled: true,
                fillColor: colors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: const BorderSide(color: _accent, width: 1.5),
                ),
              ),
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
              ),
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

  // ==========================================================
  // CREAR ORDEN
  // ==========================================================

  void _submit() {
    if (widget.isSubmitting) return;

    setState(() {
      _attemptedSubmit = true;
    });

    final formValid = _formKey.currentState?.validate() ?? false;

    final providerValid = _proveedorId != null;

    final productsValid = _detalles.every((draft) => draft.insumoId != null);

    if (!formValid || !providerValid || !productsValid) {
      return;
    }

    final mapped = _detalles
        .map((draft) {
          final cantidad = _parseNumber(draft.cantidadController.text)!;

          final costo = _parseNumber(draft.costoController.text);

          final observacion = draft.observacionController.text.trim();

          return CreateOrdenCompraDetalleInput(
            insumoId: draft.insumoId!,
            cantidadSolicitada: cantidad,
            costoUnitarioEstimado: costo,
            observacion: observacion.isEmpty ? null : observacion,
          );
        })
        .toList(growable: false);

    final observacionGeneral = _observacionController.text.trim();

    Navigator.of(context).pop(
      OrdenCompraUpsertFormData(
        proveedorId: _proveedorId!,
        fechaEmision: _fechaEmision,
        observacion: observacionGeneral.isEmpty ? null : observacionGeneral,
        detalles: mapped,
      ),
    );
  }

  // ==========================================================
  // VISTA PRINCIPAL
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final colors = Theme.of(context).colorScheme;

    final mobile = screen.width < 760;

    final maxDialogHeight = (screen.height * 0.92)
        .clamp(320.0, 900.0)
        .toDouble();

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: mobile ? 10 : 25,
        vertical: mobile ? 10 : 20,
      ),
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 1080, maxHeight: maxDialogHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ==============================================
            // ENCABEZADO
            // ==============================================
            _buildHeader(context, mobile),

            // ==============================================
            // FORMULARIO DESPLAZABLE
            // ==============================================
            Flexible(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    mobile ? 14 : 25,
                    8,
                    mobile ? 14 : 25,
                    18,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // PROVEEDOR Y FECHA
                      _buildGeneralFields(context),

                      const SizedBox(height: 17),

                      // OBSERVACION GENERAL
                      _buildGeneralObservation(context),

                      const SizedBox(height: 20),

                      Divider(color: colors.outlineVariant),

                      const SizedBox(height: 12),

                      // TITULO DE PRODUCTOS
                      _buildDetailTitle(context),

                      const SizedBox(height: 12),

                      // TABLA DE PRODUCTOS
                      _buildProductsTable(context),
                    ],
                  ),
                ),
              ),
            ),

            // ==============================================
            // TOTAL Y BOTONES FIJOS
            // ==============================================
            _buildFooter(context, mobile),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // ENCABEZADO
  // ==========================================================

  Widget _buildHeader(BuildContext context, bool mobile) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        mobile ? 14 : 25,
        mobile ? 15 : 20,
        mobile ? 10 : 17,
        12,
      ),
      child: Row(
        children: [
          Container(
            width: mobile ? 43 : 49,
            height: mobile ? 43 : 49,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? _accent.withValues(alpha: 0.16)
                  : _accentSoft,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.shopping_cart_checkout_rounded,
              color: _accent,
              size: 25,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nueva orden de compra',
                  style: TextStyle(
                    fontSize: mobile ? 19 : 23,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Registra los productos y genera una nueva orden de compra.',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            tooltip: 'Cerrar',
            onPressed: widget.isSubmitting
                ? null
                : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, size: 21),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // PROVEEDOR Y FECHA
  // ==========================================================

  Widget _buildGeneralFields(BuildContext context) {
    final providerField = _buildProviderField(context);
    final dateField = _buildDateField(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 650) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [providerField, const SizedBox(height: 14), dateField],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 6, child: providerField),
            const SizedBox(width: 16),
            Expanded(flex: 4, child: dateField),
          ],
        );
      },
    );
  }

  // ==========================================================
  // PROVEEDOR BUSCABLE
  // ==========================================================

  Widget _buildProviderField(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return _FieldLabel(
      label: 'Proveedor',
      requiredField: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownMenu<int>(
                width: constraints.maxWidth,
                menuHeight: 300,
                enableFilter: true,
                enableSearch: true,
                requestFocusOnTap: true,
                enabled: widget.proveedores.isNotEmpty && !widget.isSubmitting,
                initialSelection: _proveedorId,
                hintText: widget.proveedores.isEmpty
                    ? 'No hay proveedores disponibles'
                    : 'Seleccionar proveedor',
                leadingIcon: const Icon(
                  Icons.local_shipping_outlined,
                  size: 19,
                ),
                inputDecorationTheme: _dropdownTheme(context),
                dropdownMenuEntries: widget.proveedores
                    .map(
                      (provider) => DropdownMenuEntry<int>(
                        value: provider.id,
                        label: provider.displayName,
                      ),
                    )
                    .toList(growable: false),
                onSelected: (value) {
                  setState(() {
                    _proveedorId = value;
                  });
                },
              ),

              if (_attemptedSubmit && _proveedorId == null) ...[
                const SizedBox(height: 5),
                Text(
                  'Selecciona un proveedor.',
                  style: TextStyle(color: colors.error, fontSize: 11),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  // ==========================================================
  // FECHA
  // ==========================================================

  Widget _buildDateField(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return _FieldLabel(
      label: 'Fecha de emisión',
      requiredField: true,
      child: InkWell(
        onTap: widget.isSubmitting ? null : _pickDate,
        borderRadius: BorderRadius.circular(9),
        child: InputDecorator(
          decoration: _decoration(context, hint: ''),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat('dd/MM/yyyy').format(_fechaEmision),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.calendar_month_outlined,
                size: 20,
                color: colors.onSurface,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // OBSERVACION GENERAL
  // ==========================================================

  Widget _buildGeneralObservation(BuildContext context) {
    return _FieldLabel(
      label: 'Observación general',
      child: TextFormField(
        controller: _observacionController,
        maxLength: 500,
        minLines: 2,
        maxLines: 3,
        enabled: !widget.isSubmitting,
        textCapitalization: TextCapitalization.sentences,
        decoration: _decoration(
          context,
          hint: 'Escribe una observación general...',
        ),
      ),
    );
  }

  // ==========================================================
  // TITULO DEL DETALLE
  // ==========================================================

  Widget _buildDetailTitle(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        const Icon(Icons.receipt_long_outlined, size: 21, color: _accent),

        const SizedBox(width: 9),

        const Expanded(
          child: Text(
            'Detalle de la compra',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ),

        Text(
          '${_detalles.length} '
          '${_detalles.length == 1 ? 'producto' : 'productos'}',
          style: TextStyle(fontSize: 11.5, color: colors.onSurfaceVariant),
        ),
      ],
    );
  }

  // ==========================================================
  // TABLA DE PRODUCTOS
  // ==========================================================

  Widget _buildProductsTable(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: math.max(810.0, constraints.maxWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // CABECERA
                  _buildTableHeader(context),

                  // FILAS
                  if (_detalles.length <= 5)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final draft in _detalles)
                          _buildProductRow(context, draft),
                      ],
                    )
                  else
                    SizedBox(
                      height: 345,
                      child: ListView.builder(
                        itemCount: _detalles.length,
                        itemBuilder: (context, index) {
                          final draft = _detalles[index];

                          return _buildProductRow(context, draft);
                        },
                      ),
                    ),

                  // AGREGAR PRODUCTO
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: widget.isSubmitting ? null : _addDetail,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _accent,
                          side: BorderSide(
                            color: _accent.withValues(alpha: 0.45),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text(
                          'Agregar producto',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================================
  // ENCABEZADO DE LA TABLA
  // ==========================================================

  Widget _buildTableHeader(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    Widget header(String label) {
      return Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: colors.onSurfaceVariant,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      color: colors.surfaceContainerLow,
      child: Row(
        children: [
          Expanded(flex: 5, child: header('Producto *')),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: header('Cantidad *')),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: header('Costo estimado')),
          const SizedBox(width: 10),
          SizedBox(width: 51, child: Center(child: header('Obs.'))),
          SizedBox(width: 51, child: Center(child: header('Acción'))),
        ],
      ),
    );
  }

  // ==========================================================
  // FILA DE PRODUCTO
  // ==========================================================

  Widget _buildProductRow(
    BuildContext context,
    _OrdenCompraDetalleDraft draft,
  ) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      key: ObjectKey(draft),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ============================================
          // PRODUCTO BUSCABLE
          // ============================================
          Expanded(
            flex: 5,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownMenu<int>(
                      key: ValueKey(draft),
                      width: constraints.maxWidth,
                      menuHeight: 280,
                      enableFilter: true,
                      enableSearch: true,
                      requestFocusOnTap: true,
                      enabled:
                          widget.insumos.isNotEmpty && !widget.isSubmitting,
                      initialSelection: draft.insumoId,
                      hintText: widget.insumos.isEmpty
                          ? 'Sin insumos disponibles'
                          : 'Seleccionar producto',
                      inputDecorationTheme: _dropdownTheme(context),
                      dropdownMenuEntries: widget.insumos
                          .map(
                            (insumo) => DropdownMenuEntry<int>(
                              value: insumo.id,
                              label: insumo.displayName,
                            ),
                          )
                          .toList(growable: false),
                      onSelected: (value) {
                        setState(() {
                          draft.insumoId = value;
                        });
                      },
                    ),

                    if (_attemptedSubmit && draft.insumoId == null) ...[
                      const SizedBox(height: 5),
                      Text(
                        'Selecciona un producto.',
                        style: TextStyle(fontSize: 10.5, color: colors.error),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),

          const SizedBox(width: 12),

          // ============================================
          // CANTIDAD
          // ============================================
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: draft.cantidadController,
              enabled: !widget.isSubmitting,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: _decoration(context, hint: '0'),
              onChanged: (_) => setState(() {}),
              validator: (value) {
                final cantidad = _parseNumber(value ?? '');

                if (cantidad == null || cantidad <= 0) {
                  return 'Cantidad inválida';
                }

                return null;
              },
            ),
          ),

          const SizedBox(width: 12),

          // ============================================
          // COSTO UNITARIO ESTIMADO
          // ============================================
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: draft.costoController,
              enabled: !widget.isSubmitting,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: _decoration(
                context,
                hint: '0.00',
              ).copyWith(prefixText: 'S/ '),
              onChanged: (_) => setState(() {}),
              validator: (value) {
                final text = value?.trim() ?? '';

                // Se conserva el costo opcional del
                // contrato original del repositorio.
                if (text.isEmpty) return null;

                final costo = _parseNumber(text);

                if (costo == null || costo < 0) {
                  return 'Costo inválido';
                }

                return null;
              },
            ),
          ),

          const SizedBox(width: 10),

          // ============================================
          // OBSERVACION
          // ============================================
          SizedBox(
            width: 51,
            child: IconButton.outlined(
              tooltip: draft.observacionController.text.trim().isEmpty
                  ? 'Agregar observación'
                  : 'Editar observación',
              visualDensity: VisualDensity.compact,
              onPressed: widget.isSubmitting
                  ? null
                  : () => _editObservation(draft),
              icon: Icon(
                draft.observacionController.text.trim().isEmpty
                    ? Icons.note_add_outlined
                    : Icons.sticky_note_2_outlined,
                size: 19,
                color: _accent,
              ),
            ),
          ),

          // ============================================
          // ELIMINAR
          // ============================================
          SizedBox(
            width: 51,
            child: IconButton.outlined(
              tooltip: 'Eliminar producto',
              visualDensity: VisualDensity.compact,
              onPressed: widget.isSubmitting || _detalles.length <= 1
                  ? null
                  : () => _removeDetail(draft),
              icon: Icon(
                Icons.delete_outline_rounded,
                size: 19,
                color: _detalles.length > 1
                    ? colors.error
                    : colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // PIE FIJO
  // ==========================================================

  Widget _buildFooter(BuildContext context, bool mobile) {
    final colors = Theme.of(context).colorScheme;

    final totalWidget = Wrap(
      spacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          'Total estimado:',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
        ),
        Text(
          NumberFormat.currency(
            locale: 'es_PE',
            symbol: 'S/ ',
            decimalDigits: 2,
          ).format(_total),
          style: const TextStyle(
            color: _accent,
            fontSize: 19,
            fontWeight: FontWeight.w800,
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
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          ),
          child: const Text('Cancelar'),
        ),

        const SizedBox(width: 11),

        FilledButton.icon(
          onPressed: widget.isSubmitting ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          ),
          icon: widget.isSubmitting
              ? const SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.shopping_cart_checkout_outlined, size: 19),
          label: const Text(
            'Crear orden',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: mobile ? 14 : 25, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 610) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                totalWidget,
                const SizedBox(height: 12),
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
    );
  }

  // ==========================================================
  // DECORACION GENERAL
  // ==========================================================

  InputDecoration _decoration(BuildContext context, {required String hint}) {
    final colors = Theme.of(context).colorScheme;

    return InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
      filled: true,
      fillColor: colors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide(color: colors.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: _accent, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide(color: colors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide(color: colors.error, width: 1.4),
      ),
    );
  }

  InputDecorationTheme _dropdownTheme(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: colors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide(color: colors.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: _accent, width: 1.4),
      ),
    );
  }
}

// ============================================================
// ETIQUETA DE CAMPO
// ============================================================

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.label,
    required this.child,
    this.requiredField = false,
  });

  final String label;
  final Widget child;
  final bool requiredField;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            if (requiredField) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(color: _accent, fontWeight: FontWeight.w800),
              ),
            ],
          ],
        ),

        const SizedBox(height: 7),

        child,
      ],
    );
  }
}

// ============================================================
// MODELO TEMPORAL DE CADA PRODUCTO
// ============================================================

class _OrdenCompraDetalleDraft {
  _OrdenCompraDetalleDraft({this.insumoId});

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
