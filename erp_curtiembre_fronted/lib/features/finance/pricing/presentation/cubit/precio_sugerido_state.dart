import 'package:equatable/equatable.dart';
import 'package:erp_curtiembre_fronted/features/finance/pricing/domain/entities/precio_sugerido_record.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/orden_produccion_record.dart';

enum PrecioSugeridoStatus { loading, success, error }

class PrecioSugeridoState extends Equatable {
  static const Object _sentinel = Object();

  const PrecioSugeridoState({
    required this.status,
    this.orderOptions = const [],
    this.selectedOrderId,
    this.selectedOrder,
    this.detail,
    this.errorMessage,
    this.detailErrorMessage,
    this.isDetailLoading = false,
    this.isSubmittingAction = false,
  });

  const PrecioSugeridoState.loading() : this(status: PrecioSugeridoStatus.loading);

  final PrecioSugeridoStatus status;
  final List<OrdenProduccionRecord> orderOptions;
  final int? selectedOrderId;
  final OrdenProduccionRecord? selectedOrder;
  final PrecioSugeridoRecord? detail;
  final String? errorMessage;
  final String? detailErrorMessage;
  final bool isDetailLoading;
  final bool isSubmittingAction;

  PrecioSugeridoState copyWith({
    PrecioSugeridoStatus? status,
    List<OrdenProduccionRecord>? orderOptions,
    Object? selectedOrderId = _sentinel,
    Object? selectedOrder = _sentinel,
    Object? detail = _sentinel,
    String? errorMessage,
    String? detailErrorMessage,
    bool? isDetailLoading,
    bool? isSubmittingAction,
    bool clearError = false,
    bool clearDetailError = false,
  }) {
    return PrecioSugeridoState(
      status: status ?? this.status,
      orderOptions: orderOptions ?? this.orderOptions,
      selectedOrderId: identical(selectedOrderId, _sentinel)
          ? this.selectedOrderId
          : selectedOrderId as int?,
      selectedOrder: identical(selectedOrder, _sentinel)
          ? this.selectedOrder
          : selectedOrder as OrdenProduccionRecord?,
      detail: identical(detail, _sentinel) ? this.detail : detail as PrecioSugeridoRecord?,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      detailErrorMessage:
          clearDetailError ? null : detailErrorMessage ?? this.detailErrorMessage,
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
      isSubmittingAction: isSubmittingAction ?? this.isSubmittingAction,
    );
  }

  @override
  List<Object?> get props => [
        status,
        orderOptions,
        selectedOrderId,
        selectedOrder,
        detail,
        errorMessage,
        detailErrorMessage,
        isDetailLoading,
        isSubmittingAction,
      ];
}

