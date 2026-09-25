import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/repositories/ordenes_produccion_repository.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/presentation/cubit/ordenes_produccion_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';

class OrdenesActionResult {
  const OrdenesActionResult._({required this.success, required this.message});

  const OrdenesActionResult.success(String message)
    : this._(success: true, message: message);

  const OrdenesActionResult.failure(String message)
    : this._(success: false, message: message);

  final bool success;
  final String message;
}

class OrdenesProduccionCubit extends Cubit<OrdenesProduccionState> {
  OrdenesProduccionCubit(this._repository, this._talker)
    : super(const OrdenesProduccionState.loading());

  final OrdenesProduccionRepository _repository;
  final Talker _talker;

  Future<void> initialize() async {
    _talker.cubit('Inicializando modulo de ordenes de produccion.');
    emit(const OrdenesProduccionState.loading());

    try {
      final clienteOptions = await _repository.listActiveClientes();
      final loteOptions = await _repository.listLotesDisponibles();
      final insumoOptions = await _repository.listActiveInsumos();
      _talker.cubit(
        'Catalogos base cargados para ordenes: clientes=${clienteOptions.length}, lotes=${loteOptions.length}, insumos=${insumoOptions.length}.',
        logLevel: LogLevel.debug,
      );
      emit(
        state.copyWith(
          clienteOptions: clienteOptions,
          loteOptions: loteOptions,
          insumoOptions: insumoOptions,
        ),
      );
      await load();
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo preparar el modulo de ordenes de produccion: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(
        state.copyWith(
          status: OrdenesProduccionStatus.error,
          errorMessage: exception.message,
        ),
      );
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al preparar el modulo de ordenes de produccion.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          status: OrdenesProduccionStatus.error,
          errorMessage:
              'No pudimos preparar el modulo de ordenes de produccion.',
        ),
      );
    }
  }

  Future<void> load({
    String? searchTerm,
    int? clienteId,
    bool resetCliente = false,
    int? loteId,
    bool resetLote = false,
    String? estado,
    bool resetEstado = false,
  }) async {
    final nextSearchTerm = searchTerm ?? state.searchTerm;
    final nextClienteId = resetCliente
        ? null
        : clienteId ?? state.selectedClienteId;
    final nextLoteId = resetLote ? null : loteId ?? state.selectedLoteId;
    final nextEstado = resetEstado ? null : estado ?? state.estadoFilter;
    _talker.cubit(
      'Cargando ordenes con filtros texto=${_describeText(nextSearchTerm)}, clienteId=$nextClienteId, loteId=$nextLoteId, estado=${_describeState(nextEstado)}.',
    );

    emit(
      state.copyWith(
        status: OrdenesProduccionStatus.loading,
        searchTerm: nextSearchTerm,
        selectedClienteId: nextClienteId,
        selectedLoteId: nextLoteId,
        estadoFilter: nextEstado,
        clearError: true,
      ),
    );

    try {
      await _reloadOrdenes(
        searchTerm: nextSearchTerm,
        clienteId: nextClienteId,
        loteId: nextLoteId,
        estado: nextEstado,
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar la lista de ordenes: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(
        state.copyWith(
          status: OrdenesProduccionStatus.error,
          errorMessage: exception.message,
        ),
      );
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al cargar la lista de ordenes.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          status: OrdenesProduccionStatus.error,
          errorMessage: 'No pudimos cargar las ordenes. Intenta nuevamente.',
        ),
      );
    }
  }

  Future<void> selectOrden(int ordenId) async {
    if (state.selectedOrdenId == ordenId &&
        state.selectedOrden?.id == ordenId) {
      _talker.cubit(
        'Se ignoro la seleccion de la orden $ordenId porque ya estaba cargada.',
        logLevel: LogLevel.debug,
      );
      return;
    }

    _talker.cubit(
      'Seleccionando orden de produccion $ordenId para ver detalle.',
    );
    emit(state.copyWith(selectedOrdenId: ordenId, clearDetailError: true));

    await _loadOrdenDetail(ordenId);
  }

  Future<void> retryDetail() async {
    final ordenId = state.selectedOrdenId;
    if (ordenId == null) {
      _talker.cubit(
        'Se intento reintentar detalle sin una orden seleccionada.',
        logLevel: LogLevel.warning,
      );
      return;
    }

    _talker.cubit('Reintentando carga de detalle para la orden $ordenId.');
    await _loadOrdenDetail(ordenId);
  }

  Future<OrdenesActionResult> createOrden({
    required int loteId,
    required int clienteId,
    required double cantidadPieles,
    DateTime? fechaInicioPlanificada,
    required DateTime fechaFinEstimada,
    int? responsableUsuarioId,
    String? observacion,
  }) async {
    _talker.cubit(
      'Iniciando creacion de orden para loteId=$loteId, clienteId=$clienteId, cantidadPieles=$cantidadPieles.',
    );
    emit(state.copyWith(isSubmittingAction: true));

    try {
      final orden = await _repository.createOrden(
        loteId: loteId,
        clienteId: clienteId,
        cantidadPieles: cantidadPieles,
        fechaInicioPlanificada: fechaInicioPlanificada,
        fechaFinEstimada: fechaFinEstimada,
        responsableUsuarioId: responsableUsuarioId,
        observacion: observacion,
      );

      await _refreshOptions();
      await _reloadOrdenes(
        searchTerm: state.searchTerm,
        clienteId: state.selectedClienteId,
        loteId: state.selectedLoteId,
        estado: state.estadoFilter,
        preferredOrdenId: orden.id,
      );

      emit(state.copyWith(isSubmittingAction: false));
      _talker.cubit('Orden creada correctamente con id=${orden.id}.');
      return const OrdenesActionResult.success('Orden creada correctamente.');
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo crear la orden de produccion: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return OrdenesActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al crear la orden de produccion.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const OrdenesActionResult.failure(
        'No pudimos crear la orden. Intenta nuevamente.',
      );
    }
  }

  Future<OrdenesActionResult> startSelectedOrden({
    required double pesoBaseKg,
    required DateTime fechaFinEstimada,
    int? responsableUsuarioId,
    String? observacion,
  }) async {
    final ordenId = state.selectedOrdenId;
    if (ordenId == null) {
      _talker.cubit(
        'Se intento iniciar una orden sin seleccion previa.',
        logLevel: LogLevel.warning,
      );
      return const OrdenesActionResult.failure(
        'Selecciona una orden para continuar.',
      );
    }

    _talker.cubit('Iniciando orden de produccion $ordenId.');
    emit(state.copyWith(isSubmittingAction: true));

    try {
      await _repository.startOrden(
        id: ordenId,
        pesoBaseKg: pesoBaseKg,
        fechaFinEstimada: fechaFinEstimada,
        responsableUsuarioId: responsableUsuarioId,
        observacion: observacion,
      );

      await _reloadOrdenes(
        searchTerm: state.searchTerm,
        clienteId: state.selectedClienteId,
        loteId: state.selectedLoteId,
        estado: state.estadoFilter,
        preferredOrdenId: ordenId,
      );

      emit(state.copyWith(isSubmittingAction: false));
      _talker.cubit('Orden de produccion $ordenId iniciada correctamente.');
      return const OrdenesActionResult.success('Orden iniciada correctamente.');
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo iniciar la orden $ordenId: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return OrdenesActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al iniciar la orden $ordenId.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const OrdenesActionResult.failure('No pudimos iniciar la orden.');
    }
  }

  Future<OrdenesActionResult> cancelSelectedOrden({
    required String motivo,
  }) async {
    final ordenId = state.selectedOrdenId;
    if (ordenId == null) {
      _talker.cubit(
        'Se intento anular una orden sin seleccion previa.',
        logLevel: LogLevel.warning,
      );
      return const OrdenesActionResult.failure(
        'Selecciona una orden para continuar.',
      );
    }

    _talker.cubit(
      'Iniciando anulacion de la orden $ordenId con motivo=${_describeText(motivo)}.',
      logLevel: LogLevel.warning,
    );
    emit(state.copyWith(isSubmittingAction: true));

    try {
      await _repository.cancelOrden(id: ordenId, motivo: motivo);

      await _refreshOptions();
      await _reloadOrdenes(
        searchTerm: state.searchTerm,
        clienteId: state.selectedClienteId,
        loteId: state.selectedLoteId,
        estado: state.estadoFilter,
        preferredOrdenId: ordenId,
      );

      emit(state.copyWith(isSubmittingAction: false));
      _talker.cubit(
        'Orden de produccion $ordenId anulada correctamente.',
        logLevel: LogLevel.warning,
      );
      return const OrdenesActionResult.success('Orden anulada correctamente.');
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo anular la orden $ordenId: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return OrdenesActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al anular la orden $ordenId.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const OrdenesActionResult.failure('No pudimos anular la orden.');
    }
  }

  Future<OrdenesActionResult> startProceso({
    required int procesoId,
    required double pesoBaseKg,
    required DateTime fechaFinEstimada,
    int? responsableUsuarioId,
    String? observacion,
  }) async {
    _talker.cubit('Iniciando proceso de produccion $procesoId.');
    emit(state.copyWith(isSubmittingAction: true));

    try {
      await _repository.startProceso(
        id: procesoId,
        pesoBaseKg: pesoBaseKg,
        fechaFinEstimada: fechaFinEstimada,
        responsableUsuarioId: responsableUsuarioId,
        observacion: observacion,
      );

      final ordenId = state.selectedOrdenId;
      if (ordenId != null) {
        await _reloadOrdenes(
          searchTerm: state.searchTerm,
          clienteId: state.selectedClienteId,
          loteId: state.selectedLoteId,
          estado: state.estadoFilter,
          preferredOrdenId: ordenId,
        );
      }

      emit(state.copyWith(isSubmittingAction: false));
      _talker.cubit('Proceso de produccion $procesoId iniciado correctamente.');
      return const OrdenesActionResult.success(
        'Proceso iniciado correctamente.',
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo iniciar el proceso $procesoId: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return OrdenesActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al iniciar el proceso $procesoId.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const OrdenesActionResult.failure(
        'No pudimos iniciar el proceso.',
      );
    }
  }

  Future<OrdenesActionResult> finishProceso({
    required int procesoId,
    String? observacion,
  }) async {
    _talker.cubit('Finalizando proceso de produccion $procesoId.');
    emit(state.copyWith(isSubmittingAction: true));

    try {
      await _repository.finishProceso(id: procesoId, observacion: observacion);

      final ordenId = state.selectedOrdenId;
      if (ordenId != null) {
        await _reloadOrdenes(
          searchTerm: state.searchTerm,
          clienteId: state.selectedClienteId,
          loteId: state.selectedLoteId,
          estado: state.estadoFilter,
          preferredOrdenId: ordenId,
        );
      }

      emit(state.copyWith(isSubmittingAction: false));
      _talker.cubit(
        'Proceso de produccion $procesoId finalizado correctamente.',
      );
      return const OrdenesActionResult.success(
        'Proceso finalizado correctamente.',
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo finalizar el proceso $procesoId: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return OrdenesActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al finalizar el proceso $procesoId.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const OrdenesActionResult.failure(
        'No pudimos finalizar el proceso.',
      );
    }
  }

  Future<OrdenesActionResult> updateProcesoObservacion({
    required int procesoId,
    String? observacion,
  }) async {
    _talker.cubit(
      'Actualizando observacion del proceso $procesoId con valor=${_describeText(observacion)}.',
    );
    emit(state.copyWith(isSubmittingAction: true));

    try {
      await _repository.updateObservacionProceso(
        id: procesoId,
        observacion: observacion,
      );

      final ordenId = state.selectedOrdenId;
      if (ordenId != null) {
        await _reloadOrdenes(
          searchTerm: state.searchTerm,
          clienteId: state.selectedClienteId,
          loteId: state.selectedLoteId,
          estado: state.estadoFilter,
          preferredOrdenId: ordenId,
        );
      }

      emit(state.copyWith(isSubmittingAction: false));
      _talker.cubit(
        'Observacion del proceso $procesoId actualizada correctamente.',
      );
      return const OrdenesActionResult.success(
        'Observacion del proceso actualizada.',
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo actualizar la observacion del proceso $procesoId: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return OrdenesActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al actualizar la observacion del proceso $procesoId.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const OrdenesActionResult.failure(
        'No pudimos actualizar la observacion del proceso.',
      );
    }
  }

  Future<void> _refreshOptions() async {
    _talker.cubit(
      'Recargando catalogos auxiliares para ordenes de produccion.',
      logLevel: LogLevel.debug,
    );
    final clienteOptions = await _repository.listActiveClientes();
    final loteOptions = await _repository.listLotesDisponibles();
    final insumoOptions = await _repository.listActiveInsumos();
    _talker.cubit(
      'Catalogos auxiliares recargados: clientes=${clienteOptions.length}, lotes=${loteOptions.length}, insumos=${insumoOptions.length}.',
      logLevel: LogLevel.debug,
    );
    emit(
      state.copyWith(
        clienteOptions: clienteOptions,
        loteOptions: loteOptions,
        insumoOptions: insumoOptions,
      ),
    );
  }

  Future<OrdenesActionResult> generarConsumoPlanificado() async {
    final ordenId = state.selectedOrdenId;
    if (ordenId == null) {
      _talker.cubit(
        'Se intento generar consumo planificado sin una orden seleccionada.',
        logLevel: LogLevel.warning,
      );
      return const OrdenesActionResult.failure(
        'Selecciona una orden para continuar.',
      );
    }

    _talker.cubit('Generando consumo planificado para la orden $ordenId.');
    emit(state.copyWith(isSubmittingAction: true));
    try {
      await _repository.generarConsumoPlanificado(ordenId);
      await _reloadOrdenes(
        searchTerm: state.searchTerm,
        clienteId: state.selectedClienteId,
        loteId: state.selectedLoteId,
        estado: state.estadoFilter,
        preferredOrdenId: ordenId,
      );
      emit(state.copyWith(isSubmittingAction: false));
      _talker.cubit(
        'Consumo planificado generado correctamente para la orden $ordenId.',
      );
      return const OrdenesActionResult.success(
        'Consumo planificado calculado correctamente.',
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo generar el consumo planificado para la orden $ordenId: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return OrdenesActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al generar el consumo planificado para la orden $ordenId.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const OrdenesActionResult.failure(
        'No pudimos calcular el consumo planificado.',
      );
    }
  }

  Future<OrdenesActionResult> solicitarConsumo({
    required int ordenProcesoId,
    String? motivo,
    String? observacion,
    required List<SolicitarConsumoProduccionDetalleInput> detalles,
  }) async {
    final ordenId = state.selectedOrdenId;
    if (ordenId == null) {
      _talker.cubit(
        'Se intento solicitar consumo sin una orden seleccionada.',
        logLevel: LogLevel.warning,
      );
      return const OrdenesActionResult.failure(
        'Selecciona una orden para continuar.',
      );
    }

    _talker.cubit(
      'Solicitando consumo para ordenId=$ordenId, ordenProcesoId=$ordenProcesoId con ${detalles.length} detalles.',
    );
    emit(state.copyWith(isSubmittingAction: true));
    try {
      await _repository.solicitarConsumo(
        ordenId: ordenId,
        ordenProcesoId: ordenProcesoId,
        motivo: motivo,
        observacion: observacion,
        detalles: detalles,
      );
      await _reloadOrdenes(
        searchTerm: state.searchTerm,
        clienteId: state.selectedClienteId,
        loteId: state.selectedLoteId,
        estado: state.estadoFilter,
        preferredOrdenId: ordenId,
      );
      emit(state.copyWith(isSubmittingAction: false));
      _talker.cubit(
        'Solicitud de insumos creada correctamente para ordenId=$ordenId y procesoId=$ordenProcesoId.',
      );
      return const OrdenesActionResult.success(
        'Solicitud de insumos enviada a Logistica.',
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo solicitar consumo para ordenId=$ordenId y procesoId=$ordenProcesoId: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return OrdenesActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al solicitar consumo para ordenId=$ordenId y procesoId=$ordenProcesoId.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const OrdenesActionResult.failure(
        'No pudimos crear la solicitud de insumos.',
      );
    }
  }

  Future<OrdenesActionResult> registerMerma({
    required int procesoId,
    required RegistrarMermaProcesoInput input,
  }) async {
    _talker.cubit(
      'Registrando merma para procesoId=$procesoId con cantidadPerdida=${input.cantidadPerdida}.',
    );
    emit(state.copyWith(isSubmittingAction: true));
    try {
      await _repository.registerMerma(procesoId: procesoId, input: input);
      final ordenId = state.selectedOrdenId;
      if (ordenId != null) {
        await _reloadOrdenes(
          searchTerm: state.searchTerm,
          clienteId: state.selectedClienteId,
          loteId: state.selectedLoteId,
          estado: state.estadoFilter,
          preferredOrdenId: ordenId,
        );
      }
      emit(state.copyWith(isSubmittingAction: false));
      _talker.cubit(
        'Merma registrada correctamente para procesoId=$procesoId.',
      );
      return const OrdenesActionResult.success(
        'Merma registrada correctamente.',
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo registrar la merma para procesoId=$procesoId: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return OrdenesActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al registrar la merma para procesoId=$procesoId.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const OrdenesActionResult.failure(
        'No pudimos registrar la merma.',
      );
    }
  }

  Future<OrdenesActionResult> registerCalidadFinal({
    required RegistrarCalidadFinalInput input,
  }) async {
    final ordenId = state.selectedOrdenId;
    if (ordenId == null) {
      _talker.cubit(
        'Se intento registrar calidad final sin una orden seleccionada.',
        logLevel: LogLevel.warning,
      );
      return const OrdenesActionResult.failure(
        'Selecciona una orden para continuar.',
      );
    }

    _talker.cubit(
      'Registrando calidad final para ordenId=$ordenId con resultado=${input.resultado}.',
    );
    emit(state.copyWith(isSubmittingAction: true));
    try {
      final controlCalidad = await _repository.registerCalidadFinal(
        ordenId: ordenId,
        input: input,
      );
      emit(
        state.copyWith(
          isSubmittingAction: false,
          controlCalidad: controlCalidad,
        ),
      );
      _talker.cubit(
        'Calidad final registrada correctamente para la orden $ordenId.',
      );
      return const OrdenesActionResult.success(
        'Calidad final registrada correctamente.',
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo registrar la calidad final para la orden $ordenId: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return OrdenesActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al registrar la calidad final para la orden $ordenId.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const OrdenesActionResult.failure(
        'No pudimos registrar la calidad final.',
      );
    }
  }

  Future<OrdenesActionResult> finalizeSelectedOrden({
    required FinalizarOrdenProduccionInput input,
  }) async {
    final ordenId = state.selectedOrdenId;
    if (ordenId == null) {
      _talker.cubit(
        'Se intento finalizar una orden sin seleccion previa.',
        logLevel: LogLevel.warning,
      );
      return const OrdenesActionResult.failure(
        'Selecciona una orden para continuar.',
      );
    }

    _talker.cubit(
      'Finalizando orden de produccion $ordenId con cantidadLados=${input.cantidadLados}.',
      logLevel: LogLevel.warning,
    );
    emit(state.copyWith(isSubmittingAction: true));
    try {
      final productoTerminado = await _repository.finalizeOrden(
        ordenId: ordenId,
        input: input,
      );
      await _reloadOrdenes(
        searchTerm: state.searchTerm,
        clienteId: state.selectedClienteId,
        loteId: state.selectedLoteId,
        estado: state.estadoFilter,
        preferredOrdenId: ordenId,
      );
      emit(
        state.copyWith(
          isSubmittingAction: false,
          productoTerminado: productoTerminado,
        ),
      );
      _talker.cubit(
        'Orden de produccion $ordenId finalizada correctamente.',
        logLevel: LogLevel.warning,
      );
      return const OrdenesActionResult.success(
        'Orden finalizada correctamente.',
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo finalizar la orden $ordenId: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return OrdenesActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al finalizar la orden $ordenId.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const OrdenesActionResult.failure(
        'No pudimos finalizar la orden.',
      );
    }
  }

  Future<void> _loadOrdenDetail(int ordenId) async {
    _talker.cubit('Cargando detalle operativo de la orden $ordenId.');
    emit(
      state.copyWith(
        isDetailLoading: true,
        clearSelectedOrden: true,
        clearSelectedProcesos: true,
        clearDetailError: true,
      ),
    );

    try {
      final orden = await _repository.getOrden(ordenId);
      final procesos = await _repository.listProcesos(ordenId);
      final consumoReal = await _repository.listConsumoReal(ordenId);
      final desviaciones = await _repository.listDesviaciones(ordenId);
      final mermas = await _repository.listMermas(ordenProduccionId: ordenId);
      final productoTerminado = await _repository.getProductoTerminadoByOrder(
        ordenId,
      );
      _talker.cubit(
        'Detalle de la orden $ordenId cargado con procesos=${procesos.length}, reales=${consumoReal.length}, desviaciones=${desviaciones.length}, mermas=${mermas.length}.',
        logLevel: LogLevel.debug,
      );

      emit(
        state.copyWith(
          isDetailLoading: false,
          selectedOrden: orden,
          selectedProcesos: procesos,
          consumoPlanificado: const [],
          consumoReal: consumoReal,
          desviaciones: desviaciones,
          mermas: mermas,
          productoTerminado: productoTerminado,
          clearDetailError: true,
        ),
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar el detalle de la orden $ordenId: ${exception.message}',
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
        'Fallo inesperado al cargar el detalle de la orden $ordenId.',
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

  Future<void> _reloadOrdenes({
    required String searchTerm,
    required int? clienteId,
    required int? loteId,
    required String? estado,
    int? preferredOrdenId,
  }) async {
    _talker.cubit(
      'Recargando ordenes con texto=${_describeText(searchTerm)}, clienteId=$clienteId, loteId=$loteId, estado=${_describeState(estado)}, preferida=${preferredOrdenId ?? state.selectedOrdenId}.',
      logLevel: LogLevel.debug,
    );
    final items = await _repository.listOrdenes(
      texto: searchTerm,
      clienteId: clienteId,
      loteId: loteId,
      estado: estado,
    );

    final currentSelectedId = preferredOrdenId ?? state.selectedOrdenId;
    final selectedOrdenId = items.any((item) => item.id == currentSelectedId)
        ? currentSelectedId
        : items.isNotEmpty
        ? items.first.id
        : null;
    _talker.cubit(
      'Recarga de ordenes completada con ${items.length} resultados. Seleccion actual=${selectedOrdenId ?? 'ninguna'}.',
      logLevel: LogLevel.debug,
    );

    emit(
      state.copyWith(
        status: OrdenesProduccionStatus.success,
        items: items,
        selectedOrdenId: selectedOrdenId,
        searchTerm: searchTerm,
        selectedClienteId: clienteId,
        selectedLoteId: loteId,
        estadoFilter: estado,
        clearError: true,
      ),
    );

    if (selectedOrdenId == null) {
      emit(
        state.copyWith(
          isDetailLoading: false,
          clearSelectedOrden: true,
          clearSelectedProcesos: true,
          clearDetailError: true,
        ),
      );
      _talker.cubit(
        'No hay orden seleccionada despues de la recarga.',
        logLevel: LogLevel.debug,
      );
      return;
    }

    await _loadOrdenDetail(selectedOrdenId);
  }

  String _describeText(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
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
