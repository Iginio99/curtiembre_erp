import 'package:equatable/equatable.dart';
import 'package:erp_curtiembre_fronted/features/inventory/insumos/domain/entities/insumo_record.dart';
import 'package:erp_curtiembre_fronted/features/inventory/insumos/domain/entities/unidad_medida_option.dart';

enum InsumosStatus {
  loading,
  success,
  error,
}

enum InsumoActivityFilter {
  active,
  inactive,
  all,
}

class InsumosState extends Equatable {
  static const Object _sentinel = Object();

  const InsumosState({
    required this.status,
    this.items = const [],
    this.unitOptions = const [],
    this.selectedInsumoId,
    this.selectedInsumo,
    this.errorMessage,
    this.detailErrorMessage,
    this.isDetailLoading = false,
    this.isSubmittingAction = false,
    this.searchTerm = '',
    this.activityFilter = InsumoActivityFilter.active,
    this.stockBajoOnly = false,
    this.tipoBienFilter,
  });

  const InsumosState.loading() : this(status: InsumosStatus.loading);

  final InsumosStatus status;
  final List<InsumoRecord> items;
  final List<UnidadMedidaOption> unitOptions;
  final int? selectedInsumoId;
  final InsumoRecord? selectedInsumo;
  final String? errorMessage;
  final String? detailErrorMessage;
  final bool isDetailLoading;
  final bool isSubmittingAction;
  final String searchTerm;
  final InsumoActivityFilter activityFilter;
  final bool stockBajoOnly;
  final String? tipoBienFilter;

  InsumosState copyWith({
    InsumosStatus? status,
    List<InsumoRecord>? items,
    List<UnidadMedidaOption>? unitOptions,
    Object? selectedInsumoId = _sentinel,
    InsumoRecord? selectedInsumo,
    String? errorMessage,
    String? detailErrorMessage,
    bool? isDetailLoading,
    bool? isSubmittingAction,
    String? searchTerm,
    InsumoActivityFilter? activityFilter,
    bool? stockBajoOnly,
    Object? tipoBienFilter = _sentinel,
    bool clearError = false,
    bool clearDetailError = false,
    bool clearSelectedInsumo = false,
  }) {
    return InsumosState(
      status: status ?? this.status,
      items: items ?? this.items,
      unitOptions: unitOptions ?? this.unitOptions,
      selectedInsumoId: identical(selectedInsumoId, _sentinel)
          ? this.selectedInsumoId
          : selectedInsumoId as int?,
      selectedInsumo: clearSelectedInsumo ? null : selectedInsumo ?? this.selectedInsumo,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      detailErrorMessage:
          clearDetailError ? null : detailErrorMessage ?? this.detailErrorMessage,
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
      isSubmittingAction: isSubmittingAction ?? this.isSubmittingAction,
      searchTerm: searchTerm ?? this.searchTerm,
      activityFilter: activityFilter ?? this.activityFilter,
      stockBajoOnly: stockBajoOnly ?? this.stockBajoOnly,
      tipoBienFilter: identical(tipoBienFilter, _sentinel)
          ? this.tipoBienFilter
          : tipoBienFilter as String?,
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        unitOptions,
        selectedInsumoId,
        selectedInsumo,
        errorMessage,
        detailErrorMessage,
        isDetailLoading,
        isSubmittingAction,
        searchTerm,
        activityFilter,
        stockBajoOnly,
        tipoBienFilter,
      ];
}
