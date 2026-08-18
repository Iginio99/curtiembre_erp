import 'package:equatable/equatable.dart';
import 'package:erp_curtiembre_fronted/features/finance/costos/domain/entities/costo_orden_record.dart';
import 'package:erp_curtiembre_fronted/features/finance/periodos/domain/entities/periodo_costo_record.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/orden_produccion_record.dart';

enum CostosOrdenStatus { loading, success, error }

class CostosOrdenState extends Equatable {
  static const Object _sentinel = Object();

  const CostosOrdenState({
    required this.status,
    this.items = const [],
    this.ordenOptions = const [],
    this.periodoOptions = const [],
    this.selectedCostoOrdenId,
    this.selectedCostoOrden,
    this.errorMessage,
    this.detailErrorMessage,
    this.isDetailLoading = false,
    this.isSubmittingAction = false,
    this.ordenProduccionIdFilter,
    this.periodoCostoIdFilter,
    this.estadoFilter,
  });

  const CostosOrdenState.loading() : this(status: CostosOrdenStatus.loading);

  final CostosOrdenStatus status;
  final List<CostoOrdenRecord> items;
  final List<OrdenProduccionRecord> ordenOptions;
  final List<PeriodoCostoRecord> periodoOptions;
  final int? selectedCostoOrdenId;
  final CostoOrdenRecord? selectedCostoOrden;
  final String? errorMessage;
  final String? detailErrorMessage;
  final bool isDetailLoading;
  final bool isSubmittingAction;
  final int? ordenProduccionIdFilter;
  final int? periodoCostoIdFilter;
  final String? estadoFilter;

  CostosOrdenState copyWith({
    CostosOrdenStatus? status,
    List<CostoOrdenRecord>? items,
    List<OrdenProduccionRecord>? ordenOptions,
    List<PeriodoCostoRecord>? periodoOptions,
    Object? selectedCostoOrdenId = _sentinel,
    CostoOrdenRecord? selectedCostoOrden,
    String? errorMessage,
    String? detailErrorMessage,
    bool? isDetailLoading,
    bool? isSubmittingAction,
    Object? ordenProduccionIdFilter = _sentinel,
    Object? periodoCostoIdFilter = _sentinel,
    Object? estadoFilter = _sentinel,
    bool clearError = false,
    bool clearDetailError = false,
    bool clearSelectedCostoOrden = false,
  }) {
    return CostosOrdenState(
      status: status ?? this.status,
      items: items ?? this.items,
      ordenOptions: ordenOptions ?? this.ordenOptions,
      periodoOptions: periodoOptions ?? this.periodoOptions,
      selectedCostoOrdenId: identical(selectedCostoOrdenId, _sentinel)
          ? this.selectedCostoOrdenId
          : selectedCostoOrdenId as int?,
      selectedCostoOrden:
          clearSelectedCostoOrden ? null : selectedCostoOrden ?? this.selectedCostoOrden,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      detailErrorMessage:
          clearDetailError ? null : detailErrorMessage ?? this.detailErrorMessage,
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
      isSubmittingAction: isSubmittingAction ?? this.isSubmittingAction,
      ordenProduccionIdFilter: identical(ordenProduccionIdFilter, _sentinel)
          ? this.ordenProduccionIdFilter
          : ordenProduccionIdFilter as int?,
      periodoCostoIdFilter: identical(periodoCostoIdFilter, _sentinel)
          ? this.periodoCostoIdFilter
          : periodoCostoIdFilter as int?,
      estadoFilter: identical(estadoFilter, _sentinel)
          ? this.estadoFilter
          : estadoFilter as String?,
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        ordenOptions,
        periodoOptions,
        selectedCostoOrdenId,
        selectedCostoOrden,
        errorMessage,
        detailErrorMessage,
        isDetailLoading,
        isSubmittingAction,
        ordenProduccionIdFilter,
        periodoCostoIdFilter,
        estadoFilter,
      ];
}

