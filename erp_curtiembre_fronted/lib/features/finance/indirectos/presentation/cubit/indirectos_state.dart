import 'package:equatable/equatable.dart';
import 'package:erp_curtiembre_fronted/features/finance/indirectos/domain/entities/costo_indirecto_record.dart';
import 'package:erp_curtiembre_fronted/features/finance/periodos/domain/entities/periodo_costo_record.dart';

class IndirectosState extends Equatable {
  static const Object _sentinel = Object();

  const IndirectosState({
    required this.status,
    this.items = const [],
    this.periodoOptions = const [],
    this.selectedIndirectoId,
    this.selectedIndirecto,
    this.errorMessage,
    this.detailErrorMessage,
    this.isDetailLoading = false,
    this.isSubmittingAction = false,
    this.periodoCostoIdFilter,
    this.tipoCostoFilter,
    this.searchTerm = '',
  });

  const IndirectosState.loading() : this(status: IndirectosStatus.loading);

  final IndirectosStatus status;
  final List<CostoIndirectoRecord> items;
  final List<PeriodoCostoRecord> periodoOptions;
  final int? selectedIndirectoId;
  final CostoIndirectoRecord? selectedIndirecto;
  final String? errorMessage;
  final String? detailErrorMessage;
  final bool isDetailLoading;
  final bool isSubmittingAction;
  final int? periodoCostoIdFilter;
  final String? tipoCostoFilter;
  final String searchTerm;

  List<String> get availableTypes {
    final types = <String>{};
    for (final item in items) {
      types.add(item.tipoCosto);
    }
    final values = types.toList(growable: false)..sort();
    return values;
  }

  IndirectosState copyWith({
    IndirectosStatus? status,
    List<CostoIndirectoRecord>? items,
    List<PeriodoCostoRecord>? periodoOptions,
    Object? selectedIndirectoId = _sentinel,
    CostoIndirectoRecord? selectedIndirecto,
    String? errorMessage,
    String? detailErrorMessage,
    bool? isDetailLoading,
    bool? isSubmittingAction,
    Object? periodoCostoIdFilter = _sentinel,
    Object? tipoCostoFilter = _sentinel,
    String? searchTerm,
    bool clearError = false,
    bool clearDetailError = false,
    bool clearSelectedIndirecto = false,
  }) {
    return IndirectosState(
      status: status ?? this.status,
      items: items ?? this.items,
      periodoOptions: periodoOptions ?? this.periodoOptions,
      selectedIndirectoId: identical(selectedIndirectoId, _sentinel)
          ? this.selectedIndirectoId
          : selectedIndirectoId as int?,
      selectedIndirecto:
          clearSelectedIndirecto ? null : selectedIndirecto ?? this.selectedIndirecto,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      detailErrorMessage:
          clearDetailError ? null : detailErrorMessage ?? this.detailErrorMessage,
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
      isSubmittingAction: isSubmittingAction ?? this.isSubmittingAction,
      periodoCostoIdFilter: identical(periodoCostoIdFilter, _sentinel)
          ? this.periodoCostoIdFilter
          : periodoCostoIdFilter as int?,
      tipoCostoFilter: identical(tipoCostoFilter, _sentinel)
          ? this.tipoCostoFilter
          : tipoCostoFilter as String?,
      searchTerm: searchTerm ?? this.searchTerm,
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        periodoOptions,
        selectedIndirectoId,
        selectedIndirecto,
        errorMessage,
        detailErrorMessage,
        isDetailLoading,
        isSubmittingAction,
        periodoCostoIdFilter,
        tipoCostoFilter,
        searchTerm,
      ];
}

enum IndirectosStatus { loading, success, error }
