import 'package:erp_curtiembre_fronted/core/di/service_locator.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_state.dart';
import 'package:erp_curtiembre_fronted/features/inventory/entradas/domain/repositories/entradas_repository.dart';
import 'package:erp_curtiembre_fronted/features/inventory/entradas/presentation/cubit/entradas_cubit.dart';
import 'package:erp_curtiembre_fronted/features/inventory/entradas/presentation/cubit/entradas_state.dart';
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

class EntradasPage extends StatefulWidget {
  const EntradasPage({super.key});

  @override
  State<EntradasPage> createState() => _EntradasPageState();
}

enum _EntradaView { stockInicial, recepcionCompra }

class _EntradasPageState extends State<EntradasPage> {
  _EntradaView _selectedView = _EntradaView.stockInicial;
  final _stockDocumentoController = TextEditingController();
  final _stockObservacionController = TextEditingController();
  final _recepcionDocumentoController = TextEditingController();
  final _recepcionObservacionController = TextEditingController();
  final List<_StockDraft> _stockDrafts = [_StockDraft()];
  final List<_RecepcionDraft> _recepcionDrafts = [];
  final Talker _talker = getIt<Talker>();

  @override
  void initState() {
    super.initState();
    _talker.ui('Se abrio la pantalla de entradas de inventario.');
  }

  @override
  void dispose() {
    _stockDocumentoController.dispose();
    _stockObservacionController.dispose();
    _recepcionDocumentoController.dispose();
    _recepcionObservacionController.dispose();
    for (final item in _stockDrafts) {
      item.dispose();
    }
    for (final item in _recepcionDrafts) {
      item.dispose();
    }
    super.dispose();
  }

