import 'package:equatable/equatable.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/domain/entities/insumo_lookup.dart';
import 'package:erp_curtiembre_fronted/features/production/clientes/domain/entities/cliente_option.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/consumo_planificado_record.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/consumo_real_record.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/control_calidad_record.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/desviacion_consumo_record.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/lote_option.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/merma_proceso_record.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/orden_proceso_record.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/orden_produccion_record.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/producto_terminado_record.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/personal_empresa_option.dart';

enum OrdenesProduccionStatus { loading, success, error }

class OrdenesProduccionState extends Equatable {
  static const Object _sentinel = Object();

  const OrdenesProduccionState({
    required this.status,
    this.items = const [],
    this.clienteOptions = const [],
    this.loteOptions = const [],
    this.insumoOptions = const [],
    this.personalOptions = const [],
    this.selectedOrdenId,
    this.selectedOrden,
    this.selectedProcesos = const [],
    this.consumoPlanificado = const [],
    this.consumoReal = const [],
    this.desviaciones = const [],
    this.mermas = const [],
    this.controlCalidad,
    this.productoTerminado,
    this.errorMessage,
    this.detailErrorMessage,
    this.isDetailLoading = false,
    this.isSubmittingAction = false,
    this.searchTerm = '',
    this.selectedClienteId,
    this.selectedLoteId,
    this.estadoFilter,
  });

  const OrdenesProduccionState.loading()
    : this(status: OrdenesProduccionStatus.loading);

  final OrdenesProduccionStatus status;
  final List<OrdenProduccionRecord> items;
  final List<ClienteOption> clienteOptions;
  final List<LoteOption> loteOptions;
  final List<InsumoLookup> insumoOptions;
  final List<PersonalEmpresaOption> personalOptions;
  final int? selectedOrdenId;
  final OrdenProduccionRecord? selectedOrden;
  final List<OrdenProcesoRecord> selectedProcesos;
  final List<ConsumoPlanificadoRecord> consumoPlanificado;
  final List<ConsumoRealRecord> consumoReal;
  final List<DesviacionConsumoRecord> desviaciones;
  final List<MermaProcesoRecord> mermas;
  final ControlCalidadRecord? controlCalidad;
  final ProductoTerminadoRecord? productoTerminado;
  final String? errorMessage;
  final String? detailErrorMessage;
  final bool isDetailLoading;
  final bool isSubmittingAction;
  final String searchTerm;
  final int? selectedClienteId;
  final int? selectedLoteId;
  final String? estadoFilter;

  OrdenesProduccionState copyWith({
    OrdenesProduccionStatus? status,
    List<OrdenProduccionRecord>? items,
    List<ClienteOption>? clienteOptions,
    List<LoteOption>? loteOptions,
    List<InsumoLookup>? insumoOptions,
    List<PersonalEmpresaOption>? personalOptions,
    Object? selectedOrdenId = _sentinel,
    OrdenProduccionRecord? selectedOrden,
    List<OrdenProcesoRecord>? selectedProcesos,
    List<ConsumoPlanificadoRecord>? consumoPlanificado,
    List<ConsumoRealRecord>? consumoReal,
    List<DesviacionConsumoRecord>? desviaciones,
    List<MermaProcesoRecord>? mermas,
    Object? controlCalidad = _sentinel,
    Object? productoTerminado = _sentinel,
    String? errorMessage,
    String? detailErrorMessage,
    bool? isDetailLoading,
    bool? isSubmittingAction,
    String? searchTerm,
    Object? selectedClienteId = _sentinel,
    Object? selectedLoteId = _sentinel,
    Object? estadoFilter = _sentinel,
    bool clearError = false,
    bool clearDetailError = false,
    bool clearSelectedOrden = false,
    bool clearSelectedProcesos = false,
  }) {
    return OrdenesProduccionState(
      status: status ?? this.status,
      items: items ?? this.items,
      clienteOptions: clienteOptions ?? this.clienteOptions,
      loteOptions: loteOptions ?? this.loteOptions,
      insumoOptions: insumoOptions ?? this.insumoOptions,
      personalOptions: personalOptions ?? this.personalOptions,
      selectedOrdenId: identical(selectedOrdenId, _sentinel)
          ? this.selectedOrdenId
          : selectedOrdenId as int?,
      selectedOrden: clearSelectedOrden
          ? null
          : selectedOrden ?? this.selectedOrden,
      selectedProcesos: clearSelectedProcesos
          ? const []
          : selectedProcesos ?? this.selectedProcesos,
      consumoPlanificado: clearSelectedProcesos
          ? const []
          : consumoPlanificado ?? this.consumoPlanificado,
      consumoReal: clearSelectedProcesos
          ? const []
          : consumoReal ?? this.consumoReal,
      desviaciones: clearSelectedProcesos
          ? const []
          : desviaciones ?? this.desviaciones,
      mermas: clearSelectedProcesos ? const [] : mermas ?? this.mermas,
      controlCalidad: clearSelectedProcesos
          ? null
          : identical(controlCalidad, _sentinel)
          ? this.controlCalidad
          : controlCalidad as ControlCalidadRecord?,
      productoTerminado: clearSelectedProcesos
          ? null
          : identical(productoTerminado, _sentinel)
          ? this.productoTerminado
          : productoTerminado as ProductoTerminadoRecord?,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      detailErrorMessage: clearDetailError
          ? null
          : detailErrorMessage ?? this.detailErrorMessage,
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
      isSubmittingAction: isSubmittingAction ?? this.isSubmittingAction,
      searchTerm: searchTerm ?? this.searchTerm,
      selectedClienteId: identical(selectedClienteId, _sentinel)
          ? this.selectedClienteId
          : selectedClienteId as int?,
      selectedLoteId: identical(selectedLoteId, _sentinel)
          ? this.selectedLoteId
          : selectedLoteId as int?,
      estadoFilter: identical(estadoFilter, _sentinel)
          ? this.estadoFilter
          : estadoFilter as String?,
    );
  }

  @override
  List<Object?> get props => [
    status,
    items,
    clienteOptions,
    loteOptions,
    insumoOptions,
    personalOptions,
    selectedOrdenId,
    selectedOrden,
    selectedProcesos,
    consumoPlanificado,
    consumoReal,
    desviaciones,
    mermas,
    controlCalidad,
    productoTerminado,
    errorMessage,
    detailErrorMessage,
    isDetailLoading,
    isSubmittingAction,
    searchTerm,
    selectedClienteId,
    selectedLoteId,
    estadoFilter,
  ];
}
