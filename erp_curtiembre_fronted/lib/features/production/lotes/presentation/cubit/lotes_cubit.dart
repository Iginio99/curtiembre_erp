import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/production/lotes/domain/repositories/lotes_repository.dart';
import 'package:erp_curtiembre_fronted/features/production/lotes/presentation/cubit/lotes_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';

class LotesActionResult {
  const LotesActionResult._({required this.success, required this.message});

  const LotesActionResult.success(String message)
    : this._(success: true, message: message);

  const LotesActionResult.failure(String message)
    : this._(success: false, message: message);

  final bool success;
  final String message;
}

class LotesCubit extends Cubit<LotesState> {
  LotesCubit(this._repository, this._talker)
    : super(const LotesState.loading());

  final LotesRepository _repository;
  final Talker _talker;

  Future<void> initialize() async {
    _talker.cubit('Inicializando modulo de lotes.');
    emit(const LotesState.loading());

    try {
      final clienteOptions = await _repository.listActiveClientes();
      final tipoPielOptions = await _repository.listActiveTiposPiel();
      emit(
        state.copyWith(
          clienteOptions: clienteOptions,
          tipoPielOptions: tipoPielOptions,
        ),
      );
      _talker.cubit(
        'Catalogos de lotes cargados con ${clienteOptions.length} clientes y ${tipoPielOptions.length} tipos de piel.',
      );
      await load();
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo preparar el modulo de lotes: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(
        state.copyWith(
          status: LotesStatus.error,
          errorMessage: exception.message,
        ),
      );
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado durante la preparacion del modulo de lotes.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          status: LotesStatus.error,
          errorMessage: 'No pudimos preparar el modulo de lotes.',
        ),
      );
    }
  }

  Future<void> load({
    String? searchTerm,
    int? clienteId,
    bool resetCliente = false,
    int? tipoPielId,
    bool resetTipoPiel = false,
    String? estado,
    bool resetEstado = false,
  }) async {
    final nextSearchTerm = searchTerm ?? state.searchTerm;
    final nextClienteId = resetCliente
        ? null
        : clienteId ?? state.selectedClienteId;
    final nextTipoPielId = resetTipoPiel
        ? null
        : tipoPielId ?? state.selectedTipoPielId;
    final nextEstado = resetEstado ? null : estado ?? state.estadoFilter;
    _talker.cubit(
      'Cargando lotes con filtros texto=${_describeSearchTerm(nextSearchTerm)}, clienteId=$nextClienteId, tipoPielId=$nextTipoPielId, estado=${_describeState(nextEstado)}.',
    );

    emit(
      state.copyWith(
        status: LotesStatus.loading,
        searchTerm: nextSearchTerm,
        selectedClienteId: nextClienteId,
        selectedTipoPielId: nextTipoPielId,
        estadoFilter: nextEstado,
        clearError: true,
      ),
    );

    try {
      await _reloadLotes(
        searchTerm: nextSearchTerm,
        clienteId: nextClienteId,
        tipoPielId: nextTipoPielId,
        estado: nextEstado,
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar la lista de lotes: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(
        state.copyWith(
          status: LotesStatus.error,
          errorMessage: exception.message,
        ),
      );
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al cargar la lista de lotes.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          status: LotesStatus.error,
          errorMessage: 'No pudimos cargar los lotes. Intenta nuevamente.',
        ),
      );
    }
  }

  Future<void> selectLote(int loteId) async {
    if (state.selectedLoteId == loteId && state.selectedLote?.id == loteId) {
      _talker.cubit(
        'Se ignoro la seleccion del lote $loteId porque ya estaba cargado.',
        logLevel: LogLevel.debug,
      );
      return;
    }

    _talker.cubit('Seleccionando lote $loteId para ver detalle.');
    emit(state.copyWith(selectedLoteId: loteId, clearDetailError: true));

    await _loadLoteDetail(loteId);
  }

  Future<void> retryDetail() async {
    final loteId = state.selectedLoteId;
    if (loteId == null) {
      _talker.cubit(
        'Se intento reintentar detalle sin un lote seleccionado.',
        logLevel: LogLevel.warning,
      );
      return;
    }

    _talker.cubit('Reintentando carga de detalle para el lote $loteId.');
    await _loadLoteDetail(loteId);
  }

  Future<LotesActionResult> createLote({
    required int clienteId,
    required int tipoPielId,
    required DateTime fechaIngreso,
    required double cantidadPielesInicial,
    required bool clienteTraeLote,
    required double costoPielesTotal,
    String? observacion,
  }) async {
    _talker.cubit(
      'Iniciando creacion de lote para clienteId=$clienteId, tipoPielId=$tipoPielId, cantidadPielesInicial=$cantidadPielesInicial.',
    );
    emit(state.copyWith(isSubmittingAction: true));

    try {
      final lote = await _repository.createLote(
        clienteId: clienteId,
        tipoPielId: tipoPielId,
        fechaIngreso: fechaIngreso,
        cantidadPielesInicial: cantidadPielesInicial,
        clienteTraeLote: clienteTraeLote,
        costoPielesTotal: costoPielesTotal,
        observacion: observacion,
      );

      await _reloadLotes(
        searchTerm: state.searchTerm,
        clienteId: state.selectedClienteId,
        tipoPielId: state.selectedTipoPielId,
        estado: state.estadoFilter,
        preferredLoteId: lote.id,
      );

      emit(state.copyWith(isSubmittingAction: false));
      _talker.cubit('Lote creado correctamente con id=${lote.id}.');
      return const LotesActionResult.success('Lote creado correctamente.');
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo crear el lote: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return LotesActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al crear el lote.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const LotesActionResult.failure(
        'No pudimos crear el lote. Intenta nuevamente.',
      );
    }
  }

  Future<LotesActionResult> updateSelectedLote({
    required int clienteId,
    required int tipoPielId,
    required DateTime fechaIngreso,
    required double cantidadPielesInicial,
    required bool clienteTraeLote,
    required double costoPielesTotal,
    String? observacion,
  }) async {
    final loteId = state.selectedLoteId;
    if (loteId == null) {
      _talker.cubit(
        'Se intento editar un lote sin seleccion previa.',
        logLevel: LogLevel.warning,
      );
      return const LotesActionResult.failure('Selecciona un lote para editar.');
    }

    _talker.cubit(
      'Iniciando actualizacion del lote $loteId para clienteId=$clienteId, tipoPielId=$tipoPielId, cantidadPielesInicial=$cantidadPielesInicial.',
    );
    emit(state.copyWith(isSubmittingAction: true));

    try {
      await _repository.updateLote(
        id: loteId,
        clienteId: clienteId,
        tipoPielId: tipoPielId,
        fechaIngreso: fechaIngreso,
        cantidadPielesInicial: cantidadPielesInicial,
        clienteTraeLote: clienteTraeLote,
        costoPielesTotal: costoPielesTotal,
        observacion: observacion,
      );

      await _reloadLotes(
        searchTerm: state.searchTerm,
        clienteId: state.selectedClienteId,
        tipoPielId: state.selectedTipoPielId,
        estado: state.estadoFilter,
        preferredLoteId: loteId,
      );

      emit(state.copyWith(isSubmittingAction: false));
      _talker.cubit('Lote $loteId actualizado correctamente.');
      return const LotesActionResult.success('Lote actualizado correctamente.');
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo actualizar el lote $loteId: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return LotesActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al actualizar el lote $loteId.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const LotesActionResult.failure(
        'No pudimos actualizar el lote. Intenta nuevamente.',
      );
    }
  }

  Future<void> _loadLoteDetail(int loteId) async {
    _talker.cubit('Cargando detalle del lote $loteId.');
    emit(
      state.copyWith(
        isDetailLoading: true,
        clearSelectedLote: true,
        clearDisponibilidad: true,
        clearDetailError: true,
      ),
    );

    try {
      final lote = await _repository.getLote(loteId);
      final disponibilidad = await _repository.getDisponibilidad(loteId);
      _talker.cubit(
        'Detalle y disponibilidad del lote $loteId cargados correctamente.',
      );
      emit(
        state.copyWith(
          isDetailLoading: false,
          selectedLote: lote,
          disponibilidad: disponibilidad,
          clearDetailError: true,
        ),
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar el detalle del lote $loteId: ${exception.message}',
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
        'Fallo inesperado al cargar el detalle del lote $loteId.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          isDetailLoading: false,
          detailErrorMessage: 'No pudimos cargar el detalle del lote.',
        ),
      );
    }
  }

  Future<void> _reloadLotes({
    required String searchTerm,
    required int? clienteId,
    required int? tipoPielId,
    required String? estado,
    int? preferredLoteId,
  }) async {
    _talker.cubit(
      'Recargando lotes con texto=${_describeSearchTerm(searchTerm)}, clienteId=$clienteId, tipoPielId=$tipoPielId, estado=${_describeState(estado)}, preferido=${preferredLoteId ?? state.selectedLoteId}.',
      logLevel: LogLevel.debug,
    );
    final items = await _repository.listLotes(
      texto: searchTerm,
      clienteId: clienteId,
      tipoPielId: tipoPielId,
      estado: estado,
    );

    final currentSelectedId = preferredLoteId ?? state.selectedLoteId;
    final selectedLoteId = items.any((item) => item.id == currentSelectedId)
        ? currentSelectedId
        : items.isNotEmpty
        ? items.first.id
        : null;
    _talker.cubit(
      'Recarga de lotes completada con ${items.length} resultados. Seleccion actual=${selectedLoteId ?? 'ninguna'}.',
      logLevel: LogLevel.debug,
    );

    emit(
      state.copyWith(
        status: LotesStatus.success,
        items: items,
        selectedLoteId: selectedLoteId,
        searchTerm: searchTerm,
        selectedClienteId: clienteId,
        selectedTipoPielId: tipoPielId,
        estadoFilter: estado,
        clearError: true,
      ),
    );

    if (selectedLoteId == null) {
      emit(
        state.copyWith(
          isDetailLoading: false,
          clearSelectedLote: true,
          clearDisponibilidad: true,
          clearDetailError: true,
        ),
      );
      _talker.cubit(
        'No hay lote seleccionado despues de la recarga.',
        logLevel: LogLevel.debug,
      );
      return;
    }

    await _loadLoteDetail(selectedLoteId);
  }

  String _describeSearchTerm(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return 'vacio';
    }

    return '${normalized.length} caracteres';
  }

  String _describeState(String? estado) {
    final normalized = estado?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return normalized;
  }
}