  void _showActionResult(EntradasActionResult result) {
    _talker.ui(
      result.success
          ? 'Accion en entradas de inventario completada correctamente.'
          : 'La accion en entradas de inventario fallo: ${result.message}',
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

  void _addStockDraft() {
    _talker.ui(
      'Se agrego una nueva fila al formulario de stock inicial.',
      logLevel: LogLevel.debug,
    );
    setState(() => _stockDrafts.add(_StockDraft()));
  }

  void _removeStockDraft(int index) {
    if (_stockDrafts.length == 1) return;
    _talker.ui(
      'Se elimino la fila $index del formulario de stock inicial.',
      logLevel: LogLevel.debug,
    );
    setState(() {
      final removed = _stockDrafts.removeAt(index);
      removed.dispose();
    });
  }

  Future<void> _submitStockInitial(EntradasState state) async {
    _talker.ui(
      'Se intento registrar stock inicial con documentoSoporte=${_describeText(_stockDocumentoController.text)} y ${_stockDrafts.length} filas visibles.',
      logLevel: LogLevel.warning,
    );
    final details = <RegistrarStockInicialDetalleInput>[];

    for (final item in _stockDrafts) {
      if (item.insumoId == null) continue;
      final cantidad = double.tryParse(
        item.cantidadController.text.trim().replaceAll(',', '.'),
      );
      final costo = double.tryParse(
        item.costoController.text.trim().replaceAll(',', '.'),
      );
      if (cantidad == null || cantidad <= 0 || costo == null || costo < 0) {
        _showActionResult(
          const EntradasActionResult.failure(
            'Revisa las cantidades y costos del stock inicial.',
          ),
        );
        return;
      }
      details.add(
        RegistrarStockInicialDetalleInput(
          insumoId: item.insumoId!,
          cantidad: cantidad,
          costoUnitario: costo,
          observacion: item.observacionController.text.trim().isEmpty
              ? null
              : item.observacionController.text.trim(),
        ),
      );
    }

    if (details.isEmpty) {
      _showActionResult(
        const EntradasActionResult.failure(
          'Agrega al menos un insumo valido para registrar stock inicial.',
        ),
      );
      return;
    }

    final result = await context.read<EntradasCubit>().registerStockInitial(
      documentoSoporte: _stockDocumentoController.text.trim().isEmpty
          ? null
          : _stockDocumentoController.text.trim(),
      observacion: _stockObservacionController.text.trim().isEmpty
          ? null
          : _stockObservacionController.text.trim(),
      detalles: details,
    );

    if (!mounted) return;

    if (result.success) {
      _stockDocumentoController.clear();
      _stockObservacionController.clear();
      for (final item in _stockDrafts) {
        item.dispose();
      }
      setState(() {
        _stockDrafts
          ..clear()
          ..add(_StockDraft());
      });
    }

    _showActionResult(result);
  }

  Future<void> _prepareRecepcionDrafts(
    EntradasState state,
    int? orderId,
  ) async {
    _talker.ui(
      orderId == null
          ? 'Se limpio la seleccion de orden para recepcion.'
          : 'Se selecciono la orden $orderId para preparar la recepcion.',
      logLevel: LogLevel.debug,
    );
    await context.read<EntradasCubit>().selectReceivableOrder(orderId);
    if (!mounted) return;
    final detail = context.read<EntradasCubit>().state.selectedReceivableOrder;
    for (final item in _recepcionDrafts) {
      item.dispose();
    }
    _recepcionDrafts.clear();
    if (detail != null) {
      for (final line in detail.detalles.where(
        (item) => item.saldoPendiente > 0,
      )) {
        _recepcionDrafts.add(
          _RecepcionDraft(
            ordenCompraDetalleId: line.id,
            insumoId: line.insumoId,
            insumoLabel: '${line.insumoCodigo} · ${line.insumoNombre}',
            saldoPendiente: line.saldoPendiente,
            costoSugerido: line.costoUnitarioEstimado,
          ),
        );
      }
    }
    _talker.ui(
      'Se prepararon ${_recepcionDrafts.length} lineas para la recepcion de la orden ${orderId ?? 'ninguna'}.',
      logLevel: LogLevel.debug,
    );
    setState(() {});
  }

  Future<void> _submitRecepcion(EntradasState state) async {
    final orderId = state.selectedReceivableOrderId;
    _talker.ui(
      'Se intento registrar una recepcion para ordenCompraId=${orderId ?? 'ninguna'} con documentoSoporte=${_describeText(_recepcionDocumentoController.text)}.',
      logLevel: LogLevel.warning,
    );
    if (orderId == null) {
      _showActionResult(
        const EntradasActionResult.failure(
          'Selecciona una orden para registrar la recepcion.',
        ),
      );
      return;
    }

    if (_recepcionDocumentoController.text.trim().isEmpty) {
      _showActionResult(
        const EntradasActionResult.failure(
          'Ingresa el documento de soporte de la recepcion.',
        ),
      );
      return;
    }

    final details = <RegistrarEntradaCompraDetalleInput>[];
    for (final item in _recepcionDrafts) {
      final cantidadText = item.cantidadController.text.trim().replaceAll(
        ',',
        '.',
      );
      if (cantidadText.isEmpty) continue;
      final cantidad = double.tryParse(cantidadText);
      final costo = double.tryParse(
        item.costoController.text.trim().replaceAll(',', '.'),
      );
      if (cantidad == null || cantidad <= 0) {
        _showActionResult(
          EntradasActionResult.failure(
            'Revisa la cantidad de ${item.insumoLabel}.',
          ),
        );
        return;
      }
      if (cantidad > item.saldoPendiente) {
        _showActionResult(
          EntradasActionResult.failure(
            'No puedes recibir mas del saldo pendiente de ${item.insumoLabel}.',
          ),
        );
        return;
      }
      if (costo == null || costo < 0) {
        _showActionResult(
          EntradasActionResult.failure(
            'Revisa el costo unitario de ${item.insumoLabel}.',
          ),
        );
        return;
      }

      details.add(
        RegistrarEntradaCompraDetalleInput(
          ordenCompraDetalleId: item.ordenCompraDetalleId,
          insumoId: item.insumoId,
          cantidad: cantidad,
          costoUnitario: costo,
          observacion: item.observacionController.text.trim().isEmpty
              ? null
              : item.observacionController.text.trim(),
        ),
      );
    }

    if (details.isEmpty) {
      _showActionResult(
        const EntradasActionResult.failure(
          'Ingresa al menos una linea con cantidad a recibir.',
        ),
      );
      return;
    }

    final result = await context.read<EntradasCubit>().registerPurchaseEntry(
      ordenCompraId: orderId,
      documentoSoporte: _recepcionDocumentoController.text.trim(),
      observacion: _recepcionObservacionController.text.trim().isEmpty
          ? null
          : _recepcionObservacionController.text.trim(),
      detalles: details,
    );

    if (!mounted) return;

    if (result.success) {
      _recepcionDocumentoController.clear();
      _recepcionObservacionController.clear();
      await _prepareRecepcionDrafts(
        context.read<EntradasCubit>().state,
        orderId,
      );
    }

    _showActionResult(result);
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
      title: 'Entradas',
      currentPath: '/inventario/entradas',
      breadcrumbs: const ['Inicio', 'Inventario', 'Entradas'],
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
                constraints: const BoxConstraints(maxWidth: 1440),
                child: BlocBuilder<EntradasCubit, EntradasState>(
                  builder: (context, state) {
                    if (state.status == EntradasStatus.loading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state.status == EntradasStatus.error) {
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: AppMessageCard.error(
                            title: 'No pudimos cargar las entradas',
                            message:
                                state.errorMessage ??
                                'Intenta nuevamente para consultar el flujo de ingresos.',
                          ),
                        ),
                      );
                    }

                    final compactHeight = constraints.maxHeight < 860;
                    final isStockInitial =
                        _selectedView == _EntradaView.stockInicial;
                    final visibleEntry =
                        state.lastEntry?.tipoEntrada ==
                            (isStockInitial ? 'STOCK_INICIAL' : 'COMPRA')
                        ? state.lastEntry
                        : null;

                    final form = isStockInitial
                        ? _StockInicialPanel(
                            state: state,
                            drafts: _stockDrafts,
                            documentoController: _stockDocumentoController,
                            observacionController: _stockObservacionController,
                            onAddDraft: _addStockDraft,
                            onRemoveDraft: _removeStockDraft,
                            onSubmit: () => _submitStockInitial(state),
                          )
                        : _RecepcionCompraPanel(
                            state: state,
                            drafts: _recepcionDrafts,
                            documentoController: _recepcionDocumentoController,
                            observacionController:
                                _recepcionObservacionController,
                            onOrderChanged: (value) =>
                                _prepareRecepcionDrafts(state, value),
                            onSubmit: () => _submitRecepcion(state),
                          );

                    final content = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SegmentedButton<_EntradaView>(
                          segments: const [
                            ButtonSegment(
                              value: _EntradaView.stockInicial,
                              icon: Icon(Icons.inventory_outlined),
                              label: Text('Stock inicial'),
                            ),
                            ButtonSegment(
                              value: _EntradaView.recepcionCompra,
                              icon: Icon(Icons.move_to_inbox_outlined),
                              label: Text('Recepcion de compra'),
                            ),
                          ],
                          selected: {_selectedView},
                          showSelectedIcon: false,
                          onSelectionChanged: (selection) {
                            setState(() => _selectedView = selection.first);
                          },
                        ),
                        const Gap(AppSpacing.lg),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: KeyedSubtree(
                            key: ValueKey(_selectedView),
                            child: form,
                          ),
                        ),
                        const Gap(AppSpacing.xl),
                        _LastEntryPanel(
                          entry: visibleEntry,
                          emptyMessage: isStockInitial
                              ? 'Cuando registres stock inicial, aqui se mostrara el detalle generado.'
                              : 'Cuando registres una recepcion de compra, aqui se mostrara el detalle generado.',
                        ),
                      ],
                    );

