import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/configuration/formulas/domain/entities/formula_record.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/domain/entities/insumo_lookup.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';

// ============================================================
// MODELOS
// ============================================================

class FormulaUpsertFormData {
  const FormulaUpsertFormData({
    required this.codigo,
    required this.nombre,
    required this.procesoProductivoId,
    required this.tipoProducto,
    required this.color,
    this.productoId,
    this.descripcion,
    this.detalles = const [],
  });

  final String codigo;
  final String nombre;
  final int procesoProductivoId;
  final String tipoProducto;
  final String color;
  final int? productoId;
  final String? descripcion;
  final List<FormulaRecipeLine> detalles;
}

class FormulaRecipeLine {
  const FormulaRecipeLine({
    required this.insumoId,
    required this.porcentaje,
    this.observacion,
  });

  final int insumoId;
  final double porcentaje;
  final String? observacion;
}

// ============================================================
// DIÁLOGO NUEVA FÓRMULA
// ============================================================

class FormulaUpsertDialog extends StatefulWidget {
  const FormulaUpsertDialog({
    super.key,
    required this.title,
    required this.submitLabel,
    required this.processOptions,
    required this.isSubmitting,
    required this.insumoOptions,
    this.initialFormula,
  });

  final String title;
  final String submitLabel;

  final List<ProcesoProductivoOption> processOptions;
  final List<InsumoLookup> insumoOptions;

  final bool isSubmitting;
  final FormulaRecord? initialFormula;

  @override
  State<FormulaUpsertDialog> createState() => _FormulaUpsertDialogState();
}

