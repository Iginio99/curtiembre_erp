import 'dart:math' as math;

import 'package:erp_curtiembre_fronted/features/inventory/fisico/domain/entities/inventario_fisico_detail.dart';
import 'package:erp_curtiembre_fronted/features/inventory/fisico/domain/repositories/inventario_fisico_repository.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/domain/entities/insumo_lookup.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/buttons/app_button.dart';
import 'package:flutter/material.dart';

/// Conserva exactamente el contrato que consume InventarioFisicoPage.
class InventarioFisicoCountsFormData {
  const InventarioFisicoCountsFormData({required this.detalles});

  final List<RegistrarConteoInventarioFisicoDetalleInput> detalles;
}

class InventarioFisicoCountsDialog extends StatefulWidget {
  const InventarioFisicoCountsDialog({
    super.key,
    required this.insumos,
    required this.existingDetails,
    required this.isSubmitting,
  });

  final List<InsumoLookup> insumos;
  final List<InventarioFisicoConteoLine> existingDetails;
  final bool isSubmitting;

  @override
  State<InventarioFisicoCountsDialog> createState() =>
      _InventarioFisicoCountsDialogState();
}

class _InventarioFisicoCountsDialogState
    extends State<InventarioFisicoCountsDialog> {
  static const Color _orange = Color(0xFFF35B0B);
  static const int _pageSize = 8;

  final TextEditingController _countController = TextEditingController();
  final TextEditingController _tableSearchController = TextEditingController();
  late final List<_ConteoDraft> _drafts;

  InsumoLookup? _selectedInsumo;
  String? _addError;
  int _autocompleteVersion = 0;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // Ya contados: están en la tabla y NO en las opciones del buscador.
    _drafts = widget.existingDetails
        .map((line) {
          return _ConteoDraft(
            insumoId: line.insumoId,
            codigo: line.insumoCodigo,
            nombre: line.insumoNombre,
            stockSistema: line.stockSistema.toDouble(),
            unidad: line.unidadMedidaCodigo,
            stockContado: line.stockContado.toStringAsFixed(2),
            observacion: line.observacion ?? '',
            isPersisted: true,
          );
        })
        .toList(growable: true);
  }

  @override
  void dispose() {
    _countController.dispose();
    _tableSearchController.dispose();
    for (final line in _drafts) {
      line.dispose();
    }
    super.dispose();
  }

  static String _optionLabel(InsumoLookup item) =>
      '${item.codigo} - ${item.nombre}';

  Iterable<InsumoLookup> _availableOptions(TextEditingValue query) {
    final filter = query.text.trim().toLowerCase();
    // No despliega todo el catálogo al hacer clic en el campo vacío.
    if (filter.isEmpty) return const <InsumoLookup>[];
    final used = _drafts.map((line) => line.insumoId).toSet();
    return widget.insumos
        .where((item) {
          if (used.contains(item.id)) return false;
          return item.codigo.toLowerCase().contains(filter) ||
              item.nombre.toLowerCase().contains(filter);
        })
        .take(7);
  }

  double? _parseCount(String value) {
    final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
    if (parsed == null || !parsed.isFinite || parsed < 0) return null;
    return parsed;
  }

  void _addLine() {
    if (widget.isSubmitting) return;
    final item = _selectedInsumo;
    final count = _parseCount(_countController.text);
    if (item == null) {
      setState(() => _addError = 'Busca y selecciona un insumo pendiente.');
      return;
    }
    if (_drafts.any((line) => line.insumoId == item.id)) {
      setState(() {
        _selectedInsumo = null;
        _autocompleteVersion++;
        _addError = 'Este insumo ya se encuentra en los conteos.';
      });
      return;
    }
    if (count == null) {
      setState(() => _addError = 'Ingresa una cantidad válida (0 o mayor).');
      return;
    }

    setState(() {
      _drafts.add(
        _ConteoDraft(
          insumoId: item.id,
          codigo: item.codigo,
          nombre: item.nombre,
          stockSistema: item.stockActual.toDouble(),
          unidad: item.unidadMedidaCodigo,
          stockContado: count.toStringAsFixed(2),
          observacion: '',
          isPersisted: false,
        ),
      );
      _selectedInsumo = null;
      _countController.clear();
      _addError = null;
      _autocompleteVersion++;
      _currentPage = 0;
      _tableSearchController.clear();
    });
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _editLine(_ConteoDraft draft) async {
    if (widget.isSubmitting) return;
    final edited = await showDialog<_EditedLine>(
      context: context,
      builder: (context) => _EditConteoDialog(draft: draft),
    );
    if (!mounted || edited == null) return;
    setState(() {
      draft.stockContadoController.text = edited.stockContado;
      draft.observacionController.text = edited.observacion;
    });
  }

  void _removeUnsavedLine(_ConteoDraft draft) {
    // Quitar del formulario una fila recién añadida no modifica el servidor.
    // Las filas ya persistidas NO se eliminan aquí porque el contrato actual
    // de registerCounts no garantiza una operación de borrado.
    if (widget.isSubmitting || draft.isPersisted) return;
    setState(() {
      _drafts.remove(draft);
      draft.dispose();
      _currentPage = 0;
    });
  }

  void _submit() {
    if (widget.isSubmitting) return;
    if (_drafts.isEmpty) {
      setState(() => _addError = 'Agrega al menos un insumo para guardar.');
      return;
    }

    final usedIds = <int>{};
    final payload = <RegistrarConteoInventarioFisicoDetalleInput>[];
    for (final line in _drafts) {
      final count = _parseCount(line.stockContadoController.text);
      if (!usedIds.add(line.insumoId) || count == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hay conteos duplicados o cantidades no válidas.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      final note = line.observacionController.text.trim();
      payload.add(
        RegistrarConteoInventarioFisicoDetalleInput(
          insumoId: line.insumoId,
          stockContado: count,
          observacion: note.isEmpty ? null : note,
        ),
      );
    }

    // IMPORTANTE: incluye los registrados previamente más los nuevos.
    // Así se mantiene el contrato original del diálogo con el Cubit.
    Navigator.of(
      context,
    ).pop(InventarioFisicoCountsFormData(detalles: payload));
  }

  List<_ConteoDraft> get _filteredDrafts {
    final filter = _tableSearchController.text.trim().toLowerCase();
    if (filter.isEmpty) return _drafts;
    return _drafts
        .where((line) {
          return line.codigo.toLowerCase().contains(filter) ||
              line.nombre.toLowerCase().contains(filter);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    // El diálogo se adapta a su contenido. Antes se le forzaba una altura de
    // 780 px incluso con una sola línea, dejando una zona vacía muy grande.
    final width = math.max(0.0, math.min(1180.0, size.width - 32));
    final maxHeight = math.max(0.0, math.min(700.0, size.height - 32));
    final compact = size.width < 700;
    final padding = compact ? 16.0 : 22.0;
    final pending = widget.insumos
        .where((item) => !_drafts.any((line) => line.insumoId == item.id))
        .length;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width, maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(padding, padding, 12, 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _orange.withValues(alpha: .09),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.fact_check_outlined,
                      color: _orange,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Registrar conteos',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Busca únicamente insumos pendientes y registra su cantidad contada.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
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
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: theme.colorScheme.outlineVariant),
            Flexible(
              fit: FlexFit.loose,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionBox(
                      context,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Agregar insumo pendiente',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (!compact)
                                _SmallTag(
                                  text: '$pending disponibles',
                                  color: _orange,
                                ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          Text(
                            'Los insumos ya registrados no aparecerán en los resultados.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (compact)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _insumoAutocomplete(context),
                                const SizedBox(height: 12),
                                _stockInput(context),
                                const SizedBox(height: 12),
                                _addButton(),
                              ],
                            )
                          else
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: _insumoAutocomplete(context),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 180,
                                  child: _stockInput(context),
                                ),
                                const SizedBox(width: 12),
                                Padding(
                                  padding: const EdgeInsets.only(top: 1),
                                  child: _addButton(),
                                ),
                              ],
                            ),
                          if (_selectedInsumo != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Stock de referencia: ${_selectedInsumo!.stockActual.toStringAsFixed(2)} ${_selectedInsumo!.unidadMedidaCodigo}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                          if (_addError != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              _addError!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _sectionBox(
                      context,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (compact)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _registeredTitle(context),
                                const SizedBox(height: 12),
                                _tableSearchField(),
                              ],
                            )
                          else
                            Row(
                              children: [
                                Expanded(child: _registeredTitle(context)),
                                SizedBox(
                                  width: 230,
                                  child: _tableSearchField(),
                                ),
                              ],
                            ),
                          const SizedBox(height: 14),
                          if (_filteredDrafts.isEmpty)
                            _emptyTable(context)
                          else
                            _registeredTable(context, compact: compact),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: theme.colorScheme.outlineVariant),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: padding,
                vertical: compact ? 12 : 16,
              ),
              child: compact
                  ? Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        AppButton.secondary(
                          label: 'Cancelar',
                          onPressed: widget.isSubmitting
                              ? null
                              : () => Navigator.of(context).pop(),
                        ),
                        AppButton.primary(
                          label: 'Guardar conteos',
                          icon: Icons.check_circle_outline,
                          expand: false,
                          isLoading: widget.isSubmitting,
                          onPressed: widget.isSubmitting ? null : _submit,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_drafts.length} ${_drafts.length == 1 ? 'línea' : 'líneas'} en esta toma',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        AppButton.secondary(
                          label: 'Cancelar',
                          onPressed: widget.isSubmitting
                              ? null
                              : () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 10),
                        AppButton.primary(
                          label: 'Guardar conteos',
                          icon: Icons.check_circle_outline,
                          expand: false,
                          isLoading: widget.isSubmitting,
                          onPressed: widget.isSubmitting ? null : _submit,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionBox(BuildContext context, {required Widget child}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: child,
    );
  }

  Widget _insumoAutocomplete(BuildContext context) {
    final theme = Theme.of(context);
    return Autocomplete<InsumoLookup>(
      key: ValueKey('autocomplete_$_autocompleteVersion'),
      displayStringForOption: _optionLabel,
      optionsBuilder: _availableOptions,
      onSelected: (item) {
        setState(() {
          _selectedInsumo = item;
          _addError = null;
        });
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: !widget.isSubmitting,
          onChanged: (_) {
            if (_selectedInsumo != null || _addError != null) {
              setState(() {
                _selectedInsumo = null;
                _addError = null;
              });
            }
          },
          decoration: InputDecoration(
            labelText: 'Buscar o seleccionar insumo',
            hintText: 'Código o nombre del insumo...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(11)),
            isDense: true,
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: theme.colorScheme.surface,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520, maxHeight: 280),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 6),
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final item = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    title: Text(
                      _optionLabel(item),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      'Stock: ${item.stockActual.toStringAsFixed(2)} ${item.unidadMedidaCodigo}',
                    ),
                    onTap: () => onSelected(item),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _stockInput(BuildContext context) {
    return TextField(
      controller: _countController,
      enabled: !widget.isSubmitting,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) {
        if (_addError != null) setState(() => _addError = null);
      },
      onSubmitted: (_) => _addLine(),
      decoration: InputDecoration(
        labelText: 'Stock contado',
        hintText: '0.00',
        suffixText: _selectedInsumo?.unidadMedidaCodigo,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(11)),
        isDense: true,
      ),
    );
  }

  Widget _addButton() {
    return SizedBox(
      height: 49,
      child: OutlinedButton.icon(
        onPressed: widget.isSubmitting ? null : _addLine,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Agregar línea'),
        style: OutlinedButton.styleFrom(
          foregroundColor: _orange,
          side: const BorderSide(color: _orange),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
      ),
    );
  }

  Widget _registeredTitle(BuildContext context) {
    final theme = Theme.of(context);
    final saved = _drafts.where((line) => line.isPersisted).length;
    final newLines = _drafts.length - saved;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 6,
          children: [
            Text(
              'Conteos de esta toma',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            _SmallTag(text: '$saved registrados', color: _orange),
            if (newLines > 0)
              const _SmallTag(
                text: 'Nuevos sin guardar',
                color: Color(0xFF28724A),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Revisa los conteos existentes y los nuevos antes de guardar.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _tableSearchField() {
    return TextField(
      controller: _tableSearchController,
      onChanged: (_) => setState(() => _currentPage = 0),
      decoration: InputDecoration(
        hintText: 'Buscar en conteos...',
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _emptyTable(BuildContext context) {
    final theme = Theme.of(context);
    final isFiltered = _tableSearchController.text.trim().isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 38,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 10),
          Text(
            isFiltered ? 'No se encontraron conteos' : 'Aún no hay conteos',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            isFiltered
                ? 'Prueba con otro código o nombre.'
                : 'Busca un insumo arriba para registrar la primera línea.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _registeredTable(BuildContext context, {required bool compact}) {
    final scheme = Theme.of(context).colorScheme;
    final filtered = _filteredDrafts;
    final pages = (filtered.length / _pageSize).ceil();
    final page = _currentPage.clamp(0, pages - 1).toInt();
    final start = page * _pageSize;
    final visible = filtered.skip(start).take(_pageSize).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (compact)
          for (final draft in visible) ...[
            _compactDraftCard(context, draft),
            const SizedBox(height: 8),
          ]
        else
          LayoutBuilder(
            builder: (context, constraints) => Container(
              decoration: BoxDecoration(
                border: Border.all(color: scheme.outlineVariant),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  // Hace que el encabezado y las filas cubran todo el panel
                  // aunque haya pocos conteos.
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    columnSpacing: 20,
                    horizontalMargin: 14,
                    headingRowHeight: 44,
                    dataRowMinHeight: 53,
                    dataRowMaxHeight: 64,
                    headingRowColor: WidgetStatePropertyAll(
                      scheme.surfaceContainerLow,
                    ),
                    columns: const [
                      DataColumn(label: Text('#')),
                      DataColumn(label: Text('Código')),
                      DataColumn(label: Text('Insumo')),
                      DataColumn(label: Text('Sistema'), numeric: true),
                      DataColumn(label: Text('Contado'), numeric: true),
                      DataColumn(label: Text('Diferencia'), numeric: true),
                      DataColumn(label: Text('UM')),
                      DataColumn(label: Text('Observación')),
                      DataColumn(label: Text('Acciones')),
                    ],
                    rows: [
                      for (var i = 0; i < visible.length; i++)
                        _dataRow(context, visible[i], start + i + 1),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (pages > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Página ${page + 1} de $pages'),
              IconButton(
                tooltip: 'Página anterior',
                onPressed: page == 0
                    ? null
                    : () => setState(() => _currentPage = page - 1),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              IconButton(
                tooltip: 'Página siguiente',
                onPressed: page >= pages - 1
                    ? null
                    : () => setState(() => _currentPage = page + 1),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ],
      ],
    );
  }

  DataRow _dataRow(BuildContext context, _ConteoDraft line, int number) {
    final difference = line.difference;
    return DataRow(
      cells: [
        DataCell(Text('$number')),
        DataCell(Text(line.codigo)),
        DataCell(
          SizedBox(
            width: 160,
            child: Text(
              line.nombre,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ),
        DataCell(Text(line.stockSistema.toStringAsFixed(2))),
        DataCell(Text(line.stockContadoController.text)),
        DataCell(_differenceTag(difference)),
        DataCell(Text(line.unidad)),
        DataCell(
          SizedBox(
            width: 150,
            child: Text(
              line.observacionController.text.isEmpty
                  ? '—'
                  : line.observacionController.text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(_rowActions(line)),
      ],
    );
  }

  Widget _rowActions(_ConteoDraft line) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 19),
          tooltip: 'Editar conteo',
          color: _orange,
          onPressed: widget.isSubmitting ? null : () => _editLine(line),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          padding: EdgeInsets.zero,
        ),
        if (!line.isPersisted)
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 19),
            tooltip: 'Quitar línea todavía no guardada',
            color: Theme.of(context).colorScheme.error,
            onPressed: widget.isSubmitting
                ? null
                : () => _removeUnsavedLine(line),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
      ],
    );
  }

  Widget _compactDraftCard(BuildContext context, _ConteoDraft line) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${line.codigo} · ${line.nombre}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              _rowActions(line),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              Text(
                'Sistema: ${line.stockSistema.toStringAsFixed(2)} ${line.unidad}',
              ),
              Text(
                'Contado: ${line.stockContadoController.text} ${line.unidad}',
              ),
              _differenceTag(line.difference),
            ],
          ),
          if (line.observacionController.text.trim().isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(line.observacionController.text),
          ],
        ],
      ),
    );
  }

  Widget _differenceTag(double? difference) {
    if (difference == null) return const Text('—');
    final positive = difference > 0;
    final negative = difference < 0;
    final color = negative ? const Color(0xFFB42318) : const Color(0xFF167347);
    final number = '${positive ? '+' : ''}${difference.toStringAsFixed(2)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        number,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _SmallTag extends StatelessWidget {
  const _SmallTag({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ConteoDraft {
  _ConteoDraft({
    required this.insumoId,
    required this.codigo,
    required this.nombre,
    required this.stockSistema,
    required this.unidad,
    required this.isPersisted,
    required String stockContado,
    required String observacion,
  }) : stockContadoController = TextEditingController(text: stockContado),
       observacionController = TextEditingController(text: observacion);

  final int insumoId;
  final String codigo;
  final String nombre;
  final double stockSistema;
  final String unidad;
  final bool isPersisted;
  final TextEditingController stockContadoController;
  final TextEditingController observacionController;

  double? get difference {
    final count = double.tryParse(
      stockContadoController.text.trim().replaceAll(',', '.'),
    );
    if (count == null || !count.isFinite) return null;
    return count - stockSistema;
  }

  void dispose() {
    stockContadoController.dispose();
    observacionController.dispose();
  }
}

class _EditedLine {
  const _EditedLine({required this.stockContado, required this.observacion});
  final String stockContado;
  final String observacion;
}

class _EditConteoDialog extends StatefulWidget {
  const _EditConteoDialog({required this.draft});
  final _ConteoDraft draft;

  @override
  State<_EditConteoDialog> createState() => _EditConteoDialogState();
}

class _EditConteoDialogState extends State<_EditConteoDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _stockController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _stockController = TextEditingController(
      text: widget.draft.stockContadoController.text,
    );
    _noteController = TextEditingController(
      text: widget.draft.observacionController.text,
    );
  }

  @override
  void dispose() {
    _stockController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Editar conteo'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.draft.codigo} · ${widget.draft.nombre}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Stock referencial: ${widget.draft.stockSistema.toStringAsFixed(2)} ${widget.draft.unidad}',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _stockController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Stock contado',
                  suffixText: widget.draft.unidad,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  final count = double.tryParse(
                    (value ?? '').trim().replaceAll(',', '.'),
                  );
                  if (count == null || !count.isFinite || count < 0) {
                    return 'Ingresa una cantidad válida (0 o mayor).';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                minLines: 1,
                decoration: const InputDecoration(
                  labelText: 'Observación (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final count = double.parse(
              _stockController.text.trim().replaceAll(',', '.'),
            );
            Navigator.of(context).pop(
              _EditedLine(
                stockContado: count.toStringAsFixed(2),
                observacion: _noteController.text.trim(),
              ),
            );
          },
          icon: const Icon(Icons.check_rounded),
          label: const Text('Aplicar cambios'),
        ),
      ],
    );
  }
}