                    if (compactHeight) {
                      return SingleChildScrollView(child: content);
                    }

                    return SingleChildScrollView(child: content);
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
}

class _StockInicialPanel extends StatelessWidget {
  const _StockInicialPanel({
    required this.state,
    required this.drafts,
    required this.documentoController,
    required this.observacionController,
    required this.onAddDraft,
    required this.onRemoveDraft,
    required this.onSubmit,
  });

  final EntradasState state;
  final List<_StockDraft> drafts;
  final TextEditingController documentoController;
  final TextEditingController observacionController;
  final VoidCallback onAddDraft;
  final ValueChanged<int> onRemoveDraft;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Stock inicial', style: theme.textTheme.titleLarge),
          const Gap(AppSpacing.sm),
          Text(
            'Carga cantidades y costo unitario para dejar listo el inventario base.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(AppSpacing.lg),
          TextField(
            controller: documentoController,
            decoration: const InputDecoration(
              labelText: 'Documento soporte',
              hintText: 'Ej. CARGA-INICIAL-001',
            ),
          ),
          const Gap(AppSpacing.md),
          TextField(
            controller: observacionController,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Observacion'),
          ),
          const Gap(AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Detalle', style: theme.textTheme.titleMedium),
              TextButton.icon(
                onPressed: onAddDraft,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Agregar fila'),
              ),
            ],
          ),
          const Gap(AppSpacing.md),
          ...List.generate(
            drafts.length,
            (index) => Padding(
              padding: EdgeInsets.only(
                bottom: index == drafts.length - 1 ? 0 : AppSpacing.lg,
              ),
              child: _StockDraftCard(
                draft: drafts[index],
                insumos: state.insumos,
                canRemove: drafts.length > 1,
                onRemove: () => onRemoveDraft(index),
              ),
            ),
          ),
          const Gap(AppSpacing.lg),
          AppButton.primary(
            label: 'Registrar stock inicial',
            icon: Icons.inventory_outlined,
            isLoading: state.isSubmittingAction,
            onPressed: onSubmit,
            expand: false,
          ),
        ],
      ),
    );
  }
}

