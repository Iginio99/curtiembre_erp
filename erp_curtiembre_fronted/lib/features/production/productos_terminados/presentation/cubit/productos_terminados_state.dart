import 'package:equatable/equatable.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/producto_terminado_record.dart';

enum ProductosTerminadosStatus { loading, success, error }

class ProductosTerminadosState extends Equatable {
  const ProductosTerminadosState({
    required this.status,
    this.items = const [],
    this.filteredItems = const [],
    this.selectedItem,
    this.searchTerm = '',
    this.errorMessage,
  });

  const ProductosTerminadosState.loading()
      : this(status: ProductosTerminadosStatus.loading);

  final ProductosTerminadosStatus status;
  final List<ProductoTerminadoRecord> items;
  final List<ProductoTerminadoRecord> filteredItems;
  final ProductoTerminadoRecord? selectedItem;
  final String searchTerm;
  final String? errorMessage;

  ProductosTerminadosState copyWith({
    ProductosTerminadosStatus? status,
    List<ProductoTerminadoRecord>? items,
    List<ProductoTerminadoRecord>? filteredItems,
    ProductoTerminadoRecord? selectedItem,
    String? searchTerm,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProductosTerminadosState(
      status: status ?? this.status,
      items: items ?? this.items,
      filteredItems: filteredItems ?? this.filteredItems,
      selectedItem: selectedItem ?? this.selectedItem,
      searchTerm: searchTerm ?? this.searchTerm,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        filteredItems,
        selectedItem,
        searchTerm,
        errorMessage,
      ];
}
