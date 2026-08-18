import 'package:equatable/equatable.dart';
import 'package:erp_curtiembre_fronted/features/inventory/ajustes/domain/entities/ajuste_detail.dart';
import 'package:erp_curtiembre_fronted/features/inventory/ajustes/domain/entities/ajuste_record.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/domain/entities/insumo_lookup.dart';

enum AjustesStatus {
  loading,
  success,
  error,
}

class AjustesState extends Equatable {
  static const Object _sentinel = Object();

  const AjustesState({
    required this.status,
    this.items = const [],
    this.insumos = const [],
    this.selectedAjusteId,
    this.selectedAjuste,
    this.errorMessage,
    this.detailErrorMessage,
    this.isDetailLoading = false,
    this.isSubmittingAction = false,
    this.searchTerm = '',
    this.tipoAjusteFilter,
  });

  const AjustesState.loading() : this(status: AjustesStatus.loading);

  final AjustesStatus status;
  final List<AjusteRecord> items;
  final List<InsumoLookup> insumos;
  final int? selectedAjusteId;
  final AjusteDetail? selectedAjuste;
  final String? errorMessage;
  final String? detailErrorMessage;
  final bool isDetailLoading;
  final bool isSubmittingAction;
  final String searchTerm;
  final String? tipoAjusteFilter;

  AjustesState copyWith({
    AjustesStatus? status,
    List<AjusteRecord>? items,
    List<InsumoLookup>? insumos,
    Object? selectedAjusteId = _sentinel,
    AjusteDetail? selectedAjuste,
    String? errorMessage,
    String? detailErrorMessage,
    bool? isDetailLoading,
    bool? isSubmittingAction,
    String? searchTerm,
    Object? tipoAjusteFilter = _sentinel,
    bool clearError = false,
    bool clearDetailError = false,
    bool clearSelectedAjuste = false,
  }) {
    return AjustesState(
      status: status ?? this.status,
      items: items ?? this.items,
      insumos: insumos ?? this.insumos,
      selectedAjusteId: identical(selectedAjusteId, _sentinel)
          ? this.selectedAjusteId
          : selectedAjusteId as int?,
      selectedAjuste: clearSelectedAjuste ? null : selectedAjuste ?? this.selectedAjuste,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      detailErrorMessage:
          clearDetailError ? null : detailErrorMessage ?? this.detailErrorMessage,
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
      isSubmittingAction: isSubmittingAction ?? this.isSubmittingAction,
      searchTerm: searchTerm ?? this.searchTerm,
      tipoAjusteFilter: identical(tipoAjusteFilter, _sentinel)
          ? this.tipoAjusteFilter
          : tipoAjusteFilter as String?,
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        insumos,
        selectedAjusteId,
        selectedAjuste,
        errorMessage,
        detailErrorMessage,
        isDetailLoading,
        isSubmittingAction,
        searchTerm,
        tipoAjusteFilter,
      ];
}