class _RecepcionCompraPanel extends StatelessWidget {
  const _RecepcionCompraPanel({
    required this.state,
    required this.drafts,
    required this.documentoController,
    required this.observacionController,
    required this.onOrderChanged,
    required this.onSubmit,
  });

  final EntradasState state;
  final List<_RecepcionDraft> drafts;
  final TextEditingController documentoController;
  final TextEditingController observacionController;
  final ValueChanged<int?> onOrderChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recepcion desde compra', style: theme.textTheme.titleLarge),
          const Gap(AppSpacing.sm),
          Text(
            'Selecciona una orden aprobada o parcialmente recibida y registra solo el saldo pendiente que realmente ingreso.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(AppSpacing.lg),
          DropdownButtonFormField<int?>(
            initialValue: state.selectedReceivableOrderId,
            decoration: const InputDecoration(labelText: 'Orden de compra'),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Seleccionar orden'),
              ),
              ...state.receivableOrders.map(
                (item) => DropdownMenuItem<int?>(
                  value: item.id,
                  child: Text('${item.codigo} · ${item.proveedorRazonSocial}'),
                ),
              ),
            ],
            onChanged: onOrderChanged,
          ),
          const Gap(AppSpacing.md),
          TextField(
            controller: documentoController,
            decoration: const InputDecoration(
              labelText: 'Documento soporte',
              hintText: 'Ej. F001-000123',
            ),
          ),
          const Gap(AppSpacing.md),
          TextField(
            controller: observacionController,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Observacion'),
          ),
          const Gap(AppSpacing.lg),
          if (state.isOrderDetailLoading)
            const Center(child: CircularProgressIndicator())
          else if (state.orderDetailErrorMessage != null)
            AppMessageCard.error(
              title: 'No pudimos cargar la orden',
              message: state.orderDetailErrorMessage!,
            )
          else if (state.selectedReceivableOrder == null)
            const AppMessageCard.info(
              title: 'Selecciona una orden',
              message:
                  'Al elegir una compra veras aqui las lineas pendientes por recibir.',
            )
          else if (drafts.isEmpty)
            const AppMessageCard.info(
              title: 'Sin saldo pendiente',
              message:
                  'La orden seleccionada no tiene lineas pendientes por recepcionar.',
            )
          else ...[
            Text('Lineas pendientes', style: theme.textTheme.titleMedium),
            const Gap(AppSpacing.md),
            ...drafts.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: _RecepcionDraftCard(draft: item),
              ),
            ),
          ],
          const Gap(AppSpacing.lg),
          AppButton.primary(
            label: 'Registrar recepcion',
            icon: Icons.move_to_inbox_outlined,
            isLoading: state.isSubmittingAction,
            onPressed: onSubmit,
            expand: false,
          ),
        ],
      ),
    );
  }
}

class _LastEntryPanel extends StatelessWidget {
  const _LastEntryPanel({required this.entry, required this.emptyMessage});

