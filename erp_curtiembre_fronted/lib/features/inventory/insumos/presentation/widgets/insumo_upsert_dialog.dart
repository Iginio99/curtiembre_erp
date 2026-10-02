import 'package:erp_curtiembre_fronted/features/inventory/insumos/domain/constants/insumo_tipo_bien_options.dart';
import 'package:erp_curtiembre_fronted/features/inventory/insumos/domain/entities/insumo_record.dart';
import 'package:erp_curtiembre_fronted/features/inventory/insumos/domain/entities/unidad_medida_option.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============================================================
// COLORES
// ============================================================

const Color _accent = Color(0xFFE8590C);
const Color _accentSoft = Color(0xFFFFEADF);
const Color _textMuted = Color(0xFF737985);

// ============================================================
// DATOS DEL FORMULARIO
// SE CONSERVA EL CONTRATO ORIGINAL
// ============================================================

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

// ============================================================
// DIALOGO CREAR / EDITAR INSUMO
// ============================================================

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

  bool _unitError = false;

  bool get _isEditing => widget.initialInsumo != null;

  // ==========================================================
  // INICIALIZACION
  // ==========================================================

  @override
  void initState() {
    super.initState();

    final insumo = widget.initialInsumo;

    _codigoController = TextEditingController(text: insumo?.codigo ?? '');

    _nombreController = TextEditingController(text: insumo?.nombre ?? '');

    _presentacionController = TextEditingController(
      text: insumo?.presentacion ?? '',
    );

    _stockMinimoController = TextEditingController(
      text: insumo == null ? '' : insumo.stockMinimo.toStringAsFixed(2),
    );

    _tipoBien = insumo?.tipoBien ?? inventoryInsumoTipoBienOptions.first.value;

    _unidadMedidaId =
        insumo?.unidadMedidaId ??
        (widget.unitOptions.isNotEmpty ? widget.unitOptions.first.id : null);

    _requiereLote = insumo?.requiereLote ?? false;
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _presentacionController.dispose();
    _stockMinimoController.dispose();

    super.dispose();
  }

  // ==========================================================
  // GUARDAR DATOS
  // ==========================================================

  void _submit() {
    if (widget.isSubmitting) return;

    final valid = _formKey.currentState?.validate() ?? false;

    setState(() {
      _unitError = _unidadMedidaId == null;
    });

    if (!valid || _unitError) return;

    final normalizedStock = _stockMinimoController.text.trim().replaceAll(
      ',',
      '.',
    );

    Navigator.of(context).pop(
      InsumoUpsertFormData(
        codigo: _codigoController.text.trim(),
        nombre: _nombreController.text.trim(),
        tipoBien: _tipoBien,
        unidadMedidaId: _unidadMedidaId!,
        stockMinimo: double.parse(normalizedStock),
        requiereLote: _requiereLote,
        presentacion: _normalizeOptional(_presentacionController.text),
      ),
    );
  }

  String? _normalizeOptional(String value) {
    final normalized = value.trim();

    return normalized.isEmpty ? null : normalized;
  }

  // ==========================================================
  // DIALOGO PRINCIPAL
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screen = MediaQuery.sizeOf(context);

    final compact = screen.width < 850;

    final dialogWidth = compact ? 620.0 : 980.0;

    final dialogHeight = (screen.height * 0.91).clamp(300.0, 850.0);

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 28,
        vertical: compact ? 12 : 22,
      ),
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(19),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: dialogHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ================================================
            // ENCABEZADO
            // ================================================
            _buildHeader(context, compact),

            // ================================================
            // FORMULARIO DESPLAZABLE
            // ================================================
            Flexible(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    compact ? 16 : 25,
                    5,
                    compact ? 16 : 25,
                    20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildGeneralSection(context, compact),

                      const SizedBox(height: 17),

                      _buildInventorySection(context, compact),
                    ],
                  ),
                ),
              ),
            ),

            // ================================================
            // PIE FIJO DEL FORMULARIO
            // ================================================
            _buildFooter(context, compact),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // ENCABEZADO
  // ==========================================================

  Widget _buildHeader(BuildContext context, bool compact) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 25,
        compact ? 16 : 24,
        compact ? 12 : 20,
        16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: compact ? 46 : 53,
            height: compact ? 46 : 53,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _accentSoft,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              _isEditing ? Icons.edit_note_rounded : Icons.inventory_2_outlined,
              color: _accent,
              size: compact ? 23 : 27,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: compact ? 21 : 25,
                    letterSpacing: -0.6,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  _isEditing
                      ? 'Actualiza la información operativa del insumo.'
                      : 'Registra un nuevo insumo en el inventario.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            tooltip: 'Cerrar formulario',
            onPressed: widget.isSubmitting
                ? null
                : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, size: 23),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.surfaceContainerLow,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SECCION INFORMACION GENERAL
  // ==========================================================

  Widget _buildGeneralSection(BuildContext context, bool compact) {
    final nameField = _buildNameField();

    final codeField = _buildAutomaticCodeField();

    final typeField = _buildTypeDropdown();

    final unitField = _buildUnitDropdown();

    return _FormSection(
      icon: Icons.folder_open_outlined,
      title: 'Información general',
      subtitle: 'Datos principales del insumo.',
      child: Column(
        children: [
          _responsivePair(
            compact: compact,
            first: nameField,
            second: codeField,
          ),

          const SizedBox(height: 15),

          _responsivePair(
            compact: compact,
            first: typeField,
            second: unitField,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SECCION CONTROL DE INVENTARIO
  // ==========================================================

  Widget _buildInventorySection(BuildContext context, bool compact) {
    return _FormSection(
      icon: Icons.bar_chart_rounded,
      title: 'Control de inventario',
      subtitle: 'Configuración operativa y de stock.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _responsivePair(
            compact: compact,
            first: _buildMinimumStockField(),
            second: _buildPresentationField(),
          ),

          const SizedBox(height: 17),

          _buildBatchControl(),
        ],
      ),
    );
  }

  // ==========================================================
  // DISTRIBUCION RESPONSIVE DE CAMPOS
  // ==========================================================

  Widget _responsivePair({
    required bool compact,
    required Widget first,
    required Widget second,
  }) {
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [first, const SizedBox(height: 15), second],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: first),

        const SizedBox(width: 17),

        Expanded(child: second),
      ],
    );
  }

  // ==========================================================
  // CAMPO NOMBRE
  // ==========================================================

  Widget _buildNameField() {
    return _FieldBlock(
      label: 'Nombre del insumo',
      requiredField: true,
      helper: 'Nombre con el que se identificará en el catálogo.',
      child: TextFormField(
        controller: _nombreController,
        maxLength: 150,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.next,
        decoration: _inputDecoration(
          hint: 'Ej. Sulfuro de Sodio',
          icon: Icons.sell_outlined,
        ).copyWith(counterText: ''),
        validator: (value) {
          final name = value?.trim() ?? '';

          if (name.isEmpty) {
            return 'Ingresa el nombre del insumo.';
          }

          return null;
        },
      ),
    );
  }

  // ==========================================================
  // CODIGO AUTOMATICO (CONSERVA LA LOGICA ORIGINAL)
  // ==========================================================

  Widget _buildAutomaticCodeField() {
    return _FieldBlock(
      label: 'Código',
      helper: _isEditing
          ? 'Identificador del registro.'
          : 'Se asigna automáticamente al crear el insumo.',
      child: TextFormField(
        controller: _codigoController,
        readOnly: true,
        enabled: true,
        decoration:
            _inputDecoration(
              hint: _isEditing ? 'Código del insumo' : 'Asignación automática',
              icon: Icons.tag_rounded,
            ).copyWith(
              suffixIcon: Tooltip(
                message: 'Código gestionado por el sistema',
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 19,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
      ),
    );
  }

  // ==========================================================
  // TIPO DE BIEN CON BUSQUEDA
  // ==========================================================

  Widget _buildTypeDropdown() {
    return _FieldBlock(
      label: 'Tipo de bien',
      requiredField: true,
      helper: 'Clasificación dentro del inventario.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          return DropdownMenu<String>(
            key: ValueKey(_tipoBien),
            width: constraints.maxWidth,
            menuHeight: 270,
            enableFilter: true,
            enableSearch: true,
            requestFocusOnTap: true,
            initialSelection: _tipoBien,
            leadingIcon: const Icon(Icons.category_outlined, size: 20),
            inputDecorationTheme: _dropdownDecoration(context),
            dropdownMenuEntries: inventoryInsumoTipoBienOptions
                .map(
                  (option) => DropdownMenuEntry<String>(
                    value: option.value,
                    label: option.label,
                  ),
                )
                .toList(growable: false),
            onSelected: (value) {
              if (value == null) return;

              setState(() {
                _tipoBien = value;
              });
            },
          );
        },
      ),
    );
  }

  // ==========================================================
  // UNIDAD DE MEDIDA CON BUSQUEDA
  // ==========================================================

  Widget _buildUnitDropdown() {
    return _FieldBlock(
      label: 'Unidad de medida',
      requiredField: true,
      helper: 'Unidad en la que se registra y controla.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownMenu<int>(
                key: ValueKey(_unidadMedidaId ?? '__none__'),
                width: constraints.maxWidth,
                menuHeight: 270,
                enableFilter: true,
                enableSearch: true,
                requestFocusOnTap: true,
                enabled: widget.unitOptions.isNotEmpty,
                initialSelection: _unidadMedidaId,
                leadingIcon: const Icon(Icons.straighten_rounded, size: 20),
                hintText: widget.unitOptions.isEmpty
                    ? 'No hay unidades disponibles'
                    : 'Seleccionar unidad',
                inputDecorationTheme: _dropdownDecoration(context),
                dropdownMenuEntries: widget.unitOptions
                    .map(
                      (option) => DropdownMenuEntry<int>(
                        value: option.id,
                        label: option.displayName,
                      ),
                    )
                    .toList(growable: false),
                onSelected: (value) {
                  setState(() {
                    _unidadMedidaId = value;
                    _unitError = value == null;
                  });
                },
              ),

              if (_unitError) ...[
                const SizedBox(height: 5),
                Text(
                  'Selecciona una unidad de medida.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  // ==========================================================
  // STOCK MINIMO
  // ==========================================================

  Widget _buildMinimumStockField() {
    return _FieldBlock(
      label: 'Stock mínimo',
      requiredField: true,
      helper: 'Cantidad mínima para alertas de stock.',
      child: TextFormField(
        controller: _stockMinimoController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.next,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        ],
        decoration: _inputDecoration(
          hint: 'Ej. 20.00',
          icon: Icons.inventory_2_outlined,
        ),
        validator: (value) {
          final normalized = value?.trim().replaceAll(',', '.') ?? '';

          if (normalized.isEmpty) {
            return 'Ingresa el stock mínimo.';
          }

          final stock = double.tryParse(normalized);

          if (stock == null || !stock.isFinite || stock < 0) {
            return 'Ingresa un stock mínimo válido.';
          }

          return null;
        },
      ),
    );
  }

  // ==========================================================
  // PRESENTACION
  // ==========================================================

  Widget _buildPresentationField() {
    return _FieldBlock(
      label: 'Presentación',
      helper: 'Formato o presentación comercial (opcional).',
      child: TextFormField(
        controller: _presentacionController,
        maxLength: 150,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        decoration: _inputDecoration(
          hint: 'Ej. Saco de 25 kg',
          icon: Icons.widgets_outlined,
        ).copyWith(counterText: ''),
        onFieldSubmitted: (_) => _submit(),
      ),
    );
  }

  // ==========================================================
  // CONTROL POR LOTE
  // ==========================================================

  Widget _buildBatchControl() {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: SwitchListTile.adaptive(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        secondary: Container(
          height: 36,
          width: 36,
          alignment: Alignment.center,
          child: const Icon(Icons.qr_code_2_rounded, size: 23, color: _accent),
        ),
        title: const Text(
          'Control por lote',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        subtitle: const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text(
            'Actívalo si el insumo requiere trazabilidad individual por lotes.',
            style: TextStyle(fontSize: 11, height: 1.4),
          ),
        ),
        value: _requiereLote,
        activeTrackColor: _accent,
        onChanged: (value) {
          setState(() {
            _requiereLote = value;
          });
        },
      ),
    );
  }

  // ==========================================================
  // PIE DEL FORMULARIO
  // ==========================================================

  Widget _buildFooter(BuildContext context, bool compact) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 16 : 25,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: widget.isSubmitting
                ? null
                : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            child: const Text('Cancelar'),
          ),

          const SizedBox(width: 12),

          FilledButton.icon(
            onPressed: widget.isSubmitting ? null : _submit,
            icon: widget.isSubmitting
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_outlined, size: 19),
            label: Text(widget.submitLabel),
            style: FilledButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _accent.withValues(alpha: 0.5),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // DECORACIONES DE LOS CAMPOS
  // ==========================================================

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12.5, color: _textMuted),
      prefixIcon: Icon(
        icon,
        size: 20,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      filled: true,
      fillColor: theme.colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 17),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: _accent, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide(color: theme.colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 1.4),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
    );
  }

  InputDecorationTheme _dropdownDecoration(BuildContext context) {
    final theme = Theme.of(context);

    return InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: theme.colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: _accent, width: 1.4),
      ),
    );
  }
}

// ============================================================
// COMPONENTE VISUAL DE SECCION
// ============================================================

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _accentSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 21, color: _accent),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          child,
        ],
      ),
    );
  }
}

// ============================================================
// ETIQUETA DE CAMPO CON TEXTO AUXILIAR
// ============================================================

class _FieldBlock extends StatelessWidget {
  const _FieldBlock({
    required this.label,
    required this.child,
    this.helper,
    this.requiredField = false,
  });

  final String label;
  final String? helper;
  final Widget child;
  final bool requiredField;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 12.5,
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

        if (helper != null) ...[
          const SizedBox(height: 6),
          Text(
            helper!,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 10.8,
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }
}
