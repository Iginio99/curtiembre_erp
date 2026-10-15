import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/inventory/kardex/domain/repositories/kardex_repository.dart';
import 'package:erp_curtiembre_fronted/features/inventory/kardex/presentation/cubit/kardex_state.dart';
import 'package:erp_curtiembre_fronted/features/inventory/stock/domain/entities/stock_record.dart';
import 'package:erp_curtiembre_fronted/features/inventory/stock/domain/repositories/stock_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';

class KardexCubit extends Cubit<KardexState> {
  KardexCubit(this._repository, this._stockRepository, this._talker)
    : super(const KardexState.loading());

  final KardexRepository _repository;
  final StockRepository _stockRepository;
  final Talker _talker;

  Future<void> initialize() async {
    emit(const KardexState.loading());
    try {
      final insumos = await _repository.listActiveInsumos();
      final selectedId = insumos.isEmpty ? null : insumos.first.id;
      emit(state.copyWith(insumos: insumos, selectedInsumoId: selectedId));
      await load(selectedInsumoId: selectedId);
    } catch (error) {
      _fail(error);
    }
  }

  Future<void> load({
    required int? selectedInsumoId,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    if (state.status == KardexStatus.success &&
        state.selectedInsumoId == selectedInsumoId) {
      emit(state.copyWith(fechaDesde: fechaDesde, fechaHasta: fechaHasta));
      return;
    }
    emit(
      state.copyWith(
        status: KardexStatus.loading,
        selectedInsumoId: selectedInsumoId,
        fechaDesde: fechaDesde,
        fechaHasta: fechaHasta,
        clearError: true,
      ),
    );
    if (selectedInsumoId == null) {
      emit(
        state.copyWith(
          status: KardexStatus.success,
          items: const [],
          stock: null,
        ),
      );
      return;
    }
    try {
      // Dates are applied by the view, retaining history for opening balance.
      final items = await _repository.listKardexByInsumo(selectedInsumoId);
      StockRecord? stock;
      try {
        stock = await _stockRepository.getStockByInsumoId(selectedInsumoId);
      } catch (_) {
        // Stock has a separate permission. The Kardex history remains usable.
        _talker.cubit(
          'Detalle de stock no disponible para este usuario.',
          logLevel: LogLevel.warning,
        );
      }
      emit(
        state.copyWith(
          status: KardexStatus.success,
          items: items,
          stock: stock,
        ),
      );
    } catch (error) {
      _fail(error);
    }
  }

  void _fail(Object error) {
    final message = error is ApiException
        ? error.message
        : 'No pudimos cargar el kardex. Intenta nuevamente.';
    _talker.cubit('Error al cargar kardex: $message', logLevel: LogLevel.error);
    emit(state.copyWith(status: KardexStatus.error, errorMessage: message));
  }
}
