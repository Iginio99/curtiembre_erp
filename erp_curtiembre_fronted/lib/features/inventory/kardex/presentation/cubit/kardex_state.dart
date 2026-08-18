import 'package:equatable/equatable.dart';
import 'package:erp_curtiembre_fronted/features/inventory/kardex/domain/entities/kardex_record.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/domain/entities/insumo_lookup.dart';

enum KardexStatus {
  loading,
  success,
  error,
}

class KardexState extends Equatable {
  static const Object _sentinel = Object();

  const KardexState({
    required this.status,
    this.items = const [],
    this.insumos = const [],
    this.errorMessage,
    this.selectedInsumoId,
    this.tipoMovimientoFilter,
    this.documentoTipoFilter,
    this.usuarioResponsableIdFilter,
    this.fechaDesde,
    this.fechaHasta,
  });

  const KardexState.loading() : this(status: KardexStatus.loading);

  final KardexStatus status;
  final List<KardexRecord> items;
  final List<InsumoLookup> insumos;
  final String? errorMessage;
  final int? selectedInsumoId;
  final String? tipoMovimientoFilter;
  final String? documentoTipoFilter;
  final int? usuarioResponsableIdFilter;
  final DateTime? fechaDesde;
  final DateTime? fechaHasta;

  KardexState copyWith({
    KardexStatus? status,
    List<KardexRecord>? items,
    List<InsumoLookup>? insumos,
    String? errorMessage,
    Object? selectedInsumoId = _sentinel,
    Object? tipoMovimientoFilter = _sentinel,
    Object? documentoTipoFilter = _sentinel,
    Object? usuarioResponsableIdFilter = _sentinel,
    Object? fechaDesde = _sentinel,
    Object? fechaHasta = _sentinel,
    bool clearError = false,
  }) {
    return KardexState(
      status: status ?? this.status,
      items: items ?? this.items,
      insumos: insumos ?? this.insumos,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      selectedInsumoId: identical(selectedInsumoId, _sentinel)
          ? this.selectedInsumoId
          : selectedInsumoId as int?,
      tipoMovimientoFilter: identical(tipoMovimientoFilter, _sentinel)
          ? this.tipoMovimientoFilter
          : tipoMovimientoFilter as String?,
      documentoTipoFilter: identical(documentoTipoFilter, _sentinel)
          ? this.documentoTipoFilter
          : documentoTipoFilter as String?,
      usuarioResponsableIdFilter: identical(usuarioResponsableIdFilter, _sentinel)
          ? this.usuarioResponsableIdFilter
          : usuarioResponsableIdFilter as int?,
      fechaDesde: identical(fechaDesde, _sentinel)
          ? this.fechaDesde
          : fechaDesde as DateTime?,
      fechaHasta: identical(fechaHasta, _sentinel)
          ? this.fechaHasta
          : fechaHasta as DateTime?,
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        insumos,
        errorMessage,
        selectedInsumoId,
        tipoMovimientoFilter,
        documentoTipoFilter,
        usuarioResponsableIdFilter,
        fechaDesde,
        fechaHasta,
      ];
}
