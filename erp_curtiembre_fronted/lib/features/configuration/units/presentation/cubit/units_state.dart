import 'package:equatable/equatable.dart';
import 'package:erp_curtiembre_fronted/features/configuration/units/domain/entities/unit_record.dart';

enum UnitsStatus {
  loading,
  success,
  error,
}

enum UnitActivityFilter {
  active,
  inactive,
  all,
}

enum UnitDecimalFilter {
  all,
  decimals,
  integers,
}

class UnitsState extends Equatable {
  static const Object _sentinel = Object();

  const UnitsState({
    required this.status,
    this.items = const [],
    this.selectedUnitId,
    this.selectedUnit,
    this.errorMessage,
    this.detailErrorMessage,
    this.isDetailLoading = false,
    this.isSubmittingAction = false,
    this.searchTerm = '',
    this.activityFilter = UnitActivityFilter.active,
    this.decimalFilter = UnitDecimalFilter.all,
  });

  const UnitsState.loading() : this(status: UnitsStatus.loading);

  final UnitsStatus status;
  final List<UnitRecord> items;
  final int? selectedUnitId;
  final UnitRecord? selectedUnit;
  final String? errorMessage;
  final String? detailErrorMessage;
  final bool isDetailLoading;
  final bool isSubmittingAction;
  final String searchTerm;
  final UnitActivityFilter activityFilter;
  final UnitDecimalFilter decimalFilter;

  UnitsState copyWith({
    UnitsStatus? status,
    List<UnitRecord>? items,
    Object? selectedUnitId = _sentinel,
    UnitRecord? selectedUnit,
    String? errorMessage,
    String? detailErrorMessage,
    bool? isDetailLoading,
    bool? isSubmittingAction,
    String? searchTerm,
    UnitActivityFilter? activityFilter,
    UnitDecimalFilter? decimalFilter,
    bool clearError = false,
    bool clearDetailError = false,
    bool clearSelectedUnit = false,
  }) {
    return UnitsState(
      status: status ?? this.status,
      items: items ?? this.items,
      selectedUnitId: identical(selectedUnitId, _sentinel)
          ? this.selectedUnitId
          : selectedUnitId as int?,
      selectedUnit: clearSelectedUnit ? null : selectedUnit ?? this.selectedUnit,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      detailErrorMessage:
          clearDetailError ? null : detailErrorMessage ?? this.detailErrorMessage,
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
      isSubmittingAction: isSubmittingAction ?? this.isSubmittingAction,
      searchTerm: searchTerm ?? this.searchTerm,
      activityFilter: activityFilter ?? this.activityFilter,
      decimalFilter: decimalFilter ?? this.decimalFilter,
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        selectedUnitId,
        selectedUnit,
        errorMessage,
        detailErrorMessage,
        isDetailLoading,
        isSubmittingAction,
        searchTerm,
        activityFilter,
        decimalFilter,
      ];
}
