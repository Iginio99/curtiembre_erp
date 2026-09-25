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
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/producto_terminado_record.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/presentation/cubit/ordenes_produccion_cubit.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/presentation/cubit/ordenes_produccion_state.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/presentation/widgets/finalizar_orden_dialog.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/presentation/widgets/orden_simple_action_dialog.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/presentation/widgets/orden_upsert_dialog.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/presentation/widgets/registrar_calidad_final_dialog.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/presentation/widgets/registrar_merma_dialog.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/presentation/widgets/solicitar_consumo_dialog.dart';
import 'package:erp_curtiembre_fronted/features/security/presentation/cubit/security_access_cubit.dart';
import 'package:erp_curtiembre_fronted/features/users/domain/entities/user_list_item.dart';
import 'package:erp_curtiembre_fronted/features/users/domain/repositories/users_repository.dart';
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

  Future<List<UserListItem>> _loadResponsables() =>
      getIt<UsersRepository>().listUsers(activo: true);

  Future<void> _openCreateDialog(OrdenesProduccionState state) async {
    _talker.ui('Se abrio el dialogo para crear una orden de produccion.');
    final responsables = await _loadResponsables();
    if (!mounted) return;
    final payload = await showDialog<OrdenUpsertFormData>(
      context: context,
      builder: (_) => OrdenUpsertDialog(
        title: 'Nueva orden de produccion',
        submitLabel: 'Crear orden',
        isSubmitting: state.isSubmittingAction,
        clienteOptions: state.clienteOptions,
        loteOptions: state.loteOptions,
        responsableOptions: responsables,
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
      responsableUsuarioId: payload.responsableUsuarioId,
    );

    if (!mounted) {
      return;
    }

    _showActionResult(result);
  }

  Future<void> _startSelectedOrden() async {
    _talker.ui('Se abrio el dialogo para iniciar la orden seleccionada.');
    final responsables = await _loadResponsables();
    if (!mounted) return;
    final payload = await showDialog<OrdenSimpleActionFormData>(
      context: context,
      builder: (_) => OrdenSimpleActionDialog(
        title: 'Iniciar orden',
        submitLabel: 'Iniciar',
        labelText: 'Observacion inicial',
        hintText: 'Detalle breve del arranque de la orden',
        requireStagePlanning: true,
        responsableOptions: responsables,
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
          responsableUsuarioId: payload.responsableUsuarioId,
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
    final responsables = await _loadResponsables();
    if (!mounted) return;
    final payload = await showDialog<OrdenSimpleActionFormData>(
      context: context,
      builder: (_) => OrdenSimpleActionDialog(
        title: 'Iniciar ${proceso.procesoNombre}',
        submitLabel: 'Iniciar proceso',
        labelText: 'Observacion de inicio',
        hintText: 'Detalle breve del arranque del proceso',
        requireStagePlanning: proceso.estado == 'PENDIENTE',
        responsableOptions: responsables,
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
      responsableUsuarioId: payload.responsableUsuarioId,
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
      builder: (_) =>
          RegistrarCalidadFinalDialog(isSubmitting: state.isSubmittingAction),
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
        .registerCalidadFinal(input: payload.input);

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
      title: 'Órdenes de producción',
      currentPath: '/produccion/ordenes',
      breadcrumbs: const ['Inicio', 'Producción', 'Órdenes'],
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
                    final visibleItems = state.items.where((item) {
                      final date = item.creadoEn.toLocal();
                      return date.year == _selectedMonth.year &&
                          date.month == _selectedMonth.month;
                    }).toList(growable: false);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Órdenes', style: theme.textTheme.titleMedium),
              ),
              AppButton.primary(
                label: 'Nueva orden',
                icon: Icons.add_rounded,
                isLoading: state.isSubmittingAction,
                onPressed: onCreate,
                expand: false,
              ),
            ],
          ),
          const Gap(AppSpacing.md),
          Row(
            children: [
              Expanded(
                flex: 6,
                child: TextField(
                  controller: searchController,
                  textInputAction: TextInputAction.search,
                  onChanged: onSearchChanged,
                  decoration: const InputDecoration(
                    labelText: 'Buscar orden',
                    hintText: 'Ej. OP-0001 o cliente',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
              const Gap(AppSpacing.sm),
              Expanded(
                flex: 5,
                child: DropdownButtonFormField<int?>(
                  isExpanded: true,
                  initialValue: state.selectedClienteId,
                  decoration: const InputDecoration(labelText: 'Cliente'),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Todos los clientes'),
                    ),
                    ...state.clienteOptions.map(
                      (option) => DropdownMenuItem<int?>(
                        value: option.id,
                        child: Text(
                          option.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: onClienteChanged,
                ),
              ),
              const Gap(AppSpacing.sm),
              Expanded(
                flex: 5,
                child: DropdownButtonFormField<int?>(
                  isExpanded: true,
                  initialValue: state.selectedLoteId,
                  decoration: const InputDecoration(labelText: 'Lote'),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Todos los lotes'),
                    ),
                    ...state.loteOptions.map(
                      (option) => DropdownMenuItem<int?>(
                        value: option.id,
                        child: Text(
                          option.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: onLoteChanged,
                ),
              ),
              const Gap(AppSpacing.sm),
              Expanded(
                flex: 4,
                child: TextField(
                  controller: estadoController,
                  onChanged: onSearchChanged,
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                    hintText: 'Ej. EN_PROCESO',
                  ),
                ),
              ),
              const Gap(AppSpacing.sm),
              Expanded(
                flex: 4,
                child: DropdownButtonFormField<DateTime>(
                  initialValue: selectedMonth,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Mes',
                    prefixIcon: Icon(Icons.calendar_month_outlined),
                  ),
                  items: List.generate(18, (index) {
                    final now = DateTime.now();
                    final month = DateTime(now.year, now.month - index);
                    return DropdownMenuItem<DateTime>(
                      value: month,
                      child: Text(
                        _formatMonth(month),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }),
                  onChanged: onMonthChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrdenesListPanel extends StatelessWidget {
  const _OrdenesListPanel({
    required this.state,
    required this.onRetry,
    required this.onSelectOrden,
  });

  final OrdenesProduccionState state;
  final VoidCallback onRetry;
  final ValueChanged<int> onSelectOrden;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Listado de ordenes', style: theme.textTheme.titleLarge),
          const Gap(AppSpacing.xs),
          Text(
            '${state.items.length} resultado(s) para la vista actual.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(AppSpacing.lg),
          Expanded(
            child: switch (state.status) {
              OrdenesProduccionStatus.loading => const Center(
                child: CircularProgressIndicator(),
              ),
              OrdenesProduccionStatus.error => _CenteredMessage(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppMessageCard.error(
                      title: 'No pudimos cargar las ordenes',
                      message:
                          state.errorMessage ??
                          'Intenta nuevamente para revisar la operacion del modulo.',
                    ),
                    const Gap(AppSpacing.lg),
                    AppButton.secondary(
                      label: 'Reintentar',
                      icon: Icons.refresh_rounded,
                      onPressed: onRetry,
                    ),
                  ],
                ),
              ),
              OrdenesProduccionStatus.success =>
                state.items.isEmpty
                    ? const _CenteredMessage(
                        child: AppMessageCard.info(
                          title: 'Sin resultados',
                          message:
                              'No encontramos ordenes con los filtros actuales.',
                        ),
                      )
                    : ListView.separated(
                        itemCount: state.items.length,
                        separatorBuilder: (_, _) => const Gap(AppSpacing.md),
                        itemBuilder: (context, index) {
                          final item = state.items[index];
                          return _OrdenListTileCard(
                            item: item,
                            isSelected: item.id == state.selectedOrdenId,
                            onTap: () => onSelectOrden(item.id),
                          );
                        },
                      ),
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
                        '${orden.clienteRazonSocial} · ${orden.loteCodigo}',
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
                              value: orden.responsableNombre ?? 'Sin asignar',
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
                        procesos: state.selectedProcesos,
                        planificados: state.consumoPlanificado,
                        consumos: state.consumoReal,
                        mermas: state.mermas,
                        desviaciones: state.desviaciones,
                        controlCalidad: state.controlCalidad,
                        productoTerminado: state.productoTerminado,
                        isSubmitting: state.isSubmittingAction,
                        onStart: onStartProceso,
                        onFinish: onFinishProceso,
                        onEditObservation: onEditObservacion,
                        onRequestConsumption: onRequestConsumption,
                        onRegisterMerma: onRegisterMerma,
                        onStartOrder: onStartOrden,
                        onCalculatePlanned: onGeneratePlannedConsumption,
                        onRegisterQuality: onRegisterCalidadFinal,
                        onFinalizeOrder: onFinalizeOrden,
                        hasQuality: state.controlCalidad != null,
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

class _OrdersPipelineBoard extends StatelessWidget {
  const _OrdersPipelineBoard({
    required this.state,
    required this.onRetry,
    required this.onSelectOrden,
  });

  final OrdenesProduccionState state;
  final VoidCallback onRetry;
  final ValueChanged<int> onSelectOrden;

  static const _stages = <({String title, Set<String> states})>[
    (title: 'Programadas', states: {'PROGRAMADA'}),
    (
      title: 'Preparación',
      states: {'ESPERANDO_MATERIALES', 'LISTA_PARA_INICIAR'},
    ),
    (title: 'En proceso', states: {'EN_PROCESO'}),
    (title: 'Finalizadas', states: {'FINALIZADA'}),
    (title: 'Anuladas', states: {'ANULADA', 'CANCELADA'}),
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
              title: 'No pudimos cargar las ordenes',
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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final stage in _stages) ...[
            _OrderPipelineColumn(
              title: stage.title,
              items: state.items
                  .where((item) => stage.states.contains(item.estado))
                  .toList(growable: false),
              onSelectOrden: onSelectOrden,
            ),
            const Gap(AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _OrderPipelineColumn extends StatelessWidget {
  const _OrderPipelineColumn({
    required this.title,
    required this.items,
    required this.onSelectOrden,
  });

  final String title;
  final List<OrdenProduccionRecord> items;
  final ValueChanged<int> onSelectOrden;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 240,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const Gap(AppSpacing.sm),
              Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
              _MiniPill(
                label: '${items.length}',
                background: theme.colorScheme.surfaceContainerHighest,
                foreground: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          const Gap(AppSpacing.sm),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'Sin ordenes',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Gap(AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _OrdenListTileCard(
                        item: item,
                        isSelected: false,
                        onTap: () => onSelectOrden(item.id),
                      );
                    },
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
  });

  final OrdenProduccionRecord item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.68)
                : theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.42)
                  : theme.colorScheme.outlineVariant,
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
                  Text(item.codigo, style: theme.textTheme.titleSmall),
                  _MiniPill(
                    label: _humanizeStatus(item.estado),
                    background: theme.colorScheme.primaryContainer,
                    foreground: theme.colorScheme.onPrimaryContainer,
                  ),
                ],
              ),
              const Gap(AppSpacing.sm),
              Text(
                '${item.clienteRazonSocial} · ${item.loteCodigo}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const Gap(AppSpacing.sm),
              Text(
                '${item.procesosFinalizados}/${item.procesosTotales} procesos · fin ${_formatDate(item.fechaFinEstimada)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
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
    required this.planificados,
    required this.consumos,
  });

  final OrdenProcesoRecord proceso;
  final bool isSubmitting;
  final VoidCallback? onStart;
  final VoidCallback? onFinish;
  final VoidCallback onEditObservation;
  final VoidCallback? onRequestConsumption;
  final VoidCallback? onRegisterMerma;
  final bool isLocked;
  final List<ConsumoPlanificadoRecord> planificados;
  final List<ConsumoRealRecord> consumos;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                value: proceso.responsableNombre ?? 'Sin asignar',
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
          Text('Insumos', style: theme.textTheme.titleSmall),
          const Gap(AppSpacing.xs),
          Text(
            planificados.isEmpty
                ? 'Sin insumos planificados'
                : planificados.map((item) => item.insumoNombre).join(' · '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(AppSpacing.xs),
          Text(
            '${planificados.length} planificados · ${consumos.length} consumidos',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const Gap(AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              AppButton.secondary(
                label: 'Iniciar',
                icon: Icons.play_circle_outline,
                isLoading: isSubmitting,
                onPressed: onStart,
              ),
              AppButton.secondary(
                label: 'Finalizar',
                icon: Icons.task_alt_outlined,
                isLoading: isSubmitting,
                onPressed: onFinish,
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
                onPressed: onRequestConsumption,
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
    required this.procesos,
    required this.planificados,
    required this.consumos,
    required this.mermas,
    required this.desviaciones,
    required this.controlCalidad,
    required this.productoTerminado,
    required this.isSubmitting,
    required this.onStart,
    required this.onFinish,
    required this.onEditObservation,
    required this.onRequestConsumption,
    required this.onRegisterMerma,
    required this.onStartOrder,
    required this.onCalculatePlanned,
    required this.onRegisterQuality,
    required this.onFinalizeOrder,
    required this.hasQuality,
  });

  final List<OrdenProcesoRecord> procesos;
  final List<ConsumoPlanificadoRecord> planificados;
  final List<ConsumoRealRecord> consumos;
  final List<MermaProcesoRecord> mermas;
  final List<DesviacionConsumoRecord> desviaciones;
  final ControlCalidadRecord? controlCalidad;
  final ProductoTerminadoRecord? productoTerminado;
  final bool isSubmitting;
  final ValueChanged<OrdenProcesoRecord> onStart;
  final ValueChanged<OrdenProcesoRecord> onFinish;
  final ValueChanged<OrdenProcesoRecord> onEditObservation;
  final ValueChanged<OrdenProcesoRecord> onRequestConsumption;
  final ValueChanged<OrdenProcesoRecord> onRegisterMerma;
  final VoidCallback? onStartOrder;
  final VoidCallback onCalculatePlanned;
  final VoidCallback onRegisterQuality;
  final VoidCallback onFinalizeOrder;
  final bool hasQuality;

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
    if (_selectedIndex < 0) {
      _selectedIndex = _selectedStageByOrder[orderId] ??
          ordered.indexWhere((item) => item.estado != 'FINALIZADO');
      if (_selectedIndex < 0) _selectedIndex = ordered.length - 1;
    }
    if (_selectedIndex >= ordered.length) {
      _selectedIndex = 0;
    }

    final proceso = ordered[_selectedIndex];
    final isLocked =
        _selectedIndex > 0 &&
        ordered[_selectedIndex - 1].estado != 'FINALIZADO';
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
    final isLastStage = _selectedIndex == ordered.length - 1;

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
                  enabled:
                      index == 0 || ordered[index - 1].estado == 'FINALIZADO',
                  icon: Icon(
                    ordered[index].estado == 'FINALIZADO'
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
        if (_selectedIndex == 0) ...[
          AppMessageCard.info(
            title: 'La produccion comienza en Remojo',
            message:
                'Inicia la etapa y solicita manualmente los insumos necesarios para el proceso.',
          ),
          const Gap(AppSpacing.md),
        ],
        _ProcesoCard(
          proceso: proceso,
          isLocked: isLocked,
          planificados: stagePlanificados,
          consumos: stageConsumos,
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
        if (stagePlanificados.isNotEmpty) ...[
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
        if (stageConsumos.isNotEmpty) ...[
          const Gap(AppSpacing.lg),
          _ConsumptionSection(
            title: 'Insumos utilizados',
            helperText: '',
            isEmpty: false,
            emptyMessage: '',
            child: _ConsumoRealTable(items: stageConsumos),
          ),
        ],
        if (stageMermas.isNotEmpty) ...[
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
        if (stageDesviaciones.isNotEmpty) ...[
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
        if (isLastStage) ...[
          const Gap(AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              AppButton.secondary(
                label: 'Registrar calidad final',
                icon: Icons.verified_outlined,
                isLoading: widget.isSubmitting,
                onPressed: proceso.estado == 'FINALIZADO'
                    ? widget.onRegisterQuality
                    : null,
              ),
              AppButton.primary(
                label: 'Generar producto terminado',
                icon: Icons.inventory_2_outlined,
                isLoading: widget.isSubmitting,
                onPressed: proceso.estado == 'FINALIZADO' && widget.hasQuality
                    ? widget.onFinalizeOrder
                    : null,
                expand: false,
              ),
            ],
          ),
          if (widget.controlCalidad != null) ...[
            const Gap(AppSpacing.lg),
            _ConsumptionSection(
              title: 'Calidad final',
              helperText: 'Evaluacion registrada para cerrar la orden.',
              isEmpty: false,
              emptyMessage: '',
              child: _CalidadFinalCard(item: widget.controlCalidad!),
            ),
          ],
          if (widget.productoTerminado != null) ...[
            const Gap(AppSpacing.lg),
            _ConsumptionSection(
              title: 'Producto terminado',
              helperText: 'Resultado generado al finalizar la orden.',
              isEmpty: false,
              emptyMessage: '',
              child: _ProductoTerminadoCard(item: widget.productoTerminado!),
            ),
          ],
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
                '${item.procesoNombre} · ${item.insumoCodigo}',
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
              _InlineInfo(
                label: 'Registrado',
                value: _formatDateTime(item.creadoEn),
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
            DataColumn(label: Text('Registrado')),
          ],
          rows: items
              .map(
                (item) => DataRow(
                  cells: [
                    DataCell(Text(item.insumoNombre)),
                    DataCell(Text(_formatDecimal(item.cantidadConsumida))),
                    DataCell(Text(_formatCurrency(item.costoUnitario))),
                    DataCell(Text(_formatCurrency(item.costoTotal))),
                    DataCell(Text(_formatDateTime(item.creadoEn))),
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
                '${item.procesoNombre} · ${item.insumoCodigo}',
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
              _InlineInfo(
                label: 'Registrado',
                value: _formatDateTime(item.registradoEn),
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
                '${item.procesoNombre} · ${item.procesoCodigo}',
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
              _InlineInfo(
                label: 'Registrado',
                value: _formatDateTime(item.registradoEn),
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

class _CalidadFinalCard extends StatelessWidget {
  const _CalidadFinalCard({required this.item});

  final ControlCalidadRecord item;

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
                '${item.calidadNombre} · ${item.calidadCodigo}',
                style: theme.textTheme.titleMedium,
              ),
              _MiniPill(
                label: item.resultado,
                background: item.resultado == 'APROBADO'
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.errorContainer,
                foreground: item.resultado == 'APROBADO'
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onErrorContainer,
              ),
            ],
          ),
          const Gap(AppSpacing.md),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.md,
            children: [
              _InlineInfo(
                label: 'Evaluado por',
                value: item.evaluadoPorNombre ?? 'Sin dato',
              ),
              _InlineInfo(
                label: 'Fecha',
                value: _formatDateTime(item.evaluadoEn),
              ),
              _InlineInfo(
                label: 'Producto terminado',
                value:
                    item.productoTerminadoId?.toString() ?? 'Aun no generado',
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

class _ProductoTerminadoCard extends StatelessWidget {
  const _ProductoTerminadoCard({required this.item});

  final ProductoTerminadoRecord item;

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
              Text(item.codigo, style: theme.textTheme.titleMedium),
              _MiniPill(
                label: item.estado,
                background: theme.colorScheme.primaryContainer,
                foreground: theme.colorScheme.onPrimaryContainer,
              ),
            ],
          ),
          const Gap(AppSpacing.sm),
          Text(
            '${item.calidadNombre} · ${item.calidadCodigo}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const Gap(AppSpacing.md),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.md,
            children: [
              _InlineInfo(label: 'Orden', value: item.ordenCodigo),
              _InlineInfo(
                label: 'Lados registrados',
                value: _formatDecimal(item.cantidadLadosCalculada),
              ),
              _InlineInfo(label: 'Unidad', value: 'Lado'),
              _InlineInfo(
                label: 'Fecha ingreso',
                value: _formatDateTime(item.fechaIngreso),
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

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 270,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const Gap(AppSpacing.md),
          for (final line in lines) ...[
            Text(line, style: theme.textTheme.bodyMedium),
            const Gap(AppSpacing.sm),
          ],
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
      (word) => word.isEmpty
          ? word
          : '${word[0].toUpperCase()}${word.substring(1)}',
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

