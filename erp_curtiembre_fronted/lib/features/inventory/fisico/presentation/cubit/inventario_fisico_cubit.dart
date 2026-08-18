import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/inventory/fisico/domain/repositories/inventario_fisico_repository.dart';
import 'package:erp_curtiembre_fronted/features/inventory/fisico/presentation/cubit/inventario_fisico_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';

class InventarioFisicoActionResult {
  const InventarioFisicoActionResult._({
    required this.success,
    required this.message,
  });

  const InventarioFisicoActionResult.success(String message)
    : this._(success: true, message: message);

  const InventarioFisicoActionResult.failure(String message)
    : this._(success: false, message: message);

  final bool success;
  final String message;
}

class InventarioFisicoCubit extends Cubit<InventarioFisicoState> {
  InventarioFisicoCubit(this._repository, this._talker)
    : super(const InventarioFisicoState.loading());

  final InventarioFisicoRepository _repository;
  final Talker _talker;

  Future<void> initialize() async {
    _talker.cubit('Inicializando modulo de inventario fisico.');
    emit(const InventarioFisicoState.loading());
    try {
      final insumos = await _repository.listActiveInsumos();
      _talker.cubit(
        'Catalogo base de inventario fisico cargado con ${insumos.length} insumos activos.',
        logLevel: LogLevel.debug,
      );
      emit(state.copyWith(insumos: insumos, clearError: true));
      await load();
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar la base de inventario fisico: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(
        state.copyWith(
          status: InventarioFisicoStatus.error,
          errorMessage: exception.message,
        ),
      );
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al cargar la base de inventario fisico.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          status: InventarioFisicoStatus.error,
          errorMessage: 'No pudimos cargar la base de inventario fisico.',
        ),
      );
    }
  }

  Future<void> load({
    Object? periodoAnioFilter = _sentinel,
    Object? periodoMesFilter = _sentinel,
    Object? estadoFilter = _sentinel,
  }) async {
    final nextPeriodoAnio = identical(periodoAnioFilter, _sentinel)
        ? state.periodoAnioFilter
        : periodoAnioFilter as int?;
    final nextPeriodoMes = identical(periodoMesFilter, _sentinel)
        ? state.periodoMesFilter
        : periodoMesFilter as int?;
    final nextEstado = identical(estadoFilter, _sentinel)
        ? state.estadoFilter
        : estadoFilter as String?;
    _talker.cubit(
      'Cargando inventarios fisicos con filtros periodoAnio=$nextPeriodoAnio, periodoMes=$nextPeriodoMes, estado=${_describeState(nextEstado)}.',
    );

    emit(
      state.copyWith(
        status: InventarioFisicoStatus.loading,
        periodoAnioFilter: nextPeriodoAnio,
        periodoMesFilter: nextPeriodoMes,
        estadoFilter: nextEstado,
        clearError: true,
      ),
    );

    try {
      await _reload(
        periodoAnio: nextPeriodoAnio,
        periodoMes: nextPeriodoMes,
        estado: nextEstado,
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar la lista de inventarios fisicos: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(
        state.copyWith(
          status: InventarioFisicoStatus.error,
          errorMessage: exception.message,
        ),
      );
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al cargar la lista de inventarios fisicos.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          status: InventarioFisicoStatus.error,
          errorMessage:
              'No pudimos cargar las tomas fisicas. Intenta nuevamente.',
        ),
      );
    }
  }

  Future<void> selectInventario(int inventarioId) async {
    if (state.selectedInventarioId == inventarioId &&
        state.selectedInventario?.id == inventarioId) {
      _talker.cubit(
        'Se ignoro la seleccion del inventario fisico $inventarioId porque ya estaba cargado.',
        logLevel: LogLevel.debug,
      );
      return;
    }

    _talker.cubit(
      'Seleccionando inventario fisico $inventarioId para ver detalle.',
    );
    emit(
      state.copyWith(
        selectedInventarioId: inventarioId,
        clearDetailError: true,
      ),
    );

    await _loadDetail(inventarioId);
  }

  Future<void> retryDetail() async {
    final inventarioId = state.selectedInventarioId;
    if (inventarioId == null) {
      _talker.cubit(
        'Se intento reintentar detalle sin un inventario seleccionado.',
        logLevel: LogLevel.warning,
      );
      return;
    }
    _talker.cubit(
      'Reintentando carga de detalle para el inventario fisico $inventarioId.',
    );
    await _loadDetail(inventarioId);
  }

  Future<InventarioFisicoActionResult> createInventarioFisico({
    required int periodoAnio,
    required int periodoMes,
    String? observacion,
  }) async {
    _talker.cubit(
      'Creando inventario fisico para periodo=$periodoMes/$periodoAnio.',
    );
    emit(state.copyWith(isSubmittingAction: true));
    try {
      final detail = await _repository.createInventarioFisico(
        periodoAnio: periodoAnio,
        periodoMes: periodoMes,
        observacion: observacion,
      );
      await _reload(
        periodoAnio: state.periodoAnioFilter,
        periodoMes: state.periodoMesFilter,
        estado: state.estadoFilter,
        preferredInventarioId: detail.id,
      );
      emit(state.copyWith(isSubmittingAction: false));
      _talker.cubit(
        'Inventario fisico creado correctamente con id=${detail.id}.',
      );
      return const InventarioFisicoActionResult.success(
        'Inventario fisico creado correctamente.',
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo crear el inventario fisico: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return InventarioFisicoActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al crear el inventario fisico.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const InventarioFisicoActionResult.failure(
        'No pudimos crear el inventario fisico.',
      );
    }
  }

  Future<InventarioFisicoActionResult> registerCounts({
    required int inventarioFisicoId,
    required List<RegistrarConteoInventarioFisicoDetalleInput> detalles,
  }) async {
    _talker.cubit(
      'Registrando conteos para inventario fisico $inventarioFisicoId con ${detalles.length} detalles.',
      logLevel: LogLevel.warning,
    );
    emit(state.copyWith(isSubmittingAction: true));
    try {
      final detail = await _repository.registerCounts(
        inventarioFisicoId: inventarioFisicoId,
        detalles: detalles,
      );
      await _reload(
        periodoAnio: state.periodoAnioFilter,
        periodoMes: state.periodoMesFilter,
        estado: state.estadoFilter,
        preferredInventarioId: detail.id,
      );
      emit(state.copyWith(isSubmittingAction: false));
      _talker.cubit(
        'Conteos registrados correctamente para inventario fisico $inventarioFisicoId.',
        logLevel: LogLevel.warning,
      );
      return const InventarioFisicoActionResult.success(
        'Conteos registrados correctamente.',
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudieron registrar los conteos para inventario fisico $inventarioFisicoId: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return InventarioFisicoActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al registrar conteos para inventario fisico $inventarioFisicoId.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const InventarioFisicoActionResult.failure(
        'No pudimos registrar los conteos.',
      );
    }
  }

  Future<InventarioFisicoActionResult> closeSelected({
    String? observacion,
  }) async {
    final inventarioId = state.selectedInventarioId;
    if (inventarioId == null) {
      _talker.cubit(
        'Se intento cerrar un inventario fisico sin seleccion previa.',
        logLevel: LogLevel.warning,
      );
      return const InventarioFisicoActionResult.failure(
        'Selecciona un inventario fisico antes de cerrarlo.',
      );
    }

    _talker.cubit(
      'Cerrando inventario fisico $inventarioId con observacion=${_describeText(observacion)}.',
      logLevel: LogLevel.warning,
    );
    emit(state.copyWith(isSubmittingAction: true));
    try {
      final detail = await _repository.closeInventarioFisico(
        inventarioFisicoId: inventarioId,
        observacion: observacion,
      );
      await _reload(
        periodoAnio: state.periodoAnioFilter,
        periodoMes: state.periodoMesFilter,
        estado: state.estadoFilter,
        preferredInventarioId: detail.id,
      );
      emit(state.copyWith(isSubmittingAction: false));
      _talker.cubit(
        'Inventario fisico $inventarioId cerrado correctamente.',
        logLevel: LogLevel.warning,
      );
      return const InventarioFisicoActionResult.success(
        'Inventario fisico cerrado correctamente.',
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cerrar el inventario fisico $inventarioId: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return InventarioFisicoActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al cerrar el inventario fisico $inventarioId.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const InventarioFisicoActionResult.failure(
        'No pudimos cerrar el inventario fisico.',
      );
    }
  }

  Future<void> _loadDetail(int inventarioId) async {
    _talker.cubit('Cargando detalle del inventario fisico $inventarioId.');
    emit(
      state.copyWith(
        isDetailLoading: true,
        clearSelectedInventario: true,
        clearDetailError: true,
      ),
    );

    try {
      final detail = await _repository.getInventarioFisicoDetail(inventarioId);
      _talker.cubit(
        'Detalle del inventario fisico $inventarioId cargado con ${detail.detalles.length} lineas.',
        logLevel: LogLevel.debug,
      );
      emit(
        state.copyWith(
          isDetailLoading: false,
          selectedInventario: detail,
          clearDetailError: true,
        ),
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar el detalle del inventario fisico $inventarioId: ${exception.message}',
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
        'Fallo inesperado al cargar el detalle del inventario fisico $inventarioId.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          isDetailLoading: false,
          detailErrorMessage:
              'No pudimos cargar el detalle del inventario fisico.',
        ),
      );
    }
  }

  Future<void> _reload({
    required int? periodoAnio,
    required int? periodoMes,
    required String? estado,
    int? preferredInventarioId,
  }) async {
    _talker.cubit(
      'Recargando inventarios fisicos con periodoAnio=$periodoAnio, periodoMes=$periodoMes, estado=${_describeState(estado)}, preferido=${preferredInventarioId ?? state.selectedInventarioId}.',
      logLevel: LogLevel.debug,
    );
    final items = await _repository.listInventariosFisicos(
      periodoAnio: periodoAnio,
      periodoMes: periodoMes,
      estado: estado,
    );

    final currentSelectedId =
        preferredInventarioId ?? state.selectedInventarioId;
    final selectedInventarioId =
        items.any((item) => item.id == currentSelectedId)
        ? currentSelectedId
        : items.isNotEmpty
        ? items.first.id
        : null;
    _talker.cubit(
      'Recarga de inventarios fisicos completada con ${items.length} resultados. Seleccion actual=${selectedInventarioId ?? 'ninguna'}.',
      logLevel: LogLevel.debug,
    );

    emit(
      state.copyWith(
        status: InventarioFisicoStatus.success,
        items: items,
        selectedInventarioId: selectedInventarioId,
        periodoAnioFilter: periodoAnio,
        periodoMesFilter: periodoMes,
        estadoFilter: estado,
        clearError: true,
      ),
    );

    if (selectedInventarioId == null) {
      emit(
        state.copyWith(
          isDetailLoading: false,
          clearSelectedInventario: true,
          clearDetailError: true,
        ),
      );
      _talker.cubit(
        'No hay inventario fisico seleccionado despues de la recarga.',
        logLevel: LogLevel.debug,
      );
      return;
    }

    await _loadDetail(selectedInventarioId);
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
