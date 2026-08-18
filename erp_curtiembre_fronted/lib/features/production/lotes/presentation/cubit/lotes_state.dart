import 'package:equatable/equatable.dart';
import 'package:erp_curtiembre_fronted/features/production/clientes/domain/entities/cliente_option.dart';
import 'package:erp_curtiembre_fronted/features/production/lotes/domain/entities/lote_disponibilidad.dart';
import 'package:erp_curtiembre_fronted/features/production/lotes/domain/entities/lote_record.dart';
import 'package:erp_curtiembre_fronted/features/production/lotes/domain/entities/tipo_piel_option.dart';

enum LotesStatus {
  loading,
  success,
  error,
}

class LotesState extends Equatable {
  static const Object _sentinel = Object();

  const LotesState({
    required this.status,
    this.items = const [],
    this.clienteOptions = const [],
    this.tipoPielOptions = const [],
    this.selectedLoteId,
    this.selectedLote,
    this.disponibilidad,
    this.errorMessage,
    this.detailErrorMessage,
    this.isDetailLoading = false,
    this.isSubmittingAction = false,
    this.searchTerm = '',
    this.selectedClienteId,
    this.selectedTipoPielId,
    this.estadoFilter,
  });

  const LotesState.loading() : this(status: LotesStatus.loading);

  final LotesStatus status;
  final List<LoteRecord> items;
  final List<ClienteOption> clienteOptions;
  final List<TipoPielOption> tipoPielOptions;
  final int? selectedLoteId;
  final LoteRecord? selectedLote;
  final LoteDisponibilidad? disponibilidad;
  final String? errorMessage;
  final String? detailErrorMessage;
  final bool isDetailLoading;
  final bool isSubmittingAction;
  final String searchTerm;
  final int? selectedClienteId;
  final int? selectedTipoPielId;
  final String? estadoFilter;

  LotesState copyWith({
    LotesStatus? status,
    List<LoteRecord>? items,
    List<ClienteOption>? clienteOptions,
    List<TipoPielOption>? tipoPielOptions,
    Object? selectedLoteId = _sentinel,
    LoteRecord? selectedLote,
    LoteDisponibilidad? disponibilidad,
    String? errorMessage,
    String? detailErrorMessage,
    bool? isDetailLoading,
    bool? isSubmittingAction,
    String? searchTerm,
    Object? selectedClienteId = _sentinel,
    Object? selectedTipoPielId = _sentinel,
    Object? estadoFilter = _sentinel,
    bool clearError = false,
    bool clearDetailError = false,
    bool clearSelectedLote = false,
    bool clearDisponibilidad = false,
  }) {
    return LotesState(
      status: status ?? this.status,
      items: items ?? this.items,
      clienteOptions: clienteOptions ?? this.clienteOptions,
      tipoPielOptions: tipoPielOptions ?? this.tipoPielOptions,
      selectedLoteId: identical(selectedLoteId, _sentinel)
          ? this.selectedLoteId
          : selectedLoteId as int?,
      selectedLote: clearSelectedLote ? null : selectedLote ?? this.selectedLote,
      disponibilidad: clearDisponibilidad ? null : disponibilidad ?? this.disponibilidad,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      detailErrorMessage:
          clearDetailError ? null : detailErrorMessage ?? this.detailErrorMessage,
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
      isSubmittingAction: isSubmittingAction ?? this.isSubmittingAction,
      searchTerm: searchTerm ?? this.searchTerm,
      selectedClienteId: identical(selectedClienteId, _sentinel)
          ? this.selectedClienteId
          : selectedClienteId as int?,
      selectedTipoPielId: identical(selectedTipoPielId, _sentinel)
          ? this.selectedTipoPielId
          : selectedTipoPielId as int?,
      estadoFilter: identical(estadoFilter, _sentinel)
          ? this.estadoFilter
          : estadoFilter as String?,
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        clienteOptions,
        tipoPielOptions,
        selectedLoteId,
        selectedLote,
        disponibilidad,
        errorMessage,
        detailErrorMessage,
        isDetailLoading,
        isSubmittingAction,
        searchTerm,
        selectedClienteId,
        selectedTipoPielId,
        estadoFilter,
      ];
}