class _FormulaUpsertDialogState extends State<FormulaUpsertDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _codigoController;
  late final TextEditingController _nombreController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _tipoProductoController;
  late final TextEditingController _colorController;
  late final TextEditingController _productoIdController;

  int? _procesoProductivoId;

  final List<_RecipeDraft> _details = [_RecipeDraft()];

  bool get _isEditing => widget.initialFormula != null;

  // ==========================================================
  // INICIALIZACIÓN
  // ==========================================================

  @override
  void initState() {
    super.initState();

    final initial = widget.initialFormula;

    _codigoController = TextEditingController(text: initial?.codigo ?? '');

    _nombreController = TextEditingController(text: initial?.nombre ?? '');

    _descripcionController = TextEditingController(
      text: initial?.descripcion ?? '',
    );

    _tipoProductoController = TextEditingController(
      text: initial?.tipoProducto ?? '',
    );

    _colorController = TextEditingController(text: initial?.color ?? '');
    _productoIdController = TextEditingController(text: initial?.productoId?.toString() ?? '');

    // Crear: proceso vacío.
    // Editar: mantener el proceso existente.

    _procesoProductivoId = initial?.procesoProductivoId;
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _descripcionController.dispose();
    _tipoProductoController.dispose();
    _colorController.dispose();
    _productoIdController.dispose();

    for (final detail in _details) {
      detail.dispose();
    }

    super.dispose();
  }

  // ==========================================================
  // GENERACIÓN AUTOMÁTICA DEL CÓDIGO
  // ==========================================================

  String _suggestedCodeForProcess(String processCode) {
    final codigo = processCode.trim().toUpperCase();

    final prefijo = switch (codigo) {
      'REMOJO_PELAMBRE' => 'REM',
      'REMOJO-PELAMBRE' => 'REM',
      'REMOJO' => 'REM',
      'PELAMBRE' => 'PEL',
      'CURTIDO' => 'CUR',
      'RECURTIDO' => 'REC',
      'ACABADO' => 'ACA',

      // Otros procesos: primeras tres letras.
      _ =>
        codigo.isEmpty
            ? 'GEN'
            : codigo
                  .replaceAll(RegExp(r'[^A-Z0-9]'), '')
                  .padRight(3, 'X')
                  .substring(0, 3),
    };

    return 'FOR-$prefijo-01';
  }

  // ==========================================================
  // SELECCIONAR PROCESO
  // ==========================================================

  void _selectProcess(ProcesoProductivoOption option) {
    setState(() {
      _procesoProductivoId = option.id;

      // El código solo se genera al crear.
      // En edición no se modifica el código original.

      if (!_isEditing) {
        _codigoController.text = _suggestedCodeForProcess(option.codigo);
      }
    });
  }

  // ==========================================================
  // BUSCAR PROCESO INICIAL
  // ==========================================================

  ProcesoProductivoOption? _findInitialProcess() {
    for (final option in widget.processOptions) {
      if (option.id == _procesoProductivoId) {
        return option;
      }
    }

    return null;
  }

  bool get _requiresProduct => _findInitialProcess()?.codigo.toUpperCase() == 'RECURTIDO' || _findInitialProcess()?.codigo.toUpperCase() == 'ACABADO';

  // ==========================================================
  // AGREGAR INSUMO
  // ==========================================================

  void _addInsumo() {
    if (widget.isSubmitting) return;

    setState(() {
      _details.add(_RecipeDraft());
    });
  }

  // ==========================================================
  // ELIMINAR INSUMO
  // ==========================================================

  void _removeInsumo(int index) {
    if (widget.isSubmitting || _details.length <= 1) {
      return;
    }

    final removed = _details[index];

    setState(() {
      _details.removeAt(index);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      removed.dispose();
    });
  }

  // ==========================================================
  // GUARDAR FÓRMULA
  // ==========================================================

  void _submit() {
    if (widget.isSubmitting) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final procesoId = _procesoProductivoId;

    if (procesoId == null) {
      return;
    }

    final detalles = <FormulaRecipeLine>[];

    if (!_isEditing) {
      for (final detail in _details) {
        final percentage = double.tryParse(
          detail.percentage.text.trim().replaceAll(',', '.'),
        );

        if (detail.insumoId != null && percentage != null && percentage > 0) {
          detalles.add(
            FormulaRecipeLine(
              insumoId: detail.insumoId!,
              porcentaje: percentage,
              observacion: detail.note.text.trim().isEmpty
                  ? null
                  : detail.note.text.trim(),
            ),
          );
        }
      }

      if (detalles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La receta debe tener al menos un insumo.'),
          ),
        );

        return;
      }
    }

    Navigator.of(context).pop(
      FormulaUpsertFormData(
        codigo: _codigoController.text.trim(),
        nombre: _nombreController.text.trim(),
        procesoProductivoId: procesoId,
        tipoProducto: _tipoProductoController.text.trim(),

        // Color opcional.
        color: _colorController.text.trim(),
        productoId: _requiresProduct ? int.tryParse(_productoIdController.text.trim()) : null,

        descripcion: _descripcionController.text.trim().isEmpty
            ? null
            : _descripcionController.text.trim(),

        detalles: detalles,
      ),
    );
  }

  // ==========================================================
  // ESTILO DE LOS CAMPOS
  // ==========================================================

  InputDecoration _fieldDecoration({required String hint}) {
    final colors = Theme.of(context).colorScheme;

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
      filled: true,
      fillColor: colors.surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide(color: colors.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide(color: colors.primary, width: 1.3),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide(color: colors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide(color: colors.error, width: 1.3),
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);

    final dialogWidth = screen.width < 980 ? screen.width - 32 : 980.0;

    final dialogHeight = screen.height * 0.88;

    final showSidebar = dialogWidth >= 760;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showSidebar) SizedBox(width: 235, child: _buildSidebar()),

            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildInformationSection(
                              showMobileTitle: !showSidebar,
                            ),

                            if (!_isEditing) ...[
                              const Gap(AppSpacing.lg),

                              Divider(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outlineVariant,
                              ),

                              const Gap(AppSpacing.md),

                              _buildRecipeSection(),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  _buildFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // PANEL IZQUIERDO
  // ==========================================================

  Widget _buildSidebar() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(25, 28, 25, 26),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? const Color(0xFF33261F)
            : const Color(0xFFFFF5EF),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PROBETA NARANJA
          Container(
            width: 90,
            height: 90,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE5D5),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.science_outlined,
              size: 47,
              color: Color(0xFFE8590C),
            ),
          ),

          const Gap(25),

          Text(
            widget.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),

          const Gap(12),

          Text(
            _isEditing
                ? 'Actualiza la información de la fórmula.'
                : 'Registra la información de la fórmula y agrega los insumos que la componen.',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          const Gap(28),

          Divider(color: theme.colorScheme.primary.withValues(alpha: 0.18)),

          const Spacer(),

          // DECORACIÓN INFERIOR
          Container(
            width: 140,
            height: 140,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFFFE9DD),
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 95,
                  height: 108,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.format_list_bulleted_rounded,
                    color: Color(0xFFD3C6BE),
                    size: 58,
                  ),
                ),

                Positioned(
                  right: 4,
                  bottom: 1,
                  child: Container(
                    width: 37,
                    height: 37,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8590C),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Gap(28),
        ],
      ),
    );
  }

  // ==========================================================
  // INFORMACIÓN DE LA FÓRMULA
  // ==========================================================

  Widget _buildInformationSection({required bool showMobileTitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showMobileTitle) ...[
          Text(
            widget.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),

          const Gap(AppSpacing.md),
        ],

        Row(
          children: [
            const Expanded(
              child: _SectionHeading(title: 'Información de la fórmula'),
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

        const Gap(AppSpacing.md),

        // ======================================================
        // CÓDIGO AUTOMÁTICO
        // ======================================================
        const _FormLabel(text: 'Código', requiredField: true),

        const Gap(6),

        TextFormField(
          controller: _codigoController,
          style: const TextStyle(fontSize: 13),

          textCapitalization: TextCapitalization.characters,

          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9-]')),
            UpperCaseTextFormatter(),
          ],

          decoration: _fieldDecoration(
            hint: 'Selecciona un proceso para generar el código',
          ).copyWith(suffixIcon: const Icon(Icons.tag_rounded, size: 17)),

          validator: (value) {
            return (value?.trim() ?? '').isEmpty ? 'Ingresa un código.' : null;
          },
        ),

        const Gap(AppSpacing.md),

        // El producto solo aplica a Recurtido y Acabado. En Remojo/Pelambre y
        // Curtido la fórmula es general y se registra únicamente por nombre.
        if (_requiresProduct) ...[
        const _FormLabel(text: 'ID del producto', requiredField: true),
        const Gap(6),
        TextFormField(
          controller: _productoIdController,
          keyboardType: TextInputType.number,
          decoration: _fieldDecoration(hint: 'Selecciona el ID del producto registrado'),
          validator: (value) => int.tryParse(value?.trim() ?? '') == null ? 'Selecciona un producto.' : null,
        ),
        const Gap(AppSpacing.md),
        ],
        if (false) LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth >= 430;

            final product = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _FormLabel(text: 'Tipo de producto', requiredField: true),

                const Gap(6),

                TextFormField(
                  controller: _tipoProductoController,
                  style: const TextStyle(fontSize: 13),
                  decoration: _fieldDecoration(hint: 'Ej. Graso, napa, gamuza'),
                  validator: (value) {
                    return (value?.trim() ?? '').isEmpty
                        ? 'Ingresa el tipo de producto.'
                        : null;
                  },
                ),
              ],
            );

            // COLOR OPCIONAL

            final color = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _FormLabel(text: 'Color', requiredField: false),

                const Gap(6),

                TextFormField(
                  controller: _colorController,
                  style: const TextStyle(fontSize: 13),
                  decoration: _fieldDecoration(hint: 'Ej. Negro (opcional)'),
                ),
              ],
            );

            if (!twoColumns) {
              return Column(
                children: [product, const Gap(AppSpacing.md), color],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: product),

                const Gap(AppSpacing.md),

                Expanded(child: color),
              ],
            );
          },
        ),

        const Gap(AppSpacing.md),

        // ======================================================
        // NOMBRE
        // ======================================================
        const _FormLabel(text: 'Nombre', requiredField: true),

        const Gap(6),

        TextFormField(
          controller: _nombreController,
          style: const TextStyle(fontSize: 13),
          decoration: _fieldDecoration(hint: 'Ingresa el nombre de la fórmula'),
          validator: (value) {
            return (value?.trim() ?? '').isEmpty ? 'Ingresa un nombre.' : null;
          },
        ),

        const Gap(AppSpacing.md),

        // ======================================================
        // PROCESO PRODUCTIVO CON BÚSQUEDA DINÁMICA
        // ======================================================
        const _FormLabel(text: 'Proceso productivo', requiredField: true),

        const Gap(6),

        _SearchableDropdown<ProcesoProductivoOption>(
          key: ValueKey('proceso_${widget.initialFormula?.id ?? 'nuevo'}'),

          options: widget.processOptions,

          hint: 'Escribe para buscar un proceso...',

          displayStringForOption: (option) => option.displayName,

          searchStringForOption: (option) =>
              '${option.codigo} ${option.displayName}',

          initialOption: _findInitialProcess(),

          enabled: !widget.isSubmitting,

          validator: () {
            return _procesoProductivoId == null
                ? 'Selecciona un proceso.'
                : null;
          },

          onTextChanged: (value) {
            if (_procesoProductivoId != null) {
              setState(() {
                _procesoProductivoId = null;

                // No borrar el código durante la edición.
                if (!_isEditing) {
                  _codigoController.clear();
                }
              });
            }
          },

          // Al seleccionar, generar el código.
          onSelected: (option) {
            _selectProcess(option);
          },
        ),

        const Gap(AppSpacing.md),

        // ======================================================
        // DESCRIPCIÓN
        // ======================================================
        const _FormLabel(text: 'Descripción'),

        const Gap(6),

        TextFormField(
          controller: _descripcionController,
          style: const TextStyle(fontSize: 13),
          minLines: 2,
          maxLines: 3,
          decoration: _fieldDecoration(
            hint: 'Agrega una descripción (opcional)',
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // INSUMOS DE LA RECETA
  // ==========================================================

  Widget _buildRecipeSection() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: _SectionHeading(title: 'Insumos de la receta'),
            ),

            TextButton.icon(
              onPressed: widget.isSubmitting ? null : _addInsumo,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Agregar insumo'),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
              ),
            ),
          ],
        ),

        const Gap(AppSpacing.md),

        ...List.generate(_details.length, (index) {
          return Padding(
            key: ValueKey(_details[index]),
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _buildRecipeRow(index),
          );
        }),
      ],
    );
  }

  // ==========================================================
  // FILA DE INSUMO
  // ==========================================================

  Widget _buildRecipeRow(int index) {
    final detail = _details[index];

    // INSUMO CON BÚSQUEDA DINÁMICA

    final insumoField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FormLabel(text: 'Insumo', requiredField: true),

        const Gap(6),

        _SearchableDropdown<InsumoLookup>(
          key: ValueKey(detail),

          options: widget.insumoOptions,

          hint: 'Escribe para buscar un insumo...',

          displayStringForOption: (item) => item.displayName,

          searchStringForOption: (item) => item.displayName,

          enabled: !widget.isSubmitting,

          validator: () {
            return detail.insumoId == null ? 'Selecciona un insumo.' : null;
          },

          onTextChanged: (value) {
            if (detail.insumoId != null) {
              setState(() {
                detail.insumoId = null;
              });
            }
          },

          onSelected: (item) {
            setState(() {
              detail.insumoId = item.id;
            });
          },
        ),
      ],
    );

    // ========================================================
    // PORCENTAJE
    // ========================================================

    final percentageField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FormLabel(text: 'Porcentaje %', requiredField: true),

        const Gap(6),

        TextFormField(
          controller: detail.percentage,
          style: const TextStyle(fontSize: 13),

          keyboardType: const TextInputType.numberWithOptions(decimal: true),

          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],

          decoration: _fieldDecoration(hint: '0.00'),

          validator: (value) {
            final number = double.tryParse(
              (value ?? '').trim().replaceAll(',', '.'),
            );

            if (number == null || number <= 0) {
              return 'Porcentaje inválido.';
            }

            return null;
          },
        ),
      ],
    );

    // ========================================================
    // OBSERVACIÓN
    // ========================================================

    final noteField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FormLabel(text: 'Observación'),

        const Gap(6),

        TextFormField(
          controller: detail.note,
          style: const TextStyle(fontSize: 13),
          decoration: _fieldDecoration(hint: 'Observación (opcional)'),
        ),
      ],
    );

    // ========================================================
    // ELIMINAR INSUMO
    // ========================================================

    final deleteButton = IconButton(
      tooltip: 'Quitar insumo',
      onPressed: widget.isSubmitting || _details.length == 1
          ? null
          : () => _removeInsumo(index),
      icon: const Icon(Icons.delete_outline_rounded, size: 19),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 480) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              insumoField,

              const Gap(AppSpacing.sm),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: percentageField),

                  const Gap(AppSpacing.sm),

                  Expanded(flex: 3, child: noteField),

                  Padding(
                    padding: const EdgeInsets.only(top: 23),
                    child: deleteButton,
                  ),
                ],
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 4, child: insumoField),

            const Gap(AppSpacing.sm),

            Expanded(flex: 2, child: percentageField),

            const Gap(AppSpacing.sm),

            Expanded(flex: 3, child: noteField),

            Padding(
              padding: const EdgeInsets.only(top: 23),
              child: deleteButton,
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // BOTONES INFERIORES
  // ==========================================================

  Widget _buildFooter() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: widget.isSubmitting
                ? null
                : () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),

          const Gap(AppSpacing.sm),

          FilledButton.icon(
            onPressed: widget.isSubmitting ? null : _submit,
            icon: widget.isSubmitting
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined, size: 17),
            label: Text(widget.submitLabel),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DESPLEGABLE DINÁMICO
