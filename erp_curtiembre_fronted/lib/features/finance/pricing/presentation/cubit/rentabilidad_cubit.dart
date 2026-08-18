import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/finance/pricing/domain/repositories/finanzas_pricing_repository.dart';
import 'package:erp_curtiembre_fronted/features/finance/pricing/presentation/cubit/rentabilidad_state.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/repositories/ordenes_produccion_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';

class RentabilidadActionResult {
  const RentabilidadActionResult._({
    required this.success,
    required this.message,
  });

  const RentabilidadActionResult.success(String message)
    : this._(success: true, message: message);

  const RentabilidadActionResult.failure(String message)
    : this._(success: false, message: message);

  final bool success;
  final String message;
}

class RentabilidadCubit extends Cubit<RentabilidadState> {
  RentabilidadCubit(this._repository, this._ordenesRepository, this._talker)
    : super(const RentabilidadState.loading());

  final FinanzasPricingRepository _repository;
  final OrdenesProduccionRepository _ordenesRepository;
  final Talker _talker;

  Future<void> initialize() async {
    _talker.cubit('Inicializando modulo de rentabilidad.');
    emit(const RentabilidadState.loading());
    try {
      final orders = await _ordenesRepository.listOrdenes();
      final selectedOrder = orders.firstOrNull;
      _talker.cubit(
        'Base de rentabilidad preparada con ${orders.length} ordenes. Seleccion inicial=${selectedOrder?.id ?? 'ninguna'}.',
        logLevel: LogLevel.debug,
      );
      emit(
        state.copyWith(
          status: RentabilidadStatus.success,
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
        'No se pudo preparar la base de rentabilidad: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(
        state.copyWith(
          status: RentabilidadStatus.error,
          errorMessage: exception.message,
        ),
      );
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al preparar la base de rentabilidad.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          status: RentabilidadStatus.error,
          errorMessage: 'No pudimos preparar la base de rentabilidad.',
        ),
      );
    }
  }

  Future<void> selectOrder(int? orderId) async {
    final selectedOrder = state.orderOptions
        .where((item) => item.id == orderId)
        .firstOrNull;
    _talker.cubit(
      'Seleccionando orden para rentabilidad: ${orderId ?? 'ninguna'}.',
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
    _talker.cubit('Cargando detalle de rentabilidad para la orden $orderId.');
    emit(state.copyWith(isDetailLoading: true, clearDetailError: true));
    try {
      final detail = await _repository.getRentabilidad(orderId);
      _talker.cubit(
        'Detalle de rentabilidad para la orden $orderId cargado correctamente.',
        logLevel: LogLevel.debug,
      );
      emit(
        state.copyWith(
          status: RentabilidadStatus.success,
          detail: detail,
          isDetailLoading: false,
          clearDetailError: true,
        ),
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar la rentabilidad de la orden $orderId: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(
        state.copyWith(
          status: RentabilidadStatus.success,
          detail: null,
          isDetailLoading: false,
          detailErrorMessage: exception.message,
        ),
      );
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al cargar la rentabilidad de la orden $orderId.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          status: RentabilidadStatus.success,
          detail: null,
          isDetailLoading: false,
          detailErrorMessage: 'No pudimos cargar la rentabilidad de la orden.',
        ),
      );
    }
  }

  Future<RentabilidadActionResult> calculate(double precioVenta) async {
    final orderId = state.selectedOrderId;
    if (orderId == null) {
      _talker.cubit(
        'Se intento calcular rentabilidad sin una orden seleccionada.',
        logLevel: LogLevel.warning,
      );
      return const RentabilidadActionResult.failure(
        'Selecciona una orden antes de calcular la rentabilidad.',
      );
    }

    _talker.cubit(
      'Calculando rentabilidad para la orden $orderId con precioVenta=$precioVenta.',
      logLevel: LogLevel.warning,
    );
    emit(state.copyWith(isSubmittingAction: true));
    try {
      final detail = await _repository.calculateRentabilidad(
        ordenProduccionId: orderId,
        precioVenta: precioVenta,
      );
      emit(
        state.copyWith(
          isSubmittingAction: false,
          detail: detail,
          clearDetailError: true,
        ),
      );
      _talker.cubit(
        'Rentabilidad calculada correctamente para la orden $orderId.',
        logLevel: LogLevel.warning,
      );
      return const RentabilidadActionResult.success(
        'Rentabilidad calculada correctamente.',
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo calcular la rentabilidad para la orden $orderId: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return RentabilidadActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al calcular la rentabilidad para la orden $orderId.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const RentabilidadActionResult.failure(
        'No pudimos calcular la rentabilidad. Intenta nuevamente.',
      );
    }
  }
}
