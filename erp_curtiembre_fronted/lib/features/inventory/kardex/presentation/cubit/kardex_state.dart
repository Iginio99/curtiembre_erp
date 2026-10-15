import 'package:equatable/equatable.dart';
import 'package:erp_curtiembre_fronted/features/inventory/kardex/domain/entities/kardex_record.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/domain/entities/insumo_lookup.dart';
import 'package:erp_curtiembre_fronted/features/inventory/stock/domain/entities/stock_record.dart';

enum KardexStatus { loading, success, error }

class KardexState extends Equatable {
  static const Object _unset = Object();

  const KardexState({
    required this.status,
    this.items = const [],
    this.insumos = const [],
    this.stock,
    this.selectedInsumoId,
    this.fechaDesde,
    this.fechaHasta,
    this.errorMessage,
  });

  const KardexState.loading() : this(status: KardexStatus.loading);

  final KardexStatus status;
  final List<KardexRecord> items;
  final List<InsumoLookup> insumos;
  final StockRecord? stock;
  final int? selectedInsumoId;
  final DateTime? fechaDesde;
  final DateTime? fechaHasta;
  final String? errorMessage;

  KardexState copyWith({
    KardexStatus? status,
    List<KardexRecord>? items,
    List<InsumoLookup>? insumos,
    Object? stock = _unset,
    Object? selectedInsumoId = _unset,
    Object? fechaDesde = _unset,
    Object? fechaHasta = _unset,
    String? errorMessage,
    bool clearError = false,
  }) => KardexState(
    status: status ?? this.status,
    items: items ?? this.items,
    insumos: insumos ?? this.insumos,
    stock: identical(stock, _unset) ? this.stock : stock as StockRecord?,
    selectedInsumoId: identical(selectedInsumoId, _unset)
        ? this.selectedInsumoId
        : selectedInsumoId as int?,
    fechaDesde: identical(fechaDesde, _unset)
        ? this.fechaDesde
        : fechaDesde as DateTime?,
    fechaHasta: identical(fechaHasta, _unset)
        ? this.fechaHasta
        : fechaHasta as DateTime?,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );

  @override
  List<Object?> get props => [
    status,
    items,
    insumos,
    stock,
    selectedInsumoId,
    fechaDesde,
    fechaHasta,
    errorMessage,
  ];
}
