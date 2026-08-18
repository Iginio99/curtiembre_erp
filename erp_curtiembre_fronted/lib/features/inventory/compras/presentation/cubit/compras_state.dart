import 'package:equatable/equatable.dart';
import 'package:erp_curtiembre_fronted/features/inventory/compras/domain/entities/orden_compra_detail.dart';
import 'package:erp_curtiembre_fronted/features/inventory/compras/domain/entities/orden_compra_record.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/domain/entities/insumo_lookup.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/domain/entities/proveedor_lookup.dart';

enum ComprasStatus {
  loading,
  success,
  error,
}

class ComprasState extends Equatable {
  static const Object _sentinel = Object();

  const ComprasState({
    required this.status,
    this.items = const [],
    this.proveedores = const [],
    this.insumos = const [],
    this.selectedOrderId,
    this.selectedOrder,
    this.errorMessage,
    this.detailErrorMessage,
    this.isDetailLoading = false,
    this.isSubmittingAction = false,
    this.searchTerm = '',
    this.proveedorIdFilter,
    this.estadoFilter,
  });

  const ComprasState.loading() : this(status: ComprasStatus.loading);

  final ComprasStatus status;
  final List<OrdenCompraRecord> items;
  final List<ProveedorLookup> proveedores;
  final List<InsumoLookup> insumos;
  final int? selectedOrderId;
  final OrdenCompraDetail? selectedOrder;
  final String? errorMessage;
  final String? detailErrorMessage;
  final bool isDetailLoading;
  final bool isSubmittingAction;
  final String searchTerm;
  final int? proveedorIdFilter;
  final String? estadoFilter;

  ComprasState copyWith({
    ComprasStatus? status,
    List<OrdenCompraRecord>? items,
    List<ProveedorLookup>? proveedores,
    List<InsumoLookup>? insumos,
    Object? selectedOrderId = _sentinel,
    OrdenCompraDetail? selectedOrder,
    String? errorMessage,
    String? detailErrorMessage,
    bool? isDetailLoading,
    bool? isSubmittingAction,
    String? searchTerm,
    Object? proveedorIdFilter = _sentinel,
    Object? estadoFilter = _sentinel,
    bool clearError = false,
    bool clearDetailError = false,
    bool clearSelectedOrder = false,
  }) {
    return ComprasState(
      status: status ?? this.status,
      items: items ?? this.items,
      proveedores: proveedores ?? this.proveedores,
      insumos: insumos ?? this.insumos,
      selectedOrderId: identical(selectedOrderId, _sentinel)
          ? this.selectedOrderId
          : selectedOrderId as int?,
      selectedOrder: clearSelectedOrder ? null : selectedOrder ?? this.selectedOrder,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      detailErrorMessage:
          clearDetailError ? null : detailErrorMessage ?? this.detailErrorMessage,
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
      isSubmittingAction: isSubmittingAction ?? this.isSubmittingAction,
      searchTerm: searchTerm ?? this.searchTerm,
      proveedorIdFilter: identical(proveedorIdFilter, _sentinel)
          ? this.proveedorIdFilter
          : proveedorIdFilter as int?,
      estadoFilter: identical(estadoFilter, _sentinel)
          ? this.estadoFilter
          : estadoFilter as String?,
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        proveedores,
        insumos,
        selectedOrderId,
        selectedOrder,
        errorMessage,
        detailErrorMessage,
        isDetailLoading,
        isSubmittingAction,
        searchTerm,
        proveedorIdFilter,
        estadoFilter,
      ];
}
