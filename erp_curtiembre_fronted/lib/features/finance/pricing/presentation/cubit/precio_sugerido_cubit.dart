import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/finance/pricing/domain/repositories/finanzas_pricing_repository.dart';
import 'package:erp_curtiembre_fronted/features/finance/pricing/presentation/cubit/precio_sugerido_state.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/repositories/ordenes_produccion_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';

class PrecioSugeridoActionResult {
  const PrecioSugeridoActionResult._({
    required this.success,
    required this.message,
  });

  const PrecioSugeridoActionResult.success(String message)
    : this._(success: true, message: message);

  const PrecioSugeridoActionResult.failure(String message)
    : this._(success: false, message: message);

  final bool success;
  final String message;
}

class PrecioSugeridoCubit extends Cubit<PrecioSugeridoState> {
  PrecioSugeridoCubit(this._repository, this._ordenesRepository, this._talker)
    : super(const PrecioSugeridoState.loading());

  final FinanzasPricingRepository _repository;
  final OrdenesProduccionRepository _ordenesRepository;
  final Talker _talker;

  Future<void> initialize() async {
    _talker.cubit('Inicializando modulo de precio sugerido.');
    emit(const PrecioSugeridoState.loading());
    try {
      final orders = await _ordenesRepository.listOrdenes();
      final selectedOrder = orders.firstOrNull;
      _talker.cubit(
        'Base de precio sugerido preparada con ${orders.length} ordenes. Seleccion inicial=${selectedOrder?.id ?? 'ninguna'}.',
        logLevel: LogLevel.debug,
      );
      emit(
        state.copyWith(
          status: PrecioSugeridoStatus.success,
          orderOptions: orders,
          selectedOrderId: selectedOrder?.id,
          selectedOrder: selectedOrder,
          clearError: true,
          clearDetailError: true,
        ),
      );
      if (selectedOrder != null) {
        await loadDetail(selectedOrder.id);
      }
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo preparar la base de precio sugerido: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(
        state.copyWith(
          status: PrecioSugeridoStatus.error,
          errorMessage: exception.message,
        ),
      );
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al preparar la base de precio sugerido.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          status: PrecioSugeridoStatus.error,
          errorMessage: 'No pudimos preparar la base de precios sugeridos.',
        ),
      );
    }
  }

  Future<void> selectOrder(int? orderId) async {
    final selectedOrder = state.orderOptions
        .where((item) => item.id == orderId)
        .firstOrNull;
    _talker.cubit(
      'Seleccionando orden para precio sugerido: ${orderId ?? 'ninguna'}.',
      logLevel: LogLevel.debug,
    );
    emit(
      state.copyWith(
        selectedOrderId: orderId,
        selectedOrder: selectedOrder,
        detail: null,
        clearDetailError: true,
      ),
    );
    if (orderId != null) {
      await loadDetail(orderId);
    }
  }

  Future<void> loadDetail(int orderId) async {
    _talker.cubit(
      'Cargando detalle de precio sugerido para la orden $orderId.',
    );
    emit(state.copyWith(isDetailLoading: true, clearDetailError: true));
    try {
      final detail = await _repository.getPrecioSugerido(orderId);
      _talker.cubit(
        'Detalle de precio sugerido para la orden $orderId cargado correctamente.',
        logLevel: LogLevel.debug,
      );
      emit(
        state.copyWith(
          status: PrecioSugeridoStatus.success,
          detail: detail,
          isDetailLoading: false,
          clearDetailError: true,
        ),
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar el precio sugerido de la orden $orderId: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(
        state.copyWith(
          status: PrecioSugeridoStatus.success,
          detail: null,
          isDetailLoading: false,
          detailErrorMessage: exception.message,
        ),
      );
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al cargar el precio sugerido de la orden $orderId.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          status: PrecioSugeridoStatus.success,
          detail: null,
          isDetailLoading: false,
          detailErrorMessage:
              'No pudimos cargar el precio sugerido de la orden.',
        ),
      );
    }
  }

  Future<PrecioSugeridoActionResult> calculate(double margenPorcentaje) async {
    final orderId = state.selectedOrderId;
    if (orderId == null) {
      _talker.cubit(
        'Se intento calcular precio sugerido sin una orden seleccionada.',
        logLevel: LogLevel.warning,
      );
      return const PrecioSugeridoActionResult.failure(
        'Selecciona una orden antes de calcular el precio sugerido.',
      );
    }

    _talker.cubit(
      'Calculando precio sugerido para la orden $orderId con margenPorcentaje=$margenPorcentaje.',
      logLevel: LogLevel.warning,
    );
    emit(state.copyWith(isSubmittingAction: true));
    try {
      final detail = await _repository.calculatePrecioSugerido(
        ordenProduccionId: orderId,
        margenPorcentaje: margenPorcentaje,
      );
      emit(
        state.copyWith(
          isSubmittingAction: false,
          detail: detail,
          clearDetailError: true,
        ),
      );
      _talker.cubit(
        'Precio sugerido calculado correctamente para la orden $orderId.',
        logLevel: LogLevel.warning,
      );
      return const PrecioSugeridoActionResult.success(
        'Precio sugerido calculado correctamente.',
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo calcular el precio sugerido para la orden $orderId: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return PrecioSugeridoActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al calcular el precio sugerido para la orden $orderId.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const PrecioSugeridoActionResult.failure(
        'No pudimos calcular el precio sugerido. Intenta nuevamente.',
      );
    }
  }
}
