import 'dart:math' as math;

import 'package:erp_curtiembre_fronted/core/di/service_locator.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_state.dart';
import 'package:erp_curtiembre_fronted/features/inventory/entradas/domain/repositories/entradas_repository.dart';
import 'package:erp_curtiembre_fronted/features/inventory/entradas/presentation/cubit/entradas_cubit.dart';
import 'package:erp_curtiembre_fronted/features/inventory/entradas/presentation/cubit/entradas_state.dart';
import 'package:erp_curtiembre_fronted/features/security/presentation/cubit/security_access_cubit.dart';
import 'package:erp_curtiembre_fronted/shared/navigation/app_access_routes.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/layout/app_shell.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:talker_flutter/talker_flutter.dart';

// ============================================================
// COLORES
// ============================================================

const Color _orange = Color(0xFFE8590C);
const Color _orangeSoft = Color(0xFFFFE9DC);

// ============================================================
// VISTAS
// ============================================================

enum _EntradaView { stockInicial, recepcionCompra }

// ============================================================
// PAGINA PRINCIPAL
// ============================================================

class EntradasPage extends StatefulWidget {
  const EntradasPage({super.key});

  @override
  State<EntradasPage> createState() => _EntradasPageState();
}

class _EntradasPageState extends State<EntradasPage> {
  _EntradaView _selectedView = _EntradaView.stockInicial;

  final _stockDocumentoController = TextEditingController();
  final _stockObservacionController = TextEditingController();

  final _recepcionDocumentoController = TextEditingController();
  final _recepcionObservacionController = TextEditingController();

  final _stockSearchController = TextEditingController();
  final _recepcionSearchController = TextEditingController();

  final List<_StockDraft> _stockDrafts = [_StockDraft()];

  final List<_RecepcionDraft> _recepcionDrafts = [];

  final Talker _talker = getIt<Talker>();

  int _orderRequest = 0;

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

    _stockSearchController.dispose();
    _recepcionSearchController.dispose();

    for (final item in _stockDrafts) {
      item.dispose();
    }

    for (final item in _recepcionDrafts) {
      item.dispose();
    }

