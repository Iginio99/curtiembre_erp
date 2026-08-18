import 'package:equatable/equatable.dart';
import 'package:erp_curtiembre_fronted/features/production/clientes/domain/entities/cliente_record.dart';

enum ClientesStatus {
  loading,
  success,
  error,
}

enum ClienteActivityFilter {
  active,
  inactive,
  all,
}

class ClientesState extends Equatable {
  static const Object _sentinel = Object();

  const ClientesState({
    required this.status,
    this.items = const [],
    this.selectedClienteId,
    this.selectedCliente,
    this.errorMessage,
    this.detailErrorMessage,
    this.isDetailLoading = false,
    this.isSubmittingAction = false,
    this.searchTerm = '',
    this.filter = ClienteActivityFilter.active,
  });

  const ClientesState.loading() : this(status: ClientesStatus.loading);

  final ClientesStatus status;
  final List<ClienteRecord> items;
  final int? selectedClienteId;
  final ClienteRecord? selectedCliente;
  final String? errorMessage;
  final String? detailErrorMessage;
  final bool isDetailLoading;
  final bool isSubmittingAction;
  final String searchTerm;
  final ClienteActivityFilter filter;

  ClientesState copyWith({
    ClientesStatus? status,
    List<ClienteRecord>? items,
    Object? selectedClienteId = _sentinel,
    ClienteRecord? selectedCliente,
    String? errorMessage,
    String? detailErrorMessage,
    bool? isDetailLoading,
    bool? isSubmittingAction,
    String? searchTerm,
    ClienteActivityFilter? filter,
    bool clearError = false,
    bool clearDetailError = false,
    bool clearSelectedCliente = false,
  }) {
    return ClientesState(
      status: status ?? this.status,
      items: items ?? this.items,
      selectedClienteId: identical(selectedClienteId, _sentinel)
          ? this.selectedClienteId
          : selectedClienteId as int?,
      selectedCliente: clearSelectedCliente ? null : selectedCliente ?? this.selectedCliente,
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
        selectedClienteId,
        selectedCliente,
        errorMessage,
        detailErrorMessage,
        isDetailLoading,
        isSubmittingAction,
        searchTerm,
        filter,
      ];
}
