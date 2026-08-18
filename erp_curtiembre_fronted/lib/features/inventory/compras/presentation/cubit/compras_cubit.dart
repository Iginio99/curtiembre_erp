import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/domain/entities/insumo_lookup.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/domain/entities/proveedor_lookup.dart';
import 'package:erp_curtiembre_fronted/features/inventory/compras/domain/repositories/compras_repository.dart';
import 'package:erp_curtiembre_fronted/features/inventory/compras/presentation/cubit/compras_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';

class ComprasActionResult {
  const ComprasActionResult._({required this.success, required this.message});

  const ComprasActionResult.success(String message)
    : this._(success: true, message: message);

  const ComprasActionResult.failure(String message)
    : this._(success: false, message: message);

  final bool success;
  final String message;
}

class ComprasCubit extends Cubit<ComprasState> {
  ComprasCubit(this._repository, this._talker)
    : super(const ComprasState.loading());

  final ComprasRepository _repository;
  final Talker _talker;

  Future<void> initialize() async {
    _talker.cubit('Inicializando modulo de compras.');
    emit(const ComprasState.loading());

    try {
      final results = await Future.wait<dynamic>([
        _repository.listActiveSuppliers(),
        _repository.listActiveInsumos(),
      ]);
      _talker.cubit(
        'Base de compras cargada con proveedores=${(results[0] as List).length} e insumos=${(results[1] as List).length}.',
        logLevel: LogLevel.debug,
      );

      emit(
        state.copyWith(
          proveedores: (results[0] as List).cast<ProveedorLookup>(),
          insumos: (results[1] as List).cast<InsumoLookup>(),
          clearError: true,
        ),
      );

      await load();
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar la base de compras: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(
        state.copyWith(
          status: ComprasStatus.error,
          errorMessage: exception.message,
        ),
      );
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al cargar la base de compras.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          status: ComprasStatus.error,
          errorMessage: 'No pudimos cargar la base de compras.',
        ),
      );
    }
  }

  Future<void> load({
    String? searchTerm,
    Object? proveedorIdFilter = _sentinel,
    Object? estadoFilter = _sentinel,
  }) async {
    final nextSearchTerm = searchTerm ?? state.searchTerm;
    final nextProveedorId = identical(proveedorIdFilter, _sentinel)
        ? state.proveedorIdFilter
        : proveedorIdFilter as int?;
    final nextEstado = identical(estadoFilter, _sentinel)
        ? state.estadoFilter
        : estadoFilter as String?;
    _talker.cubit(
      'Cargando compras con filtros texto=${_describeText(nextSearchTerm)}, proveedorId=$nextProveedorId, estado=${_describeState(nextEstado)}.',
    );

    emit(
      state.copyWith(
        status: ComprasStatus.loading,
        searchTerm: nextSearchTerm,
        proveedorIdFilter: nextProveedorId,
        estadoFilter: nextEstado,
        clearError: true,
      ),
    );

    try {
      await _reloadOrders(
        searchTerm: nextSearchTerm,
        proveedorIdFilter: nextProveedorId,
        estadoFilter: nextEstado,
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar la lista de compras: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(
        state.copyWith(
          status: ComprasStatus.error,
          errorMessage: exception.message,
        ),
      );
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al cargar la lista de compras.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          status: ComprasStatus.error,
          errorMessage: 'No pudimos cargar las compras. Intenta nuevamente.',
        ),
      );
    }
  }

  Future<void> selectOrder(int orderId) async {
    if (state.selectedOrderId == orderId &&
        state.selectedOrder?.id == orderId) {
      _talker.cubit(
        'Se ignoro la seleccion de la orden de compra $orderId porque ya estaba cargada.',
        logLevel: LogLevel.debug,
      );
      return;
    }

    _talker.cubit('Seleccionando orden de compra $orderId para ver detalle.');
    emit(state.copyWith(selectedOrderId: orderId, clearDetailError: true));

    await _loadOrderDetail(orderId);
  }

  Future<void> retryDetail() async {
    final orderId = state.selectedOrderId;
    if (orderId == null) {
      _talker.cubit(
        'Se intento reintentar detalle sin una orden seleccionada.',
        logLevel: LogLevel.warning,
      );
      return;
    }
    _talker.cubit(
      'Reintentando carga de detalle para la orden de compra $orderId.',
    );
    await _loadOrderDetail(orderId);
  }

  Future<ComprasActionResult> createOrder({
    required int proveedorId,
    required DateTime fechaEmision,
    String? observacion,
    required List<CreateOrdenCompraDetalleInput> detalles,
  }) async {
    _talker.cubit(
      'Creando orden de compra para proveedorId=$proveedorId con ${detalles.length} detalles.',
    );
    emit(state.copyWith(isSubmittingAction: true));

    try {
      final order = await _repository.createOrder(
        proveedorId: proveedorId,
        fechaEmision: fechaEmision,
        observacion: observacion,
        detalles: detalles,
      );

      await _reloadOrders(
        searchTerm: state.searchTerm,
        proveedorIdFilter: state.proveedorIdFilter,
        estadoFilter: state.estadoFilter,
        preferredOrderId: order.id,
      );

      emit(state.copyWith(isSubmittingAction: false));
      _talker.cubit('Orden de compra creada correctamente con id=${order.id}.');
      return const ComprasActionResult.success(
        'Orden de compra creada correctamente.',
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo crear la orden de compra: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return ComprasActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al crear la orden de compra.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const ComprasActionResult.failure(
        'No pudimos crear la orden de compra. Intenta nuevamente.',
      );
    }
  }

  Future<ComprasActionResult> approveSelectedOrder() async {
    final orderId = state.selectedOrderId;
    if (orderId == null) {
      _talker.cubit(
        'Se intento aprobar una orden sin seleccion previa.',
        logLevel: LogLevel.warning,
      );
      return const ComprasActionResult.failure(
        'Selecciona una orden para aprobar.',
      );
    }

    _talker.cubit(
      'Aprobando la orden de compra $orderId.',
      logLevel: LogLevel.warning,
    );
    emit(state.copyWith(isSubmittingAction: true));

    try {
      final message = await _repository.approveOrder(orderId);
      await _reloadOrders(
        searchTerm: state.searchTerm,
        proveedorIdFilter: state.proveedorIdFilter,
        estadoFilter: state.estadoFilter,
        preferredOrderId: orderId,
      );
      emit(state.copyWith(isSubmittingAction: false));
      _talker.cubit(
        'Orden de compra $orderId aprobada correctamente.',
        logLevel: LogLevel.warning,
      );
      return ComprasActionResult.success(message);
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo aprobar la orden de compra $orderId: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return ComprasActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al aprobar la orden de compra $orderId.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const ComprasActionResult.failure(
        'No pudimos aprobar la orden de compra.',
      );
    }
  }

  Future<ComprasActionResult> rejectSelectedOrder(String motivo) async {
    final orderId = state.selectedOrderId;
    if (orderId == null) {
      _talker.cubit(
        'Se intento rechazar una orden sin seleccion previa.',
        logLevel: LogLevel.warning,
      );
      return const ComprasActionResult.failure(
        'Selecciona una orden para rechazar.',
      );
    }

    _talker.cubit(
      'Rechazando la orden de compra $orderId con motivo=${_describeText(motivo)}.',
      logLevel: LogLevel.warning,
    );
    emit(state.copyWith(isSubmittingAction: true));

    try {
      final message = await _repository.rejectOrder(orderId, motivo);
      await _reloadOrders(
        searchTerm: state.searchTerm,
        proveedorIdFilter: state.proveedorIdFilter,
        estadoFilter: state.estadoFilter,
        preferredOrderId: orderId,
      );
      emit(state.copyWith(isSubmittingAction: false));
      _talker.cubit(
        'Orden de compra $orderId rechazada correctamente.',
        logLevel: LogLevel.warning,
      );
      return ComprasActionResult.success(message);
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo rechazar la orden de compra $orderId: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return ComprasActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al rechazar la orden de compra $orderId.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const ComprasActionResult.failure(
        'No pudimos rechazar la orden de compra.',
      );
    }
  }

  Future<ComprasActionResult> cancelSelectedOrder(String motivo) async {
    final orderId = state.selectedOrderId;
    if (orderId == null) {
      _talker.cubit(
        'Se intento anular una orden sin seleccion previa.',
        logLevel: LogLevel.warning,
      );
      return const ComprasActionResult.failure(
        'Selecciona una orden para anular.',
      );
    }

    _talker.cubit(
      'Anulando la orden de compra $orderId con motivo=${_describeText(motivo)}.',
      logLevel: LogLevel.warning,
    );
    emit(state.copyWith(isSubmittingAction: true));

    try {
      final message = await _repository.cancelOrder(orderId, motivo);
      await _reloadOrders(
        searchTerm: state.searchTerm,
        proveedorIdFilter: state.proveedorIdFilter,
        estadoFilter: state.estadoFilter,
        preferredOrderId: orderId,
      );
      emit(state.copyWith(isSubmittingAction: false));
      _talker.cubit(
        'Orden de compra $orderId anulada correctamente.',
        logLevel: LogLevel.warning,
      );
      return ComprasActionResult.success(message);
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo anular la orden de compra $orderId: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return ComprasActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al anular la orden de compra $orderId.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const ComprasActionResult.failure(
        'No pudimos anular la orden de compra.',
      );
    }
  }

  Future<void> _loadOrderDetail(int orderId) async {
    _talker.cubit('Cargando detalle de la orden de compra $orderId.');
    emit(
      state.copyWith(
        isDetailLoading: true,
        clearSelectedOrder: true,
        clearDetailError: true,
      ),
    );

    try {
      final detail = await _repository.getOrderDetail(orderId);
      _talker.cubit(
        'Detalle de la orden de compra $orderId cargado con ${detail.detalles.length} lineas.',
        logLevel: LogLevel.debug,
      );
      emit(
        state.copyWith(
          isDetailLoading: false,
          selectedOrder: detail,
          clearDetailError: true,
        ),
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar el detalle de la orden de compra $orderId: ${exception.message}',
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
        'Fallo inesperado al cargar el detalle de la orden de compra $orderId.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          isDetailLoading: false,
          detailErrorMessage: 'No pudimos cargar el detalle de la orden.',
        ),
      );
    }
  }

  Future<void> _reloadOrders({
    required String searchTerm,
    required int? proveedorIdFilter,
    required String? estadoFilter,
    int? preferredOrderId,
  }) async {
    _talker.cubit(
      'Recargando compras con texto=${_describeText(searchTerm)}, proveedorId=$proveedorIdFilter, estado=${_describeState(estadoFilter)}, preferida=${preferredOrderId ?? state.selectedOrderId}.',
      logLevel: LogLevel.debug,
    );
    final items = await _repository.listOrders(
      texto: searchTerm,
      proveedorId: proveedorIdFilter,
      estado: estadoFilter,
    );

    final currentSelectedId = preferredOrderId ?? state.selectedOrderId;
    final selectedOrderId = items.any((item) => item.id == currentSelectedId)
        ? currentSelectedId
        : items.isNotEmpty
        ? items.first.id
        : null;
    _talker.cubit(
      'Recarga de compras completada con ${items.length} resultados. Seleccion actual=${selectedOrderId ?? 'ninguna'}.',
      logLevel: LogLevel.debug,
    );

    emit(
      state.copyWith(
        status: ComprasStatus.success,
        items: items,
        selectedOrderId: selectedOrderId,
        searchTerm: searchTerm,
        proveedorIdFilter: proveedorIdFilter,
        estadoFilter: estadoFilter,
        clearError: true,
      ),
    );

    if (selectedOrderId == null) {
      emit(
        state.copyWith(
          isDetailLoading: false,
          clearSelectedOrder: true,
          clearDetailError: true,
        ),
      );
      _talker.cubit(
        'No hay orden de compra seleccionada despues de la recarga.',
        logLevel: LogLevel.debug,
      );
      return;
    }

    await _loadOrderDetail(selectedOrderId);
  }

  static const Object _sentinel = Object();

  String _describeText(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return '${normalized.length} caracteres';
  }

  String _describeState(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return normalized;
  }
}
