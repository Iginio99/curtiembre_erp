import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/production/clientes/domain/repositories/clientes_repository.dart';
import 'package:erp_curtiembre_fronted/features/production/clientes/presentation/cubit/clientes_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';

class ClientesActionResult {
  const ClientesActionResult._({required this.success, required this.message});

  const ClientesActionResult.success(String message)
    : this._(success: true, message: message);

  const ClientesActionResult.failure(String message)
    : this._(success: false, message: message);

  final bool success;
  final String message;
}

class ClientesCubit extends Cubit<ClientesState> {
  ClientesCubit(this._repository, this._talker)
    : super(const ClientesState.loading());

  final ClientesRepository _repository;
  final Talker _talker;

  Future<void> initialize() async {
    _talker.cubit('Inicializando modulo de clientes de produccion.');
    emit(const ClientesState.loading());
    await load();
  }

  Future<void> load({String? searchTerm, ClienteActivityFilter? filter}) async {
    final nextSearchTerm = searchTerm ?? state.searchTerm;
    final nextFilter = filter ?? state.filter;
    _talker.cubit(
      'Cargando clientes con filtros texto=${_describeSearchTerm(nextSearchTerm)}, filtro=$nextFilter.',
    );

    emit(
      state.copyWith(
        status: ClientesStatus.loading,
        searchTerm: nextSearchTerm,
        filter: nextFilter,
        clearError: true,
      ),
    );

    try {
      await _reloadClientes(searchTerm: nextSearchTerm, filter: nextFilter);
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar la lista de clientes: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(
        state.copyWith(
          status: ClientesStatus.error,
          errorMessage: exception.message,
        ),
      );
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al cargar la lista de clientes.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          status: ClientesStatus.error,
          errorMessage: 'No pudimos cargar los clientes. Intenta nuevamente.',
        ),
      );
    }
  }

  Future<void> selectCliente(int clienteId) async {
    if (state.selectedClienteId == clienteId &&
        state.selectedCliente?.id == clienteId) {
      _talker.cubit(
        'Se ignoro la seleccion del cliente $clienteId porque ya estaba cargado.',
        logLevel: LogLevel.debug,
      );
      return;
    }

    _talker.cubit('Seleccionando cliente $clienteId para ver detalle.');
    emit(state.copyWith(selectedClienteId: clienteId, clearDetailError: true));

    await _loadClienteDetail(clienteId);
  }

  Future<void> retryDetail() async {
    final clienteId = state.selectedClienteId;
    if (clienteId == null) {
      _talker.cubit(
        'Se intento reintentar detalle sin un cliente seleccionado.',
        logLevel: LogLevel.warning,
      );
      return;
    }

    _talker.cubit('Reintentando carga de detalle para el cliente $clienteId.');
    await _loadClienteDetail(clienteId);
  }

  Future<ClientesActionResult> createCliente({
    required String rucDocumento,
    required String razonSocial,
    String? direccion,
    String? celular,
    String? correo,
    String? contacto,
  }) async {
    _talker.cubit(
      'Iniciando creacion de cliente razonSocial=$razonSocial, rucDocumento=${_describeIdentifier(rucDocumento)}.',
    );
    emit(state.copyWith(isSubmittingAction: true));

    try {
      final cliente = await _repository.createCliente(
        rucDocumento: rucDocumento,
        razonSocial: razonSocial,
        direccion: direccion,
        celular: celular,
        correo: correo,
        contacto: contacto,
      );

      await _reloadClientes(
        searchTerm: state.searchTerm,
        filter: state.filter,
        preferredClienteId: cliente.id,
      );

      emit(state.copyWith(isSubmittingAction: false));
      _talker.cubit(
        'Cliente creado correctamente con razonSocial=$razonSocial.',
      );
      return const ClientesActionResult.success(
        'Cliente creado correctamente.',
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo crear el cliente razonSocial=$razonSocial: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return ClientesActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al crear el cliente razonSocial=$razonSocial.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const ClientesActionResult.failure(
        'No pudimos crear el cliente. Intenta nuevamente.',
      );
    }
  }

  Future<ClientesActionResult> updateSelectedCliente({
    required String rucDocumento,
    required String razonSocial,
    String? direccion,
    String? celular,
    String? correo,
    String? contacto,
  }) async {
    final clienteId = state.selectedClienteId;
    if (clienteId == null) {
      _talker.cubit(
        'Se intento editar un cliente sin seleccion previa.',
        logLevel: LogLevel.warning,
      );
      return const ClientesActionResult.failure(
        'Selecciona un cliente para editar.',
      );
    }

    _talker.cubit(
      'Iniciando actualizacion del cliente $clienteId con razonSocial=$razonSocial, rucDocumento=${_describeIdentifier(rucDocumento)}.',
    );
    emit(state.copyWith(isSubmittingAction: true));

    try {
      await _repository.updateCliente(
        id: clienteId,
        rucDocumento: rucDocumento,
        razonSocial: razonSocial,
        direccion: direccion,
        celular: celular,
        correo: correo,
        contacto: contacto,
      );

      await _reloadClientes(
        searchTerm: state.searchTerm,
        filter: state.filter,
        preferredClienteId: clienteId,
      );

      emit(state.copyWith(isSubmittingAction: false));
      _talker.cubit('Cliente $clienteId actualizado correctamente.');
      return const ClientesActionResult.success(
        'Cliente actualizado correctamente.',
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo actualizar el cliente $clienteId: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return ClientesActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al actualizar el cliente $clienteId.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const ClientesActionResult.failure(
        'No pudimos actualizar el cliente. Intenta nuevamente.',
      );
    }
  }

  Future<ClientesActionResult> setSelectedClienteActive(bool active) async {
    final clienteId = state.selectedClienteId;
    if (clienteId == null) {
      _talker.cubit(
        'Se intento cambiar el estado de un cliente sin seleccion previa.',
        logLevel: LogLevel.warning,
      );
      return const ClientesActionResult.failure(
        'Selecciona un cliente para continuar.',
      );
    }

    _talker.cubit(
      active
          ? 'Iniciando activacion del cliente $clienteId.'
          : 'Iniciando inactivacion del cliente $clienteId.',
      logLevel: LogLevel.warning,
    );
    emit(state.copyWith(isSubmittingAction: true));

    try {
      await _repository.setClienteActive(id: clienteId, active: active);

      await _reloadClientes(
        searchTerm: state.searchTerm,
        filter: state.filter,
        preferredClienteId: clienteId,
      );

      emit(state.copyWith(isSubmittingAction: false));
      _talker.cubit(
        active
            ? 'Cliente $clienteId activado correctamente.'
            : 'Cliente $clienteId inactivado correctamente.',
        logLevel: LogLevel.warning,
      );
      return ClientesActionResult.success(
        active
            ? 'Cliente activado correctamente.'
            : 'Cliente inactivado correctamente.',
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        active
            ? 'No se pudo activar el cliente $clienteId: ${exception.message}'
            : 'No se pudo inactivar el cliente $clienteId: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return ClientesActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        active
            ? 'Fallo inesperado al activar el cliente $clienteId.'
            : 'Fallo inesperado al inactivar el cliente $clienteId.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return ClientesActionResult.failure(
        active
            ? 'No pudimos activar el cliente.'
            : 'No pudimos inactivar el cliente.',
      );
    }
  }

  Future<void> _loadClienteDetail(int clienteId) async {
    _talker.cubit('Cargando detalle del cliente $clienteId.');
    emit(
      state.copyWith(
        isDetailLoading: true,
        clearSelectedCliente: true,
        clearDetailError: true,
      ),
    );

    try {
      final cliente = await _repository.getCliente(clienteId);
      _talker.cubit('Detalle del cliente $clienteId cargado correctamente.');
      emit(
        state.copyWith(
          isDetailLoading: false,
          selectedCliente: cliente,
          clearDetailError: true,
        ),
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar el detalle del cliente $clienteId: ${exception.message}',
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
        'Fallo inesperado al cargar el detalle del cliente $clienteId.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          isDetailLoading: false,
          detailErrorMessage: 'No pudimos cargar el detalle del cliente.',
        ),
      );
    }
  }

  Future<void> _reloadClientes({
    required String searchTerm,
    required ClienteActivityFilter filter,
    int? preferredClienteId,
  }) async {
    _talker.cubit(
      'Recargando clientes con texto=${_describeSearchTerm(searchTerm)}, filtro=$filter, preferido=${preferredClienteId ?? state.selectedClienteId}.',
      logLevel: LogLevel.debug,
    );
    final items = await _repository.listClientes(
      texto: searchTerm,
      activo: _mapFilter(filter),
    );

    final currentSelectedId = preferredClienteId ?? state.selectedClienteId;
    final selectedClienteId = items.any((item) => item.id == currentSelectedId)
        ? currentSelectedId
        : items.isNotEmpty
        ? items.first.id
        : null;
    _talker.cubit(
      'Recarga de clientes completada con ${items.length} resultados. Seleccion actual=${selectedClienteId ?? 'ninguna'}.',
      logLevel: LogLevel.debug,
    );

    emit(
      state.copyWith(
        status: ClientesStatus.success,
        items: items,
        selectedClienteId: selectedClienteId,
        searchTerm: searchTerm,
        filter: filter,
        clearError: true,
      ),
    );

    if (selectedClienteId == null) {
      emit(
        state.copyWith(
          isDetailLoading: false,
          clearSelectedCliente: true,
          clearDetailError: true,
        ),
      );
      _talker.cubit(
        'No hay cliente seleccionado despues de la recarga.',
        logLevel: LogLevel.debug,
      );
      return;
    }

    await _loadClienteDetail(selectedClienteId);
  }

  bool? _mapFilter(ClienteActivityFilter filter) {
    return switch (filter) {
      ClienteActivityFilter.active => true,
      ClienteActivityFilter.inactive => false,
      ClienteActivityFilter.all => null,
    };
  }

  String _describeSearchTerm(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return 'vacio';
    }

    return '${normalized.length} caracteres';
  }

  String _describeIdentifier(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return 'vacio';
    }

    return '${normalized.length} caracteres';
  }
}
