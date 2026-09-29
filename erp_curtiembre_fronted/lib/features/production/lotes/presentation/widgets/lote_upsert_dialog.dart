import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/production/clientes/domain/entities/cliente_option.dart';
import 'package:erp_curtiembre_fronted/features/production/lotes/domain/entities/lote_record.dart';
import 'package:erp_curtiembre_fronted/features/production/lotes/domain/entities/tipo_piel_option.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class LoteUpsertFormData {
  const LoteUpsertFormData({
    required this.clienteId,
    required this.tipoPielId,
    required this.fechaIngreso,
    required this.cantidadPielesInicial,
    required this.clienteTraeLote,
    required this.costoUnitarioPiel,
    this.observacion,
  });

  final int clienteId;
  final int tipoPielId;
  final DateTime fechaIngreso;
  final double cantidadPielesInicial;
  final bool clienteTraeLote;
  final double costoUnitarioPiel;
  final String? observacion;
}

class LoteUpsertDialog extends StatefulWidget {
  const LoteUpsertDialog({
    required this.title,
    required this.submitLabel,
    required this.isSubmitting,
    required this.clienteOptions,
    required this.tipoPielOptions,
    this.initialLote,
    super.key,
  });

  final String title;
  final String submitLabel;
  final bool isSubmitting;
  final List<ClienteOption> clienteOptions;
  final List<TipoPielOption> tipoPielOptions;
  final LoteRecord? initialLote;

  @override
  State<LoteUpsertDialog> createState() => _LoteUpsertDialogState();
}

class _LoteUpsertDialogState extends State<LoteUpsertDialog> {
  final _formKey = GlobalKey<FormState>();

  late int? _selectedClienteId;
  late int? _selectedTipoPielId;
  late DateTime _fechaIngreso;
  late bool _clienteTraeLote;

  late final TextEditingController _cantidadController;
  late final TextEditingController _costoController;
  late final TextEditingController _observacionController;

  @override
  void initState() {
    super.initState();

    final initialLote = widget.initialLote;

    _selectedClienteId = initialLote?.clienteId;

    _selectedTipoPielId = initialLote?.tipoPielId;

    _fechaIngreso = initialLote?.fechaIngreso ?? DateTime.now();

    _clienteTraeLote = initialLote?.clienteTraeLote ?? false;

    _cantidadController = TextEditingController(
      text: _formatNumber(initialLote?.cantidadPielesInicial),
    );

    _costoController = TextEditingController(
      text: _formatNumber(initialLote?.costoUnitarioPiel),
    );

    _observacionController = TextEditingController(
      text: initialLote?.observacion ?? '',
    );

    _cantidadController.addListener(_refreshCalculatedTotal);

    _costoController.addListener(_refreshCalculatedTotal);

    _syncCostoTraeLote();
  }

  @override
  void dispose() {
    _cantidadController.removeListener(_refreshCalculatedTotal);

    _costoController.removeListener(_refreshCalculatedTotal);

    _cantidadController.dispose();
    _costoController.dispose();
    _observacionController.dispose();

    super.dispose();
  }

  void _refreshCalculatedTotal() {
    if (mounted) {
      setState(() {});
    }
  }

