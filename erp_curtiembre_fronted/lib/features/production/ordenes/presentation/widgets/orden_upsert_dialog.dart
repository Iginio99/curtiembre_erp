import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/production/clientes/domain/entities/cliente_option.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/lote_option.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/personal_empresa_option.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

// ============================================================================
// DATA
// ============================================================================

class OrdenUpsertFormData {
  const OrdenUpsertFormData({
    required this.loteId,
    required this.clienteId,
    required this.cantidadPieles,
    this.fechaInicioPlanificada,
    required this.fechaFinEstimada,
    this.observacion,
    required this.responsableNombre,
    required this.responsableCargo,
  });

  final int loteId;
  final int clienteId;
  final double cantidadPieles;
  final DateTime? fechaInicioPlanificada;
  final DateTime fechaFinEstimada;
  final String? observacion;
  final String responsableNombre;
  final String responsableCargo;
}

// ============================================================================
// DIALOG
// ============================================================================

class OrdenUpsertDialog extends StatefulWidget {
  const OrdenUpsertDialog({
    required this.title,
    required this.submitLabel,
    required this.isSubmitting,
    required this.clienteOptions,
    required this.loteOptions,
    this.responsableOptions = const [],
    this.onAddPersonal,
    super.key,
  });

  final String title;
  final String submitLabel;
  final bool isSubmitting;

  final List<ClienteOption> clienteOptions;
  final List<LoteOption> loteOptions;
  final List<PersonalEmpresaOption> responsableOptions;

  final Future<PersonalEmpresaOption?> Function()? onAddPersonal;

  @override
  State<OrdenUpsertDialog> createState() => _OrdenUpsertDialogState();
}

class _OrdenUpsertDialogState extends State<OrdenUpsertDialog> {
  final _formKey = GlobalKey<FormState>();

  int? _selectedClienteId;
  int? _selectedLoteId;
  int? _selectedPersonalId;

  // Permiten reiniciar visualmente los buscadores cuando sea necesario.
  int _loteRevision = 0;
  int _personalRevision = 0;

  DateTime? _fechaInicioPlanificada;
  late DateTime _fechaFinEstimada;

  late final TextEditingController _cantidadController;
  late final TextEditingController _observacionController;
  late final TextEditingController _responsableNombreController;
  late final TextEditingController _responsableCargoController;

  late List<PersonalEmpresaOption> _personalOptions;

  @override
  void initState() {
    super.initState();

    _fechaFinEstimada = DateTime.now().add(const Duration(days: 7));

    _cantidadController = TextEditingController();
    _observacionController = TextEditingController();
    _responsableNombreController = TextEditingController();
    _responsableCargoController = TextEditingController();

    _personalOptions = List.of(widget.responsableOptions);
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _observacionController.dispose();
    _responsableNombreController.dispose();
    _responsableCargoController.dispose();

    super.dispose();
  }

  // ==========================================================================
  // LOTES
  // ==========================================================================

  List<LoteOption> get _filteredLotes {
    if (_selectedClienteId == null) {
      return widget.loteOptions;
    }

    return widget.loteOptions
        .where((lote) => lote.clienteId == _selectedClienteId)
        .toList();
  }

  LoteOption? get _selectedLote {
    for (final lote in widget.loteOptions) {
      if (lote.id == _selectedLoteId) {
        return lote;
      }
    }

    return null;
  }

  PersonalEmpresaOption? get _selectedPersonal {
    for (final item in _personalOptions) {
      if (item.id == _selectedPersonalId) {
        return item;
      }
    }

    return null;
  }

