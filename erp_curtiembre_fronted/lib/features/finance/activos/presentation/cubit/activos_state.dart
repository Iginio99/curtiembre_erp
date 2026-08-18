import 'package:equatable/equatable.dart';
import 'package:erp_curtiembre_fronted/features/finance/activos/domain/entities/activo_depreciable_record.dart';

enum ActivosStatus { loading, success, error }

enum ActivoActivityFilter { active, inactive, all }

class ActivosState extends Equatable {
  static const Object _sentinel = Object();

  const ActivosState({
    required this.status,
    this.items = const [],
    this.selectedActivoId,
    this.selectedActivo,
    this.errorMessage,
    this.detailErrorMessage,
    this.isDetailLoading = false,
    this.isSubmittingAction = false,
    this.searchTerm = '',
    this.filter = ActivoActivityFilter.all,
  });

  const ActivosState.loading() : this(status: ActivosStatus.loading);

  final ActivosStatus status;
  final List<ActivoDepreciableRecord> items;
  final int? selectedActivoId;
  final ActivoDepreciableRecord? selectedActivo;
  final String? errorMessage;
  final String? detailErrorMessage;
  final bool isDetailLoading;
  final bool isSubmittingAction;
  final String searchTerm;
  final ActivoActivityFilter filter;

  ActivosState copyWith({
    ActivosStatus? status,
    List<ActivoDepreciableRecord>? items,
    Object? selectedActivoId = _sentinel,
    ActivoDepreciableRecord? selectedActivo,
    String? errorMessage,
    String? detailErrorMessage,
    bool? isDetailLoading,
    bool? isSubmittingAction,
    String? searchTerm,
    ActivoActivityFilter? filter,
    bool clearError = false,
    bool clearDetailError = false,
    bool clearSelectedActivo = false,
  }) {
    return ActivosState(
      status: status ?? this.status,
      items: items ?? this.items,
      selectedActivoId: identical(selectedActivoId, _sentinel)
          ? this.selectedActivoId
          : selectedActivoId as int?,
      selectedActivo:
          clearSelectedActivo ? null : selectedActivo ?? this.selectedActivo,
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
        selectedActivoId,
        selectedActivo,
        errorMessage,
        detailErrorMessage,
        isDetailLoading,
        isSubmittingAction,
        searchTerm,
        filter,
      ];
}
