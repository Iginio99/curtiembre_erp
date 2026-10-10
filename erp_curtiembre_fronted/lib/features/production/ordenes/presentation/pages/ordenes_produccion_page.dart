import 'dart:async';

import 'package:erp_curtiembre_fronted/core/di/service_locator.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_state.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/consumo_planificado_record.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/consumo_real_record.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/control_calidad_record.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/desviacion_consumo_record.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/merma_proceso_record.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/orden_proceso_record.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/orden_produccion_record.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/orden_producto_record.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/producto_terminado_record.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/personal_empresa_option.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/presentation/cubit/ordenes_produccion_cubit.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/presentation/cubit/ordenes_produccion_state.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/presentation/widgets/finalizar_orden_dialog.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/presentation/widgets/orden_simple_action_dialog.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/presentation/widgets/orden_upsert_dialog.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/presentation/widgets/registrar_calidad_final_dialog.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/presentation/widgets/registrar_merma_dialog.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/presentation/widgets/solicitar_consumo_dialog.dart';
import 'package:erp_curtiembre_fronted/features/security/presentation/cubit/security_access_cubit.dart';
import 'package:erp_curtiembre_fronted/shared/navigation/app_access_routes.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/buttons/app_button.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/feedback/app_message_card.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/layout/app_shell.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/layout/app_surface_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:talker_flutter/talker_flutter.dart';

class OrdenesProduccionPage extends StatefulWidget {
  const OrdenesProduccionPage({super.key});

  @override
  State<OrdenesProduccionPage> createState() => _OrdenesProduccionPageState();
}

class _OrdenProductosSection extends StatelessWidget {
  const _OrdenProductosSection({required this.state, required this.stageCode});
  final OrdenesProduccionState state;
  final String stageCode;

