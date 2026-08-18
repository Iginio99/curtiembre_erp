import 'package:equatable/equatable.dart';
import 'package:erp_curtiembre_fronted/features/inventory/compras/domain/entities/orden_compra_detail.dart';
import 'package:erp_curtiembre_fronted/features/inventory/compras/domain/entities/orden_compra_record.dart';
import 'package:erp_curtiembre_fronted/features/inventory/entradas/domain/entities/entrada_inventario_detail.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/domain/entities/insumo_lookup.dart';

enum EntradasStatus {
  loading,
  success,
  error,
}

class EntradasState extends Equatable {
  const EntradasState({
    required this.status,
    this.insumos = const [],
    this.receivableOrders = const [],
    this.selectedReceivableOrderId,
    this.selectedReceivableOrder,
    this.lastEntry,
    this.errorMessage,
    this.orderDetailErrorMessage,
    this.isOrderDetailLoading = false,
    this.isSubmittingAction = false,
  });

  const EntradasState.loading() : this(status: EntradasStatus.loading);

  final EntradasStatus status;
  final List<InsumoLookup> insumos;
  final List<OrdenCompraRecord> receivableOrders;
  final int? selectedReceivableOrderId;
  final OrdenCompraDetail? selectedReceivableOrder;
  final EntradaInventarioDetail? lastEntry;
  final String? errorMessage;
  final String? orderDetailErrorMessage;
  final bool isOrderDetailLoading;
  final bool isSubmittingAction;

  EntradasState copyWith({
    EntradasStatus? status,
    List<InsumoLookup>? insumos,
    List<OrdenCompraRecord>? receivableOrders,
    int? selectedReceivableOrderId,
    OrdenCompraDetail? selectedReceivableOrder,
    EntradaInventarioDetail? lastEntry,
    String? errorMessage,
    String? orderDetailErrorMessage,
    bool? isOrderDetailLoading,
    bool? isSubmittingAction,
    bool clearError = false,
    bool clearOrderDetailError = false,
    bool clearSelectedOrder = false,
    bool clearLastEntry = false,
  }) {
    return EntradasState(
      status: status ?? this.status,
      insumos: insumos ?? this.insumos,
      receivableOrders: receivableOrders ?? this.receivableOrders,
      selectedReceivableOrderId:
          selectedReceivableOrderId ?? this.selectedReceivableOrderId,
      selectedReceivableOrder:
          clearSelectedOrder ? null : selectedReceivableOrder ?? this.selectedReceivableOrder,
      lastEntry: clearLastEntry ? null : lastEntry ?? this.lastEntry,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      orderDetailErrorMessage: clearOrderDetailError
          ? null
          : orderDetailErrorMessage ?? this.orderDetailErrorMessage,
      isOrderDetailLoading: isOrderDetailLoading ?? this.isOrderDetailLoading,
      isSubmittingAction: isSubmittingAction ?? this.isSubmittingAction,
    );
  }

  @override
  List<Object?> get props => [
        status,
        insumos,
        receivableOrders,
        selectedReceivableOrderId,
        selectedReceivableOrder,
        lastEntry,
        errorMessage,
        orderDetailErrorMessage,
        isOrderDetailLoading,
        isSubmittingAction,
      ];
}
