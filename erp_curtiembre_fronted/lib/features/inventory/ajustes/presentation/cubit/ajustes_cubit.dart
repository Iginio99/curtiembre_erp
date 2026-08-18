import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/inventory/ajustes/domain/repositories/ajustes_repository.dart';
import 'package:erp_curtiembre_fronted/features/inventory/ajustes/presentation/cubit/ajustes_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';

class AjustesActionResult {
  const AjustesActionResult._({required this.success, required this.message});

  const AjustesActionResult.success(String message)
    : this._(success: true, message: message);

  const AjustesActionResult.failure(String message)
    : this._(success: false, message: message);

  final bool success;
  final String message;
}

class AjustesCubit extends Cubit<AjustesState> {
  AjustesCubit(this._repository, this._talker)
    : super(const AjustesState.loading());

  final AjustesRepository _repository;
  final Talker _talker;

  Future<void> initialize() async {
    _talker.cubit('Inicializando modulo de ajustes de inventario.');
    emit(const AjustesState.loading());
    try {
      final insumos = await _repository.listActiveInsumos();
      _talker.cubit(
        'Catalogo base de ajustes cargado con ${insumos.length} insumos activos.',
        logLevel: LogLevel.debug,
      );
      emit(state.copyWith(insumos: insumos, clearError: true));
      await load();
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar la base de ajustes: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(
        state.copyWith(
          status: AjustesStatus.error,
          errorMessage: exception.message,
        ),
      );
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al cargar la base de ajustes.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          status: AjustesStatus.error,
          errorMessage: 'No pudimos cargar la base de ajustes.',
        ),
      );
    }
  }

  Future<void> load({
    String? searchTerm,
    Object? tipoAjusteFilter = _sentinel,
  }) async {
    final nextSearchTerm = searchTerm ?? state.searchTerm;
    final nextTipoAjuste = identical(tipoAjusteFilter, _sentinel)
        ? state.tipoAjusteFilter
        : tipoAjusteFilter as String?;
    _talker.cubit(
      'Cargando ajustes con filtros texto=${_describeText(nextSearchTerm)}, tipoAjuste=${_describeType(nextTipoAjuste)}.',
    );

    emit(
      state.copyWith(
        status: AjustesStatus.loading,
        searchTerm: nextSearchTerm,
        tipoAjusteFilter: nextTipoAjuste,
        clearError: true,
      ),
    );

    try {
      await _reload(
        searchTerm: nextSearchTerm,
        tipoAjusteFilter: nextTipoAjuste,
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar la lista de ajustes: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(
        state.copyWith(
          status: AjustesStatus.error,
          errorMessage: exception.message,
        ),
      );
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al cargar la lista de ajustes.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          status: AjustesStatus.error,
          errorMessage: 'No pudimos cargar los ajustes. Intenta nuevamente.',
        ),
      );
    }
  }

  Future<void> selectAjuste(int ajusteId) async {
    if (state.selectedAjusteId == ajusteId &&
        state.selectedAjuste?.id == ajusteId) {
      _talker.cubit(
        'Se ignoro la seleccion del ajuste $ajusteId porque ya estaba cargado.',
        logLevel: LogLevel.debug,
      );
      return;
    }

    _talker.cubit(
      'Seleccionando ajuste de inventario $ajusteId para ver detalle.',
    );
    emit(state.copyWith(selectedAjusteId: ajusteId, clearDetailError: true));

    await _loadDetail(ajusteId);
  }

  Future<void> retryDetail() async {
    final ajusteId = state.selectedAjusteId;
    if (ajusteId == null) {
      _talker.cubit(
        'Se intento reintentar detalle sin un ajuste seleccionado.',
        logLevel: LogLevel.warning,
      );
      return;
    }
    _talker.cubit('Reintentando carga de detalle para el ajuste $ajusteId.');
    await _loadDetail(ajusteId);
  }

  Future<AjustesActionResult> registerPositive({
    required String motivo,
    String? observacion,
    required List<RegistrarAjusteDetalleInput> detalles,
  }) async {
    _talker.cubit(
      'Iniciando registro de ajuste positivo con motivo=${_describeText(motivo)} y ${detalles.length} detalles.',
      logLevel: LogLevel.warning,
    );
    emit(state.copyWith(isSubmittingAction: true));
    try {
      final detail = await _repository.registerPositive(
        motivo: motivo,
        observacion: observacion,
        detalles: detalles,
      );
      await _reload(
        searchTerm: state.searchTerm,
        tipoAjusteFilter: state.tipoAjusteFilter,
        preferredAjusteId: detail.id,
      );
      emit(state.copyWith(isSubmittingAction: false));
      _talker.cubit(
        'Ajuste positivo registrado correctamente con id=${detail.id}.',
        logLevel: LogLevel.warning,
      );
      return const AjustesActionResult.success(
        'Ajuste positivo registrado correctamente.',
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo registrar el ajuste positivo: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return AjustesActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al registrar el ajuste positivo.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const AjustesActionResult.failure(
        'No pudimos registrar el ajuste positivo.',
      );
    }
  }

  Future<AjustesActionResult> registerNegative({
    required String motivo,
    String? observacion,
    required List<RegistrarAjusteDetalleInput> detalles,
  }) async {
    _talker.cubit(
      'Iniciando registro de ajuste negativo con motivo=${_describeText(motivo)} y ${detalles.length} detalles.',
      logLevel: LogLevel.warning,
    );
    emit(state.copyWith(isSubmittingAction: true));
    try {
      final detail = await _repository.registerNegative(
        motivo: motivo,
        observacion: observacion,
        detalles: detalles,
      );
      await _reload(
        searchTerm: state.searchTerm,
        tipoAjusteFilter: state.tipoAjusteFilter,
        preferredAjusteId: detail.id,
      );
      emit(state.copyWith(isSubmittingAction: false));
      _talker.cubit(
        'Ajuste negativo registrado correctamente con id=${detail.id}.',
        logLevel: LogLevel.warning,
      );
      return const AjustesActionResult.success(
        'Ajuste negativo registrado correctamente.',
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo registrar el ajuste negativo: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return AjustesActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al registrar el ajuste negativo.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const AjustesActionResult.failure(
        'No pudimos registrar el ajuste negativo.',
      );
    }
  }

  Future<void> _loadDetail(int ajusteId) async {
    _talker.cubit('Cargando detalle del ajuste de inventario $ajusteId.');
    emit(
      state.copyWith(
        isDetailLoading: true,
        clearSelectedAjuste: true,
        clearDetailError: true,
      ),
    );

    try {
      final detail = await _repository.getAjusteDetail(ajusteId);
      _talker.cubit(
        'Detalle del ajuste $ajusteId cargado con ${detail.detalles.length} lineas.',
        logLevel: LogLevel.debug,
      );
      emit(
        state.copyWith(
          isDetailLoading: false,
          selectedAjuste: detail,
          clearDetailError: true,
        ),
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar el detalle del ajuste $ajusteId: ${exception.message}',
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
        'Fallo inesperado al cargar el detalle del ajuste $ajusteId.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          isDetailLoading: false,
          detailErrorMessage: 'No pudimos cargar el detalle del ajuste.',
        ),
      );
    }
  }

  Future<void> _reload({
    required String searchTerm,
    required String? tipoAjusteFilter,
    int? preferredAjusteId,
  }) async {
    _talker.cubit(
      'Recargando ajustes con texto=${_describeText(searchTerm)}, tipoAjuste=${_describeType(tipoAjusteFilter)}, preferido=${preferredAjusteId ?? state.selectedAjusteId}.',
      logLevel: LogLevel.debug,
    );
    final items = await _repository.listAjustes(
      texto: searchTerm,
      tipoAjuste: tipoAjusteFilter,
    );

    final currentSelectedId = preferredAjusteId ?? state.selectedAjusteId;
    final selectedAjusteId = items.any((item) => item.id == currentSelectedId)
        ? currentSelectedId
        : items.isNotEmpty
        ? items.first.id
        : null;
    _talker.cubit(
      'Recarga de ajustes completada con ${items.length} resultados. Seleccion actual=${selectedAjusteId ?? 'ninguna'}.',
      logLevel: LogLevel.debug,
    );

    emit(
      state.copyWith(
        status: AjustesStatus.success,
        items: items,
        selectedAjusteId: selectedAjusteId,
        searchTerm: searchTerm,
        tipoAjusteFilter: tipoAjusteFilter,
        clearError: true,
      ),
    );

    if (selectedAjusteId == null) {
      emit(
        state.copyWith(
          isDetailLoading: false,
          clearSelectedAjuste: true,
          clearDetailError: true,
        ),
      );
      _talker.cubit(
        'No hay ajuste seleccionado despues de la recarga.',
        logLevel: LogLevel.debug,
      );
      return;
    }

    await _loadDetail(selectedAjusteId);
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
