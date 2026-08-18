import 'package:equatable/equatable.dart';
import 'package:erp_curtiembre_fronted/features/finance/costos/domain/entities/costo_proceso_record.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/orden_proceso_record.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/orden_produccion_record.dart';

enum CostosProcesoStatus { loading, success, error }

class CostosProcesoState extends Equatable {
  static const Object _sentinel = Object();

  const CostosProcesoState({
    required this.status,
    this.items = const [],
    this.ordenOptions = const [],
    this.processOptionsByOrderId = const {},
    this.selectedCostoProcesoId,
    this.selectedCostoProceso,
    this.errorMessage,
    this.detailErrorMessage,
    this.isDetailLoading = false,
    this.isSubmittingAction = false,
    this.ordenProduccionIdFilter,
    this.ordenProcesoIdFilter,
  });

  const CostosProcesoState.loading() : this(status: CostosProcesoStatus.loading);

  final CostosProcesoStatus status;
  final List<CostoProcesoRecord> items;
  final List<OrdenProduccionRecord> ordenOptions;
  final Map<int, List<OrdenProcesoRecord>> processOptionsByOrderId;
  final int? selectedCostoProcesoId;
  final CostoProcesoRecord? selectedCostoProceso;
  final String? errorMessage;
  final String? detailErrorMessage;
  final bool isDetailLoading;
  final bool isSubmittingAction;
  final int? ordenProduccionIdFilter;
  final int? ordenProcesoIdFilter;

  CostosProcesoState copyWith({
    CostosProcesoStatus? status,
    List<CostoProcesoRecord>? items,
    List<OrdenProduccionRecord>? ordenOptions,
    Map<int, List<OrdenProcesoRecord>>? processOptionsByOrderId,
    Object? selectedCostoProcesoId = _sentinel,
    CostoProcesoRecord? selectedCostoProceso,
    String? errorMessage,
    String? detailErrorMessage,
    bool? isDetailLoading,
    bool? isSubmittingAction,
    Object? ordenProduccionIdFilter = _sentinel,
    Object? ordenProcesoIdFilter = _sentinel,
    bool clearError = false,
    bool clearDetailError = false,
    bool clearSelectedCostoProceso = false,
  }) {
    return CostosProcesoState(
      status: status ?? this.status,
      items: items ?? this.items,
      ordenOptions: ordenOptions ?? this.ordenOptions,
      processOptionsByOrderId: processOptionsByOrderId ?? this.processOptionsByOrderId,
      selectedCostoProcesoId: identical(selectedCostoProcesoId, _sentinel)
          ? this.selectedCostoProcesoId
          : selectedCostoProcesoId as int?,
      selectedCostoProceso: clearSelectedCostoProceso
          ? null
          : selectedCostoProceso ?? this.selectedCostoProceso,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      detailErrorMessage:
          clearDetailError ? null : detailErrorMessage ?? this.detailErrorMessage,
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
      isSubmittingAction: isSubmittingAction ?? this.isSubmittingAction,
      ordenProduccionIdFilter: identical(ordenProduccionIdFilter, _sentinel)
          ? this.ordenProduccionIdFilter
          : ordenProduccionIdFilter as int?,
      ordenProcesoIdFilter: identical(ordenProcesoIdFilter, _sentinel)
          ? this.ordenProcesoIdFilter
          : ordenProcesoIdFilter as int?,
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        ordenOptions,
        processOptionsByOrderId,
        selectedCostoProcesoId,
        selectedCostoProceso,
        errorMessage,
        detailErrorMessage,
        isDetailLoading,
        isSubmittingAction,
        ordenProduccionIdFilter,
        ordenProcesoIdFilter,
      ];
}