    super.dispose();
  }

  // ==========================================================
  // RESULTADO DE OPERACIONES
  // ==========================================================

  void _showActionResult(EntradasActionResult result) {
    _talker.ui(
      result.success
          ? 'Accion en entradas completada correctamente.'
          : 'Error en entradas: ${result.message}',
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

  // ==========================================================
  // AGREGAR FILA DE STOCK
  // ==========================================================

  void _addStockDraft() {
    if (context.read<EntradasCubit>().state.isSubmittingAction) {
      return;
    }

    setState(() {
      _stockDrafts.add(_StockDraft());
    });

    _talker.ui(
      'Se agrego una fila al stock inicial.',
      logLevel: LogLevel.debug,
    );
  }

  // ==========================================================
  // ELIMINAR FILA DE STOCK
  // ==========================================================

  void _removeStockDraft(int index) {
    if (_stockDrafts.length <= 1) return;

    if (context.read<EntradasCubit>().state.isSubmittingAction) {
      return;
    }

    late final _StockDraft removed;

    setState(() {
      removed = _stockDrafts.removeAt(index);
    });

    // Esperamos a que el widget deje de usar sus controladores.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      removed.dispose();
    });
  }

  // ==========================================================
  // TOTAL ESTIMADO DE STOCK INICIAL
  // ==========================================================

  double get _stockTotal {
    return _stockDrafts.fold<double>(0, (total, item) {
      final cantidad = _parseNumber(item.cantidadController.text) ?? 0;

      final costo = _parseNumber(item.costoController.text) ?? 0;

      return total + cantidad * costo;
    });
  }

  // ==========================================================
  // TOTAL ESTIMADO DE RECEPCION
  // ==========================================================

  double get _recepcionTotal {
    return _recepcionDrafts.fold<double>(0, (total, item) {
      final cantidad = _parseNumber(item.cantidadController.text) ?? 0;

      final costo = _parseNumber(item.costoController.text) ?? 0;

      return total + cantidad * costo;
    });
  }

  // ==========================================================
  // REGISTRAR STOCK INICIAL
  // ==========================================================

  Future<void> _submitStockInitial(EntradasState state) async {
    if (state.isSubmittingAction) return;

    final details = <RegistrarStockInicialDetalleInput>[];

    for (final item in _stockDrafts) {
      final selectedId =
          item.insumoId ??
          (state.insumos.isNotEmpty ? state.insumos.first.id : null);

      if (selectedId == null) continue;

      final cantidad = _parseNumber(item.cantidadController.text);

      final costo = _parseNumber(item.costoController.text);

      if (cantidad == null || cantidad <= 0 || costo == null || costo < 0) {
        _showActionResult(
          const EntradasActionResult.failure(
            'Revisa las cantidades y costos del stock inicial.',
          ),
        );
        return;
      }

      final observacion = item.observacionController.text.trim();

      details.add(
        RegistrarStockInicialDetalleInput(
          insumoId: selectedId,
          cantidad: cantidad,
          costoUnitario: costo,
          observacion: observacion.isEmpty ? null : observacion,
        ),
      );
    }

    if (details.isEmpty) {
      _showActionResult(
        const EntradasActionResult.failure('Agrega al menos un insumo valido.'),
      );
      return;
    }

    final documento = _stockDocumentoController.text.trim();

    final observacion = _stockObservacionController.text.trim();

    final result = await context.read<EntradasCubit>().registerStockInitial(
      documentoSoporte: documento.isEmpty ? null : documento,
      observacion: observacion.isEmpty ? null : observacion,
      detalles: details,
    );

    if (!mounted) return;

    if (result.success) {
      _stockDocumentoController.clear();
      _stockObservacionController.clear();
      _stockSearchController.clear();

      final previous = List<_StockDraft>.of(_stockDrafts);

      setState(() {
        _stockDrafts
          ..clear()
          ..add(_StockDraft());
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final item in previous) {
          item.dispose();
        }
      });
    }

    _showActionResult(result);
  }

  // ==========================================================
  // PREPARAR RECEPCION DESDE UNA ORDEN
  // ==========================================================

  Future<void> _prepareRecepcionDrafts(
    EntradasState state,
    int? orderId,
  ) async {
    final request = ++_orderRequest;

    await context.read<EntradasCubit>().selectReceivableOrder(orderId);

    if (!mounted || request != _orderRequest) return;

    final detail = context.read<EntradasCubit>().state.selectedReceivableOrder;

    final nextDrafts = <_RecepcionDraft>[];

    if (detail != null) {
      for (final line in detail.detalles.where(
        (item) => item.saldoPendiente > 0,
      )) {
        nextDrafts.add(
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

    final previous = List<_RecepcionDraft>.of(_recepcionDrafts);

    _recepcionSearchController.clear();

    setState(() {
      _recepcionDrafts
        ..clear()
        ..addAll(nextDrafts);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final item in previous) {
        item.dispose();
      }
    });
  }

  // ==========================================================
  // REGISTRAR RECEPCION
  // ==========================================================

  Future<void> _submitRecepcion(EntradasState state) async {
    if (state.isSubmittingAction) return;

    final orderId = state.selectedReceivableOrderId;

    if (orderId == null) {
      _showActionResult(
        const EntradasActionResult.failure(
          'Selecciona una orden para registrar la recepcion.',
        ),
      );
      return;
    }

    final documento = _recepcionDocumentoController.text.trim();

    if (documento.isEmpty) {
      _showActionResult(
        const EntradasActionResult.failure(
          'Ingresa el documento de soporte de la recepcion.',
        ),
      );
      return;
    }

    final details = <RegistrarEntradaCompraDetalleInput>[];

    for (final item in _recepcionDrafts) {
      final cantidadText = item.cantidadController.text.trim();

      // Una línea vacía no se registra.
      if (cantidadText.isEmpty) continue;

      final cantidad = _parseNumber(cantidadText);

      final costo = _parseNumber(item.costoController.text);

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
            'No puedes recibir mas del saldo pendiente de '
            '${item.insumoLabel}.',
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

      final observacion = item.observacionController.text.trim();

      details.add(
        RegistrarEntradaCompraDetalleInput(
          ordenCompraDetalleId: item.ordenCompraDetalleId,
          insumoId: item.insumoId,
          cantidad: cantidad,
          costoUnitario: costo,
          observacion: observacion.isEmpty ? null : observacion,
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

    final observacionGeneral = _recepcionObservacionController.text.trim();

    final result = await context.read<EntradasCubit>().registerPurchaseEntry(
      ordenCompraId: orderId,
      documentoSoporte: documento,
      observacion: observacionGeneral.isEmpty ? null : observacionGeneral,
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

    if (!mounted) return;

    _showActionResult(result);
  }

  // ==========================================================
  // CONSTRUCCION PRINCIPAL
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final session = context.select((AuthCubit cubit) => cubit.state.session);

    final signingOut = context.select(
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
      onSignOut: signingOut ? () {} : () => context.read<AuthCubit>().signOut(),
      child: BlocBuilder<EntradasCubit, EntradasState>(
        builder: (context, state) {
          if (state.status == EntradasStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == EntradasStatus.error) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: _EmptyContent(
                  title: 'No pudimos cargar las entradas',
                  message:
                      state.errorMessage ??
                      'Intenta nuevamente para consultar el flujo.',
                  icon: Icons.error_outline_rounded,
                ),
              ),
            );
          }

          final stockSelected = _selectedView == _EntradaView.stockInicial;

          final lastEntry =
              state.lastEntry?.tipoEntrada ==
                  (stockSelected ? 'STOCK_INICIAL' : 'COMPRA')
              ? state.lastEntry
              : null;

          return LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  compact ? 12 : 18,
                  14,
                  compact ? 12 : 18,
                  20,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1500),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ==================================
                        // PESTAÑAS
                        // ==================================
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SegmentedButton<_EntradaView>(
                            showSelectedIcon: false,
                            style: ButtonStyle(
                              visualDensity: VisualDensity.compact,
                              backgroundColor: WidgetStateProperty.resolveWith(
                                (states) =>
                                    states.contains(WidgetState.selected)
                                    ? _orange
                                    : null,
                              ),
                              foregroundColor: WidgetStateProperty.resolveWith(
                                (states) =>
                                    states.contains(WidgetState.selected)
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            segments: const [
                              ButtonSegment(
                                value: _EntradaView.stockInicial,
                                icon: Icon(
                                  Icons.inventory_2_outlined,
                                  size: 17,
                                ),
                                label: Text('Stock inicial'),
                              ),
                              ButtonSegment(
                                value: _EntradaView.recepcionCompra,
                                icon: Icon(
                                  Icons.move_to_inbox_outlined,
                                  size: 17,
                                ),
                                label: Text('Recepción de compra'),
                              ),
                            ],
                            selected: {_selectedView},
                            onSelectionChanged: (selection) {
                              setState(() {
                                _selectedView = selection.first;
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 14),

                        // ==================================
                        // ENCABEZADO DE LA VISTA
                        // ==================================
                        _PageIntroduction(
                          icon: stockSelected
                              ? Icons.inventory_2_outlined
                              : Icons.assignment_turned_in_outlined,
                          title: stockSelected
                              ? 'Stock inicial'
                              : 'Recepción desde compra',
                          subtitle: stockSelected
                              ? 'Carga las cantidades y costos unitarios para establecer el inventario base.'
                              : 'Selecciona una orden aprobada o parcialmente recibida y registra únicamente las cantidades que ingresaron.',
                        ),

                        const SizedBox(height: 14),

                        // ==================================
                        // FORMULARIOS
                        // ==================================
                        if (stockSelected) ...[
                          _StockGeneralCard(
                            documentoController: _stockDocumentoController,
                            observacionController: _stockObservacionController,
                            disabled: state.isSubmittingAction,
                          ),

                          const SizedBox(height: 14),

                          _Surface(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _SectionHeading(
                                  icon: Icons.format_list_bulleted_rounded,
                                  title: 'Detalle de insumos',
                                  action: OutlinedButton.icon(
                                    onPressed: state.isSubmittingAction
                                        ? null
                                        : _addStockDraft,
                                    icon: const Icon(
                                      Icons.add_rounded,
                                      size: 18,
                                    ),
                                    label: const Text('Agregar fila'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: _orange,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 13),

                                TextField(
                                  controller: _stockSearchController,
                                  onChanged: (_) => setState(() {}),
                                  decoration:
                                      _fieldDecoration(
                                        context,
                                        hint: 'Buscar insumo de la lista...',
                                        icon: Icons.search_rounded,
                                      ).copyWith(
                                        suffixIcon:
                                            _stockSearchController.text.isEmpty
                                            ? null
                                            : IconButton(
                                                tooltip: 'Limpiar búsqueda',
                                                onPressed: () {
                                                  _stockSearchController
                                                      .clear();
                                                  setState(() {});
                                                },
                                                icon: const Icon(
                                                  Icons.close_rounded,
                                                ),
                                              ),
                                      ),
                                ),

                                const SizedBox(height: 12),

                                _StockTable(
                                  drafts: _stockDrafts,
                                  insumos: state.insumos,
                                  filter: _stockSearchController.text,
                                  disabled: state.isSubmittingAction,
                                  onChanged: () => setState(() {}),
                                  onRemove: (draft) {
                                    final index = _stockDrafts.indexOf(draft);

                                    if (index >= 0) {
                                      _removeStockDraft(index);
                                    }
                                  },
                                ),

                                const SizedBox(height: 15),

                                _FormFooter(
                                  total: _stockTotal,
                                  label: 'Registrar stock inicial',
                                  icon: Icons.inventory_2_outlined,
                                  loading: state.isSubmittingAction,
                                  onSubmit: () => _submitStockInitial(state),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          _RecepcionGeneralCard(
                            state: state,
                            documentoController: _recepcionDocumentoController,
                            observacionController:
                                _recepcionObservacionController,
                            onOrderChanged: (id) =>
                                _prepareRecepcionDrafts(state, id),
                          ),

                          const SizedBox(height: 14),

                          _Surface(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const _SectionHeading(
                                  icon: Icons.pending_actions_outlined,
                                  title: 'Líneas pendientes',
                                ),

                                const SizedBox(height: 12),

                                if (state.isOrderDetailLoading)
                                  const Padding(
                                    padding: EdgeInsets.all(28),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                else if (state.orderDetailErrorMessage != null)
                                  _EmptyContent(
                                    icon: Icons.error_outline,
                                    title: 'No pudimos cargar la orden',
                                    message: state.orderDetailErrorMessage!,
                                  )
                                else if (state.selectedReceivableOrder == null)
                                  const _EmptyContent(
                                    icon: Icons.shopping_cart_outlined,
                                    title: 'Selecciona una orden',
                                    message:
                                        'Aquí se mostrarán los insumos pendientes de recepción.',
                                  )
                                else if (_recepcionDrafts.isEmpty)
                                  const _EmptyContent(
                                    icon: Icons.check_circle_outline,
                                    title: 'Sin saldo pendiente',
                                    message:
                                        'La orden seleccionada no tiene líneas pendientes por recibir.',
                                  )
                                else ...[
                                  TextField(
                                    controller: _recepcionSearchController,
                                    onChanged: (_) => setState(() {}),
                                    decoration:
                                        _fieldDecoration(
                                          context,
                                          hint:
                                              'Buscar producto por código o nombre...',
                                          icon: Icons.search_rounded,
                                        ).copyWith(
                                          suffixIcon:
                                              _recepcionSearchController
                                                  .text
                                                  .isEmpty
                                              ? null
                                              : IconButton(
                                                  onPressed: () {
                                                    _recepcionSearchController
                                                        .clear();
                                                    setState(() {});
                                                  },
                                                  icon: const Icon(
                                                    Icons.close_rounded,
                                                  ),
                                                ),
                                        ),
                                  ),

                                  const SizedBox(height: 12),

                                  _RecepcionTable(
                                    drafts: _recepcionDrafts,
                                    filter: _recepcionSearchController.text,
                                    disabled: state.isSubmittingAction,
                                    onChanged: () => setState(() {}),
                                  ),
                                ],

                                const SizedBox(height: 15),

                                _FormFooter(
                                  total: _recepcionTotal,
                                  label: 'Registrar recepción',
                                  icon: Icons.move_to_inbox_outlined,
                                  loading: state.isSubmittingAction,
                                  onSubmit: _recepcionDrafts.isEmpty
                                      ? null
                                      : () => _submitRecepcion(state),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // ==================================
                        // ULTIMA ENTRADA
                        // ==================================
                        if (lastEntry != null) ...[
                          const SizedBox(height: 14),
                          _LastEntryPanel(entry: lastEntry),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ============================================================
// ENCABEZADO DE CADA PESTAÑA
// ============================================================

class _PageIntroduction extends StatelessWidget {
  const _PageIntroduction({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return _Surface(
      padding: const EdgeInsets.all(17),
      child: Row(
        children: [
          const SizedBox(width: 2),
          _IconBox(icon, size: 48),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 11.7,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// INFORMACION GENERAL DEL STOCK INICIAL
// ============================================================

class _StockGeneralCard extends StatelessWidget {
  const _StockGeneralCard({
    required this.documentoController,
    required this.observacionController,
    required this.disabled,
  });

  final TextEditingController documentoController;
  final TextEditingController observacionController;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeading(
            icon: Icons.folder_open_outlined,
            title: 'Información general',
          ),

          const SizedBox(height: 15),

          _FieldLabel(
            label: 'Documento soporte',
            child: TextField(
              controller: documentoController,
              enabled: !disabled,
              maxLength: 150,
              decoration: _fieldDecoration(
                context,
                hint: 'Ej. Acta de inventario, guía u otro documento...',
                icon: Icons.description_outlined,
              ).copyWith(counterText: ''),
            ),
          ),

          const SizedBox(height: 13),

          _FieldLabel(
            label: 'Observación',
            child: TextField(
              controller: observacionController,
              enabled: !disabled,
              minLines: 2,
              maxLines: 3,
              decoration: _fieldDecoration(
                context,
                hint: 'Describe el motivo o detalle del stock inicial...',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// INFORMACION GENERAL DE RECEPCION
// ============================================================

class _RecepcionGeneralCard extends StatelessWidget {
  const _RecepcionGeneralCard({
    required this.state,
    required this.documentoController,
    required this.observacionController,
    required this.onOrderChanged,
  });

  final EntradasState state;

  final TextEditingController documentoController;
  final TextEditingController observacionController;

  final ValueChanged<int?> onOrderChanged;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeading(
            icon: Icons.folder_open_outlined,
            title: 'Información general',
          ),

          const SizedBox(height: 14),

          _FieldLabel(
            label: 'Orden de compra',
            requiredField: true,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return DropdownMenu<int>(
                  key: ValueKey(state.selectedReceivableOrderId),
                  width: constraints.maxWidth,
                  menuHeight: 310,
                  enableFilter: true,
                  enableSearch: true,
                  requestFocusOnTap: true,
                  enabled:
                      !state.isSubmittingAction && !state.isOrderDetailLoading,
                  initialSelection: state.selectedReceivableOrderId ?? -1,
                  leadingIcon: const Icon(
                    Icons.shopping_cart_outlined,
                    size: 19,
                  ),
                  hintText: 'Seleccionar orden',
                  inputDecorationTheme: _dropdownTheme(context),
                  dropdownMenuEntries: [
                    const DropdownMenuEntry<int>(
                      value: -1,
                      label: 'Seleccionar orden',
                    ),
                    ...state.receivableOrders.map(
                      (item) => DropdownMenuEntry<int>(
                        value: item.id,
                        label: '${item.codigo} · ${item.proveedorRazonSocial}',
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == null) return;

                    onOrderChanged(value == -1 ? null : value);
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 13),

          _FieldLabel(
            label: 'Documento soporte',
            requiredField: true,
            child: TextField(
              controller: documentoController,
              enabled: !state.isSubmittingAction,
              maxLength: 150,
              decoration: _fieldDecoration(
                context,
                hint: 'Ej. Guía de remisión, factura u otro documento...',
                icon: Icons.description_outlined,
              ).copyWith(counterText: ''),
            ),
          ),

          const SizedBox(height: 13),

          _FieldLabel(
            label: 'Observación',
            child: TextField(
              controller: observacionController,
              enabled: !state.isSubmittingAction,
              minLines: 2,
              maxLines: 3,
              decoration: _fieldDecoration(
                context,
                hint: 'Descripción adicional de la recepción...',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TABLA DE STOCK INICIAL
// ============================================================

class _StockTable extends StatelessWidget {
  const _StockTable({
    required this.drafts,
    required this.insumos,
    required this.filter,
    required this.disabled,
    required this.onChanged,
    required this.onRemove,
  });

  final List<_StockDraft> drafts;
  final List<dynamic> insumos;
  final String filter;
  final bool disabled;
  final VoidCallback onChanged;
  final ValueChanged<_StockDraft> onRemove;

  static const double _minTableWidth = 850;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final normalized = filter.toLowerCase().trim();

    final visible = drafts
        .where((draft) {
          if (normalized.isEmpty) return true;

          final id =
              draft.insumoId ??
              (insumos.isNotEmpty ? insumos.first.id as int : null);

          final selected = insumos.where((item) => item.id == id);

          if (selected.isEmpty) return false;

          return (selected.first.displayName as String).toLowerCase().contains(
            normalized,
          );
        })
        .toList(growable: false);

    return _Surface(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: math.max(_minTableWidth, constraints.maxWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // CABECERA
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 12,
                    ),
                    color: colors.surfaceContainerLow,
                    child: const Row(
                      children: [
                        SizedBox(width: 30, child: _TableHeader('#')),
                        Expanded(flex: 5, child: _TableHeader('Insumo *')),
                        SizedBox(width: 12),
                        Expanded(flex: 2, child: _TableHeader('Cantidad *')),
                        SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _TableHeader('Costo unitario *'),
                        ),
                        SizedBox(width: 12),
                        SizedBox(width: 90, child: _TableHeader('Observación')),
                        SizedBox(width: 48, child: _TableHeader('Acción')),
                      ],
                    ),
                  ),

                  if (visible.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(22),
                      child: Text(
                        'No hay filas que coincidan con la búsqueda.',
                      ),
                    ),

                  for (final draft in visible)
                    _StockTableRow(
                      key: ObjectKey(draft),
                      index: drafts.indexOf(draft) + 1,
                      draft: draft,
                      insumos: insumos,
                      disabled: disabled,
                      canRemove: drafts.length > 1,
                      onChanged: onChanged,
                      onRemove: () => onRemove(draft),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// FILA DE STOCK
// ============================================================

class _StockTableRow extends StatelessWidget {
  const _StockTableRow({
    required this.index,
    required this.draft,
    required this.insumos,
    required this.disabled,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
    super.key,
  });

  final int index;
  final _StockDraft draft;
  final List<dynamic> insumos;

  final bool disabled;
  final bool canRemove;

  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final selectedId =
        draft.insumoId ?? (insumos.isNotEmpty ? insumos.first.id as int : null);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30,
            child: Padding(
              padding: const EdgeInsets.only(top: 13),
              child: Text(
                '$index',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          // INSUMO
          Expanded(
            flex: 5,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return DropdownMenu<int>(
                  key: ValueKey('stock-${identityHashCode(draft)}-$selectedId'),
                  width: constraints.maxWidth,
                  menuHeight: 280,
                  enableFilter: true,
                  enableSearch: true,
                  requestFocusOnTap: true,
                  enabled: !disabled && insumos.isNotEmpty,
                  initialSelection: selectedId,
                  hintText: 'Seleccionar insumo',
                  inputDecorationTheme: _dropdownTheme(context),
                  dropdownMenuEntries: [
                    for (final item in insumos)
                      DropdownMenuEntry<int>(
                        value: item.id as int,
                        label: item.displayName as String,
                      ),
                  ],
                  onSelected: (value) {
                    draft.insumoId = value;
                    onChanged();
                  },
                );
              },
            ),
          ),

          const SizedBox(width: 12),

          // CANTIDAD
          Expanded(
            flex: 2,
            child: TextField(
              controller: draft.cantidadController,
              enabled: !disabled,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => onChanged(),
              decoration: _fieldDecoration(context, hint: '0.00'),
            ),
          ),

          const SizedBox(width: 12),

          // COSTO UNITARIO
          Expanded(
            flex: 2,
            child: TextField(
              controller: draft.costoController,
              enabled: !disabled,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => onChanged(),
              decoration: _fieldDecoration(
                context,
                hint: '0.00',
              ).copyWith(prefixText: 'S/ '),
            ),
          ),

          const SizedBox(width: 12),

          // OBSERVACION
          SizedBox(
            width: 90,
            child: IconButton.outlined(
              tooltip: 'Observación de la línea',
              visualDensity: VisualDensity.compact,
              onPressed: disabled
                  ? null
                  : () => _editLineObservation(
                      context,
                      draft.observacionController,
                      onChanged,
                    ),
              icon: Icon(
                draft.observacionController.text.trim().isEmpty
                    ? Icons.note_add_outlined
                    : Icons.sticky_note_2_outlined,
                color: _orange,
                size: 18,
              ),
            ),
          ),

          // ELIMINAR
          SizedBox(
            width: 48,
            child: IconButton(
              tooltip: 'Eliminar línea',
              onPressed: disabled || !canRemove ? null : onRemove,
              icon: Icon(
                Icons.delete_outline_rounded,
                size: 19,
                color: canRemove ? colors.error : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TABLA DE RECEPCION
// ============================================================

class _RecepcionTable extends StatelessWidget {
  const _RecepcionTable({
    required this.drafts,
    required this.filter,
    required this.disabled,
    required this.onChanged,
  });

  final List<_RecepcionDraft> drafts;
  final String filter;
  final bool disabled;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final normalized = filter.toLowerCase().trim();

    final visible = drafts
        .where((item) {
          return normalized.isEmpty ||
              item.insumoLabel.toLowerCase().contains(normalized);
        })
        .toList(growable: false);

    return _Surface(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: math.max(850, constraints.maxWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 12,
                    ),
                    color: colors.surfaceContainerLow,
                    child: const Row(
                      children: [
                        SizedBox(width: 30, child: _TableHeader('#')),
                        Expanded(flex: 5, child: _TableHeader('Insumo')),
                        SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _TableHeader('Saldo pendiente'),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _TableHeader('Cantidad a recibir'),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _TableHeader('Costo unitario'),
                        ),
                        SizedBox(width: 80, child: _TableHeader('Observación')),
                      ],
                    ),
                  ),

                  if (visible.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(22),
                      child: Text(
                        'No hay productos que coincidan con la búsqueda.',
                      ),
                    ),

                  for (final draft in visible)
                    _RecepcionTableRow(
                      key: ObjectKey(draft),
                      index: drafts.indexOf(draft) + 1,
                      draft: draft,
                      disabled: disabled,
                      onChanged: onChanged,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// FILA DE RECEPCION
// ============================================================

class _RecepcionTableRow extends StatelessWidget {
  const _RecepcionTableRow({
    required this.index,
    required this.draft,
    required this.disabled,
    required this.onChanged,
    super.key,
  });

  final int index;
  final _RecepcionDraft draft;

  final bool disabled;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30,
            child: Padding(
              padding: const EdgeInsets.only(top: 13),
              child: Text('$index', style: const TextStyle(fontSize: 11)),
            ),
          ),

          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.only(top: 11),
              child: Text(
                draft.insumoLabel,
                style: const TextStyle(
                  fontSize: 11.7,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _quantity(draft.saldoPendiente),
                style: TextStyle(
                  fontSize: 12,
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            flex: 2,
            child: TextField(
              controller: draft.cantidadController,
              enabled: !disabled,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => onChanged(),
              decoration: _fieldDecoration(context, hint: '0.00'),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            flex: 2,
            child: TextField(
              controller: draft.costoController,
              enabled: !disabled,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => onChanged(),
              decoration: _fieldDecoration(
                context,
                hint: '0.00',
              ).copyWith(prefixText: 'S/ '),
            ),
          ),

          SizedBox(
            width: 80,
            child: IconButton.outlined(
              visualDensity: VisualDensity.compact,
              tooltip: 'Observación de recepción',
              onPressed: disabled
                  ? null
                  : () => _editLineObservation(
                      context,
                      draft.observacionController,
                      onChanged,
                    ),
              icon: Icon(
                draft.observacionController.text.trim().isEmpty
                    ? Icons.note_add_outlined
                    : Icons.sticky_note_2_outlined,
                color: _orange,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// EDITOR DE OBSERVACION DE UNA LINEA
// ============================================================

Future<void> _editLineObservation(
  BuildContext context,
  TextEditingController controller,
  VoidCallback onChanged,
) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text(
          'Observación de la línea',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: controller,
            autofocus: true,
            minLines: 3,
            maxLines: 5,
            maxLength: 300,
            decoration: _fieldDecoration(
              dialogContext,
              hint: 'Escribe una observación para este insumo...',
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: _orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Listo'),
          ),
        ],
      );
    },
  );

  if (context.mounted) {
    onChanged();
  }
}

// ============================================================
// PIE DEL FORMULARIO
// ============================================================

class _FormFooter extends StatelessWidget {
  const _FormFooter({
    required this.total,
    required this.label,
    required this.icon,
    required this.loading,
    required this.onSubmit,
  });

  final double total;
  final String label;
  final IconData icon;
  final bool loading;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _orange.withValues(alpha: 0.065),
        borderRadius: BorderRadius.circular(11),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidget = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _IconBox(Icons.calculate_outlined, size: 39),
              const SizedBox(width: 11),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total estimado',
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _money(total),
                    style: const TextStyle(
                      color: _orange,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          );

          final button = FilledButton.icon(
            onPressed: loading ? null : onSubmit,
            style: FilledButton.styleFrom(
              backgroundColor: _orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            icon: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(icon, size: 18),
            label: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          );

          if (constraints.maxWidth < 500) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [totalWidget, const SizedBox(height: 13), button],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [totalWidget, button],
          );
        },
      ),
    );
  }
}

// ============================================================
// ULTIMA ENTRADA
// ============================================================

class _LastEntryPanel extends StatelessWidget {
  const _LastEntryPanel({required this.entry});

  final dynamic entry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return _Surface(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeading(
            icon: Icons.history_rounded,
            title: 'Última entrada registrada',
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 15,
            runSpacing: 9,
            children: [
              _InfoText(label: 'Código', value: entry.codigo),
              _InfoText(label: 'Tipo', value: entry.tipoEntrada),
              _InfoText(label: 'Estado', value: entry.estado),
              _InfoText(
                label: 'Fecha',
                value: DateFormat(
                  'dd/MM/yyyy hh:mm a',
                ).format(entry.fechaEntrada.toLocal()),
              ),
              _InfoText(
                label: 'Documento',
                value: entry.documentoSoporte ?? 'Sin documento',
              ),
            ],
          ),

          if ((entry.observacion ?? '').toString().trim().isNotEmpty) ...[
            const SizedBox(height: 11),
            Text(
              'Observación: ${entry.observacion}',
              style: TextStyle(fontSize: 11.5, color: colors.onSurfaceVariant),
            ),
          ],

          const SizedBox(height: 13),

          for (final item in entry.detalles)
            Container(
              margin: const EdgeInsets.only(bottom: 7),
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.insumoCodigo} · ${item.insumoNombre}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Wrap(
                    spacing: 15,
                    runSpacing: 6,
                    children: [
                      Text('Cantidad: ${_quantity(item.cantidad)}'),
                      Text('Unitario: ${_money(item.costoUnitario)}'),
                      Text('Total: ${_money(item.costoTotal)}'),
                      Text(
                        'Stock actual: ${_quantity(item.stockActual)} '
                        '${item.unidadMedidaCodigo}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// COMPONENTES AUXILIARES
// ============================================================

class _Surface extends StatelessWidget {
  const _Surface({required this.child, required this.padding});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      padding: padding,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: child,
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox(this.icon, {this.size = 35});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? _orange.withValues(alpha: 0.17)
            : _orangeSoft,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, color: _orange, size: size * 0.52),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.icon, required this.title, this.action});

  final IconData icon;
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _orange, size: 20),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

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
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            if (requiredField)
              const Text(
                ' *',
                style: TextStyle(color: _orange, fontWeight: FontWeight.w800),
              ),
          ],
        ),
        const SizedBox(height: 7),
        child,
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      maxLines: 2,
      style: TextStyle(
        fontSize: 10.7,
        fontWeight: FontWeight.w800,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _InfoText extends StatelessWidget {
  const _InfoText({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 11.8, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _EmptyContent extends StatelessWidget {
  const _EmptyContent({
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _orange, size: 32),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// DECORACION DE CAMPOS
// ============================================================

InputDecoration _fieldDecoration(
  BuildContext context, {
  required String hint,
  IconData? icon,
}) {
  final colors = Theme.of(context).colorScheme;

  return InputDecoration(
    isDense: true,
    hintText: hint,
    hintStyle: TextStyle(fontSize: 11.8, color: colors.onSurfaceVariant),
    prefixIcon: icon == null
        ? null
        : Icon(icon, size: 19, color: colors.onSurfaceVariant),
    filled: true,
    fillColor: colors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: colors.outlineVariant),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: _orange, width: 1.4),
    ),
  );
}

InputDecorationTheme _dropdownTheme(BuildContext context) {
  final colors = Theme.of(context).colorScheme;

  return InputDecorationTheme(
    isDense: true,
    filled: true,
    fillColor: colors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: colors.outlineVariant),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: _orange, width: 1.4),
    ),
  );
}

// ============================================================
// FORMATEADORES
// ============================================================

double? _parseNumber(String value) {
  final normalized = value.trim().replaceAll(',', '.');

  if (normalized.isEmpty) return null;

  final parsed = double.tryParse(normalized);

  if (parsed == null || !parsed.isFinite) {
    return null;
  }

  return parsed;
}

String _quantity(num value) {
  return value.toStringAsFixed(2);
}

String _money(num value) {
  return NumberFormat.currency(
    locale: 'es_PE',
    symbol: 'S/ ',
    decimalDigits: 2,
  ).format(value);
}

// ============================================================
// MODELO TEMPORAL DE STOCK INICIAL
// ============================================================

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

// ============================================================
// MODELO TEMPORAL DE RECEPCION DE COMPRA
// ============================================================

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