  Future<void> _requestSupplies(
    BuildContext context,
    OrdenProductoRecord product,
  ) async {
    OrdenProcesoRecord? process;
    for (final candidate in state.selectedProcesos) {
      if (candidate.procesoCodigo == stageCode) process = candidate;
    }
    if (process == null) return;

    OrdenProductoFormulaRecord? assignedFormula;
    for (final candidate in product.formulas) {
      if (candidate.procesoCodigo == stageCode) {
        assignedFormula = candidate;
        break;
      }
    }
    FormulaProduccionOption? formulaOption;
    if (assignedFormula != null) {
      for (final candidate in state.formulaProduccionOptions) {
        if (candidate.formulaVersionId == assignedFormula.formulaVersionId) {
          formulaOption = candidate;
          break;
        }
      }
    }
    if (assignedFormula == null || formulaOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se encontro la formula con la que se inicio este producto.',
          ),
        ),
      );
      return;
    }
    final payload = await showDialog<SolicitarConsumoDialogResult>(
      context: context,
      builder: (_) => SolicitarConsumoDialog(
        proceso: process!,
        insumos: state.insumoOptions,
        formulas: const [],
        formulaAsignada: formulaOption,
        pesoBaseAsignado: assignedFormula!.kilosBase,
        cantidadPielesAsignada: product.cantidadPieles,
        isSubmitting: state.isSubmittingAction,
      ),
    );
    if (payload == null || !context.mounted) return;
    final result = await context
        .read<OrdenesProduccionCubit>()
        .solicitarConsumo(
          ordenProcesoId: payload.ordenProcesoId,
          ordenProductoId: product.id,
          motivo: payload.motivo,
          observacion: '${product.nombre}: ${payload.observacion ?? ''}'.trim(),
          detalles: payload.detalles,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    }
  }

  Future<void> _open(BuildContext context, [OrdenProductoRecord? item]) async {
    final totalSkins = state.selectedOrden?.cantidadPieles ?? 0;
    final assignedToOtherProducts = state.ordenProductos
        .where((product) => product.id != item?.id)
        .fold<double>(0, (total, product) => total + product.cantidadPieles);
    final availableSkins = totalSkins - assignedToOtherProducts;
    final input = await showDialog<OrdenProductoInput>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _OrdenProductoDialog(
        item: item,
        products: state.productoProduccionOptions,
        maxPieles: availableSkins,
      ),
    );
    if (input == null || !context.mounted) return;
    final result = await context.read<OrdenesProduccionCubit>().saveProducto(
      id: item?.id,
      input: input,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    }
  }

  Future<void> _runProcess(
    BuildContext context,
    OrdenProductoRecord product,
    String process,
    bool finish,
  ) async {
    double? completed;
    int? formulaVersionId;
    double? pesoBaseKg;
    int? responsableId;
    if (!finish) {
      final options = state.formulaProduccionOptions
          .where((x) => x.procesoCodigo == process)
          .toList();
      int? selectedFormula = options.length == 1
          ? options.first.formulaVersionId
          : null;
      int? selectedResponsable = state.personalOptions.isEmpty
          ? null
          : state.personalOptions.first.id;
      final weightController = TextEditingController();
      final selection = await showDialog<(int, double, int)>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(
              'Iniciar ${process == 'RECURTIDO' ? 'Recurtido' : 'Acabado'} - ${product.nombre}',
            ),
            content: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: selectedFormula,
                    decoration: const InputDecoration(
                      labelText: 'Formula del producto',
                    ),
                    items: options
                        .map(
                          (x) => DropdownMenuItem(
                            value: x.formulaVersionId,
                            child: Text(
                              '${x.formulaNombre} - v${x.numeroVersion}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => selectedFormula = value),
                  ),
                  const Gap(AppSpacing.md),
                  DropdownButtonFormField<int>(
                    initialValue: selectedResponsable,
                    decoration: const InputDecoration(
                      labelText: 'Responsable del producto',
                    ),
                    items: state.personalOptions
                        .map(
                          (person) => DropdownMenuItem(
                            value: person.id,
                            child: Text(person.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => selectedResponsable = value),
                  ),
                  const Gap(AppSpacing.md),
                  TextField(
                    controller: weightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Peso base (kg)',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  final weight = double.tryParse(
                    weightController.text.replaceAll(',', '.'),
                  );
                  if (selectedFormula != null &&
                      selectedResponsable != null &&
                      weight != null &&
                      weight > 0) {
                    Navigator.pop(dialogContext, (
                      selectedFormula!,
                      weight,
                      selectedResponsable!,
                    ));
                  }
                },
                child: const Text('Iniciar producto'),
              ),
            ],
          ),
        ),
      );
      weightController.dispose();
      if (selection == null || !context.mounted) return;
      formulaVersionId = selection.$1;
      pesoBaseKg = selection.$2;
      responsableId = selection.$3;
    }
    if (finish && process == 'ACABADO') {
      final controller = TextEditingController(
        text: product.cantidadPieles.toStringAsFixed(0),
      );
      completed = await showDialog<double>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Finalizar Acabado - ${product.nombre}'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Pieles terminadas',
              helperText:
                  'Maximo: ${product.cantidadPieles.toStringAsFixed(0)}',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final value = double.tryParse(
                  controller.text.replaceAll(',', '.'),
                );
                if (value != null &&
                    value > 0 &&
                    value <= product.cantidadPieles) {
                  Navigator.pop(dialogContext, value);
                }
              },
              child: const Text('Finalizar y registrar'),
            ),
          ],
        ),
      );
      controller.dispose();
      if (completed == null || !context.mounted) return;
    }
    final result = await context
        .read<OrdenesProduccionCubit>()
        .updateProductoProcess(
          productoId: product.id,
          proceso: process,
          finalizar: finish,
          cantidadPielesTerminadas: completed,
          formulaVersionId: formulaVersionId,
          pesoBaseKg: pesoBaseKg,
          responsableId: responsableId,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final order = state.selectedOrden;
    final usedSkins = state.ordenProductos.fold<double>(
      0,
      (a, b) => a + b.cantidadPieles,
    );
    final usedSides = state.ordenProductos.fold<double>(
      0,
      (a, b) => a + b.cantidadLados,
    );
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Productos en ${stageCode == 'RECURTIDO' ? 'Recurtido' : 'Acabado'}',
                      style: theme.textTheme.titleLarge,
                    ),
                    Text(
                      stageCode == 'RECURTIDO'
                          ? 'Distribuye las pieles y controla el avance independiente de cada producto.'
                          : 'Cada producto puede avanzar a Acabado cuando termine su Recurtido.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (stageCode == 'RECURTIDO')
                AppButton.primary(
                  label: 'Agregar producto',
                  icon: Icons.add_rounded,
                  expand: false,
                  onPressed: order == null || state.isSubmittingAction
                      ? null
                      : () => _open(context),
                ),
            ],
          ),
          const Gap(AppSpacing.md),
          Text(
            'Asignado: ${usedSkins.toStringAsFixed(0)} de ${order?.cantidadPieles.toStringAsFixed(0) ?? '-'} pieles Ã‚Â· ${usedSides.toStringAsFixed(0)} lados',
          ),
          const Gap(AppSpacing.md),
          if (state.ordenProductos.isEmpty)
            AppMessageCard.info(
              title: 'Sin division de productos',
              message: stageCode == 'RECURTIDO'
                  ? 'Agrega aqui los productos que se obtendran de esta orden.'
                  : 'Primero registra los productos dentro de la etapa de Recurtido.',
            )
          else
            ...state.ordenProductos.map((p) {
              final hasPendingRequest = p.hasPendingSupplyRequest(stageCode);
              final hasApprovedRequest = p.hasApprovedSupplies(stageCode);
              final isCurrentProcessRunning = stageCode == 'RECURTIDO'
                  ? p.estadoRecurtido == 'EN_PROCESO'
                  : p.estadoAcabado == 'EN_PROCESO';
              final productConsumptions = state.consumoReal
                  .where(
                    (item) =>
                        item.ordenProductoId == p.id &&
                        item.procesoCodigo == stageCode,
                  )
                  .toList(growable: false);
              final processWeight = stageCode == 'RECURTIDO'
                  ? 'Recurtido ${p.kilosRecurtido.toStringAsFixed(2)} kg'
                  : p.estadoAcabado == 'PENDIENTE'
                  ? 'Peso de Acabado pendiente'
                  : 'Acabado ${p.kilosAcabado.toStringAsFixed(2)} kg';
              final processResponsible = stageCode == 'RECURTIDO'
                  ? p.responsableRecurtidoNombre
                  : p.responsableAcabadoNombre;
              final processCost = p.formulas
                  .where((formula) => formula.procesoCodigo == stageCode)
                  .fold<double>(
                    0,
                    (total, formula) => total + formula.costoEstimado,
                  );
              final hasProcessFormula = p.formulas.any(
                (formula) => formula.procesoCodigo == stageCode,
              );
              final processCostText = hasProcessFormula
                  ? 'Costo estimado de ${stageCode == 'RECURTIDO' ? 'Recurtido' : 'Acabado'} S/ ${processCost.toStringAsFixed(2)} Ã‚Â· S/ ${(p.cantidadLados > 0 ? processCost / p.cantidadLados : 0).toStringAsFixed(2)} por lado'
                  : 'Costo estimado de ${stageCode == 'RECURTIDO' ? 'Recurtido' : 'Acabado'} pendiente';
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: Text(
                          '${p.nombre}${(p.color ?? '').isEmpty ? '' : ' Ã‚Â· ${p.color}'}',
                        ),
                        subtitle: Text(
                          '${p.cantidadPieles.toStringAsFixed(0)} pieles Ã‚Â· ${p.cantidadLados.toStringAsFixed(0)} lados Ã‚Â· $processWeight\nResponsable: ${processResponsible ?? 'Pendiente de asignar'}\n$processCostText',
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_rounded),
                          tooltip: 'Editar producto',
                          onPressed: p.estadoRecurtido == 'PENDIENTE'
                              ? () => _open(context, p)
                              : null,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          0,
                          AppSpacing.md,
                          AppSpacing.md,
                        ),
                        child: Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (hasPendingRequest || hasApprovedRequest)
                              OutlinedButton.icon(
                                onPressed: null,
                                icon: Icon(
                                  hasPendingRequest
                                      ? Icons.schedule_rounded
                                      : Icons.check_circle_outline_rounded,
                                ),
                                label: Text(
                                  hasPendingRequest
                                      ? 'Solicitud enviada Ã‚Â· Pendiente de aprobacion'
                                      : 'Insumos aprobados',
                                ),
                              ),
                            if (stageCode == 'RECURTIDO')
                              Chip(
                                label: Text('Recurtido: ${p.estadoRecurtido}'),
                              ),
                            if (stageCode == 'RECURTIDO' &&
                                p.estadoRecurtido == 'PENDIENTE')
                              OutlinedButton(
                                onPressed: state.isSubmittingAction
                                    ? null
                                    : () => _runProcess(
                                        context,
                                        p,
                                        'RECURTIDO',
                                        false,
                                      ),
                                child: const Text('Iniciar'),
                              ),
                            if (stageCode == 'RECURTIDO' &&
                                p.estadoRecurtido == 'EN_PROCESO')
                              FilledButton(
                                onPressed:
                                    state.isSubmittingAction ||
                                        !hasApprovedRequest
                                    ? null
                                    : () => _runProcess(
                                        context,
                                        p,
                                        'RECURTIDO',
                                        true,
                                      ),
                                child: const Text('Finalizar'),
                              ),
                            if (stageCode == 'ACABADO')
                              Chip(label: Text('Acabado: ${p.estadoAcabado}')),
                            if (stageCode == 'ACABADO' &&
                                p.estadoRecurtido == 'FINALIZADO' &&
                                p.estadoAcabado == 'PENDIENTE')
                              OutlinedButton(
                                onPressed: state.isSubmittingAction
                                    ? null
                                    : () => _runProcess(
                                        context,
                                        p,
                                        'ACABADO',
                                        false,
                                      ),
                                child: const Text('Iniciar'),
                              ),
                            if (stageCode == 'ACABADO' &&
                                p.estadoAcabado == 'EN_PROCESO')
                              FilledButton(
                                onPressed:
                                    state.isSubmittingAction ||
                                        !hasApprovedRequest
                                    ? null
                                    : () => _runProcess(
                                        context,
                                        p,
                                        'ACABADO',
                                        true,
                                      ),
                                child: const Text('Finalizar'),
                              ),
                            if (isCurrentProcessRunning)
                              OutlinedButton.icon(
                                onPressed:
                                    state.isSubmittingAction ||
                                        hasPendingRequest
                                    ? null
                                    : () => _requestSupplies(context, p),
                                icon: const Icon(Icons.inventory_2_outlined),
                                label: const Text('Solicitar insumos'),
                              ),
                            if (stageCode == 'ACABADO' &&
                                p.cantidadPielesTerminadas != null)
                              Text(
                                'Terminado: ${p.cantidadPielesTerminadas!.toStringAsFixed(0)} pieles',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (productConsumptions.isNotEmpty) ...[
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Insumos utilizados por ${p.nombre}',
                                style: theme.textTheme.titleSmall,
                              ),
                              const Gap(AppSpacing.sm),
                              _ConsumoRealTable(items: productConsumptions),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _OrdenProductoDialog extends StatefulWidget {
  const _OrdenProductoDialog({
    this.item,
    required this.products,
    required this.maxPieles,
  });
  final OrdenProductoRecord? item;
  final List<ProductoProduccionOption> products;
  final double maxPieles;
  @override
  State<_OrdenProductoDialog> createState() => _OrdenProductoDialogState();
}

class _OrdenProductoDialogState extends State<_OrdenProductoDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _code, _name, _color, _skins, _sides;
  int? _productId;
  @override
  void initState() {
    super.initState();
    final p = widget.item;
    _code = TextEditingController(text: p?.codigo);
    _name = TextEditingController(text: p?.nombre);
    _color = TextEditingController(text: p?.color);
    _skins = TextEditingController(text: p?.cantidadPieles.toString());
    _sides = TextEditingController(text: p?.cantidadLados.toString());
    _skins.addListener(_calculateSides);
    if (p != null) {
      for (final product in widget.products) {
        if (product.codigo == p.codigo) {
          _productId = product.id;
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    _skins.removeListener(_calculateSides);
    for (final c in [_code, _name, _color, _skins, _sides]) {
      c.dispose();
    }
    super.dispose();
  }

  void _calculateSides() {
    final skins = double.tryParse(_skins.text.replaceAll(',', '.'));
    final next = skins == null
        ? ''
        : (skins * 2).toStringAsFixed(skins % 1 == 0 ? 0 : 2);
    if (_sides.text != next) _sides.text = next;
  }

  void _selectProduct(int? productId) {
    if (productId == null) return;
    final product = widget.products.firstWhere((x) => x.id == productId);
    setState(() {
      _productId = productId;
      _code.text = product.codigo;
      _name.text = product.nombre;
    });
  }

  String? _required(String? v) =>
      v == null || v.trim().isEmpty ? 'Obligatorio' : null;
  String? _positive(String? v) {
    final n = double.tryParse((v ?? '').replaceAll(',', '.'));
    return n == null || n <= 0 ? 'Ingresa un valor mayor que cero' : null;
  }

  String? _skinsValidator(String? value) {
    final positiveError = _positive(value);
    if (positiveError != null) return positiveError;
    final skins = double.parse(value!.replaceAll(',', '.'));
    if (skins > widget.maxPieles) {
      return 'Solo hay ${widget.maxPieles.toStringAsFixed(0)} pieles disponibles';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final products = {
      for (final product in widget.products) product.id: product,
    };
    return AlertDialog(
      title: Text(widget.item == null ? 'Agregar producto' : 'Editar producto'),
      content: SizedBox(
        width: 720,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _productId,
                  decoration: const InputDecoration(labelText: 'Producto'),
                  items: products.values
                      .map(
                        (x) => DropdownMenuItem(
                          value: x.id,
                          child: Text('${x.codigo} - ${x.nombre}'),
                        ),
                      )
                      .toList(),
                  onChanged: widget.item == null ? _selectProduct : null,
                  validator: (value) => value == null
                      ? 'Selecciona un producto del catalogo'
                      : null,
                ),
                const Gap(AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _skins,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Cantidad de pieles',
                          helperText:
                              'Disponibles: ${widget.maxPieles.toStringAsFixed(0)}',
                        ),
                        validator: _skinsValidator,
                      ),
                    ),
                    const Gap(AppSpacing.md),
                    Expanded(
                      child: TextFormField(
                        controller: _sides,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Cantidad de lados (automatico)',
                        ),
                        readOnly: true,
                        validator: _positive,
                      ),
                    ),
                  ],
                ),
                const Gap(AppSpacing.md),
                TextFormField(
                  controller: _color,
                  decoration: const InputDecoration(
                    labelText: 'Color de fondo de Recurtido',
                  ),
                  validator: _required,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            const kgR = 0.0;
            const kgA = 0.0;
            Navigator.pop(
              context,
              OrdenProductoInput(
                codigo: _code.text.trim(),
                nombre: _name.text.trim(),
                color: _color.text.trim(),
                cantidadPieles: double.parse(_skins.text.replaceAll(',', '.')),
                cantidadLados: double.parse(_sides.text.replaceAll(',', '.')),
                kilosRecurtido: kgR,
                kilosAcabado: kgA,
                observacion: widget.item?.observacion,
                formulas: const [],
              ),
            );
          },
          child: const Text('Guardar producto'),
        ),
      ],
    );
  }
}