  final dynamic entry;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: entry == null
          ? AppMessageCard.info(
              title: 'Sin entrada reciente',
              message: emptyMessage,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ultima entrada registrada',
                  style: theme.textTheme.titleLarge,
                ),
                const Gap(AppSpacing.sm),
                Text(
                  '${entry.codigo} · ${entry.tipoEntrada} · ${entry.estado}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const Gap(AppSpacing.md),
                Text(
                  'Fecha: ${DateFormat('dd/MM/yyyy hh:mm a').format(entry.fechaEntrada.toLocal())}',
                ),
                const Gap(AppSpacing.xs),
                Text('Documento: ${entry.documentoSoporte ?? 'Sin documento'}'),
                const Gap(AppSpacing.xs),
                Text('Observacion: ${entry.observacion ?? 'Sin observacion'}'),
                const Gap(AppSpacing.lg),
                ...entry.detalles.map<Widget>(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.lg),
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
                            '${item.insumoCodigo} · ${item.insumoNombre}',
                            style: theme.textTheme.titleSmall,
                          ),
                          const Gap(AppSpacing.sm),
                          Text(
                            'Cantidad: ${item.cantidad.toStringAsFixed(2)} · Costo: S/ ${item.costoUnitario.toStringAsFixed(2)} · Total: S/ ${item.costoTotal.toStringAsFixed(2)}',
                          ),
                          const Gap(AppSpacing.xs),
                          Text(
                            'Stock actual: ${item.stockActual.toStringAsFixed(2)} · Unidad: ${item.unidadMedidaCodigo}',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _StockDraftCard extends StatefulWidget {
  const _StockDraftCard({
    required this.draft,
    required this.insumos,
    required this.canRemove,
    required this.onRemove,
  });

  final _StockDraft draft;
  final List<dynamic> insumos;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  State<_StockDraftCard> createState() => _StockDraftCardState();
}

class _StockDraftCardState extends State<_StockDraftCard> {
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
              Text('Linea de stock', style: theme.textTheme.titleSmall),
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
                .map<DropdownMenuItem<int>>(
                  (item) => DropdownMenuItem<int>(
                    value: item.id as int,
                    child: Text(item.displayName as String),
                  ),
                )
                .toList(growable: false),
            onChanged: widget.insumos.isEmpty
                ? null
                : (value) => setState(() => widget.draft.insumoId = value),
          ),
          const Gap(AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.draft.cantidadController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Cantidad'),
                ),
              ),
              const Gap(AppSpacing.lg),
              Expanded(
                child: TextField(
                  controller: widget.draft.costoController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Costo unitario',
                  ),
                ),
              ),
            ],
          ),
          const Gap(AppSpacing.md),
          TextField(
            controller: widget.draft.observacionController,
            decoration: const InputDecoration(labelText: 'Observacion'),
          ),
        ],
      ),
    );
  }
}

class _RecepcionDraftCard extends StatelessWidget {
  const _RecepcionDraftCard({required this.draft});

  final _RecepcionDraft draft;

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
          Text(draft.insumoLabel, style: theme.textTheme.titleSmall),
          const Gap(AppSpacing.xs),
          Text(
            'Saldo pendiente: ${draft.saldoPendiente.toStringAsFixed(2)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: draft.cantidadController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Cantidad a recibir',
                  ),
                ),
              ),
              const Gap(AppSpacing.lg),
              Expanded(
                child: TextField(
                  controller: draft.costoController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Costo unitario',
                  ),
                ),
              ),
            ],
          ),
          const Gap(AppSpacing.md),
          TextField(
            controller: draft.observacionController,
            decoration: const InputDecoration(labelText: 'Observacion'),
          ),
        ],
      ),
    );
  }
}

class _StockDraft {
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

class _RecepcionDraft {
  _RecepcionDraft({
    required this.ordenCompraDetalleId,
    required this.insumoId,
    required this.insumoLabel,
    required this.saldoPendiente,
    required this.costoSugerido,
  }) {
    if (costoSugerido != null) {
      costoController.text = costoSugerido!.toStringAsFixed(2);
    }
  }

  final int ordenCompraDetalleId;
  final int insumoId;
  final String insumoLabel;
  final double saldoPendiente;
  final double? costoSugerido;
  final TextEditingController cantidadController = TextEditingController();
  final TextEditingController costoController = TextEditingController();
  final TextEditingController observacionController = TextEditingController();

  void dispose() {
    cantidadController.dispose();
    costoController.dispose();
    observacionController.dispose();
  }
}
