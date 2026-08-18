import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/finance/mano_obra/domain/repositories/mano_obra_repository.dart';
import 'package:erp_curtiembre_fronted/features/finance/mano_obra/presentation/cubit/mano_obra_state.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/orden_proceso_record.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/repositories/ordenes_produccion_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';

class ManoObraActionResult {
  const ManoObraActionResult._({required this.success, required this.message});

  const ManoObraActionResult.success(String message)
    : this._(success: true, message: message);

  const ManoObraActionResult.failure(String message)
    : this._(success: false, message: message);

  final bool success;
  final String message;
}

class ManoObraCubit extends Cubit<ManoObraState> {
  ManoObraCubit(this._repository, this._ordenesRepository, this._talker)
    : super(const ManoObraState.loading());

  final ManoObraRepository _repository;
  final OrdenesProduccionRepository _ordenesRepository;
  final Talker _talker;

  Future<void> initialize() async {
    _talker.cubit('Inicializando modulo de mano de obra directa.');
    emit(const ManoObraState.loading());

    try {
      final ordenes = await _ordenesRepository.listOrdenes();
      final processOptionsByOrderId = <int, List<OrdenProcesoRecord>>{};
      for (final orden in ordenes) {
        processOptionsByOrderId[orden.id] = await _ordenesRepository
            .listProcesos(orden.id);
      }
      _talker.cubit(
        'Base de mano de obra preparada con ${ordenes.length} ordenes y ${processOptionsByOrderId.length} mapas de procesos.',
        logLevel: LogLevel.debug,
      );

      emit(
        state.copyWith(
          ordenOptions: ordenes,
          processOptionsByOrderId: processOptionsByOrderId,
        ),
      );
      await load();
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo preparar la base de mano de obra: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(
        state.copyWith(
          status: ManoObraStatus.error,
          errorMessage: exception.message,
        ),
      );
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al preparar la base de mano de obra.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          status: ManoObraStatus.error,
          errorMessage: 'No pudimos preparar la base de mano de obra.',
        ),
      );
    }
  }

  List<OrdenProcesoRecord> processOptionsForOrder(int? orderId) {
    if (orderId == null) return const [];
    return state.processOptionsByOrderId[orderId] ?? const [];
  }

  Future<void> load({
    int? ordenProduccionIdFilter,
    int? ordenProcesoIdFilter,
  }) async {
    final nextOrderId =
        ordenProduccionIdFilter ?? state.ordenProduccionIdFilter;
    final nextProcessId = ordenProcesoIdFilter ?? state.ordenProcesoIdFilter;
    final normalizedProcessId = nextOrderId == null ? null : nextProcessId;
    _talker.cubit(
      'Cargando mano de obra con ordenProduccionId=$nextOrderId y ordenProcesoId=$normalizedProcessId.',
    );

    emit(
      state.copyWith(
        status: ManoObraStatus.loading,
        ordenProduccionIdFilter: nextOrderId,
        ordenProcesoIdFilter: normalizedProcessId,
        clearError: true,
      ),
    );

    try {
      await _ensureProcessOptionsForOrder(nextOrderId);
      await _reloadManoObra(
        ordenProduccionIdFilter: nextOrderId,
        ordenProcesoIdFilter: normalizedProcessId,
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar la lista de mano de obra: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(
        state.copyWith(
          status: ManoObraStatus.error,
          errorMessage: exception.message,
        ),
      );
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al cargar la lista de mano de obra.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          status: ManoObraStatus.error,
          errorMessage:
              'No pudimos cargar la mano de obra. Intenta nuevamente.',
        ),
      );
    }
  }

  Future<void> selectManoObra(int manoObraId) async {
    if (state.selectedManoObraId == manoObraId &&
        state.selectedManoObra?.id == manoObraId) {
      _talker.cubit(
        'Se ignoro la seleccion de mano de obra $manoObraId porque ya estaba cargada.',
        logLevel: LogLevel.debug,
      );
      return;
    }

    _talker.cubit('Seleccionando mano de obra $manoObraId para ver detalle.');
    emit(
      state.copyWith(selectedManoObraId: manoObraId, clearDetailError: true),
    );
    await _loadManoObraDetail(manoObraId);
  }

  Future<void> retryDetail() async {
    final manoObraId = state.selectedManoObraId;
    if (manoObraId == null) {
      _talker.cubit(
        'Se intento reintentar detalle sin un registro de mano de obra seleccionado.',
        logLevel: LogLevel.warning,
      );
      return;
    }
    _talker.cubit(
      'Reintentando carga de detalle para la mano de obra $manoObraId.',
    );
    await _loadManoObraDetail(manoObraId);
  }

  Future<ManoObraActionResult> createManoObra({
    required int ordenProduccionId,
    required int ordenProcesoId,
    required double monto,
    String? descripcion,
  }) async {
    _talker.cubit(
      'Creando mano de obra con ordenProduccionId=$ordenProduccionId, ordenProcesoId=$ordenProcesoId, monto=$monto, descripcion=${_describeText(descripcion)}.',
      logLevel: LogLevel.warning,
    );
    emit(state.copyWith(isSubmittingAction: true));

    try {
      final item = await _repository.createManoObra(
        ordenProduccionId: ordenProduccionId,
        ordenProcesoId: ordenProcesoId,
        monto: monto,
        descripcion: descripcion,
      );

      await _ensureProcessOptionsForOrder(ordenProduccionId);
      await _reloadManoObra(
        ordenProduccionIdFilter: state.ordenProduccionIdFilter,
        ordenProcesoIdFilter: state.ordenProcesoIdFilter,
        preferredManoObraId: item.id,
      );

      emit(state.copyWith(isSubmittingAction: false));
      _talker.cubit(
        'Mano de obra creada correctamente con id=${item.id}.',
        logLevel: LogLevel.warning,
      );
      return const ManoObraActionResult.success(
        'Mano de obra registrada correctamente.',
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo crear la mano de obra: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return ManoObraActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al crear la mano de obra.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const ManoObraActionResult.failure(
        'No pudimos registrar la mano de obra. Intenta nuevamente.',
      );
    }
  }

  Future<void> _ensureProcessOptionsForOrder(int? orderId) async {
    if (orderId == null || state.processOptionsByOrderId.containsKey(orderId)) {
      return;
    }

    _talker.cubit(
      'Cargando procesos para la orden $orderId.',
      logLevel: LogLevel.debug,
    );
    final processes = await _ordenesRepository.listProcesos(orderId);
    final nextMap = Map<int, List<OrdenProcesoRecord>>.from(
      state.processOptionsByOrderId,
    );
    nextMap[orderId] = processes;
    _talker.cubit(
      'Se cargaron ${processes.length} procesos para la orden $orderId.',
      logLevel: LogLevel.debug,
    );
    emit(state.copyWith(processOptionsByOrderId: nextMap));
  }

  Future<void> _loadManoObraDetail(int manoObraId) async {
    _talker.cubit('Cargando detalle de mano de obra $manoObraId.');
    emit(
      state.copyWith(
        isDetailLoading: true,
        clearSelectedManoObra: true,
        clearDetailError: true,
      ),
    );

    try {
      final item = await _repository.getManoObra(manoObraId);
      _talker.cubit(
        'Detalle de mano de obra $manoObraId cargado correctamente.',
        logLevel: LogLevel.debug,
      );
      emit(
        state.copyWith(
          isDetailLoading: false,
          selectedManoObra: item,
          clearDetailError: true,
        ),
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar el detalle de mano de obra $manoObraId: ${exception.message}',
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
        'Fallo inesperado al cargar el detalle de mano de obra $manoObraId.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          isDetailLoading: false,
          detailErrorMessage: 'No pudimos cargar el detalle de mano de obra.',
        ),
      );
    }
  }

  Future<void> _reloadManoObra({
    required int? ordenProduccionIdFilter,
    required int? ordenProcesoIdFilter,
    int? preferredManoObraId,
  }) async {
    _talker.cubit(
      'Recargando mano de obra con ordenProduccionId=$ordenProduccionIdFilter, ordenProcesoId=$ordenProcesoIdFilter, preferido=${preferredManoObraId ?? state.selectedManoObraId ?? 'ninguno'}.',
      logLevel: LogLevel.debug,
    );
    final items = await _repository.listManoObra(
      ordenProduccionId: ordenProduccionIdFilter,
      ordenProcesoId: ordenProcesoIdFilter,
    );

    final currentSelectedId = preferredManoObraId ?? state.selectedManoObraId;
    final selectedId = items.any((item) => item.id == currentSelectedId)
        ? currentSelectedId
        : items.isNotEmpty
        ? items.first.id
        : null;
    _talker.cubit(
      'Recarga de mano de obra completada con ${items.length} resultados. Seleccion actual=${selectedId ?? 'ninguna'}.',
      logLevel: LogLevel.debug,
    );

    emit(
      state.copyWith(
        status: ManoObraStatus.success,
        items: items,
        selectedManoObraId: selectedId,
        ordenProduccionIdFilter: ordenProduccionIdFilter,
        ordenProcesoIdFilter: ordenProcesoIdFilter,
        clearError: true,
      ),
    );

    if (selectedId == null) {
      emit(
        state.copyWith(
          isDetailLoading: false,
          clearSelectedManoObra: true,
          clearDetailError: true,
        ),
      );
      _talker.cubit(
        'No hay mano de obra seleccionada despues de la recarga.',
        logLevel: LogLevel.debug,
      );
      return;
    }

    await _loadManoObraDetail(selectedId);
  }

  String _describeText(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return '${normalized.length} caracteres';
  }
}
