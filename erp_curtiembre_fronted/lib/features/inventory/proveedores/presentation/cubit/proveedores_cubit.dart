import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/inventory/proveedores/domain/repositories/proveedores_repository.dart';
import 'package:erp_curtiembre_fronted/features/inventory/proveedores/presentation/cubit/proveedores_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';

class ProveedoresActionResult {
  const ProveedoresActionResult._({
    required this.success,
    required this.message,
  });

  const ProveedoresActionResult.success(String message)
    : this._(success: true, message: message);

  const ProveedoresActionResult.failure(String message)
    : this._(success: false, message: message);

  final bool success;
  final String message;
}

class ProveedoresCubit extends Cubit<ProveedoresState> {
  ProveedoresCubit(this._repository, this._talker)
    : super(const ProveedoresState.loading());

  final ProveedoresRepository _repository;
  final Talker _talker;

  Future<void> initialize() async {
    _talker.cubit('Inicializando modulo de proveedores.');
    emit(const ProveedoresState.loading());
    await load();
  }

  Future<void> load({
    String? searchTerm,
    ProveedorActivityFilter? filter,
  }) async {
    final nextSearchTerm = searchTerm ?? state.searchTerm;
    final nextFilter = filter ?? state.filter;
    _talker.cubit(
      'Cargando proveedores con busqueda=${_describeText(nextSearchTerm)}, actividad=${_describeActivityFilter(nextFilter)}.',
    );

    emit(
      state.copyWith(
        status: ProveedoresStatus.loading,
        searchTerm: nextSearchTerm,
        filter: nextFilter,
        clearError: true,
      ),
    );

    try {
      await _reloadProveedores(searchTerm: nextSearchTerm, filter: nextFilter);
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar la lista de proveedores: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(
        state.copyWith(
          status: ProveedoresStatus.error,
          errorMessage: exception.message,
        ),
      );
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al cargar la lista de proveedores.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          status: ProveedoresStatus.error,
          errorMessage:
              'No pudimos cargar los proveedores. Intenta nuevamente.',
        ),
      );
    }
  }

  Future<void> selectProveedor(int proveedorId) async {
    if (state.selectedProveedorId == proveedorId &&
        state.selectedProveedor?.id == proveedorId) {
      _talker.cubit(
        'Se ignoro la seleccion del proveedor $proveedorId porque ya estaba cargado.',
        logLevel: LogLevel.debug,
      );
      return;
    }

    _talker.cubit('Seleccionando proveedor $proveedorId para ver detalle.');
    emit(
      state.copyWith(selectedProveedorId: proveedorId, clearDetailError: true),
    );

    await _loadProveedorDetail(proveedorId);
  }

  Future<void> retryDetail() async {
    final proveedorId = state.selectedProveedorId;
    if (proveedorId == null) {
      _talker.cubit(
        'Se intento reintentar detalle sin un proveedor seleccionado.',
        logLevel: LogLevel.warning,
      );
      return;
    }

    _talker.cubit(
      'Reintentando carga de detalle para el proveedor $proveedorId.',
    );
    await _loadProveedorDetail(proveedorId);
  }

  Future<ProveedoresActionResult> createProveedor({
    required String rucDocumento,
    required String razonSocial,
    String? direccion,
    String? telefono,
    String? correo,
    String? contacto,
  }) async {
    _talker.cubit(
      'Creando proveedor con ruc=${_describeText(rucDocumento)}, razonSocial=${_describeText(razonSocial)}.',
    );
    emit(state.copyWith(isSubmittingAction: true));

    try {
      final proveedor = await _repository.createProveedor(
        rucDocumento: rucDocumento,
        razonSocial: razonSocial,
        direccion: direccion,
        telefono: telefono,
        correo: correo,
        contacto: contacto,
      );

      await _reloadProveedores(
        searchTerm: state.searchTerm,
        filter: state.filter,
        preferredProveedorId: proveedor.id,
      );

      emit(state.copyWith(isSubmittingAction: false));
      _talker.cubit('Proveedor creado correctamente con id=${proveedor.id}.');
      return const ProveedoresActionResult.success(
        'Proveedor creado correctamente.',
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo crear el proveedor: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return ProveedoresActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al crear el proveedor.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const ProveedoresActionResult.failure(
        'No pudimos crear el proveedor. Intenta nuevamente.',
      );
    }
  }

  Future<ProveedoresActionResult> updateSelectedProveedor({
    required String rucDocumento,
    required String razonSocial,
    String? direccion,
    String? telefono,
    String? correo,
    String? contacto,
  }) async {
    final proveedorId = state.selectedProveedorId;
    if (proveedorId == null) {
      _talker.cubit(
        'Se intento editar un proveedor sin seleccion previa.',
        logLevel: LogLevel.warning,
      );
      return const ProveedoresActionResult.failure(
        'Selecciona un proveedor para editar.',
      );
    }

    _talker.cubit(
      'Actualizando proveedor $proveedorId con ruc=${_describeText(rucDocumento)}, razonSocial=${_describeText(razonSocial)}.',
      logLevel: LogLevel.warning,
    );
    emit(state.copyWith(isSubmittingAction: true));

    try {
      await _repository.updateProveedor(
        id: proveedorId,
        rucDocumento: rucDocumento,
        razonSocial: razonSocial,
        direccion: direccion,
        telefono: telefono,
        correo: correo,
        contacto: contacto,
      );

      await _reloadProveedores(
        searchTerm: state.searchTerm,
        filter: state.filter,
        preferredProveedorId: proveedorId,
      );

      emit(state.copyWith(isSubmittingAction: false));
      _talker.cubit(
        'Proveedor $proveedorId actualizado correctamente.',
        logLevel: LogLevel.warning,
      );
      return const ProveedoresActionResult.success(
        'Proveedor actualizado correctamente.',
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo actualizar el proveedor $proveedorId: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return ProveedoresActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al actualizar el proveedor $proveedorId.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const ProveedoresActionResult.failure(
        'No pudimos actualizar el proveedor. Intenta nuevamente.',
      );
    }
  }

  Future<ProveedoresActionResult> setSelectedProveedorActive(
    bool active,
  ) async {
    final proveedorId = state.selectedProveedorId;
    if (proveedorId == null) {
      _talker.cubit(
        'Se intento cambiar el estado de un proveedor sin seleccion previa.',
        logLevel: LogLevel.warning,
      );
      return const ProveedoresActionResult.failure(
        'Selecciona un proveedor para continuar.',
      );
    }

    _talker.cubit(
      '${active ? 'Activando' : 'Inactivando'} proveedor $proveedorId.',
      logLevel: LogLevel.warning,
    );
    emit(state.copyWith(isSubmittingAction: true));

    try {
      await _repository.setProveedorActive(id: proveedorId, active: active);

      await _reloadProveedores(
        searchTerm: state.searchTerm,
        filter: state.filter,
        preferredProveedorId: proveedorId,
      );

      emit(state.copyWith(isSubmittingAction: false));
      _talker.cubit(
        'Proveedor $proveedorId ${active ? 'activado' : 'inactivado'} correctamente.',
        logLevel: LogLevel.warning,
      );
      return ProveedoresActionResult.success(
        active
            ? 'Proveedor activado correctamente.'
            : 'Proveedor inactivado correctamente.',
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo ${active ? 'activar' : 'inactivar'} el proveedor $proveedorId: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return ProveedoresActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al ${active ? 'activar' : 'inactivar'} el proveedor $proveedorId.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return ProveedoresActionResult.failure(
        active
            ? 'No pudimos activar el proveedor.'
            : 'No pudimos inactivar el proveedor.',
      );
    }
  }

  Future<void> _loadProveedorDetail(int proveedorId) async {
    _talker.cubit('Cargando detalle del proveedor $proveedorId.');
    emit(
      state.copyWith(
        isDetailLoading: true,
        clearSelectedProveedor: true,
        clearDetailError: true,
      ),
    );

    try {
      final proveedor = await _repository.getProveedor(proveedorId);
      _talker.cubit(
        'Detalle del proveedor $proveedorId cargado correctamente.',
        logLevel: LogLevel.debug,
      );
      emit(
        state.copyWith(
          isDetailLoading: false,
          selectedProveedor: proveedor,
          clearDetailError: true,
        ),
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar el detalle del proveedor $proveedorId: ${exception.message}',
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
        'Fallo inesperado al cargar el detalle del proveedor $proveedorId.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          isDetailLoading: false,
          detailErrorMessage: 'No pudimos cargar el detalle del proveedor.',
        ),
      );
    }
  }

  Future<void> _reloadProveedores({
    required String searchTerm,
    required ProveedorActivityFilter filter,
    int? preferredProveedorId,
  }) async {
    _talker.cubit(
      'Recargando proveedores con busqueda=${_describeText(searchTerm)}, actividad=${_describeActivityFilter(filter)}, preferido=${preferredProveedorId ?? state.selectedProveedorId ?? 'ninguno'}.',
      logLevel: LogLevel.debug,
    );
    final items = await _repository.listProveedores(
      texto: searchTerm,
      activo: _mapFilter(filter),
    );

    final currentSelectedId = preferredProveedorId ?? state.selectedProveedorId;
    final selectedProveedorId =
        items.any((item) => item.id == currentSelectedId)
        ? currentSelectedId
        : items.isNotEmpty
        ? items.first.id
        : null;
    _talker.cubit(
      'Recarga de proveedores completada con ${items.length} resultados. Seleccion actual=${selectedProveedorId ?? 'ninguna'}.',
      logLevel: LogLevel.debug,
    );

    emit(
      state.copyWith(
        status: ProveedoresStatus.success,
        items: items,
        selectedProveedorId: selectedProveedorId,
        searchTerm: searchTerm,
        filter: filter,
        clearError: true,
      ),
    );

    if (selectedProveedorId == null) {
      emit(
        state.copyWith(
          isDetailLoading: false,
          clearSelectedProveedor: true,
          clearDetailError: true,
        ),
      );
      _talker.cubit(
        'No hay proveedor seleccionado despues de la recarga.',
        logLevel: LogLevel.debug,
      );
      return;
    }

    await _loadProveedorDetail(selectedProveedorId);
  }

  bool? _mapFilter(ProveedorActivityFilter filter) {
    return switch (filter) {
      ProveedorActivityFilter.active => true,
      ProveedorActivityFilter.inactive => false,
      ProveedorActivityFilter.all => null,
    };
  }

  String _describeText(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return '${normalized.length} caracteres';
  }

  String _describeActivityFilter(ProveedorActivityFilter value) {
    return switch (value) {
      ProveedorActivityFilter.active => 'activos',
      ProveedorActivityFilter.inactive => 'inactivos',
      ProveedorActivityFilter.all => 'todos',
    };
  }
}
