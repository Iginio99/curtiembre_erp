import 'package:equatable/equatable.dart';
import 'package:erp_curtiembre_fronted/features/inventory/salidas/domain/entities/salida_detail.dart';
import 'package:erp_curtiembre_fronted/features/inventory/salidas/domain/entities/salida_record.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/domain/entities/insumo_lookup.dart';

enum SalidasStatus {
  loading,
  success,
  error,
}

class SalidasState extends Equatable {
  static const Object _sentinel = Object();

  const SalidasState({
    required this.status,
    this.items = const [],
    this.insumos = const [],
    this.selectedSalidaId,
    this.selectedSalida,
    this.errorMessage,
    this.detailErrorMessage,
    this.isDetailLoading = false,
    this.isSubmittingAction = false,
    this.searchTerm = '',
    this.tipoSalidaFilter,
  });

  const SalidasState.loading() : this(status: SalidasStatus.loading);

  final SalidasStatus status;
  final List<SalidaRecord> items;
  final List<InsumoLookup> insumos;
  final int? selectedSalidaId;
  final SalidaDetail? selectedSalida;
  final String? errorMessage;
  final String? detailErrorMessage;
  final bool isDetailLoading;
  final bool isSubmittingAction;
  final String searchTerm;
  final String? tipoSalidaFilter;

  SalidasState copyWith({
    SalidasStatus? status,
    List<SalidaRecord>? items,
    List<InsumoLookup>? insumos,
    Object? selectedSalidaId = _sentinel,
    SalidaDetail? selectedSalida,
    String? errorMessage,
    String? detailErrorMessage,
    bool? isDetailLoading,
    bool? isSubmittingAction,
    String? searchTerm,
    Object? tipoSalidaFilter = _sentinel,
    bool clearError = false,
    bool clearDetailError = false,
    bool clearSelectedSalida = false,
  }) {
    return SalidasState(
      status: status ?? this.status,
      items: items ?? this.items,
      insumos: insumos ?? this.insumos,
      selectedSalidaId: identical(selectedSalidaId, _sentinel)
          ? this.selectedSalidaId
          : selectedSalidaId as int?,
      selectedSalida: clearSelectedSalida ? null : selectedSalida ?? this.selectedSalida,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      detailErrorMessage:
          clearDetailError ? null : detailErrorMessage ?? this.detailErrorMessage,
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
      isSubmittingAction: isSubmittingAction ?? this.isSubmittingAction,
      searchTerm: searchTerm ?? this.searchTerm,
      tipoSalidaFilter: identical(tipoSalidaFilter, _sentinel)
          ? this.tipoSalidaFilter
          : tipoSalidaFilter as String?,
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        insumos,
        selectedSalidaId,
        selectedSalida,
        errorMessage,
        detailErrorMessage,
        isDetailLoading,
        isSubmittingAction,
        searchTerm,
        tipoSalidaFilter,
      ];
}
