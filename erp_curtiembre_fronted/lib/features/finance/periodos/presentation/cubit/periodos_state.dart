import 'package:equatable/equatable.dart';
import 'package:erp_curtiembre_fronted/features/finance/periodos/domain/entities/periodo_costo_record.dart';

enum PeriodosStatus { loading, success, error }

class PeriodosState extends Equatable {
  static const Object _sentinel = Object();

  const PeriodosState({
    required this.status,
    this.items = const [],
    this.selectedPeriodoId,
    this.selectedPeriodo,
    this.errorMessage,
    this.detailErrorMessage,
    this.isDetailLoading = false,
    this.isSubmittingAction = false,
    this.anioFilter,
    this.mesFilter,
    this.estadoFilter,
  });

  const PeriodosState.loading() : this(status: PeriodosStatus.loading);

  final PeriodosStatus status;
  final List<PeriodoCostoRecord> items;
  final int? selectedPeriodoId;
  final PeriodoCostoRecord? selectedPeriodo;
  final String? errorMessage;
  final String? detailErrorMessage;
  final bool isDetailLoading;
  final bool isSubmittingAction;
  final int? anioFilter;
  final int? mesFilter;
  final String? estadoFilter;

  PeriodosState copyWith({
    PeriodosStatus? status,
    List<PeriodoCostoRecord>? items,
    Object? selectedPeriodoId = _sentinel,
    PeriodoCostoRecord? selectedPeriodo,
    String? errorMessage,
    String? detailErrorMessage,
    bool? isDetailLoading,
    bool? isSubmittingAction,
    Object? anioFilter = _sentinel,
    Object? mesFilter = _sentinel,
    Object? estadoFilter = _sentinel,
    bool clearError = false,
    bool clearDetailError = false,
    bool clearSelectedPeriodo = false,
  }) {
    return PeriodosState(
      status: status ?? this.status,
      items: items ?? this.items,
      selectedPeriodoId: identical(selectedPeriodoId, _sentinel)
          ? this.selectedPeriodoId
          : selectedPeriodoId as int?,
      selectedPeriodo:
          clearSelectedPeriodo ? null : selectedPeriodo ?? this.selectedPeriodo,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      detailErrorMessage:
          clearDetailError ? null : detailErrorMessage ?? this.detailErrorMessage,
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
      isSubmittingAction: isSubmittingAction ?? this.isSubmittingAction,
      anioFilter:
          identical(anioFilter, _sentinel) ? this.anioFilter : anioFilter as int?,
      mesFilter: identical(mesFilter, _sentinel) ? this.mesFilter : mesFilter as int?,
      estadoFilter: identical(estadoFilter, _sentinel)
          ? this.estadoFilter
          : estadoFilter as String?,
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        selectedPeriodoId,
        selectedPeriodo,
        errorMessage,
        detailErrorMessage,
        isDetailLoading,
        isSubmittingAction,
        anioFilter,
        mesFilter,
        estadoFilter,
      ];
}