  double? _parseNumber(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  double get _costoTotalCalculado {
    if (_clienteTraeLote) {
      return 0;
    }

    final cantidad = _parseNumber(_cantidadController.text) ?? 0;

    final costoUnitario = _parseNumber(_costoController.text) ?? 0;

    return cantidad * costoUnitario;
  }

  String _formatNumber(double? value) {
    if (value == null) {
      return '';
    }

    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(2);
  }

  String _formatMoney(double value) {
    return NumberFormat.currency(
      locale: 'en_US',
      symbol: 'S/ ',
      decimalDigits: 2,
    ).format(value);
  }

  Future<void> _pickFechaIngreso() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _fechaIngreso,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selected != null) {
      setState(() => _fechaIngreso = selected);
    }
  }

  void _syncCostoTraeLote() {
    if (_clienteTraeLote) {
      _costoController.text = '0';
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedClienteId == null || _selectedTipoPielId == null) {
      return;
    }

    Navigator.of(context).pop(
      LoteUpsertFormData(
        clienteId: _selectedClienteId!,
        tipoPielId: _selectedTipoPielId!,
        fechaIngreso: _fechaIngreso,
        cantidadPielesInicial: _parseNumber(_cantidadController.text)!,
        clienteTraeLote: _clienteTraeLote,
        costoUnitarioPiel: _parseNumber(_costoController.text)!,
        observacion: _normalizeOptional(_observacionController.text),
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

    final dateLabel = DateFormat('dd/MM/yyyy').format(_fechaIngreso);

    final isEditing = widget.initialLote != null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),

      clipBehavior: Clip.antiAlias,

      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /*
            ═══════════════════════════════
            HEADER
            ═══════════════════════════════
            */
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 22, 18, 14),

              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,

                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const Gap(4),

                        Text(
                          isEditing
                              ? 'Actualiza la información del lote de producción.'
                              : 'Registra la información del lote de producción.',

                          style: theme.textTheme.bodySmall?.copyWith(
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

            /*
            ═══════════════════════════════
            FORMULARIO
            ═══════════════════════════════
            */
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),

                child: Form(
                  key: _formKey,

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      /*
                      ═══════════════════════
                      SECCIÓN 1
                      INFO GENERAL
                      ═══════════════════════
                      */
                      _FormSection(
                        icon: Icons.layers_outlined,

                        title: 'Información general',

                        subtitle:
                            'Define el cliente, tipo de piel y fecha de ingreso del lote.',

                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final desktop = constraints.maxWidth >= 700;

                            final clienteField = DropdownButtonFormField<int>(
                              isExpanded: true,

                              initialValue: _selectedClienteId,

                              items: widget.clienteOptions
                                  .map(
                                    (option) => DropdownMenuItem<int>(
                                      value: option.id,

                                      child: Text(
                                        option.label,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),

                              decoration: const InputDecoration(
                                labelText: 'Cliente *',

                                hintText: 'Selecciona un cliente',

                                prefixIcon: Icon(
                                  Icons.people_outline_rounded,
                                  size: 18,
                                ),
                              ),

                              onChanged: widget.isSubmitting
                                  ? null
                                  : (value) => setState(
                                      () => _selectedClienteId = value,
                                    ),

                              validator: (value) => value == null
                                  ? 'Selecciona un cliente activo.'
                                  : null,
                            );

                            final tipoPielField = DropdownButtonFormField<int>(
                              isExpanded: true,

                              initialValue: _selectedTipoPielId,

                              items: widget.tipoPielOptions
                                  .map(
                                    (option) => DropdownMenuItem<int>(
                                      value: option.id,

                                      child: Text(
                                        option.label,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),

                              decoration: const InputDecoration(
                                labelText: 'Tipo de piel *',

                                hintText: 'Selecciona un tipo de piel',

                                prefixIcon: Icon(Icons.sell_outlined, size: 18),
                              ),

                              onChanged: widget.isSubmitting
                                  ? null
                                  : (value) => setState(
                                      () => _selectedTipoPielId = value,
                                    ),

                              validator: (value) => value == null
                                  ? 'Selecciona un tipo de piel activo.'
                                  : null,
                            );

                            final fechaField = InkWell(
                              onTap: widget.isSubmitting
                                  ? null
                                  : _pickFechaIngreso,

                              borderRadius: BorderRadius.circular(8),

                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Fecha de ingreso *',

                                  prefixIcon: Icon(
                                    Icons.calendar_today_outlined,
                                    size: 18,
                                  ),

                                  suffixIcon: Icon(
                                    Icons.calendar_month_outlined,
                                    size: 18,
                                  ),
                                ),

                                child: Text(dateLabel),
                              ),
                            );

                            final cantidadField = TextFormField(
                              controller: _cantidadController,

                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),

                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*[.,]?\d{0,2}'),
                                ),
                              ],

                              decoration: const InputDecoration(
                                labelText: 'Cantidad de pieles inicial *',

                                hintText: 'Ej. 100',

                                prefixIcon: Icon(
                                  Icons.layers_outlined,
                                  size: 18,
                                ),
                              ),

                              validator: (value) {
                                final text = value?.trim() ?? '';

                                final number = _parseNumber(text);

                                if (number == null || number <= 0) {
                                  return 'Ingresa una cantidad válida mayor a cero.';
                                }

                                return null;
                              },
                            );

                            if (desktop) {
                              return Column(
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: clienteField),

                                      const Gap(AppSpacing.md),

                                      Expanded(child: tipoPielField),
                                    ],
                                  ),

                                  const Gap(AppSpacing.md),

                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: fechaField),

                                      const Gap(AppSpacing.md),

                                      Expanded(child: cantidadField),
                                    ],
                                  ),
                                ],
                              );
                            }

                            return Column(
                              children: [
                                clienteField,

                                const Gap(AppSpacing.md),

                                tipoPielField,

                                const Gap(AppSpacing.md),

                                fechaField,

                                const Gap(AppSpacing.md),

                                cantidadField,
                              ],
                            );
                          },
                        ),
                      ),

                      const Gap(AppSpacing.md),

                      /*
                      ═══════════════════════
                      SECCIÓN 2
                      COSTO
                      ═══════════════════════
                      */
                      _FormSection(
                        icon: Icons.settings_outlined,

                        title: 'Costo del lote',

                        subtitle:
                            'Configura el costo por piel. Si el cliente trae su propio lote, el costo debe quedar en cero.',

                        trailing: _OwnBatchSwitch(
                          value: _clienteTraeLote,

                          enabled: !widget.isSubmitting,

                          onChanged: (value) {
                            setState(() {
                              _clienteTraeLote = value;

                              _syncCostoTraeLote();
                            });
                          },
                        ),

                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final desktop = constraints.maxWidth >= 700;

                            final costoField = TextFormField(
                              controller: _costoController,

                              enabled: !_clienteTraeLote,

                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),

                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*[.,]?\d{0,2}'),
                                ),
                              ],

                              decoration: const InputDecoration(
                                labelText: 'Costo unitario por piel',

                                hintText: 'Ej. 5.00',

                                prefixIcon: Icon(
                                  Icons.payments_outlined,
                                  size: 18,
                                ),
                              ),

                              validator: (value) {
                                final text = value?.trim() ?? '';

                                final number = _parseNumber(text);

                                if (number == null || number < 0) {
                                  return 'Ingresa un costo válido.';
                                }

                                if (_clienteTraeLote && number != 0) {
                                  return 'Cuando el cliente trae lote, el costo debe ser 0.';
                                }

                                return null;
                              },
                            );

                            final totalField = InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Costo total de pieles (automático)',

                                prefixIcon: Icon(
                                  Icons.calculate_outlined,
                                  size: 18,
                                ),
                              ),

                              child: Text(
                                _formatMoney(_costoTotalCalculado),

                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,

                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            );

                            if (desktop) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: costoField),

                                  const Gap(AppSpacing.md),

                                  Expanded(child: totalField),
                                ],
                              );
                            }

                            return Column(
                              children: [
                                costoField,

                                const Gap(AppSpacing.md),

                                totalField,
                              ],
                            );
                          },
                        ),
                      ),

                      const Gap(AppSpacing.md),

                      /*
                      ═══════════════════════
                      SECCIÓN 3
                      OBSERVACIÓN
                      ═══════════════════════
                      */
                      _FormSection(
                        icon: Icons.description_outlined,

                        title: 'Observación',

                        subtitle: 'Agrega una observación adicional del lote.',

                        child: TextFormField(
                          controller: _observacionController,

                          maxLength: 500,

                          minLines: 2,

                          maxLines: 3,

                          textCapitalization: TextCapitalization.sentences,

                          decoration: const InputDecoration(
                            hintText: 'Escribe una observación...',

                            prefixIcon: Padding(
                              padding: EdgeInsets.only(bottom: 34),

                              child: Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            /*
            ═══════════════════════════════
            FOOTER
            ═══════════════════════════════
            */
            Divider(height: 1, color: theme.colorScheme.outlineVariant),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),

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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/*
════════════════════════════════════════════════════════
SECCIÓN DEL FORMULARIO
════════════════════════════════════════════════════════
*/

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(AppSpacing.lg),

      decoration: BoxDecoration(
        color: theme.colorScheme.surface,

        borderRadius: BorderRadius.circular(12),

        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,

                alignment: Alignment.center,

                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,

                  borderRadius: BorderRadius.circular(10),
                ),

                child: Icon(icon, size: 21, color: theme.colorScheme.primary),
              ),

              const Gap(AppSpacing.md),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,

                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const Gap(2),

                    Text(
                      subtitle,

                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              if (trailing != null) ...[const Gap(AppSpacing.md), trailing!],
            ],
          ),

          const Gap(AppSpacing.lg),

          child,
        ],
      ),
    );
  }
}

/*
════════════════════════════════════════════════════════
SWITCH CLIENTE TRAE LOTE
════════════════════════════════════════════════════════
*/

class _OwnBatchSwitch extends StatelessWidget {
  const _OwnBatchSwitch({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final bool value;
  final bool enabled;

  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 275),

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'El cliente trae su propio lote',

                  textAlign: TextAlign.right,

                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const Gap(2),

                Text(
                  value
                      ? 'Costo de pieles en cero'
                      : 'Costo configurado por piel',

                  textAlign: TextAlign.right,

                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const Gap(AppSpacing.md),

          Switch.adaptive(value: value, onChanged: enabled ? onChanged : null),
        ],
      ),
    );
  }
}
