import 'package:equatable/equatable.dart';
import 'package:erp_curtiembre_fronted/features/inventory/fisico/domain/entities/inventario_fisico_detail.dart';
import 'package:erp_curtiembre_fronted/features/inventory/fisico/domain/entities/inventario_fisico_record.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/domain/entities/insumo_lookup.dart';

enum InventarioFisicoStatus {
  loading,
  success,
  error,
}

class InventarioFisicoState extends Equatable {
  static const Object _sentinel = Object();

  const InventarioFisicoState({
    required this.status,
    this.items = const [],
    this.insumos = const [],
    this.selectedInventarioId,
    this.selectedInventario,
    this.errorMessage,
    this.detailErrorMessage,
    this.isDetailLoading = false,
    this.isSubmittingAction = false,
    this.periodoAnioFilter,
    this.periodoMesFilter,
    this.estadoFilter,
  });

  const InventarioFisicoState.loading() : this(status: InventarioFisicoStatus.loading);

  final InventarioFisicoStatus status;
  final List<InventarioFisicoRecord> items;
  final List<InsumoLookup> insumos;
  final int? selectedInventarioId;
  final InventarioFisicoDetail? selectedInventario;
  final String? errorMessage;
  final String? detailErrorMessage;
  final bool isDetailLoading;
  final bool isSubmittingAction;
  final int? periodoAnioFilter;
  final int? periodoMesFilter;
  final String? estadoFilter;

  InventarioFisicoState copyWith({
    InventarioFisicoStatus? status,
    List<InventarioFisicoRecord>? items,
    List<InsumoLookup>? insumos,
    Object? selectedInventarioId = _sentinel,
    InventarioFisicoDetail? selectedInventario,
    String? errorMessage,
    String? detailErrorMessage,
    bool? isDetailLoading,
    bool? isSubmittingAction,
    Object? periodoAnioFilter = _sentinel,
    Object? periodoMesFilter = _sentinel,
    Object? estadoFilter = _sentinel,
    bool clearError = false,
    bool clearDetailError = false,
    bool clearSelectedInventario = false,
  }) {
    return InventarioFisicoState(
      status: status ?? this.status,
      items: items ?? this.items,
      insumos: insumos ?? this.insumos,
      selectedInventarioId: identical(selectedInventarioId, _sentinel)
          ? this.selectedInventarioId
          : selectedInventarioId as int?,
      selectedInventario:
          clearSelectedInventario ? null : selectedInventario ?? this.selectedInventario,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      detailErrorMessage:
          clearDetailError ? null : detailErrorMessage ?? this.detailErrorMessage,
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
      isSubmittingAction: isSubmittingAction ?? this.isSubmittingAction,
      periodoAnioFilter: identical(periodoAnioFilter, _sentinel)
          ? this.periodoAnioFilter
          : periodoAnioFilter as int?,
      periodoMesFilter: identical(periodoMesFilter, _sentinel)
          ? this.periodoMesFilter
          : periodoMesFilter as int?,
      estadoFilter: identical(estadoFilter, _sentinel)
          ? this.estadoFilter
          : estadoFilter as String?,
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        insumos,
        selectedInventarioId,
        selectedInventario,
        errorMessage,
        detailErrorMessage,
        isDetailLoading,
        isSubmittingAction,
        periodoAnioFilter,
        periodoMesFilter,
        estadoFilter,
      ];
}
