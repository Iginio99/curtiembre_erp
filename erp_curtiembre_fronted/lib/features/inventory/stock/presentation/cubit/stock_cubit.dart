import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/inventory/stock/domain/repositories/stock_repository.dart';
import 'package:erp_curtiembre_fronted/features/inventory/stock/presentation/cubit/stock_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';

class StockCubit extends Cubit<StockState> {
  static const Object _sentinel = Object();

  StockCubit(this._repository, this._talker)
    : super(const StockState.loading());

  final StockRepository _repository;
  final Talker _talker;

  Future<void> initialize() async {
    _talker.cubit('Inicializando modulo de stock.');
    emit(const StockState.loading());
    await load();
  }

  Future<void> load({
    String? searchTerm,
    StockActivityFilter? activityFilter,
    bool? lowStockOnly,
    Object? tipoBienFilter = _sentinel,
  }) async {
    final nextSearchTerm = searchTerm ?? state.searchTerm;
    final nextActivityFilter = activityFilter ?? state.activityFilter;
    final nextLowStockOnly = lowStockOnly ?? state.lowStockOnly;
    final nextTipoBienFilter = identical(tipoBienFilter, _sentinel)
        ? state.tipoBienFilter
        : tipoBienFilter as String?;
    _talker.cubit(
      'Cargando stock con busqueda=${_describeText(nextSearchTerm)}, actividad=${_describeActivityFilter(nextActivityFilter)}, stockBajo=$nextLowStockOnly, tipoBien=${_describeType(nextTipoBienFilter)}.',
    );

    emit(
      state.copyWith(
        status: StockStatus.loading,
        searchTerm: nextSearchTerm,
        activityFilter: nextActivityFilter,
        lowStockOnly: nextLowStockOnly,
        tipoBienFilter: nextTipoBienFilter,
        clearError: true,
      ),
    );

    try {
      await _reloadStock(
        searchTerm: nextSearchTerm,
        activityFilter: nextActivityFilter,
        lowStockOnly: nextLowStockOnly,
        tipoBienFilter: nextTipoBienFilter,
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar la lista de stock: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(
        state.copyWith(
          status: StockStatus.error,
          errorMessage: exception.message,
        ),
      );
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al cargar la lista de stock.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          status: StockStatus.error,
          errorMessage: 'No pudimos cargar el stock. Intenta nuevamente.',
        ),
      );
    }
  }

  Future<void> selectInsumo(int insumoId) async {
    if (state.selectedInsumoId == insumoId &&
        state.selectedStock?.insumoId == insumoId) {
      _talker.cubit(
        'Se ignoro la seleccion del insumo $insumoId porque ya estaba cargado.',
        logLevel: LogLevel.debug,
      );
      return;
    }

    _talker.cubit('Seleccionando insumo $insumoId para ver detalle de stock.');
    emit(state.copyWith(selectedInsumoId: insumoId, clearDetailError: true));

    await _loadDetail(insumoId);
  }

  Future<void> retryDetail() async {
    final insumoId = state.selectedInsumoId;
    if (insumoId == null) {
      _talker.cubit(
        'Se intento reintentar detalle sin un insumo seleccionado.',
        logLevel: LogLevel.warning,
      );
      return;
    }
    _talker.cubit('Reintentando carga de detalle para el insumo $insumoId.');
    await _loadDetail(insumoId);
  }

  Future<void> _loadDetail(int insumoId) async {
    _talker.cubit('Cargando detalle de stock para el insumo $insumoId.');
    emit(
      state.copyWith(
        isDetailLoading: true,
        clearSelectedStock: true,
        clearDetailError: true,
      ),
    );

    try {
      final detail = await _repository.getStockByInsumoId(insumoId);
      _talker.cubit(
        'Detalle de stock para el insumo $insumoId cargado correctamente.',
        logLevel: LogLevel.debug,
      );
      emit(
        state.copyWith(
          isDetailLoading: false,
          selectedStock: detail,
          clearDetailError: true,
        ),
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar el detalle de stock para el insumo $insumoId: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(
        state.copyWith(
          isDetailLoading: false,
          detailErrorMessage: exception.message,
        ),
      );
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al cargar el detalle de stock para el insumo $insumoId.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          isDetailLoading: false,
          detailErrorMessage: 'No pudimos cargar el detalle del stock.',
        ),
      );
    }
  }

  Future<void> _reloadStock({
    required String searchTerm,
    required StockActivityFilter activityFilter,
    required bool lowStockOnly,
    required String? tipoBienFilter,
  }) async {
    _talker.cubit(
      'Recargando stock con busqueda=${_describeText(searchTerm)}, actividad=${_describeActivityFilter(activityFilter)}, stockBajo=$lowStockOnly, tipoBien=${_describeType(tipoBienFilter)}.',
      logLevel: LogLevel.debug,
    );
    final items = lowStockOnly
        ? await _repository.listLowStock(
            texto: searchTerm,
            tipoBien: tipoBienFilter,
            activo: _mapFilter(activityFilter),
          )
        : await _repository.listStock(
            texto: searchTerm,
            tipoBien: tipoBienFilter,
            activo: _mapFilter(activityFilter),
          );

    final selectedInsumoId =
        items.any((item) => item.insumoId == state.selectedInsumoId)
        ? state.selectedInsumoId
        : items.isNotEmpty
        ? items.first.insumoId
        : null;
    _talker.cubit(
      'Recarga de stock completada con ${items.length} resultados. Seleccion actual=${selectedInsumoId ?? 'ninguna'}.',
      logLevel: LogLevel.debug,
    );

    emit(
      state.copyWith(
        status: StockStatus.success,
        items: items,
        selectedInsumoId: selectedInsumoId,
        searchTerm: searchTerm,
        activityFilter: activityFilter,
        lowStockOnly: lowStockOnly,
        tipoBienFilter: tipoBienFilter,
        clearError: true,
      ),
    );

    if (selectedInsumoId == null) {
      emit(
        state.copyWith(
          isDetailLoading: false,
          clearSelectedStock: true,
          clearDetailError: true,
        ),
      );
      _talker.cubit(
        'No hay insumo seleccionado despues de la recarga de stock.',
        logLevel: LogLevel.debug,
      );
      return;
    }

    await _loadDetail(selectedInsumoId);
  }

  bool? _mapFilter(StockActivityFilter filter) {
    return switch (filter) {
      StockActivityFilter.active => true,
      StockActivityFilter.inactive => false,
      StockActivityFilter.all => null,
    };
  }

  String _describeText(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return '${normalized.length} caracteres';
  }

  String _describeType(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return normalized;
  }

  String _describeActivityFilter(StockActivityFilter value) {
    return switch (value) {
      StockActivityFilter.active => 'activos',
      StockActivityFilter.inactive => 'inactivos',
      StockActivityFilter.all => 'todos',
    };
  }
}
