import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/inventory/salidas/domain/repositories/salidas_repository.dart';
import 'package:erp_curtiembre_fronted/features/inventory/salidas/presentation/cubit/salidas_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';

class SalidasActionResult {
  const SalidasActionResult._({required this.success, required this.message});

  const SalidasActionResult.success(String message)
    : this._(success: true, message: message);

  const SalidasActionResult.failure(String message)
    : this._(success: false, message: message);

  final bool success;
  final String message;
}

class SalidasCubit extends Cubit<SalidasState> {
  SalidasCubit(this._repository, this._talker)
    : super(const SalidasState.loading());

  final SalidasRepository _repository;
  final Talker _talker;

  Future<void> initialize() async {
    _talker.cubit('Inicializando modulo de salidas.');
    emit(const SalidasState.loading());

    try {
      final insumos = await _repository.listActiveInsumos();
      _talker.cubit(
        'Catalogo base de salidas cargado con ${insumos.length} insumos activos.',
        logLevel: LogLevel.debug,
      );
      emit(state.copyWith(insumos: insumos, clearError: true));
      await load();
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar la base de salidas: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(
        state.copyWith(
          status: SalidasStatus.error,
          errorMessage: exception.message,
        ),
      );
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al cargar la base de salidas.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          status: SalidasStatus.error,
          errorMessage: 'No pudimos cargar la base de salidas.',
        ),
      );
    }
  }

  Future<void> load({
    String? searchTerm,
    Object? tipoSalidaFilter = _sentinel,
  }) async {
    final nextSearchTerm = searchTerm ?? state.searchTerm;
    final nextTipoSalida = identical(tipoSalidaFilter, _sentinel)
        ? state.tipoSalidaFilter
        : tipoSalidaFilter as String?;
    _talker.cubit(
      'Cargando salidas con busqueda=${_describeText(nextSearchTerm)}, tipoSalida=${_describeType(nextTipoSalida)}.',
    );

    emit(
      state.copyWith(
        status: SalidasStatus.loading,
        searchTerm: nextSearchTerm,
        tipoSalidaFilter: nextTipoSalida,
        clearError: true,
      ),
    );

    try {
      await _reload(
        searchTerm: nextSearchTerm,
        tipoSalidaFilter: nextTipoSalida,
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar la lista de salidas: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(
        state.copyWith(
          status: SalidasStatus.error,
          errorMessage: exception.message,
        ),
      );
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al cargar la lista de salidas.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          status: SalidasStatus.error,
          errorMessage: 'No pudimos cargar las salidas. Intenta nuevamente.',
        ),
      );
    }
  }

  Future<void> selectSalida(int salidaId) async {
    if (state.selectedSalidaId == salidaId &&
        state.selectedSalida?.id == salidaId) {
      _talker.cubit(
        'Se ignoro la seleccion de la salida $salidaId porque ya estaba cargada.',
        logLevel: LogLevel.debug,
      );
      return;
    }

    _talker.cubit('Seleccionando salida $salidaId para ver detalle.');
    emit(state.copyWith(selectedSalidaId: salidaId, clearDetailError: true));

    await _loadDetail(salidaId);
  }

  Future<void> retryDetail() async {
    final salidaId = state.selectedSalidaId;
    if (salidaId == null) {
      _talker.cubit(
        'Se intento reintentar detalle sin una salida seleccionada.',
        logLevel: LogLevel.warning,
      );
      return;
    }
    _talker.cubit('Reintentando carga de detalle para la salida $salidaId.');
    await _loadDetail(salidaId);
  }

  Future<SalidasActionResult> registerGeneral({
    required String motivo,
    String? observacion,
    required List<RegistrarSalidaDetalleInput> detalles,
  }) async {
    _talker.cubit(
      'Registrando salida general con motivo=${_describeText(motivo)}, observacion=${_describeText(observacion)}, detalles=${detalles.length}.',
      logLevel: LogLevel.warning,
    );
    emit(state.copyWith(isSubmittingAction: true));
    try {
      final detail = await _repository.registerGeneral(
        motivo: motivo,
        observacion: observacion,
        detalles: detalles,
      );
      await _reload(
        searchTerm: state.searchTerm,
        tipoSalidaFilter: state.tipoSalidaFilter,
        preferredSalidaId: detail.id,
      );
      emit(state.copyWith(isSubmittingAction: false));
      _talker.cubit(
        'Salida general registrada correctamente con id=${detail.id}.',
        logLevel: LogLevel.warning,
      );
      return const SalidasActionResult.success(
        'Salida general registrada correctamente.',
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo registrar la salida general: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return SalidasActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al registrar la salida general.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const SalidasActionResult.failure(
        'No pudimos registrar la salida general.',
      );
    }
  }

  Future<SalidasActionResult> registerSupplierReturn({
    required String motivo,
    String? observacion,
    required List<RegistrarSalidaDetalleInput> detalles,
  }) async {
    _talker.cubit(
      'Registrando devolucion a proveedor con motivo=${_describeText(motivo)}, observacion=${_describeText(observacion)}, detalles=${detalles.length}.',
      logLevel: LogLevel.warning,
    );
    emit(state.copyWith(isSubmittingAction: true));
    try {
      final detail = await _repository.registerSupplierReturn(
        motivo: motivo,
        observacion: observacion,
        detalles: detalles,
      );
      await _reload(
        searchTerm: state.searchTerm,
        tipoSalidaFilter: state.tipoSalidaFilter,
        preferredSalidaId: detail.id,
      );
      emit(state.copyWith(isSubmittingAction: false));
      _talker.cubit(
        'Devolucion a proveedor registrada correctamente con id=${detail.id}.',
        logLevel: LogLevel.warning,
      );
      return const SalidasActionResult.success(
        'Devolucion a proveedor registrada correctamente.',
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo registrar la devolucion a proveedor: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return SalidasActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al registrar la devolucion a proveedor.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const SalidasActionResult.failure(
        'No pudimos registrar la devolucion al proveedor.',
      );
    }
  }

  Future<SalidasActionResult> registerNegativeAdjustment({
    required String motivo,
    String? observacion,
    required List<RegistrarSalidaDetalleInput> detalles,
  }) async {
    _talker.cubit(
      'Registrando ajuste negativo con motivo=${_describeText(motivo)}, observacion=${_describeText(observacion)}, detalles=${detalles.length}.',
      logLevel: LogLevel.warning,
    );
    emit(state.copyWith(isSubmittingAction: true));
    try {
      final detail = await _repository.registerNegativeAdjustment(
        motivo: motivo,
        observacion: observacion,
        detalles: detalles,
      );
      await _reload(
        searchTerm: state.searchTerm,
        tipoSalidaFilter: state.tipoSalidaFilter,
        preferredSalidaId: detail.id,
      );
      emit(state.copyWith(isSubmittingAction: false));
      _talker.cubit(
        'Ajuste negativo registrado correctamente con id=${detail.id}.',
        logLevel: LogLevel.warning,
      );
      return const SalidasActionResult.success(
        'Ajuste negativo registrado correctamente.',
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo registrar el ajuste negativo: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return SalidasActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al registrar el ajuste negativo.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const SalidasActionResult.failure(
        'No pudimos registrar el ajuste negativo.',
      );
    }
  }

  Future<void> _loadDetail(int salidaId) async {
    _talker.cubit('Cargando detalle de la salida $salidaId.');
    emit(
      state.copyWith(
        isDetailLoading: true,
        clearSelectedSalida: true,
        clearDetailError: true,
      ),
    );

    try {
      final detail = await _repository.getSalidaDetail(salidaId);
      _talker.cubit(
        'Detalle de la salida $salidaId cargado con ${detail.detalles.length} lineas.',
        logLevel: LogLevel.debug,
      );
      emit(
        state.copyWith(
          isDetailLoading: false,
          selectedSalida: detail,
          clearDetailError: true,
        ),
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar el detalle de la salida $salidaId: ${exception.message}',
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
        'Fallo inesperado al cargar el detalle de la salida $salidaId.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          isDetailLoading: false,
          detailErrorMessage: 'No pudimos cargar el detalle de la salida.',
        ),
      );
    }
  }

  Future<void> _reload({
    required String searchTerm,
    required String? tipoSalidaFilter,
    int? preferredSalidaId,
  }) async {
    _talker.cubit(
      'Recargando salidas con busqueda=${_describeText(searchTerm)}, tipoSalida=${_describeType(tipoSalidaFilter)}, preferida=${preferredSalidaId ?? state.selectedSalidaId ?? 'ninguna'}.',
      logLevel: LogLevel.debug,
    );
    final items = await _repository.listSalidas(
      texto: searchTerm,
      tipoSalida: tipoSalidaFilter,
    );

    final currentSelectedId = preferredSalidaId ?? state.selectedSalidaId;
    final selectedSalidaId = items.any((item) => item.id == currentSelectedId)
        ? currentSelectedId
        : items.isNotEmpty
        ? items.first.id
        : null;
    _talker.cubit(
      'Recarga de salidas completada con ${items.length} resultados. Seleccion actual=${selectedSalidaId ?? 'ninguna'}.',
      logLevel: LogLevel.debug,
    );

    emit(
      state.copyWith(
        status: SalidasStatus.success,
        items: items,
        selectedSalidaId: selectedSalidaId,
        searchTerm: searchTerm,
        tipoSalidaFilter: tipoSalidaFilter,
        clearError: true,
      ),
    );

    if (selectedSalidaId == null) {
      emit(
        state.copyWith(
          isDetailLoading: false,
          clearSelectedSalida: true,
          clearDetailError: true,
        ),
      );
      _talker.cubit(
        'No hay salida seleccionada despues de la recarga.',
        logLevel: LogLevel.debug,
      );
      return;
    }

    await _loadDetail(selectedSalidaId);
  }

  static const Object _sentinel = Object();

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
}
