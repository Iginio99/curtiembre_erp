import 'package:equatable/equatable.dart';
import 'package:erp_curtiembre_fronted/features/configuration/skin_types/domain/entities/skin_type_record.dart';

enum SkinTypesStatus {
  loading,
  success,
  error,
}

enum SkinTypeActivityFilter {
  active,
  inactive,
  all,
}

class SkinTypesState extends Equatable {
  static const Object _sentinel = Object();

  const SkinTypesState({
    required this.status,
    this.items = const [],
    this.selectedSkinTypeId,
    this.selectedSkinType,
    this.errorMessage,
    this.detailErrorMessage,
    this.isDetailLoading = false,
    this.isSubmittingAction = false,
    this.searchTerm = '',
    this.filter = SkinTypeActivityFilter.active,
  });

  const SkinTypesState.loading() : this(status: SkinTypesStatus.loading);

  final SkinTypesStatus status;
  final List<SkinTypeRecord> items;
  final int? selectedSkinTypeId;
  final SkinTypeRecord? selectedSkinType;
  final String? errorMessage;
  final String? detailErrorMessage;
  final bool isDetailLoading;
  final bool isSubmittingAction;
  final String searchTerm;
  final SkinTypeActivityFilter filter;

  SkinTypesState copyWith({
    SkinTypesStatus? status,
    List<SkinTypeRecord>? items,
    Object? selectedSkinTypeId = _sentinel,
    SkinTypeRecord? selectedSkinType,
    String? errorMessage,
    String? detailErrorMessage,
    bool? isDetailLoading,
    bool? isSubmittingAction,
    String? searchTerm,
    SkinTypeActivityFilter? filter,
    bool clearError = false,
    bool clearDetailError = false,
    bool clearSelectedSkinType = false,
  }) {
    return SkinTypesState(
      status: status ?? this.status,
      items: items ?? this.items,
      selectedSkinTypeId: identical(selectedSkinTypeId, _sentinel)
          ? this.selectedSkinTypeId
          : selectedSkinTypeId as int?,
      selectedSkinType: clearSelectedSkinType
          ? null
          : selectedSkinType ?? this.selectedSkinType,
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
        selectedSkinTypeId,
        selectedSkinType,
        errorMessage,
        detailErrorMessage,
        isDetailLoading,
        isSubmittingAction,
        searchTerm,
        filter,
      ];
}