// ============================================================

class _SearchableDropdown<T extends Object> extends StatelessWidget {
  const _SearchableDropdown({
    super.key,
    required this.options,
    required this.hint,
    required this.displayStringForOption,
    required this.searchStringForOption,
    required this.onSelected,
    required this.onTextChanged,
    required this.validator,
    this.initialOption,
    this.enabled = true,
  });

  final List<T> options;
  final String hint;

  final String Function(T) displayStringForOption;
  final String Function(T) searchStringForOption;

  final ValueChanged<T> onSelected;
  final ValueChanged<String> onTextChanged;

  final String? Function() validator;

  final T? initialOption;
  final bool enabled;

  String _normalize(String value) {
    return value
        .toLowerCase()
        .trim()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Autocomplete<T>(
          initialValue: initialOption == null
              ? null
              : TextEditingValue(
                  text: displayStringForOption(initialOption as T),
                ),

          displayStringForOption: displayStringForOption,

          // SOLO MOSTRAR COINCIDENCIAS
          optionsBuilder: (textEditingValue) {
            final query = _normalize(textEditingValue.text);

            if (query.isEmpty) {
              return Iterable<T>.empty();
            }

            return options.where((option) {
              final searchableText = _normalize(searchStringForOption(option));

              return searchableText.contains(query);
            });
          },

          onSelected: onSelected,

          // CAMPO DE BÚSQUEDA
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              style: const TextStyle(fontSize: 13),
              textInputAction: TextInputAction.search,
              onChanged: onTextChanged,
              onFieldSubmitted: (_) {
                onFieldSubmitted();
              },
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: colors.onSurfaceVariant,
                ),
                isDense: true,
                filled: true,
                fillColor: colors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: BorderSide(color: colors.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: BorderSide(color: colors.primary, width: 1.3),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: BorderSide(color: colors.error),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: BorderSide(color: colors.error, width: 1.3),
                ),
              ),
              validator: (_) => validator(),
            );
          },

          // RESULTADOS FLOTANTES
          optionsViewBuilder: (context, selectOption, matchingOptions) {
            final results = matchingOptions.toList();

            if (results.isEmpty) {
              return const SizedBox.shrink();
            }

            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 8,
                color: colors.surface,
                borderRadius: BorderRadius.circular(10),
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      shrinkWrap: true,
                      itemCount: results.length,
                      separatorBuilder: (_, _) =>
                          Divider(height: 1, color: colors.outlineVariant),
                      itemBuilder: (context, index) {
                        final option = results[index];

                        final highlightedIndex =
                            AutocompleteHighlightedOption.of(context);

                        final isHighlighted = highlightedIndex == index;

                        return InkWell(
                          onTap: () {
                            selectOption(option);
                          },
                          child: Container(
                            color: isHighlighted
                                ? colors.primary.withValues(alpha: 0.10)
                                : Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Text(
                              displayStringForOption(option),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 12,
                                fontWeight: isHighlighted
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ============================================================
// ENCABEZADO DE SECCIÓN
// ============================================================

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(3),
          ),
        ),

        const Gap(AppSpacing.sm),

        Flexible(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// ETIQUETAS
// ============================================================

class _FormLabel extends StatelessWidget {
  const _FormLabel({required this.text, this.requiredField = false});

  final String text;
  final bool requiredField;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        if (requiredField) ...[
          const Gap(3),

          Text(
            '*',
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

// ============================================================
// CONVERTIR EL CÓDIGO A MAYÚSCULAS
// ============================================================

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

// ============================================================
// BORRADOR DE INSUMO
// ============================================================

class _RecipeDraft {
  int? insumoId;

  final percentage = TextEditingController();
  final note = TextEditingController();

  void dispose() {
    percentage.dispose();
    note.dispose();
  }
}