  String _formatCantidad(double value) {
    return value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2);
  }

  // ==========================================================================
  // SELECCIÓN DE CLIENTE
  // ==========================================================================

  void _selectCliente(ClienteOption? cliente) {
    final newId = cliente?.id;

    setState(() {
      final changed = newId != _selectedClienteId;

      _selectedClienteId = newId;

      if (changed) {
        // Si cambia el cliente, el lote anterior deja de ser válido.
        _selectedLoteId = null;
        _loteRevision++;
      }
    });
  }

  // ==========================================================================
  // SELECCIÓN DE LOTE
  // ==========================================================================

  void _selectLote(LoteOption? lote) {
    setState(() {
      _selectedLoteId = lote?.id;
    });
  }

  // ==========================================================================
  // SELECCIÓN DE RESPONSABLE
  // ==========================================================================

  void _selectResponsable(PersonalEmpresaOption? item) {
    setState(() {
      _selectedPersonalId = item?.id;
    });

    _responsableNombreController.text = item?.nombre ?? '';
    _responsableCargoController.text = item?.cargo ?? '';
  }

  // ==========================================================================
  // AGREGAR PERSONAL
  // ==========================================================================

  Future<void> _addPersonal() async {
    if (widget.onAddPersonal == null) return;

    try {
      final item = await widget.onAddPersonal!();

      if (item == null || !mounted) return;

      setState(() {
        _personalOptions = [
          ..._personalOptions.where((option) => option.id != item.id),
          item,
        ]..sort((a, b) => a.nombre.compareTo(b.nombre));

        _selectedPersonalId = item.id;

        // Actualiza el texto del autocompletado con el nuevo personal.
        _personalRevision++;
      });

      _responsableNombreController.text = item.nombre;
      _responsableCargoController.text = item.cargo;
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo agregar el personal.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ==========================================================================
  // FECHAS
  // ==========================================================================

  Future<void> _pickFechaInicioPlanificada() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _fechaInicioPlanificada ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selected == null || !mounted) return;

    setState(() {
      _fechaInicioPlanificada = selected;
    });
  }

  Future<void> _pickFechaFinEstimada() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _fechaFinEstimada,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selected == null || !mounted) return;

    setState(() {
      _fechaFinEstimada = selected;
    });
  }

  // ==========================================================================
  // SUBMIT
  // ==========================================================================

  void _submit() {
    if (widget.isSubmitting) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedClienteId == null ||
        _selectedLoteId == null ||
        _selectedPersonalId == null) {
      return;
    }

    if (_fechaInicioPlanificada != null &&
        _fechaFinEstimada.isBefore(_fechaInicioPlanificada!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La fecha de fin no puede ser anterior a la fecha de inicio.',
          ),
        ),
      );

      return;
    }

    Navigator.of(context).pop(
      OrdenUpsertFormData(
        loteId: _selectedLoteId!,
        clienteId: _selectedClienteId!,
        cantidadPieles: double.parse(
          _cantidadController.text.trim().replaceAll(',', '.'),
        ),
        fechaInicioPlanificada: _fechaInicioPlanificada,
        fechaFinEstimada: _fechaFinEstimada,
        observacion: _normalizeOptional(_observacionController.text),
        responsableNombre: _responsableNombreController.text.trim(),
        responsableCargo: _responsableCargoController.text.trim(),
      ),
    );
  }

  String? _normalizeOptional(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final inicioLabel = _fechaInicioPlanificada == null
        ? 'Sin fecha'
        : DateFormat('dd/MM/yyyy').format(_fechaInicioPlanificada!);

    final finLabel = DateFormat('dd/MM/yyyy').format(_fechaFinEstimada);

    final screenHeight = MediaQuery.sizeOf(context).height;

    final dialogHeight = (screenHeight - 48).clamp(320.0, 760.0).toDouble();

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: SizedBox(
        width: 820,
        height: dialogHeight,
        child: Material(
          color: colors.surface,
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // DECORACIÓN SUPERIOR
              Positioned(
                top: -110,
                right: -80,
                child: IgnorePointer(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.primary.withValues(alpha: 0.075),
                    ),
                  ),
                ),
              ),

              Positioned(
                top: -65,
                right: 55,
                child: IgnorePointer(
                  child: Container(
                    width: 145,
                    height: 145,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.primary.withValues(alpha: 0.04),
                    ),
                  ),
                ),
              ),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // =========================================================
                    // HEADER
                    // =========================================================
                    Padding(
                      padding: const EdgeInsets.fromLTRB(30, 26, 30, 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.13),
                              borderRadius: BorderRadius.circular(17),
                            ),
                            child: Icon(
                              Icons.factory_outlined,
                              size: 33,
                              color: colors.primary,
                            ),
                          ),

                          const Gap(18),

                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.title,
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(
                                          fontSize: 27,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.5,
                                        ),
                                  ),

                                  const Gap(5),

                                  Text(
                                    'Registra los datos de la nueva orden de producción.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          IconButton(
                            tooltip: 'Cerrar',
                            onPressed: widget.isSubmitting
                                ? null
                                : () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),

                    // =========================================================
                    // CONTENIDO
                    // =========================================================
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(30, 0, 30, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _OrdenSectionTitle(
                              title: 'Información principal',
                            ),

                            const Gap(14),

                            LayoutBuilder(
                              builder: (context, constraints) {
                                final wide = constraints.maxWidth >= 650;

                                if (!wide) {
                                  return Column(
                                    children: [
                                      _clienteField(),
                                      const Gap(AppSpacing.md),
                                      _loteField(),
                                      const Gap(AppSpacing.md),
                                      _responsableField(),
                                      const Gap(AppSpacing.md),
                                      _cantidadField(),
                                    ],
                                  );
                                }

                                return Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(child: _clienteField()),
                                        const Gap(AppSpacing.md),
                                        Expanded(child: _loteField()),
                                      ],
                                    ),

                                    const Gap(AppSpacing.md),

                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(child: _responsableField()),
                                        const Gap(AppSpacing.md),
                                        Expanded(child: _cantidadField()),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),

                            const Gap(25),

                            const _OrdenSectionTitle(title: 'Fechas'),

                            const Gap(14),

                            LayoutBuilder(
                              builder: (context, constraints) {
                                final inicio = _dateField(
                                  label: 'Fecha inicio planificada',
                                  value: inicioLabel,
                                  icon: Icons.calendar_today_outlined,
                                  onTap: _pickFechaInicioPlanificada,
                                );

                                final fin = _dateField(
                                  label: 'Fecha fin estimada',
                                  value: finLabel,
                                  icon: Icons.event_available_outlined,
                                  onTap: _pickFechaFinEstimada,
                                  required: true,
                                );

                                if (constraints.maxWidth < 650) {
                                  return Column(
                                    children: [
                                      inicio,
                                      const Gap(AppSpacing.md),
                                      fin,
                                    ],
                                  );
                                }

                                return Row(
                                  children: [
                                    Expanded(child: inicio),
                                    const Gap(AppSpacing.md),
                                    Expanded(child: fin),
                                  ],
                                );
                              },
                            ),

                            const Gap(25),

                            const _OrdenSectionTitle(title: 'Observación'),

                            const Gap(14),

                            TextFormField(
                              controller: _observacionController,
                              enabled: !widget.isSubmitting,
                              maxLength: 500,
                              minLines: 3,
                              maxLines: 4,
                              decoration: _fieldDecoration(
                                hint: 'Agrega una observación (opcional)',
                                icon: Icons.description_outlined,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // =========================================================
                    // FOOTER
                    // =========================================================
                    Divider(height: 1, color: colors.outlineVariant),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(30, 16, 30, 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
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
                                : const Icon(Icons.save_outlined, size: 19),
                            label: Text(widget.submitLabel),
                            style: FilledButton.styleFrom(
                              backgroundColor: colors.primary,
                              foregroundColor: colors.onPrimary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 15,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // CLIENTE - AUTOCOMPLETADO
  // ==========================================================================

  Widget _clienteField() {
    return _SearchableSelect<ClienteOption>(
      label: 'Cliente',
      hint: 'Escribe para buscar un cliente',
      icon: Icons.groups_2_outlined,
      required: true,
      enabled: !widget.isSubmitting,
      options: widget.clienteOptions,
      displayString: (item) => item.label,
      selected: _selectedClienteId == null
          ? null
          : _findCliente(_selectedClienteId!),
      onChanged: _selectCliente,
      errorText: 'Selecciona un cliente.',
    );
  }

  ClienteOption? _findCliente(int id) {
    for (final item in widget.clienteOptions) {
      if (item.id == id) return item;
    }

    return null;
  }

  // ==========================================================================
  // LOTE - AUTOCOMPLETADO
  // ==========================================================================

  Widget _loteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SearchableSelect<LoteOption>(
          key: ValueKey('lote_$_loteRevision'),
          label: 'Lote disponible',
          hint: 'Escribe para buscar un lote',
          icon: Icons.inventory_2_outlined,
          required: true,
          enabled: !widget.isSubmitting,
          options: _filteredLotes,
          displayString: (item) => item.label,
          selected: _selectedLote,
          onChanged: _selectLote,
          errorText: 'Selecciona un lote.',
        ),

        if (_selectedLote case final lote?) ...[
          const Gap(6),

          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              'Disponible: ${_formatCantidad(lote.cantidadPielesDisponible)} pieles',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ==========================================================================
  // RESPONSABLE - AUTOCOMPLETADO
  // ==========================================================================

  Widget _responsableField() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _SearchableSelect<PersonalEmpresaOption>(
            key: ValueKey('personal_$_personalRevision'),
            label: 'Responsable',
            hint: 'Escribe el nombre o cargo',
            icon: Icons.person_outline_rounded,
            required: true,
            enabled: !widget.isSubmitting,
            options: _personalOptions,
            displayString: (item) => item.label,
            selected: _selectedPersonal,
            onChanged: _selectResponsable,
            errorText: 'Selecciona un responsable.',
          ),
        ),

        if (widget.onAddPersonal != null) ...[
          const Gap(AppSpacing.sm),

          Tooltip(
            message: 'Registrar nuevo personal',
            child: SizedBox(
              width: 48,
              height: 56,
              child: OutlinedButton(
                onPressed: widget.isSubmitting ? null : _addPersonal,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Icon(Icons.add_rounded, size: 23),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ==========================================================================
  // CANTIDAD
  // ==========================================================================

  Widget _cantidadField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel(text: 'Cantidad de pieles', required: true),

        const Gap(7),

        TextFormField(
          controller: _cantidadController,
          enabled: !widget.isSubmitting,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _fieldDecoration(
            hint: 'Ingresa la cantidad de pieles',
            icon: Icons.numbers_rounded,
          ),
          validator: (value) {
            final number = double.tryParse(
              (value ?? '').trim().replaceAll(',', '.'),
            );

            if (number == null || number <= 0) {
              return 'Ingresa una cantidad válida mayor a cero.';
            }

            final disponible = _selectedLote?.cantidadPielesDisponible;

            if (disponible != null && number > disponible) {
              return 'Máximo disponible: ${_formatCantidad(disponible)}.';
            }

            return null;
          },
        ),
      ],
    );
  }

  // ==========================================================================
  // FECHAS
  // ==========================================================================

  Widget _dateField({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
    bool required = false,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(text: label, required: required),

        const Gap(7),

        InkWell(
          onTap: widget.isSubmitting ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: _fieldDecoration(
              icon: icon,
              suffixIcon: Icons.calendar_month_outlined,
            ),
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.onSurface),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // DECORACIÓN DE CAMPOS
  // ==========================================================================

  InputDecoration _fieldDecoration({
    String? hint,
    IconData? icon,
    IconData? suffixIcon,
  }) {
    final colors = Theme.of(context).colorScheme;

    OutlineInputBorder border(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecoration(
      hintText: hint,
      prefixIcon: icon == null
          ? null
          : Icon(icon, size: 20, color: colors.onSurfaceVariant),
      suffixIcon: suffixIcon == null
          ? null
          : Icon(suffixIcon, size: 19, color: colors.onSurfaceVariant),
      filled: true,
      fillColor: colors.surfaceContainerLowest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: border(colors.outlineVariant),
      enabledBorder: border(colors.outlineVariant),
      focusedBorder: border(colors.primary, width: 1.5),
      errorBorder: border(colors.error),
      focusedErrorBorder: border(colors.error, width: 1.5),
    );
  }
}

// ============================================================================
// COMPONENTE REUTILIZABLE - SELECT CON BÚSQUEDA
// ============================================================================

class _SearchableSelect<T extends Object> extends StatefulWidget {
  const _SearchableSelect({
    super.key,
    required this.label,
    required this.hint,
    required this.options,
    required this.displayString,
    required this.selected,
    required this.onChanged,
    required this.errorText,
    this.icon,
    this.required = false,
    this.enabled = true,
  });

  final String label;
  final String hint;
  final IconData? icon;
  final bool required;
  final bool enabled;

  final List<T> options;
  final String Function(T) displayString;
  final T? selected;
  final ValueChanged<T?> onChanged;
  final String errorText;

  @override
  State<_SearchableSelect<T>> createState() => _SearchableSelectState<T>();
}

class _SearchableSelectState<T extends Object>
    extends State<_SearchableSelect<T>> {
  // Normaliza mayúsculas y acentos.
  String _normalize(String text) {
    const accents = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
      'ñ': 'n',
    };

    var result = text.toLowerCase().trim();

    accents.forEach((key, value) {
      result = result.replaceAll(key, value);
    });

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(text: widget.label, required: widget.required),

        const Gap(7),

        LayoutBuilder(
          builder: (context, constraints) {
            final fieldWidth = constraints.maxWidth;

            return Autocomplete<T>(
              // El texto inicial también permite seleccionar
              // automáticamente un personal recién registrado.
              initialValue: TextEditingValue(
                text: widget.selected == null
                    ? ''
                    : widget.displayString(widget.selected as T),
              ),

              displayStringForOption: widget.displayString,

              optionsBuilder: (textValue) {
                if (!widget.enabled) {
                  return Iterable<T>.empty();
                }

                final query = _normalize(textValue.text);

                // No se muestra el listado completo al dejar vacío
                // el buscador.
                if (query.isEmpty) {
                  return Iterable<T>.empty();
                }

                return widget.options.where((item) {
                  final label = _normalize(widget.displayString(item));

                  return label.contains(query);
                });
              },

              onSelected: (item) {
                widget.onChanged(item);
              },

              fieldViewBuilder:
                  (context, controller, focusNode, onFieldSubmitted) {
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      enabled: widget.enabled,
                      textInputAction: TextInputAction.search,

                      // Si el usuario altera una selección anterior,
                      // el ID elegido queda invalidado.
                      onChanged: (text) {
                        final selected = widget.selected;

                        if (selected == null) return;

                        if (text != widget.displayString(selected)) {
                          widget.onChanged(null);
                        }
                      },

                      onFieldSubmitted: (_) => onFieldSubmitted(),

                      validator: (_) {
                        if (!widget.required) return null;

                        if (widget.selected == null) {
                          return widget.errorText;
                        }

                        return null;
                      },

                      decoration: InputDecoration(
                        hintText: widget.hint,
                        prefixIcon: widget.icon == null
                            ? null
                            : Icon(
                                widget.icon,
                                color: colors.onSurfaceVariant,
                                size: 20,
                              ),
                        suffixIcon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                        ),
                        filled: true,
                        fillColor: colors.surfaceContainerLowest,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 15,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.outlineVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colors.primary,
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.error),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colors.error,
                            width: 1.5,
                          ),
                        ),
                      ),
                    );
                  },

              // PANEL FLOTANTE DE RESULTADOS
              optionsViewBuilder: (context, onSelected, options) {
                final results = options.toList(growable: false);

                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 10,
                    color: colors.surface,
                    shadowColor: Colors.black.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                    clipBehavior: Clip.antiAlias,
                    child: SizedBox(
                      width: fieldWidth,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 230),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          itemCount: results.length,
                          separatorBuilder: (_, _) =>
                              Divider(height: 1, color: colors.outlineVariant),
                          itemBuilder: (context, index) {
                            final item = results[index];

                            return InkWell(
                              onTap: () => onSelected(item),
                              hoverColor: colors.primary.withValues(
                                alpha: 0.07,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 13,
                                ),
                                child: Text(
                                  widget.displayString(item),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
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
        ),
      ],
    );
  }
}

// ============================================================================
// LABEL DE LOS CAMPOS
// ============================================================================

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text, this.required = false});

  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      children: [
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),

        if (required) ...[
          const Gap(4),
          Text(
            '*',
            style: TextStyle(color: colors.error, fontWeight: FontWeight.w800),
          ),
        ],
      ],
    );
  }
}

// ============================================================================
// TÍTULO DE SECCIÓN
// ============================================================================

class _OrdenSectionTitle extends StatelessWidget {
  const _OrdenSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const Gap(9),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
