import 'package:equatable/equatable.dart';
import 'package:erp_curtiembre_fronted/features/inventory/proveedores/domain/entities/proveedor_record.dart';

enum ProveedoresStatus {
  loading,
  success,
  error,
}

enum ProveedorActivityFilter {
  active,
  inactive,
  all,
}

class ProveedoresState extends Equatable {
  static const Object _sentinel = Object();

  const ProveedoresState({
    required this.status,
    this.items = const [],
    this.selectedProveedorId,
    this.selectedProveedor,
    this.errorMessage,
    this.detailErrorMessage,
    this.isDetailLoading = false,
    this.isSubmittingAction = false,
    this.searchTerm = '',
    this.filter = ProveedorActivityFilter.active,
  });

  const ProveedoresState.loading() : this(status: ProveedoresStatus.loading);

  final ProveedoresStatus status;
  final List<ProveedorRecord> items;
  final int? selectedProveedorId;
  final ProveedorRecord? selectedProveedor;
  final String? errorMessage;
  final String? detailErrorMessage;
  final bool isDetailLoading;
  final bool isSubmittingAction;
  final String searchTerm;
  final ProveedorActivityFilter filter;

  ProveedoresState copyWith({
    ProveedoresStatus? status,
    List<ProveedorRecord>? items,
    Object? selectedProveedorId = _sentinel,
    ProveedorRecord? selectedProveedor,
    String? errorMessage,
    String? detailErrorMessage,
    bool? isDetailLoading,
    bool? isSubmittingAction,
    String? searchTerm,
    ProveedorActivityFilter? filter,
    bool clearError = false,
    bool clearDetailError = false,
    bool clearSelectedProveedor = false,
  }) {
    return ProveedoresState(
      status: status ?? this.status,
      items: items ?? this.items,
      selectedProveedorId: identical(selectedProveedorId, _sentinel)
          ? this.selectedProveedorId
          : selectedProveedorId as int?,
      selectedProveedor:
          clearSelectedProveedor ? null : selectedProveedor ?? this.selectedProveedor,
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
        selectedProveedorId,
        selectedProveedor,
        errorMessage,
        detailErrorMessage,
        isDetailLoading,
        isSubmittingAction,
        searchTerm,
        filter,
      ];
}