class _OrdenesProduccionPageState extends State<OrdenesProduccionPage> {
  final _searchController = TextEditingController();
  final _estadoController = TextEditingController();
  final Talker _talker = getIt<Talker>();
  bool _showOrderDetail = false;
  Timer? _filterDebounce;
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    _talker.ui('Se abrio la pantalla de ordenes de produccion.');
  }

  @override
  void dispose() {
    _filterDebounce?.cancel();
    _searchController.dispose();
    _estadoController.dispose();
    super.dispose();
  }

  void _scheduleFilters() {
    _filterDebounce?.cancel();
    _filterDebounce = Timer(const Duration(milliseconds: 350), _applyFilters);
  }

  void _applyFilters() {
    FocusScope.of(context).unfocus();
    _talker.ui(
      'Se aplicaron filtros en ordenes con texto=${_describeText(_searchController.text)}, estado=${_describeState(_estadoController.text)}.',
    );
    context.read<OrdenesProduccionCubit>().load(
      searchTerm: _searchController.text.trim(),
      estado: _estadoController.text.trim().isEmpty
          ? null
          : _estadoController.text.trim(),
    );
  }

  Future<PersonalEmpresaOption?> _createPersonal() async {
    final nombre = TextEditingController();
    final cargo = TextEditingController();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nuevo personal'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombre,
                decoration: const InputDecoration(labelText: 'Nombre completo'),
              ),
              const Gap(AppSpacing.md),
              TextField(
                controller: cargo,
                decoration: const InputDecoration(labelText: 'Cargo'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
    if (accepted != true ||
        nombre.text.trim().isEmpty ||
        cargo.text.trim().isEmpty ||
        !mounted) {
      return null;
    }
    return context.read<OrdenesProduccionCubit>().createPersonal(
      nombre: nombre.text.trim(),
      cargo: cargo.text.trim(),
    );
  }

  Future<void> _openCreateDialog(OrdenesProduccionState state) async {
    _talker.ui('Se abrio el dialogo para crear una orden de produccion.');
    final payload = await showDialog<OrdenUpsertFormData>(
      context: context,
      builder: (_) => OrdenUpsertDialog(
        title: 'Nueva orden de produccion',
        submitLabel: 'Crear orden',
        isSubmitting: state.isSubmittingAction,
        clienteOptions: state.clienteOptions,
        loteOptions: state.loteOptions,
        responsableOptions: state.personalOptions,
        onAddPersonal: _createPersonal,
      ),
    );

    if (payload == null || !mounted) {
      _talker.ui(
        'Se cerro el dialogo de creacion de orden sin confirmar.',
        logLevel: LogLevel.debug,
      );
      return;
    }
    _talker.ui(
      'Se confirmo la creacion de orden para loteId=${payload.loteId}, clienteId=${payload.clienteId}.',
    );

    final result = await context.read<OrdenesProduccionCubit>().createOrden(
      loteId: payload.loteId,
      clienteId: payload.clienteId,
      cantidadPieles: payload.cantidadPieles,
      fechaInicioPlanificada: payload.fechaInicioPlanificada,
      fechaFinEstimada: payload.fechaFinEstimada,
      observacion: payload.observacion,
      responsableNombre: payload.responsableNombre,
      responsableCargo: payload.responsableCargo,
    );

    if (!mounted) {
      return;
    }

    _showActionResult(result);
  }

  Future<void> _startSelectedOrden() async {
    _talker.ui('Se abrio el dialogo para iniciar la orden seleccionada.');
    final payload = await showDialog<OrdenSimpleActionFormData>(
      context: context,
      builder: (_) => OrdenSimpleActionDialog(
        title: 'Iniciar orden',
        submitLabel: 'Iniciar',
        labelText: 'Observacion inicial',
        hintText: 'Detalle breve del arranque de la orden',
        requireStagePlanning: true,
        responsableOptions: context
            .read<OrdenesProduccionCubit>()
            .state
            .personalOptions,
        onAddPersonal: _createPersonal,
      ),
    );

    if (!mounted) {
      return;
    }
    if (payload == null) {
      _talker.ui(
        'Se cerro el inicio de orden sin confirmar.',
        logLevel: LogLevel.debug,
      );
      return;
    }
    _talker.ui('Se confirmo el inicio de la orden seleccionada.');

    final result = await context
        .read<OrdenesProduccionCubit>()
        .startSelectedOrden(
          pesoBaseKg: payload.pesoBaseKg!,
          fechaFinEstimada: payload.fechaFinEstimada!,
          observacion: payload.observacion,
          responsableNombre: payload.responsableNombre!,
          responsableCargo: payload.responsableCargo!,
        );
    if (!mounted) {
      return;
    }
    _showActionResult(result);
  }

  Future<void> _cancelSelectedOrden() async {
    _talker.ui(
      'Se abrio el dialogo para anular la orden seleccionada.',
      logLevel: LogLevel.warning,
    );
    final payload = await showDialog<OrdenSimpleActionFormData>(
      context: context,
      builder: (_) => const OrdenSimpleActionDialog(
        title: 'Anular orden',
        submitLabel: 'Anular orden',
        labelText: 'Motivo de anulacion',
        hintText: 'Explica por que la orden ya no debe continuar',
        requireValue: true,
      ),
    );

    if (!mounted) {
      return;
    }
    if (payload == null || (payload.motivo?.trim().isEmpty ?? true)) {
      _talker.ui(
        'Se cerro la anulacion de orden sin confirmar.',
        logLevel: LogLevel.debug,
      );
      return;
    }
    _talker.ui(
      'Se confirmo la anulacion de la orden seleccionada con motivo=${_describeText(payload.motivo)}.',
      logLevel: LogLevel.warning,
    );

    final result = await context
        .read<OrdenesProduccionCubit>()
        .cancelSelectedOrden(motivo: payload.motivo!);
    if (!mounted) {
      return;
    }
    _showActionResult(result);
  }

  Future<void> _startProceso(OrdenProcesoRecord proceso) async {
    _talker.ui('Se abrio el dialogo para iniciar el proceso ${proceso.id}.');
    final payload = await showDialog<OrdenSimpleActionFormData>(
      context: context,
      builder: (_) => OrdenSimpleActionDialog(
        title: 'Iniciar ${proceso.procesoNombre}',
        submitLabel: 'Iniciar proceso',
        labelText: 'Observacion de inicio',
        hintText: 'Detalle breve del arranque del proceso',
        requireStagePlanning: proceso.estado == 'PENDIENTE',
        responsableOptions: context
            .read<OrdenesProduccionCubit>()
            .state
            .personalOptions,
        onAddPersonal: _createPersonal,
      ),
    );

    if (!mounted) {
      return;
    }
    if (payload == null) {
      _talker.ui(
        'Se cerro el inicio del proceso ${proceso.id} sin confirmar.',
        logLevel: LogLevel.debug,
      );
      return;
    }
    _talker.ui('Se confirmo el inicio del proceso ${proceso.id}.');

    final result = await context.read<OrdenesProduccionCubit>().startProceso(
      procesoId: proceso.id,
      pesoBaseKg: payload.pesoBaseKg ?? 0,
      fechaFinEstimada: payload.fechaFinEstimada ?? DateTime.now(),
      observacion: payload.observacion,
      responsableNombre: payload.responsableNombre!,
      responsableCargo: payload.responsableCargo!,
    );
    if (!mounted) {
      return;
    }
    _showActionResult(result);
  }

  Future<void> _finishProceso(OrdenProcesoRecord proceso) async {
    _talker.ui('Se abrio el dialogo para finalizar el proceso ${proceso.id}.');
    final payload = await showDialog<OrdenSimpleActionFormData>(
      context: context,
      builder: (_) => OrdenSimpleActionDialog(
        title: 'Finalizar ${proceso.procesoNombre}',
        submitLabel: 'Finalizar proceso',
        labelText: 'Observacion de cierre',
        hintText: 'Resultado o detalle del cierre del proceso',
        requireCompletionDate: true,
        firstCompletionDate: proceso.fechaInicio,
      ),
    );

    if (!mounted) {
      return;
    }
    if (payload == null) {
      _talker.ui(
        'Se cerro la finalizacion del proceso ${proceso.id} sin confirmar.',
        logLevel: LogLevel.debug,
      );
      return;
    }
    _talker.ui('Se confirmo la finalizacion del proceso ${proceso.id}.');

    final result = await context.read<OrdenesProduccionCubit>().finishProceso(
      procesoId: proceso.id,
      fechaFinReal: payload.fechaFinReal!,
      observacion: payload.observacion,
    );
    if (!mounted) {
      return;
    }
    _showActionResult(result);
  }

  Future<void> _editProcesoObservacion(OrdenProcesoRecord proceso) async {
    _talker.ui(
      'Se abrio el dialogo para editar la observacion del proceso ${proceso.id}.',
    );
    final payload = await showDialog<OrdenSimpleActionFormData>(
      context: context,
      builder: (_) => OrdenSimpleActionDialog(
        title: 'Observacion de ${proceso.procesoNombre}',
        submitLabel: 'Guardar observacion',
        labelText: 'Observacion',
        hintText: 'Actualiza el comentario operativo del proceso',
        initialValue: proceso.observacion,
      ),
    );

    if (!mounted) {
      return;
    }
    if (payload == null) {
      _talker.ui(
        'Se cerro la edicion del proceso ${proceso.id} sin confirmar.',
        logLevel: LogLevel.debug,
      );
      return;
    }
    _talker.ui(
      'Se confirmo la actualizacion de observacion del proceso ${proceso.id}.',
    );

    final result = await context
        .read<OrdenesProduccionCubit>()
        .updateProcesoObservacion(
          procesoId: proceso.id,
          observacion: payload.observacion,
        );
    if (!mounted) {
      return;
    }
    _showActionResult(result);
  }

  Future<void> _generarConsumoPlanificado() async {
    _talker.ui(
      'Se solicito calcular el consumo planificado de la orden seleccionada.',
    );
    final result = await context
        .read<OrdenesProduccionCubit>()
        .generarConsumoPlanificado();
    if (!mounted) {
      return;
    }
    _showActionResult(result);
  }

  Future<void> _solicitarConsumo(
    OrdenProcesoRecord proceso,
    OrdenesProduccionState state,
  ) async {
    _talker.ui(
      'Se abrio el dialogo para solicitar insumos del proceso ${proceso.id}.',
    );
    final payload = await showDialog<SolicitarConsumoDialogResult>(
      context: context,
      builder: (_) => SolicitarConsumoDialog(
        proceso: proceso,
        insumos: state.insumoOptions,
        formulas: state.formulaProduccionOptions
            .where((x) => x.procesoProductivoId == proceso.procesoProductivoId)
            .toList(),
        isSubmitting: state.isSubmittingAction,
      ),
    );

    if (!mounted || payload == null) {
      _talker.ui(
        'Se cerro la solicitud de insumos del proceso ${proceso.id} sin confirmar.',
        logLevel: LogLevel.debug,
      );
      return;
    }
    _talker.ui(
      'Se confirmo la solicitud de insumos del proceso ${proceso.id} con ${payload.detalles.length} detalles.',
    );

    final result = await context
        .read<OrdenesProduccionCubit>()
        .solicitarConsumo(
          ordenProcesoId: payload.ordenProcesoId,
          motivo: payload.motivo,
          observacion: payload.observacion,
          detalles: payload.detalles,
        );

    if (!mounted) {
      return;
    }

    _showActionResult(result);
  }

  Future<void> _registrarMerma(
    OrdenProcesoRecord proceso,
    OrdenesProduccionState state,
  ) async {
    _talker.ui(
      'Se abrio el dialogo para registrar merma del proceso ${proceso.id}.',
    );
    final payload = await showDialog<RegistrarMermaDialogResult>(
      context: context,
      builder: (_) => RegistrarMermaDialog(
        proceso: proceso,
        isSubmitting: state.isSubmittingAction,
      ),
    );

    if (!mounted || payload == null) {
      _talker.ui(
        'Se cerro el registro de merma del proceso ${proceso.id} sin confirmar.',
        logLevel: LogLevel.debug,
      );
      return;
    }
    _talker.ui('Se confirmo el registro de merma del proceso ${proceso.id}.');

    final result = await context.read<OrdenesProduccionCubit>().registerMerma(
      procesoId: payload.procesoId,
      input: payload.input,
    );

    if (!mounted) {
      return;
    }

    _showActionResult(result);
  }

  Future<void> _registrarCalidadFinal(OrdenesProduccionState state) async {
    _talker.ui('Se abrio el dialogo para registrar calidad final.');
    final payload = await showDialog<RegistrarCalidadFinalDialogResult>(
      context: context,
      builder: (_) => RegistrarCalidadFinalDialog(
        isSubmitting: state.isSubmittingAction,
        cantidadPieles: state.selectedOrden?.cantidadPieles ?? 0,
        initialValue: state.controlCalidad,
      ),
    );

    if (!mounted || payload == null) {
      _talker.ui(
        'Se cerro el registro de calidad final sin confirmar.',
        logLevel: LogLevel.debug,
      );
      return;
    }
    _talker.ui(
      'Se confirmo el registro de calidad final con resultado=${payload.input.resultado}.',
    );

    final result = await context
        .read<OrdenesProduccionCubit>()
        .registerCalidadFinal(
          input: payload.input,
          update: state.controlCalidad != null,
        );

    if (!mounted) {
      return;
    }

    _showActionResult(result);
  }

  Future<void> _finalizarOrden(OrdenesProduccionState state) async {
    _talker.ui(
      'Se abrio el dialogo para finalizar la orden seleccionada.',
      logLevel: LogLevel.warning,
    );
    final payload = await showDialog<FinalizarOrdenDialogResult>(
      context: context,
      builder: (_) => FinalizarOrdenDialog(
        isSubmitting: state.isSubmittingAction,
        procesosFinalizados: state.selectedOrden?.procesosFinalizados ?? 0,
        procesosTotales: state.selectedOrden?.procesosTotales ?? 0,
        tieneProductoTerminado: state.productoTerminado != null,
        cantidadLadosClasificados:
            (state.controlCalidad?.cantidadLadosA ?? 0) +
            (state.controlCalidad?.cantidadLadosB ?? 0) +
            (state.controlCalidad?.cantidadLadosC ?? 0),
      ),
    );

    if (!mounted || payload == null) {
      _talker.ui(
        'Se cerro la finalizacion de orden sin confirmar.',
        logLevel: LogLevel.debug,
      );
      return;
    }
    _talker.ui(
      'Se confirmo la finalizacion de la orden con cantidadLados=${payload.input.cantidadLados}.',
      logLevel: LogLevel.warning,
    );

    final result = await context
        .read<OrdenesProduccionCubit>()
        .finalizeSelectedOrden(input: payload.input);

    if (!mounted) {
      return;
    }

    _showActionResult(result);
  }

  void _showActionResult(OrdenesActionResult result) {
    _talker.ui(
      result.success
          ? 'Accion en ordenes de produccion completada correctamente.'
          : 'La accion en ordenes de produccion fallo: ${result.message}',
      logLevel: result.success ? LogLevel.debug : LogLevel.error,
    );
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(result.message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: result.success ? null : const Color(0xFF8A2F22),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.select((AuthCubit cubit) => cubit.state.session);
    final isSigningOut = context.select(
      (AuthCubit cubit) => cubit.state.status == AuthStatus.signingOut,
    );
    final permissionCodes = context.select(
      (SecurityAccessCubit cubit) =>
          cubit.state.snapshot?.userPermissionCodes.toSet() ?? const <String>{},
    );

    if (session == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return AppShell(
      title: 'Ãƒâ€œrdenes de producciÃƒÂ³n',
      currentPath: '/produccion/ordenes',
      breadcrumbs: const ['Inicio', 'ProducciÃƒÂ³n', 'Ãƒâ€œrdenes'],
      userName: session.nombreCompleto,
      roleName: session.rolNombre,
      accessibleRoutes: AppAccessRoutes.forPermissions(permissionCodes),
      onSignOut: isSigningOut
          ? () {}
          : () => context.read<AuthCubit>().signOut(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1520),
                child: BlocBuilder<OrdenesProduccionCubit, OrdenesProduccionState>(
                  builder: (context, state) {
                    final compactHeight = constraints.maxHeight < 900;
                    final visibleItems = state.items
                        .where((item) {
                          final date = item.creadoEn.toLocal();
                          return date.year == _selectedMonth.year &&
                              date.month == _selectedMonth.month;
                        })
                        .toList(growable: false);
                    final displayState = state.copyWith(items: visibleItems);

                    if (_searchController.text != state.searchTerm) {
                      _searchController.value = TextEditingValue(
                        text: state.searchTerm,
                        selection: TextSelection.collapsed(
                          offset: state.searchTerm.length,
                        ),
                      );
                    }

                    if (_estadoController.text != (state.estadoFilter ?? '')) {
                      _estadoController.value = TextEditingValue(
                        text: state.estadoFilter ?? '',
                        selection: TextSelection.collapsed(
                          offset: (state.estadoFilter ?? '').length,
                        ),
                      );
                    }

                    final ordersBoard = _OrdersPipelineBoard(
                      state: displayState,
                      onRetry: () {
                        _talker.ui(
                          'Se solicito reintentar la carga del listado de ordenes.',
                        );
                        context.read<OrdenesProduccionCubit>().initialize();
                      },
                      onSelectOrden: (ordenId) {
                        _talker.ui(
                          'Se selecciono la orden $ordenId desde el listado.',
                          logLevel: LogLevel.debug,
                        );
                        context.read<OrdenesProduccionCubit>().selectOrden(
                          ordenId,
                        );
                        setState(() => _showOrderDetail = true);
                      },
                    );

                    final detailPanel = _OrdenDetailPanel(
                      state: state,
                      onRetry: () {
                        _talker.ui(
                          'Se solicito reintentar el detalle de la orden seleccionada.',
                        );
                        context.read<OrdenesProduccionCubit>().retryDetail();
                      },
                      onStartOrden: state.selectedOrden?.canStart == true
                          ? _startSelectedOrden
                          : null,
                      onCancelOrden: state.selectedOrden?.canCancel == true
                          ? _cancelSelectedOrden
                          : null,
                      onStartProceso: _startProceso,
                      onFinishProceso: _finishProceso,
                      onEditObservacion: _editProcesoObservacion,
                      onGeneratePlannedConsumption: _generarConsumoPlanificado,
                      onRequestConsumption: (proceso) =>
                          _solicitarConsumo(proceso, state),
                      onRegisterMerma: (proceso) =>
                          _registrarMerma(proceso, state),
                      onRegisterCalidadFinal: () =>
                          _registrarCalidadFinal(state),
                      onFinalizeOrden: () => _finalizarOrden(state),
                    );

                    final headerAndFilters = <Widget>[
                      _OrdenesFiltersCard(
                        searchController: _searchController,
                        estadoController: _estadoController,
                        state: state,
                        onApply: _applyFilters,
                        onSearchChanged: (_) => _scheduleFilters(),
                        onCreate: () => _openCreateDialog(state),
                        selectedMonth: _selectedMonth,
                        onMonthChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedMonth = value);
                          }
                        },
                        onClienteChanged: (value) {
                          _talker.ui(
                            'Se cambio el filtro de cliente en ordenes a ${value ?? 'ninguno'}.',
                            logLevel: LogLevel.debug,
                          );
                          context.read<OrdenesProduccionCubit>().load(
                            clienteId: value,
                            resetCliente: value == null,
                          );
                        },
                        onLoteChanged: (value) {
                          _talker.ui(
                            'Se cambio el filtro de lote en ordenes a ${value ?? 'ninguno'}.',
                            logLevel: LogLevel.debug,
                          );
                          context.read<OrdenesProduccionCubit>().load(
                            loteId: value,
                            resetLote: value == null,
                          );
                        },
                      ),
                      const Gap(AppSpacing.md),
                    ];

                    if (_showOrderDetail) {
                      final detailView = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextButton.icon(
                            onPressed: () =>
                                setState(() => _showOrderDetail = false),
                            icon: const Icon(Icons.arrow_back_rounded),
                            label: const Text('Volver al pipeline de ordenes'),
                          ),
                          const Gap(AppSpacing.md),
                          Expanded(child: detailPanel),
                        ],
                      );

                      if (!compactHeight) return detailView;
                      return SizedBox(height: 1050, child: detailView);
                    }

                    final boardView = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...headerAndFilters,
                        Expanded(child: ordersBoard),
                      ],
                    );

                    if (!compactHeight) return boardView;
                    return SizedBox(height: 760, child: boardView);
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _describeText(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return '${normalized.length} caracteres';
  }

  String _describeState(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return normalized;
  }
}

