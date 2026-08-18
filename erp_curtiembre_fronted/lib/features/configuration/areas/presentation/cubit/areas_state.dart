import 'package:equatable/equatable.dart';
import 'package:erp_curtiembre_fronted/features/configuration/areas/domain/entities/area_record.dart';

enum AreasStatus {
  loading,
  success,
  error,
}

enum AreaActivityFilter {
  active,
  inactive,
  all,
}

class AreasState extends Equatable {
  static const Object _sentinel = Object();

  const AreasState({
    required this.status,
    this.items = const [],
    this.selectedAreaId,
    this.selectedArea,
    this.errorMessage,
    this.detailErrorMessage,
    this.isDetailLoading = false,
    this.isSubmittingAction = false,
    this.searchTerm = '',
    this.filter = AreaActivityFilter.active,
  });

  const AreasState.loading() : this(status: AreasStatus.loading);

  final AreasStatus status;
  final List<AreaRecord> items;
  final int? selectedAreaId;
  final AreaRecord? selectedArea;
  final String? errorMessage;
  final String? detailErrorMessage;
  final bool isDetailLoading;
  final bool isSubmittingAction;
  final String searchTerm;
  final AreaActivityFilter filter;

  AreasState copyWith({
    AreasStatus? status,
    List<AreaRecord>? items,
    Object? selectedAreaId = _sentinel,
    AreaRecord? selectedArea,
    String? errorMessage,
    String? detailErrorMessage,
    bool? isDetailLoading,
    bool? isSubmittingAction,
    String? searchTerm,
    AreaActivityFilter? filter,
    bool clearError = false,
    bool clearDetailError = false,
    bool clearSelectedArea = false,
  }) {
    return AreasState(
      status: status ?? this.status,
      items: items ?? this.items,
      selectedAreaId: identical(selectedAreaId, _sentinel)
          ? this.selectedAreaId
          : selectedAreaId as int?,
      selectedArea: clearSelectedArea ? null : selectedArea ?? this.selectedArea,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      detailErrorMessage:
          clearDetailError ? null : detailErrorMessage ?? this.detailErrorMessage,
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
      isSubmittingAction: isSubmittingAction ?? this.isSubmittingAction,
      searchTerm: searchTerm ?? this.searchTerm,
      filter: filter ?? this.filter,
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        selectedAreaId,
        selectedArea,
        errorMessage,
        detailErrorMessage,
        isDetailLoading,
        isSubmittingAction,
        searchTerm,
        filter,
      ];
}
