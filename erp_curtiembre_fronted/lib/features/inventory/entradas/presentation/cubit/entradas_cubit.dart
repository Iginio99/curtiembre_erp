import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/inventory/compras/domain/entities/orden_compra_record.dart';
import 'package:erp_curtiembre_fronted/features/inventory/entradas/domain/repositories/entradas_repository.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/domain/entities/insumo_lookup.dart';
import 'package:erp_curtiembre_fronted/features/inventory/entradas/presentation/cubit/entradas_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';

class EntradasActionResult {
  const EntradasActionResult._({required this.success, required this.message});

  const EntradasActionResult.success(String message)
    : this._(success: true, message: message);

  const EntradasActionResult.failure(String message)
    : this._(success: false, message: message);

  final bool success;
  final String message;
}

class EntradasCubit extends Cubit<EntradasState> {
  EntradasCubit(this._repository, this._talker)
    : super(const EntradasState.loading());

  final EntradasRepository _repository;
  final Talker _talker;

  Future<void> initialize() async {
    _talker.cubit('Inicializando modulo de entradas de inventario.');
    emit(const EntradasState.loading());

    try {
      final results = await Future.wait<dynamic>([
        _repository.listActiveInsumos(),
        _repository.listReceivableOrders(),
      ]);
      _talker.cubit(
        'Base de entradas cargada con insumos=${(results[0] as List).length} y ordenes recepcionables=${(results[1] as List).length}.',
        logLevel: LogLevel.debug,
      );

      emit(
        state.copyWith(
          status: EntradasStatus.success,
          insumos: (results[0] as List).cast<InsumoLookup>(),
          receivableOrders: (results[1] as List).cast<OrdenCompraRecord>(),
          clearError: true,
        ),
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar la base de entradas: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(
        state.copyWith(
          status: EntradasStatus.error,
          errorMessage: exception.message,
        ),
      );
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al cargar la base de entradas.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          status: EntradasStatus.error,
          errorMessage: 'No pudimos cargar la base de entradas.',
        ),
      );
    }
  }

  Future<void> selectReceivableOrder(int? orderId) async {
    _talker.cubit(
      orderId == null
          ? 'Se limpio la orden recepcionable seleccionada.'
          : 'Seleccionando orden recepcionable $orderId.',
    );
    emit(
      state.copyWith(
        selectedReceivableOrderId: orderId,
        clearSelectedOrder: orderId == null,
        clearOrderDetailError: true,
      ),
    );

    if (orderId == null) {
      return;
    }

    emit(state.copyWith(isOrderDetailLoading: true, clearSelectedOrder: true));

    try {
      final detail = await _repository.getOrderDetail(orderId);
      _talker.cubit(
        'Detalle de la orden recepcionable $orderId cargado con ${detail.detalles.length} lineas.',
        logLevel: LogLevel.debug,
      );
      emit(
        state.copyWith(
          isOrderDetailLoading: false,
          selectedReceivableOrder: detail,
          clearOrderDetailError: true,
        ),
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar el detalle de la orden recepcionable $orderId: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(
        state.copyWith(
          isOrderDetailLoading: false,
          orderDetailErrorMessage: exception.message,
        ),
      );
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al cargar el detalle de la orden recepcionable $orderId.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          isOrderDetailLoading: false,
          orderDetailErrorMessage:
              'No pudimos cargar el detalle de la orden seleccionada.',
        ),
      );
    }
  }

  Future<EntradasActionResult> registerStockInitial({
    String? documentoSoporte,
    String? observacion,
    required List<RegistrarStockInicialDetalleInput> detalles,
  }) async {
    _talker.cubit(
      'Registrando stock inicial con documentoSoporte=${_describeText(documentoSoporte)} y ${detalles.length} detalles.',
      logLevel: LogLevel.warning,
    );
    emit(state.copyWith(isSubmittingAction: true));

    try {
      final entry = await _repository.registerStockInitial(
        documentoSoporte: documentoSoporte,
        observacion: observacion,
        detalles: detalles,
      );

      emit(
        state.copyWith(
          isSubmittingAction: false,
          lastEntry: entry,
          clearError: true,
        ),
      );
      _talker.cubit(
        'Stock inicial registrado correctamente con id=${entry.id}.',
        logLevel: LogLevel.warning,
      );
      return const EntradasActionResult.success(
        'Stock inicial registrado correctamente.',
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo registrar el stock inicial: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return EntradasActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al registrar el stock inicial.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const EntradasActionResult.failure(
        'No pudimos registrar el stock inicial.',
      );
    }
  }

  Future<EntradasActionResult> registerPurchaseEntry({
    required int ordenCompraId,
    required String documentoSoporte,
    String? observacion,
    required List<RegistrarEntradaCompraDetalleInput> detalles,
  }) async {
    _talker.cubit(
      'Registrando entrada desde compra para ordenCompraId=$ordenCompraId con documentoSoporte=${_describeText(documentoSoporte)} y ${detalles.length} detalles.',
      logLevel: LogLevel.warning,
    );
    emit(state.copyWith(isSubmittingAction: true));

    try {
      final entry = await _repository.registerPurchaseEntry(
        ordenCompraId: ordenCompraId,
        documentoSoporte: documentoSoporte,
        observacion: observacion,
        detalles: detalles,
      );

      final updatedOrders = await _repository.listReceivableOrders();
      emit(
        state.copyWith(
          isSubmittingAction: false,
          lastEntry: entry,
          receivableOrders: updatedOrders,
          clearError: true,
        ),
      );
      _talker.cubit(
        'Entrada desde compra registrada correctamente con id=${entry.id}. Se actualizaron ${updatedOrders.length} ordenes recepcionables.',
        logLevel: LogLevel.warning,
      );

      await selectReceivableOrder(ordenCompraId);

      return const EntradasActionResult.success(
        'Recepcion registrada correctamente.',
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo registrar la entrada desde compra para ordenCompraId=$ordenCompraId: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return EntradasActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al registrar la entrada desde compra para ordenCompraId=$ordenCompraId.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const EntradasActionResult.failure(
        'No pudimos registrar la entrada desde compra.',
      );
    }
  }

  String _describeText(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return '${normalized.length} caracteres';
  }
}
