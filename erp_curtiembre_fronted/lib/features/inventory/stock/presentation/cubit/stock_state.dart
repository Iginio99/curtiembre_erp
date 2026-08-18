import 'package:equatable/equatable.dart';
import 'package:erp_curtiembre_fronted/features/inventory/stock/domain/entities/stock_record.dart';

enum StockStatus {
  loading,
  success,
  error,
}

enum StockActivityFilter {
  active,
  inactive,
  all,
}

class StockState extends Equatable {
  static const Object _sentinel = Object();

  const StockState({
    required this.status,
    this.items = const [],
    this.selectedInsumoId,
    this.selectedStock,
    this.errorMessage,
    this.detailErrorMessage,
    this.isDetailLoading = false,
    this.searchTerm = '',
    this.activityFilter = StockActivityFilter.active,
    this.lowStockOnly = false,
    this.tipoBienFilter,
  });

  const StockState.loading() : this(status: StockStatus.loading);

  final StockStatus status;
  final List<StockRecord> items;
  final int? selectedInsumoId;
  final StockRecord? selectedStock;
  final String? errorMessage;
  final String? detailErrorMessage;
  final bool isDetailLoading;
  final String searchTerm;
  final StockActivityFilter activityFilter;
  final bool lowStockOnly;
  final String? tipoBienFilter;

  StockState copyWith({
    StockStatus? status,
    List<StockRecord>? items,
    Object? selectedInsumoId = _sentinel,
    StockRecord? selectedStock,
    String? errorMessage,
    String? detailErrorMessage,
    bool? isDetailLoading,
    String? searchTerm,
    StockActivityFilter? activityFilter,
    bool? lowStockOnly,
    Object? tipoBienFilter = _sentinel,
    bool clearError = false,
    bool clearDetailError = false,
    bool clearSelectedStock = false,
  }) {
    return StockState(
      status: status ?? this.status,
      items: items ?? this.items,
      selectedInsumoId: identical(selectedInsumoId, _sentinel)
          ? this.selectedInsumoId
          : selectedInsumoId as int?,
      selectedStock: clearSelectedStock ? null : selectedStock ?? this.selectedStock,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      detailErrorMessage:
          clearDetailError ? null : detailErrorMessage ?? this.detailErrorMessage,
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
      searchTerm: searchTerm ?? this.searchTerm,
      activityFilter: activityFilter ?? this.activityFilter,
      lowStockOnly: lowStockOnly ?? this.lowStockOnly,
      tipoBienFilter: identical(tipoBienFilter, _sentinel)
          ? this.tipoBienFilter
          : tipoBienFilter as String?,
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        selectedInsumoId,
        selectedStock,
        errorMessage,
        detailErrorMessage,
        isDetailLoading,
        searchTerm,
        activityFilter,
        lowStockOnly,
        tipoBienFilter,
      ];
}