class _OrdenesFiltersCard extends StatelessWidget {
  const _OrdenesFiltersCard({
    required this.searchController,
    required this.estadoController,
    required this.state,
    required this.onApply,
    required this.onSearchChanged,
    required this.onCreate,
    required this.selectedMonth,
    required this.onMonthChanged,
    required this.onClienteChanged,
    required this.onLoteChanged,
  });

  final TextEditingController searchController;
  final TextEditingController estadoController;
  final OrdenesProduccionState state;
  final VoidCallback onApply;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onCreate;
  final DateTime selectedMonth;
  final ValueChanged<DateTime?> onMonthChanged;
  final ValueChanged<int?> onClienteChanged;
  final ValueChanged<int?> onLoteChanged;

  static const _estados = <String, String>{
    '': 'Todos los estados',
    'PROGRAMADA': 'Programadas',
    'ESPERANDO_MATERIALES': 'Esperando materiales',
    'LISTA_PARA_INICIAR': 'Lista para iniciar',
    'EN_PROCESO': 'En proceso',
    'FINALIZADA': 'Finalizadas',
    'ANULADA': 'Anuladas',
    'CANCELADA': 'Canceladas',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final clientId = state.selectedClienteId;
    final visibleLotes = clientId == null
        ? state.loteOptions
        : state.loteOptions.where((x) => x.clienteId == clientId).toList();
    final selectedLoteId = visibleLotes.any((x) => x.id == state.selectedLoteId)
        ? state.selectedLoteId
        : null;
    final months = List.generate(18, (index) {
      final now = DateTime.now();
      return DateTime(now.year, now.month - index);
    });

    Widget search() => TextField(
      controller: searchController,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => onApply(),
      onChanged: onSearchChanged,
      decoration: const InputDecoration(
        hintText: 'Buscar orden, cliente o lote...',
        prefixIcon: Icon(Icons.search_rounded, size: 20),
      ),
    );

    Widget client() => LayoutBuilder(
      builder: (context, constraints) => DropdownMenu<int>(
        key: ValueKey('cliente_filtro_$clientId'),
        width: constraints.maxWidth,
        initialSelection: clientId ?? -1,
        enableFilter: true,
        enableSearch: true,
        requestFocusOnTap: true,
        menuHeight: 240,
        label: const Text('Cliente'),
        leadingIcon: const Icon(Icons.groups_2_outlined, size: 19),
        dropdownMenuEntries: [
          const DropdownMenuEntry<int>(value: -1, label: 'Todos los clientes'),
          ...state.clienteOptions.map(
            (x) => DropdownMenuEntry<int>(value: x.id, label: x.label),
          ),
        ],
        onSelected: (id) {
          if (id == null) return;
          onClienteChanged(id == -1 ? null : id);
          if (selectedLoteId != null && id != clientId) onLoteChanged(null);
        },
      ),
    );

    Widget lote() => LayoutBuilder(
      builder: (context, constraints) => DropdownMenu<int>(
        key: ValueKey('lote_filtro_${clientId}_$selectedLoteId'),
        width: constraints.maxWidth,
        initialSelection: selectedLoteId ?? -1,
        enableFilter: true,
        enableSearch: true,
        requestFocusOnTap: true,
        menuHeight: 240,
        label: const Text('Lote'),
        leadingIcon: const Icon(Icons.inventory_2_outlined, size: 19),
        dropdownMenuEntries: [
          const DropdownMenuEntry<int>(value: -1, label: 'Todos los lotes'),
          ...visibleLotes.map(
            (x) => DropdownMenuEntry<int>(value: x.id, label: x.label),
          ),
        ],
        onSelected: (id) {
          if (id != null) onLoteChanged(id == -1 ? null : id);
        },
      ),
    );

    Widget status() => LayoutBuilder(
      builder: (context, constraints) => DropdownMenu<String>(
        key: ValueKey('estado_filtro_${estadoController.text}'),
        width: constraints.maxWidth,
        initialSelection: estadoController.text,
        enableFilter: true,
        enableSearch: true,
        requestFocusOnTap: true,
        menuHeight: 245,
        label: const Text('Estado'),
        leadingIcon: const Icon(Icons.check_circle_outline_rounded, size: 19),
        dropdownMenuEntries: _estados.entries
            .map(
              (entry) =>
                  DropdownMenuEntry(value: entry.key, label: entry.value),
            )
            .toList(),
        onSelected: (value) {
          if (value == null) return;
          estadoController.text = value;
          onSearchChanged(value);
        },
      ),
    );

    Widget month() => LayoutBuilder(
      builder: (context, constraints) => DropdownMenu<DateTime>(
        key: ValueKey(
          'mes_filtro_${selectedMonth.year}_${selectedMonth.month}',
        ),
        width: constraints.maxWidth,
        initialSelection: selectedMonth,
        enableFilter: true,
        enableSearch: true,
        requestFocusOnTap: true,
        menuHeight: 245,
        label: const Text('Mes'),
        leadingIcon: const Icon(Icons.calendar_month_outlined, size: 19),
        dropdownMenuEntries: months
            .map((x) => DropdownMenuEntry(value: x, label: _formatMonth(x)))
            .toList(),
        onSelected: onMonthChanged,
      ),
    );

    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 49,
                width: 49,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.factory_outlined,
                  color: colors.primary,
                  size: 25,
                ),
              ),
              const Gap(AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ãƒâ€œrdenes de producciÃƒÂ³n',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Gestiona y visualiza el estado de las ÃƒÂ³rdenes.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              AppButton.primary(
                label: 'Nueva orden',
                icon: Icons.add_rounded,
                isLoading: state.isSubmittingAction,
                onPressed: state.isSubmittingAction ? null : onCreate,
                expand: false,
              ),
            ],
          ),
          const Gap(AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 1050) {
                return Row(
                  children: [
                    Expanded(flex: 6, child: search()),
                    const Gap(AppSpacing.sm),
                    Expanded(flex: 5, child: client()),
                    const Gap(AppSpacing.sm),
                    Expanded(flex: 5, child: lote()),
                    const Gap(AppSpacing.sm),
                    Expanded(flex: 4, child: status()),
                    const Gap(AppSpacing.sm),
                    Expanded(flex: 4, child: month()),
                  ],
                );
              }
              if (constraints.maxWidth >= 630) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(flex: 2, child: search()),
                        const Gap(AppSpacing.sm),
                        Expanded(child: client()),
                      ],
                    ),
                    const Gap(AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(child: lote()),
                        const Gap(AppSpacing.sm),
                        Expanded(child: status()),
                        const Gap(AppSpacing.sm),
                        Expanded(child: month()),
                      ],
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  search(),
                  const Gap(AppSpacing.sm),
                  client(),
                  const Gap(AppSpacing.sm),
                  lote(),
                  const Gap(AppSpacing.sm),
                  status(),
                  const Gap(AppSpacing.sm),
                  month(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _OrdenDetailPanel extends StatelessWidget {
  const _OrdenDetailPanel({
    required this.state,
    required this.onRetry,
    required this.onStartOrden,
    required this.onCancelOrden,
    required this.onStartProceso,
    required this.onFinishProceso,
    required this.onEditObservacion,
    required this.onGeneratePlannedConsumption,
    required this.onRequestConsumption,
    required this.onRegisterMerma,
    required this.onRegisterCalidadFinal,
    required this.onFinalizeOrden,
  });

  final OrdenesProduccionState state;
  final VoidCallback onRetry;
  final VoidCallback? onStartOrden;
  final VoidCallback? onCancelOrden;
  final ValueChanged<OrdenProcesoRecord> onStartProceso;
  final ValueChanged<OrdenProcesoRecord> onFinishProceso;
  final ValueChanged<OrdenProcesoRecord> onEditObservacion;
  final VoidCallback onGeneratePlannedConsumption;
  final ValueChanged<OrdenProcesoRecord> onRequestConsumption;
  final ValueChanged<OrdenProcesoRecord> onRegisterMerma;
  final VoidCallback onRegisterCalidadFinal;
  final VoidCallback onFinalizeOrden;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orden = state.selectedOrden;

    return AppSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Detalle de la orden', style: theme.textTheme.titleLarge),
          const Gap(AppSpacing.md),
          Expanded(
            child: Builder(
              builder: (context) {
                if (state.isDetailLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.detailErrorMessage != null) {
                  return _CenteredMessage(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppMessageCard.error(
                          title: 'No pudimos cargar el detalle',
                          message: state.detailErrorMessage!,
                        ),
                        const Gap(AppSpacing.lg),
                        AppButton.secondary(
                          label: 'Reintentar detalle',
                          icon: Icons.refresh_rounded,
                          onPressed: onRetry,
                        ),
                      ],
                    ),
                  );
                }

                if (orden == null) {
                  return const _CenteredMessage(
                    child: AppMessageCard.info(
                      title: 'Selecciona una orden',
                      message:
                          'Escoge un registro del listado para revisar su secuencia de procesos.',
                    ),
                  );
                }

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.md,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            orden.codigo,
                            style: theme.textTheme.headlineSmall,
                          ),
                          _StatusBadge(
                            label: orden.estado,
                            background: theme.colorScheme.primaryContainer,
                            foreground: theme.colorScheme.onPrimaryContainer,
                          ),
                          _StatusBadge(
                            label:
                                '${orden.procesosFinalizados}/${orden.procesosTotales} procesos',
                            background:
                                theme.colorScheme.surfaceContainerHighest,
                            foreground: theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                      const Gap(AppSpacing.xs),
                      Text(
                        '${orden.clienteRazonSocial} Ã‚Â· ${orden.loteCodigo}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const Gap(AppSpacing.lg),
                      LinearProgressIndicator(value: orden.progresoProcesos),
                      const Gap(AppSpacing.lg),
                      Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.md,
                        children: [
                          AppButton.secondary(
                            label: 'Anular orden',
                            icon: Icons.cancel_outlined,
                            isLoading: state.isSubmittingAction,
                            onPressed: onCancelOrden,
                          ),
                        ],
                      ),
                      const Gap(AppSpacing.lg),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: Wrap(
                          spacing: AppSpacing.xl,
                          runSpacing: AppSpacing.md,
                          children: [
                            _InlineInfo(
                              label: 'Pieles',
                              value: _formatDecimal(orden.cantidadPieles),
                            ),
                            _InlineInfo(
                              label: 'Responsable',
                              value: _formatResponsable(
                                orden.responsableNombre,
                                orden.responsableCargo,
                              ),
                            ),
                            _InlineInfo(
                              label: 'Inicio planificado',
                              value: _formatOptionalDate(
                                orden.fechaInicioPlanificada,
                              ),
                            ),
                            _InlineInfo(
                              label: 'Inicio real',
                              value: _formatOptionalDate(orden.fechaInicioReal),
                            ),
                            _InlineInfo(
                              label: 'Fin estimada',
                              value: _formatDate(orden.fechaFinEstimada),
                            ),
                            _InlineInfo(
                              label: 'Fin real',
                              value: _formatOptionalDate(orden.fechaFinReal),
                            ),
                          ],
                        ),
                      ),
                      if ((orden.observacion ?? '').trim().isNotEmpty) ...[
                        const Gap(AppSpacing.xl),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Observacion de la orden',
                                style: theme.textTheme.titleMedium,
                              ),
                              const Gap(AppSpacing.md),
                              Text(
                                orden.observacion!,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                      if ((orden.motivoAnulacion ?? '').trim().isNotEmpty) ...[
                        const Gap(AppSpacing.lg),
                        AppMessageCard.warning(
                          title: 'Motivo de anulacion',
                          message: orden.motivoAnulacion!,
                        ),
                      ],
                      const Gap(AppSpacing.lg),
                      Text(
                        'Pipeline de produccion',
                        style: theme.textTheme.titleLarge,
                      ),
                      const Gap(AppSpacing.md),
                      _ProcessPipeline(
                        state: state,
                        procesos: state.selectedProcesos,
                        planificados: state.consumoPlanificado,
                        consumos: state.consumoReal,
                        mermas: state.mermas,
                        desviaciones: state.desviaciones,
                        isSubmitting: state.isSubmittingAction,
                        onStart: onStartProceso,
                        onFinish: onFinishProceso,
                        onEditObservation: onEditObservacion,
                        onRequestConsumption: onRequestConsumption,
                        onRegisterMerma: onRegisterMerma,
                        onStartOrder: onStartOrden,
                        onCalculatePlanned: onGeneratePlannedConsumption,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TABLERO KANBAN DE Ãƒâ€œRDENES - SOLO VISUALIZACIÃƒâ€œN, SIN DRAG & DROP
// ============================================================================

class _OrdersPipelineBoard extends StatelessWidget {
  const _OrdersPipelineBoard({
    required this.state,
    required this.onRetry,
    required this.onSelectOrden,
  });

  final OrdenesProduccionState state;
  final VoidCallback onRetry;
  final ValueChanged<int> onSelectOrden;

  static const _stages =
      <
        ({
          String title,
          Set<String> states,
          Color tone,
          IconData icon,
          String emptyText,
        })
      >[
        (
          title: 'Programadas',
          states: {'PROGRAMADA'},
          tone: Color(0xFFF05A14),
          icon: Icons.event_note_outlined,
          emptyText: 'Las ÃƒÂ³rdenes programadas aparecerÃƒÂ¡n aquÃƒÂ­.',
        ),
        (
          title: 'PreparaciÃƒÂ³n',
          states: {'ESPERANDO_MATERIALES', 'LISTA_PARA_INICIAR'},
          tone: Color(0xFF2479D6),
          icon: Icons.settings_outlined,
          emptyText: 'Las ÃƒÂ³rdenes en preparaciÃƒÂ³n aparecerÃƒÂ¡n aquÃƒÂ­.',
        ),
        (
          title: 'En proceso',
          states: {'EN_PROCESO'},
          tone: Color(0xFFF3A414),
          icon: Icons.play_arrow_rounded,
          emptyText: 'Las ÃƒÂ³rdenes en proceso aparecerÃƒÂ¡n aquÃƒÂ­.',
        ),
        (
          title: 'Finalizadas',
          states: {'FINALIZADA'},
          tone: Color(0xFF15A363),
          icon: Icons.check_rounded,
          emptyText: 'Las ÃƒÂ³rdenes finalizadas aparecerÃƒÂ¡n aquÃƒÂ­.',
        ),
        (
          title: 'Anuladas',
          states: {'ANULADA', 'CANCELADA'},
          tone: Color(0xFFE53945),
          icon: Icons.close_rounded,
          emptyText: 'Las ÃƒÂ³rdenes anuladas aparecerÃƒÂ¡n aquÃƒÂ­.',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    if (state.status == OrdenesProduccionStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == OrdenesProduccionStatus.error) {
      return _CenteredMessage(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppMessageCard.error(
              title: 'No pudimos cargar las ÃƒÂ³rdenes',
              message: state.errorMessage ?? 'Intenta nuevamente.',
            ),
            const Gap(AppSpacing.md),
            AppButton.secondary(
              label: 'Reintentar',
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        // Reparte toda la anchura cuando hay espacio; en pantallas angostas,
        // permite desplazamiento horizontal en lugar de aplastar las tarjetas.
        final colWidth = ((constraints.maxWidth - 4 * gap) / 5)
            .clamp(245.0, 500.0)
            .toDouble();
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < _stages.length; i++) ...[
                _OrderPipelineColumn(
                  title: _stages[i].title,
                  tone: _stages[i].tone,
                  icon: _stages[i].icon,
                  emptyText: _stages[i].emptyText,
                  width: colWidth,
                  items: state.items
                      .where((item) => _stages[i].states.contains(item.estado))
                      .toList(growable: false),
                  onSelectOrden: onSelectOrden,
                ),
                if (i != _stages.length - 1) const SizedBox(width: gap),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _OrderPipelineColumn extends StatelessWidget {
  const _OrderPipelineColumn({
    required this.title,
    required this.tone,
    required this.icon,
    required this.emptyText,
    required this.width,
    required this.items,
    required this.onSelectOrden,
  });

  final String title;
  final Color tone;
  final IconData icon;
  final String emptyText;
  final double width;
  final List<OrdenProduccionRecord> items;
  final ValueChanged<int> onSelectOrden;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Color.alphaBlend(tone.withValues(alpha: 0.025), colors.surface),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(height: 5, color: tone.withValues(alpha: 0.32)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                tone.withValues(alpha: 0.09),
                colors.surface,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: tone,
                    shape: BoxShape.circle,
                  ),
                ),
                const Gap(AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${items.length}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: tone,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: tone.withValues(alpha: 0.10),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: tone, size: 29),
                          ),
                          const Gap(AppSpacing.md),
                          Text(
                            'Sin ÃƒÂ³rdenes',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Gap(AppSpacing.xs),
                          Text(
                            emptyText,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(10),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Gap(AppSpacing.sm),
                    itemBuilder: (context, index) => _OrdenListTileCard(
                      item: items[index],
                      isSelected: false,
                      tone: tone,
                      onTap: () => onSelectOrden(items[index].id),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _OrdenListTileCard extends StatelessWidget {
  const _OrdenListTileCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
    this.tone,
  });

  final OrdenProduccionRecord item;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final accent = tone ?? colors.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? accent.withValues(alpha: 0.08) : colors.surface,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: isSelected ? accent : colors.outlineVariant,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.codigo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Gap(5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _humanizeStatus(item.estado),
                      maxLines: 1,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 16),
                ],
              ),
              const Gap(9),
              Text(
                item.clienteRazonSocial,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Gap(3),
              Text(
                item.loteCodigo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const Gap(11),
              Row(
                children: [
                  Icon(
                    Icons.account_tree_outlined,
                    size: 15,
                    color: colors.onSurfaceVariant,
                  ),
                  const Gap(5),
                  Text(
                    '${item.procesosFinalizados}/${item.procesosTotales} procesos',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const Gap(5),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: colors.onSurfaceVariant,
                  ),
                  const Gap(5),
                  Expanded(
                    child: Text(
                      'Fin: ${_formatDate(item.fechaFinEstimada)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProcesoCard extends StatelessWidget {
  const _ProcesoCard({
    required this.proceso,
    required this.isSubmitting,
    required this.onStart,
    required this.onFinish,
    required this.onEditObservation,
    required this.onRequestConsumption,
    required this.onRegisterMerma,
    required this.isLocked,
  });

  final OrdenProcesoRecord proceso;
  final bool isSubmitting;
  final VoidCallback? onStart;
  final VoidCallback? onFinish;
  final VoidCallback onEditObservation;
  final VoidCallback? onRequestConsumption;
  final VoidCallback? onRegisterMerma;
  final bool isLocked;

  Future<void> _showRequestedSupplies(
    BuildContext context,
    List<OrdenProcesoInsumoSolicitado> items,
  ) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.inventory_2_outlined),
              const Gap(AppSpacing.sm),
              const Expanded(child: Text('Insumos solicitados')),
            ],
          ),
          content: SizedBox(
            width: 560,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 440),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    Divider(color: theme.colorScheme.outlineVariant),
                itemBuilder: (_, index) {
                  final item = items[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${item.insumoCodigo} - ${item.insumoNombre}'),
                    trailing: Text(
                      '${_formatDecimal(item.cantidadSolicitada)} '
                      '${item.unidadMedidaCodigo}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groupedRequested = <String, OrdenProcesoInsumoSolicitado>{};
    for (final item in proceso.insumosSolicitados) {
      final key =
          '${item.insumoCodigo.trim().toLowerCase()}|${item.unidadMedidaCodigo.trim().toLowerCase()}';
      final current = groupedRequested[key];
      groupedRequested[key] = OrdenProcesoInsumoSolicitado(
        insumoCodigo: item.insumoCodigo,
        insumoNombre: item.insumoNombre,
        unidadMedidaCodigo: item.unidadMedidaCodigo,
        cantidadSolicitada:
            (current?.cantidadSolicitada ?? 0) + item.cantidadSolicitada,
      );
    }
    final requestedItems = groupedRequested.values.toList(growable: false);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isLocked
            ? theme.colorScheme.surfaceContainerLow
            : theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: proceso.estado == 'EN_PROCESO'
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: proceso.estado == 'EN_PROCESO' ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${proceso.secuencia}. ${proceso.procesoNombre}',
                style: theme.textTheme.titleMedium,
              ),
              _MiniPill(
                label: isLocked ? 'BLOQUEADO' : proceso.estado,
                background: theme.colorScheme.surfaceContainerHighest,
                foreground: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          const Gap(AppSpacing.sm),
          Text(
            proceso.procesoCodigo,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const Gap(AppSpacing.md),
          if (isLocked) ...[
            Row(
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const Gap(AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Finaliza la etapa anterior para continuar.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const Gap(AppSpacing.md),
          ],
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.md,
            children: [
              _InlineInfo(
                label: 'Responsable',
                value: _formatResponsable(
                  proceso.responsableNombre,
                  proceso.responsableCargo,
                ),
              ),
              _InlineInfo(
                label: 'Peso base',
                value: proceso.pesoBaseKg == null
                    ? 'Pendiente'
                    : '${_formatDecimal(proceso.pesoBaseKg!)} kg',
              ),
              _InlineInfo(
                label: 'Termino estimado',
                value: _formatOptionalDate(proceso.fechaFinEstimada),
              ),
              _InlineInfo(
                label: 'Inicio',
                value: _formatOptionalDateTime(proceso.fechaInicio),
              ),
              _InlineInfo(
                label: 'Fin',
                value: _formatOptionalDateTime(proceso.fechaFin),
              ),
              _InlineInfo(
                label: 'Dias reales',
                value: proceso.diasReales?.toString() ?? 'Sin dato',
              ),
            ],
          ),
          if ((proceso.observacion ?? '').trim().isNotEmpty) ...[
            const Gap(AppSpacing.md),
            Text(
              proceso.observacion!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const Gap(AppSpacing.md),
          Divider(color: theme.colorScheme.outlineVariant),
          const Gap(AppSpacing.sm),
          if (requestedItems.isEmpty)
            Text(
              'Debes solicitar insumos y esperar su aprobaciÃƒÂ³n para finalizar.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: () => _showRequestedSupplies(context, requestedItems),
              icon: Icon(
                proceso.hasPendingSupplyRequest
                    ? Icons.schedule_rounded
                    : Icons.check_circle_outline_rounded,
              ),
              label: Text(
                proceso.hasPendingSupplyRequest
                    ? 'Solicitud enviada Ã‚Â· Ver insumos pendientes'
                    : 'Insumos aprobados Ã‚Â· Ver detalle',
              ),
            ),
          const Gap(AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              if (proceso.canStart)
                AppButton.secondary(
                  label: 'Iniciar',
                  icon: Icons.play_circle_outline,
                  isLoading: isSubmitting,
                  onPressed: onStart,
                ),
              if (proceso.canFinish)
                AppButton.secondary(
                  label: 'Finalizar',
                  icon: Icons.task_alt_outlined,
                  isLoading: isSubmitting,
                  onPressed:
                      proceso.hasApprovedSupplies &&
                          !proceso.hasPendingSupplyRequest
                      ? onFinish
                      : null,
                ),
              AppButton.secondary(
                label: 'Observacion',
                icon: Icons.edit_note_outlined,
                isLoading: isSubmitting,
                onPressed: onEditObservation,
              ),
              AppButton.secondary(
                label: 'Solicitar insumos',
                icon: Icons.inventory_2_outlined,
                isLoading: isSubmitting,
                onPressed: proceso.hasPendingSupplyRequest
                    ? null
                    : onRequestConsumption,
              ),
              AppButton.secondary(
                label: 'Registrar merma',
                icon: Icons.content_cut_outlined,
                isLoading: isSubmitting,
                onPressed: onRegisterMerma,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProcessPipeline extends StatefulWidget {
  const _ProcessPipeline({
    required this.state,
    required this.procesos,
    required this.planificados,
    required this.consumos,
    required this.mermas,
    required this.desviaciones,
    required this.isSubmitting,
    required this.onStart,
    required this.onFinish,
    required this.onEditObservation,
    required this.onRequestConsumption,
    required this.onRegisterMerma,
    required this.onStartOrder,
    required this.onCalculatePlanned,
  });

  final OrdenesProduccionState state;
  final List<OrdenProcesoRecord> procesos;
  final List<ConsumoPlanificadoRecord> planificados;
  final List<ConsumoRealRecord> consumos;
  final List<MermaProcesoRecord> mermas;
  final List<DesviacionConsumoRecord> desviaciones;
  final bool isSubmitting;
  final ValueChanged<OrdenProcesoRecord> onStart;
  final ValueChanged<OrdenProcesoRecord> onFinish;
  final ValueChanged<OrdenProcesoRecord> onEditObservation;
  final ValueChanged<OrdenProcesoRecord> onRequestConsumption;
  final ValueChanged<OrdenProcesoRecord> onRegisterMerma;
  final VoidCallback? onStartOrder;
  final VoidCallback onCalculatePlanned;

  @override
  State<_ProcessPipeline> createState() => _ProcessPipelineState();
}

class _ProcessPipelineState extends State<_ProcessPipeline> {
  static final Map<int, int> _selectedStageByOrder = {};
  int _selectedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final ordered = [...widget.procesos]
      ..sort((a, b) => a.secuencia.compareTo(b.secuencia));
    if (ordered.isEmpty) {
      return const AppMessageCard.info(
        title: 'Sin procesos configurados',
        message: 'La orden no tiene una secuencia productiva disponible.',
      );
    }
    final orderId = ordered.first.ordenProduccionId;
    bool stageFinished(int index) {
      final code = ordered[index].procesoCodigo;
      if (code == 'RECURTIDO') {
        return widget.state.ordenProductos.isNotEmpty &&
            widget.state.ordenProductos.every(
              (p) => p.estadoRecurtido == 'FINALIZADO',
            );
      }
      if (code == 'ACABADO') {
        return widget.state.ordenProductos.isNotEmpty &&
            widget.state.ordenProductos.every(
              (p) => p.estadoAcabado == 'FINALIZADO',
            );
      }
      return ordered[index].estado == 'FINALIZADO';
    }

    bool stageEnabled(int index) {
      if (index == 0) return true;
      if (ordered[index].procesoCodigo == 'ACABADO') {
        return widget.state.ordenProductos.any(
          (p) => p.estadoRecurtido == 'FINALIZADO',
        );
      }
      return stageFinished(index - 1);
    }

    if (_selectedIndex < 0) {
      _selectedIndex =
          _selectedStageByOrder[orderId] ??
          List.generate(ordered.length, (index) => index).firstWhere(
            (index) => !stageFinished(index),
            orElse: () => ordered.length - 1,
          );
      if (_selectedIndex < 0) _selectedIndex = ordered.length - 1;
    }
    if (_selectedIndex >= ordered.length) {
      _selectedIndex = 0;
    }

    final proceso = ordered[_selectedIndex];
    final isLocked = !stageEnabled(_selectedIndex);
    final isProductStage =
        proceso.procesoCodigo == 'RECURTIDO' ||
        proceso.procesoCodigo == 'ACABADO';
    final stagePlanificados = widget.planificados
        .where((item) => item.ordenProcesoId == proceso.id)
        .toList(growable: false);
    final stageConsumos = widget.consumos
        .where((item) => item.ordenProcesoId == proceso.id)
        .toList(growable: false);
    final stageMermas = widget.mermas
        .where((item) => item.ordenProcesoId == proceso.id)
        .toList(growable: false);
    final stageDesviaciones = widget.desviaciones
        .where((item) => item.ordenProcesoId == proceso.id)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<int>(
            segments: [
              for (var index = 0; index < ordered.length; index++)
                ButtonSegment<int>(
                  value: index,
                  enabled: stageEnabled(index),
                  icon: Icon(
                    stageFinished(index)
                        ? Icons.check_circle_rounded
                        : index > 0 && ordered[index - 1].estado != 'FINALIZADO'
                        ? Icons.lock_outline_rounded
                        : Icons.circle_outlined,
                  ),
                  label: Text('${index + 1}. ${ordered[index].procesoNombre}'),
                ),
            ],
            selected: {_selectedIndex},
            showSelectedIcon: false,
            onSelectionChanged: (selection) {
              setState(() {
                _selectedIndex = selection.first;
                _selectedStageByOrder[orderId] = _selectedIndex;
              });
            },
          ),
        ),
        const Gap(AppSpacing.lg),
        if (isProductStage)
          _OrdenProductosSection(
            state: widget.state,
            stageCode: proceso.procesoCodigo,
          )
        else
          _ProcesoCard(
            proceso: proceso,
            isLocked: isLocked,
            isSubmitting: widget.isSubmitting,
            onStart: !isLocked && proceso.canStart
                ? (_selectedIndex == 0 && widget.onStartOrder != null
                      ? widget.onStartOrder
                      : () => widget.onStart(proceso))
                : null,
            onFinish: !isLocked && proceso.canFinish
                ? () => widget.onFinish(proceso)
                : null,
            onEditObservation: () => widget.onEditObservation(proceso),
            onRequestConsumption: !isLocked && proceso.estado != 'PENDIENTE'
                ? () => widget.onRequestConsumption(proceso)
                : null,
            onRegisterMerma: !isLocked && proceso.estado != 'PENDIENTE'
                ? () => widget.onRegisterMerma(proceso)
                : null,
          ),
        if (!isProductStage && stagePlanificados.isNotEmpty) ...[
          const Gap(AppSpacing.lg),
          _ConsumptionSection(
            title: 'Insumos planificados de ${proceso.procesoNombre}',
            helperText: 'Cantidades previstas para esta etapa.',
            isEmpty: false,
            emptyMessage: '',
            child: Column(
              children: stagePlanificados
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _PlanificadoCard(item: item),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ],
        if (!isProductStage && stageConsumos.isNotEmpty) ...[
          const Gap(AppSpacing.lg),
          _ConsumptionSection(
            title: 'Insumos utilizados',
            helperText: '',
            isEmpty: false,
            emptyMessage: '',
            child: _ConsumoRealTable(items: stageConsumos),
          ),
        ],
        if (!isProductStage && stageMermas.isNotEmpty) ...[
          const Gap(AppSpacing.lg),
          _ConsumptionSection(
            title: 'Mermas de ${proceso.procesoNombre}',
            helperText: 'Perdidas registradas durante esta etapa.',
            isEmpty: false,
            emptyMessage: '',
            child: Column(
              children: stageMermas
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _MermaCard(item: item),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ],
        if (!isProductStage && stageDesviaciones.isNotEmpty) ...[
          const Gap(AppSpacing.lg),
          _ConsumptionSection(
            title: 'Desviaciones de ${proceso.procesoNombre}',
            helperText: 'Diferencias entre el consumo previsto y el real.',
            isEmpty: false,
            emptyMessage: '',
            child: Column(
              children: stageDesviaciones
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _DesviacionCard(item: item),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ],
      ],
    );
  }
}

class _ConsumptionSection extends StatelessWidget {
  const _ConsumptionSection({
    required this.title,
    required this.helperText,
    required this.isEmpty,
    required this.emptyMessage,
    required this.child,
  });

  final String title;
  final String helperText;
  final bool isEmpty;
  final String emptyMessage;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleLarge),
        if (helperText.isNotEmpty) ...[
          const Gap(AppSpacing.xs),
          Text(
            helperText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const Gap(AppSpacing.md),
        if (isEmpty)
          AppMessageCard.info(title: 'Sin registros', message: emptyMessage)
        else
          child,
      ],
    );
  }
}

class _PlanificadoCard extends StatelessWidget {
  const _PlanificadoCard({required this.item});

  final ConsumoPlanificadoRecord item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              Text(
                '${item.procesoNombre} Ã‚Â· ${item.insumoCodigo}',
                style: theme.textTheme.titleMedium,
              ),
              _MiniPill(
                label: '${item.porcentaje.toStringAsFixed(2)}%',
                background: theme.colorScheme.primaryContainer,
                foreground: theme.colorScheme.onPrimaryContainer,
              ),
            ],
          ),
          const Gap(AppSpacing.sm),
          Text(
            item.insumoNombre,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          /*
          const Gap(AppSpacing.md),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.md,
            children: [
              _InlineInfo(
                label: 'Calidad A',
                value: '${_formatDecimal(item.cantidadLadosA)} lados Ã‚Â· ${_formatDecimal(item.cantidadLadosA / 2)} pieles',
              ),
              _InlineInfo(
                label: 'Calidad B',
                value: '${_formatDecimal(item.cantidadLadosB)} lados Ã‚Â· ${_formatDecimal(item.cantidadLadosB / 2)} pieles',
              ),
              _InlineInfo(
                label: 'Calidad C',
                value: '${_formatDecimal(item.cantidadLadosC)} lados Ã‚Â· ${_formatDecimal(item.cantidadLadosC / 2)} pieles',
              ),
              _InlineInfo(
                label: 'Merma final',
                value: '${_formatDecimal(item.cantidadLadosMerma)} lados Ã‚Â· ${_formatDecimal(item.cantidadLadosMerma / 2)} pieles',
              ),
            ],
          ),
          */
          const Gap(AppSpacing.md),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.md,
            children: [
              _InlineInfo(
                label: 'Cantidad planificada',
                value: _formatDecimal(item.cantidadPlanificada),
              ),
              _InlineInfo(
                label: 'Formula version',
                value: item.formulaVersionId.toString(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConsumoRealTable extends StatelessWidget {
  const _ConsumoRealTable({required this.items});

  final List<ConsumoRealRecord> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 44,
          dataRowMinHeight: 48,
          dataRowMaxHeight: 56,
          columns: const [
            DataColumn(label: Text('Insumo')),
            DataColumn(label: Text('Cantidad'), numeric: true),
            DataColumn(label: Text('Costo unitario'), numeric: true),
            DataColumn(label: Text('Costo total'), numeric: true),
          ],
          rows: items
              .map(
                (item) => DataRow(
                  cells: [
                    DataCell(Text(item.insumoNombre)),
                    DataCell(Text(_formatDecimal(item.cantidadConsumida))),
                    DataCell(Text(_formatCurrency(item.costoUnitario))),
                    DataCell(Text(_formatCurrency(item.costoTotal))),
                  ],
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _DesviacionCard extends StatelessWidget {
  const _DesviacionCard({required this.item});

  final DesviacionConsumoRecord item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              Text(
                '${item.procesoNombre} Ã‚Â· ${item.insumoCodigo}',
                style: theme.textTheme.titleMedium,
              ),
              _MiniPill(
                label: _formatSignedDecimal(item.cantidadDesviacion),
                background: theme.colorScheme.error,
                foreground: theme.colorScheme.onError,
              ),
            ],
          ),
          const Gap(AppSpacing.sm),
          Text(
            item.insumoNombre,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(AppSpacing.md),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.md,
            children: [
              _InlineInfo(
                label: 'Planificado',
                value: _formatDecimal(item.cantidadPlanificada),
              ),
              _InlineInfo(
                label: 'Real',
                value: _formatDecimal(item.cantidadReal),
              ),
              _InlineInfo(
                label: 'Desviacion',
                value: _formatSignedDecimal(item.cantidadDesviacion),
              ),
            ],
          ),
          if ((item.motivo ?? '').trim().isNotEmpty) ...[
            const Gap(AppSpacing.md),
            Text(
              item.motivo!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MermaCard extends StatelessWidget {
  const _MermaCard({required this.item});

  final MermaProcesoRecord item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              Text(
                '${item.procesoNombre} Ã‚Â· ${item.procesoCodigo}',
                style: theme.textTheme.titleMedium,
              ),
              _MiniPill(
                label: '${_formatDecimal(item.cantidadPerdida)} perdidas',
                background: theme.colorScheme.errorContainer,
                foreground: theme.colorScheme.onErrorContainer,
              ),
            ],
          ),
          const Gap(AppSpacing.md),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.md,
            children: [
              _InlineInfo(label: 'Motivo', value: item.motivo ?? 'Sin motivo'),
              _InlineInfo(
                label: 'Responsable',
                value: item.registradoPorNombre ?? 'Sin dato',
              ),
            ],
          ),
          if ((item.observacion ?? '').trim().isNotEmpty) ...[
            const Gap(AppSpacing.md),
            Text(
              item.observacion!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}



class _InlineInfo extends StatelessWidget {
  const _InlineInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 170,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(AppSpacing.xs),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: foreground),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: foreground),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: child,
      ),
    );
  }
}

String _formatDecimal(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(2);
}

String _formatResponsable(String? nombre, String? cargo) {
  final nombreLimpio = nombre?.trim();
  final cargoLimpio = cargo?.trim();
  if (nombreLimpio == null || nombreLimpio.isEmpty) return 'Sin asignar';
  if (cargoLimpio == null || cargoLimpio.isEmpty) return nombreLimpio;
  return '$nombreLimpio Ã‚Â· $cargoLimpio';
}

String _formatSignedDecimal(double value) {
  final prefix = value > 0 ? '+' : '';
  return '$prefix${_formatDecimal(value)}';
}

String _formatCurrency(double value) {
  return 'S/ ${value.toStringAsFixed(2)}';
}

String _humanizeStatus(String value) => value
    .toLowerCase()
    .split('_')
    .map(
      (word) =>
          word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}',
    )
    .join(' ');

String _formatDate(DateTime value) {
  return DateFormat('dd/MM/yyyy').format(value.toLocal());
}

String _formatMonth(DateTime value) {
  const months = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];
  return '${months[value.month - 1]} ${value.year}';
}

String _formatDateTime(DateTime value) {
  return DateFormat('dd/MM/yyyy hh:mm a').format(value.toLocal());
}

String _formatOptionalDate(DateTime? value) {
  if (value == null) {
    return 'Sin fecha';
  }
  return _formatDate(value);
}

String _formatOptionalDateTime(DateTime? value) {
  if (value == null) {
    return 'Sin registro';
  }
  return _formatDateTime(value);
}
