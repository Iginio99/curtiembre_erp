import 'package:equatable/equatable.dart';
import 'package:erp_curtiembre_fronted/features/finance/activos/domain/entities/activo_depreciable_record.dart';
import 'package:erp_curtiembre_fronted/features/finance/depreciaciones/domain/entities/depreciacion_periodo_record.dart';
import 'package:erp_curtiembre_fronted/features/finance/periodos/domain/entities/periodo_costo_record.dart';

enum DepreciacionesStatus { loading, success, error }

class DepreciacionesState extends Equatable {
  static const Object _sentinel = Object();

  const DepreciacionesState({
    required this.status,
    this.items = const [],
    this.periodoOptions = const [],
    this.activoOptions = const [],
    this.selectedDepreciacionId,
    this.selectedDepreciacion,
    this.errorMessage,
    this.detailErrorMessage,
    this.isDetailLoading = false,
    this.isSubmittingAction = false,
    this.periodoCostoIdFilter,
    this.activoDepreciableIdFilter,
  });

  const DepreciacionesState.loading() : this(status: DepreciacionesStatus.loading);

  final DepreciacionesStatus status;
  final List<DepreciacionPeriodoRecord> items;
  final List<PeriodoCostoRecord> periodoOptions;
  final List<ActivoDepreciableRecord> activoOptions;
  final int? selectedDepreciacionId;
  final DepreciacionPeriodoRecord? selectedDepreciacion;
  final String? errorMessage;
  final String? detailErrorMessage;
  final bool isDetailLoading;
  final bool isSubmittingAction;
  final int? periodoCostoIdFilter;
  final int? activoDepreciableIdFilter;

  DepreciacionesState copyWith({
    DepreciacionesStatus? status,
    List<DepreciacionPeriodoRecord>? items,
    List<PeriodoCostoRecord>? periodoOptions,
    List<ActivoDepreciableRecord>? activoOptions,
    Object? selectedDepreciacionId = _sentinel,
    DepreciacionPeriodoRecord? selectedDepreciacion,
    String? errorMessage,
    String? detailErrorMessage,
    bool? isDetailLoading,
    bool? isSubmittingAction,
    Object? periodoCostoIdFilter = _sentinel,
    Object? activoDepreciableIdFilter = _sentinel,
    bool clearError = false,
    bool clearDetailError = false,
    bool clearSelectedDepreciacion = false,
  }) {
    return DepreciacionesState(
      status: status ?? this.status,
      items: items ?? this.items,
      periodoOptions: periodoOptions ?? this.periodoOptions,
      activoOptions: activoOptions ?? this.activoOptions,
      selectedDepreciacionId: identical(selectedDepreciacionId, _sentinel)
          ? this.selectedDepreciacionId
          : selectedDepreciacionId as int?,
      selectedDepreciacion: clearSelectedDepreciacion
          ? null
          : selectedDepreciacion ?? this.selectedDepreciacion,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      detailErrorMessage:
          clearDetailError ? null : detailErrorMessage ?? this.detailErrorMessage,
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
      isSubmittingAction: isSubmittingAction ?? this.isSubmittingAction,
      periodoCostoIdFilter: identical(periodoCostoIdFilter, _sentinel)
          ? this.periodoCostoIdFilter
          : periodoCostoIdFilter as int?,
      activoDepreciableIdFilter: identical(activoDepreciableIdFilter, _sentinel)
          ? this.activoDepreciableIdFilter
          : activoDepreciableIdFilter as int?,
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        periodoOptions,
        activoOptions,
        selectedDepreciacionId,
        selectedDepreciacion,
        errorMessage,
        detailErrorMessage,
        isDetailLoading,
        isSubmittingAction,
        periodoCostoIdFilter,
        activoDepreciableIdFilter,
      ];
}
