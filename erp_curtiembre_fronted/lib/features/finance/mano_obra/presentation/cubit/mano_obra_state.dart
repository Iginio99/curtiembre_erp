import 'package:equatable/equatable.dart';
import 'package:erp_curtiembre_fronted/features/finance/mano_obra/domain/entities/mano_obra_directa_record.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/orden_proceso_record.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/orden_produccion_record.dart';

enum ManoObraStatus { loading, success, error }

class ManoObraState extends Equatable {
  static const Object _sentinel = Object();

  const ManoObraState({
    required this.status,
    this.items = const [],
    this.ordenOptions = const [],
    this.processOptionsByOrderId = const {},
    this.selectedManoObraId,
    this.selectedManoObra,
    this.errorMessage,
    this.detailErrorMessage,
    this.isDetailLoading = false,
    this.isSubmittingAction = false,
    this.ordenProduccionIdFilter,
    this.ordenProcesoIdFilter,
  });

  const ManoObraState.loading() : this(status: ManoObraStatus.loading);

  final ManoObraStatus status;
  final List<ManoObraDirectaRecord> items;
  final List<OrdenProduccionRecord> ordenOptions;
  final Map<int, List<OrdenProcesoRecord>> processOptionsByOrderId;
  final int? selectedManoObraId;
  final ManoObraDirectaRecord? selectedManoObra;
  final String? errorMessage;
  final String? detailErrorMessage;
  final bool isDetailLoading;
  final bool isSubmittingAction;
  final int? ordenProduccionIdFilter;
  final int? ordenProcesoIdFilter;

  ManoObraState copyWith({
    ManoObraStatus? status,
    List<ManoObraDirectaRecord>? items,
    List<OrdenProduccionRecord>? ordenOptions,
    Map<int, List<OrdenProcesoRecord>>? processOptionsByOrderId,
    Object? selectedManoObraId = _sentinel,
    ManoObraDirectaRecord? selectedManoObra,
    String? errorMessage,
    String? detailErrorMessage,
    bool? isDetailLoading,
    bool? isSubmittingAction,
    Object? ordenProduccionIdFilter = _sentinel,
    Object? ordenProcesoIdFilter = _sentinel,
    bool clearError = false,
    bool clearDetailError = false,
    bool clearSelectedManoObra = false,
  }) {
    return ManoObraState(
      status: status ?? this.status,
      items: items ?? this.items,
      ordenOptions: ordenOptions ?? this.ordenOptions,
      processOptionsByOrderId: processOptionsByOrderId ?? this.processOptionsByOrderId,
      selectedManoObraId: identical(selectedManoObraId, _sentinel)
          ? this.selectedManoObraId
          : selectedManoObraId as int?,
      selectedManoObra:
          clearSelectedManoObra ? null : selectedManoObra ?? this.selectedManoObra,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      detailErrorMessage:
          clearDetailError ? null : detailErrorMessage ?? this.detailErrorMessage,
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
      isSubmittingAction: isSubmittingAction ?? this.isSubmittingAction,
      ordenProduccionIdFilter: identical(ordenProduccionIdFilter, _sentinel)
          ? this.ordenProduccionIdFilter
          : ordenProduccionIdFilter as int?,
      ordenProcesoIdFilter: identical(ordenProcesoIdFilter, _sentinel)
          ? this.ordenProcesoIdFilter
          : ordenProcesoIdFilter as int?,
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        ordenOptions,
        processOptionsByOrderId,
        selectedManoObraId,
        selectedManoObra,
        errorMessage,
        detailErrorMessage,
        isDetailLoading,
        isSubmittingAction,
        ordenProduccionIdFilter,
        ordenProcesoIdFilter,
      ];
}
