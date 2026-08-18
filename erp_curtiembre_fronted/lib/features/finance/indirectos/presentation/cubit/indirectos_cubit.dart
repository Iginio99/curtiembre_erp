import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/finance/indirectos/domain/repositories/indirectos_repository.dart';
import 'package:erp_curtiembre_fronted/features/finance/indirectos/presentation/cubit/indirectos_state.dart';
import 'package:erp_curtiembre_fronted/features/finance/periodos/domain/repositories/periodos_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';

class IndirectosActionResult {
  const IndirectosActionResult._({
    required this.success,
    required this.message,
  });

  const IndirectosActionResult.success(String message)
    : this._(success: true, message: message);

  const IndirectosActionResult.failure(String message)
    : this._(success: false, message: message);

  final bool success;
  final String message;
}

class IndirectosCubit extends Cubit<IndirectosState> {
  IndirectosCubit(this._repository, this._periodosRepository, this._talker)
    : super(const IndirectosState.loading());

  final IndirectosRepository _repository;
  final PeriodosRepository _periodosRepository;
  final Talker _talker;

  Future<void> initialize() async {
    _talker.cubit('Inicializando modulo de costos indirectos.');
    emit(const IndirectosState.loading());

    try {
      final periodos = await _periodosRepository.listPeriodos();
      _talker.cubit(
        'Base de costos indirectos preparada con ${periodos.length} periodos.',
        logLevel: LogLevel.debug,
      );
      emit(state.copyWith(periodoOptions: periodos));
      await load();
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar la base de costos indirectos: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(
        state.copyWith(
          status: IndirectosStatus.error,
          errorMessage: exception.message,
        ),
      );
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al cargar la base de costos indirectos.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          status: IndirectosStatus.error,
          errorMessage: 'No pudimos cargar la base de costos indirectos.',
        ),
      );
    }
  }

  Future<void> load({
    int? periodoCostoIdFilter,
    String? tipoCostoFilter,
    String? searchTerm,
  }) async {
    final nextPeriodoFilter =
        periodoCostoIdFilter ?? state.periodoCostoIdFilter;
    final nextTipoFilter = tipoCostoFilter ?? state.tipoCostoFilter;
    final nextSearchTerm = searchTerm ?? state.searchTerm;
    _talker.cubit(
      'Cargando costos indirectos con periodoCostoId=$nextPeriodoFilter, tipoCosto=${_describeType(nextTipoFilter)}, busqueda=${_describeText(nextSearchTerm)}.',
    );

    emit(
      state.copyWith(
        status: IndirectosStatus.loading,
        periodoCostoIdFilter: nextPeriodoFilter,
        tipoCostoFilter: nextTipoFilter,
        searchTerm: nextSearchTerm,
        clearError: true,
      ),
    );

    try {
      await _reloadIndirectos(
        periodoCostoIdFilter: nextPeriodoFilter,
        tipoCostoFilter: nextTipoFilter,
        searchTerm: nextSearchTerm,
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar la lista de costos indirectos: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(
        state.copyWith(
          status: IndirectosStatus.error,
          errorMessage: exception.message,
        ),
      );
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al cargar la lista de costos indirectos.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          status: IndirectosStatus.error,
          errorMessage:
              'No pudimos cargar los costos indirectos. Intenta nuevamente.',
        ),
      );
    }
  }

  Future<void> selectIndirecto(int indirectoId) async {
    if (state.selectedIndirectoId == indirectoId &&
        state.selectedIndirecto?.id == indirectoId) {
      _talker.cubit(
        'Se ignoro la seleccion del costo indirecto $indirectoId porque ya estaba cargado.',
        logLevel: LogLevel.debug,
      );
      return;
    }

    _talker.cubit(
      'Seleccionando costo indirecto $indirectoId para ver detalle.',
    );
    emit(
      state.copyWith(selectedIndirectoId: indirectoId, clearDetailError: true),
    );
    await _loadIndirectoDetail(indirectoId);
  }

  Future<void> retryDetail() async {
    final indirectoId = state.selectedIndirectoId;
    if (indirectoId == null) {
      _talker.cubit(
        'Se intento reintentar detalle sin un costo indirecto seleccionado.',
        logLevel: LogLevel.warning,
      );
      return;
    }
    _talker.cubit(
      'Reintentando carga de detalle para el costo indirecto $indirectoId.',
    );
    await _loadIndirectoDetail(indirectoId);
  }

  Future<IndirectosActionResult> createIndirecto({
    required int periodoCostoId,
    required String tipoCosto,
    String? descripcion,
    required double monto,
  }) async {
    _talker.cubit(
      'Creando costo indirecto con periodoCostoId=$periodoCostoId, tipoCosto=${_describeType(tipoCosto)}, descripcion=${_describeText(descripcion)}, monto=$monto.',
      logLevel: LogLevel.warning,
    );
    emit(state.copyWith(isSubmittingAction: true));

    try {
      final indirecto = await _repository.createIndirecto(
        periodoCostoId: periodoCostoId,
        tipoCosto: tipoCosto,
        descripcion: descripcion,
        monto: monto,
      );

      await _reloadIndirectos(
        periodoCostoIdFilter: state.periodoCostoIdFilter,
        tipoCostoFilter: state.tipoCostoFilter,
        searchTerm: state.searchTerm,
        preferredIndirectoId: indirecto.id,
      );

      emit(state.copyWith(isSubmittingAction: false));
      _talker.cubit(
        'Costo indirecto creado correctamente con id=${indirecto.id}.',
        logLevel: LogLevel.warning,
      );
      return const IndirectosActionResult.success(
        'Costo indirecto registrado correctamente.',
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo crear el costo indirecto: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return IndirectosActionResult.failure(exception.message);
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al crear el costo indirecto.',
        logLevel: LogLevel.error,
      );
      emit(state.copyWith(isSubmittingAction: false));
      return const IndirectosActionResult.failure(
        'No pudimos registrar el costo indirecto. Intenta nuevamente.',
      );
    }
  }

  Future<void> _loadIndirectoDetail(int indirectoId) async {
    _talker.cubit('Cargando detalle del costo indirecto $indirectoId.');
    emit(
      state.copyWith(
        isDetailLoading: true,
        clearSelectedIndirecto: true,
        clearDetailError: true,
      ),
    );

    try {
      final indirecto = await _repository.getIndirecto(indirectoId);
      _talker.cubit(
        'Detalle del costo indirecto $indirectoId cargado correctamente.',
        logLevel: LogLevel.debug,
      );
      emit(
        state.copyWith(
          isDetailLoading: false,
          selectedIndirecto: indirecto,
          clearDetailError: true,
        ),
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar el detalle del costo indirecto $indirectoId: ${exception.message}',
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
        'Fallo inesperado al cargar el detalle del costo indirecto $indirectoId.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          isDetailLoading: false,
          detailErrorMessage:
              'No pudimos cargar el detalle del costo indirecto.',
        ),
      );
    }
  }

  Future<void> _reloadIndirectos({
    required int? periodoCostoIdFilter,
    required String? tipoCostoFilter,
    required String searchTerm,
    int? preferredIndirectoId,
  }) async {
    _talker.cubit(
      'Recargando costos indirectos con periodoCostoId=$periodoCostoIdFilter, tipoCosto=${_describeType(tipoCostoFilter)}, busqueda=${_describeText(searchTerm)}, preferido=${preferredIndirectoId ?? state.selectedIndirectoId ?? 'ninguno'}.',
      logLevel: LogLevel.debug,
    );
    final items = await _repository.listIndirectos(
      periodoCostoId: periodoCostoIdFilter,
      tipoCosto: tipoCostoFilter,
      texto: searchTerm,
    );

    final currentSelectedId = preferredIndirectoId ?? state.selectedIndirectoId;
    final selectedIndirectoId =
        items.any((item) => item.id == currentSelectedId)
        ? currentSelectedId
        : items.isNotEmpty
        ? items.first.id
        : null;
    _talker.cubit(
      'Recarga de costos indirectos completada con ${items.length} resultados. Seleccion actual=${selectedIndirectoId ?? 'ninguna'}.',
      logLevel: LogLevel.debug,
    );

    emit(
      state.copyWith(
        status: IndirectosStatus.success,
        items: items,
        selectedIndirectoId: selectedIndirectoId,
        periodoCostoIdFilter: periodoCostoIdFilter,
        tipoCostoFilter: tipoCostoFilter,
        searchTerm: searchTerm,
        clearError: true,
      ),
    );

    if (selectedIndirectoId == null) {
      emit(
        state.copyWith(
          isDetailLoading: false,
          clearSelectedIndirecto: true,
          clearDetailError: true,
        ),
      );
      _talker.cubit(
        'No hay costo indirecto seleccionado despues de la recarga.',
        logLevel: LogLevel.debug,
      );
      return;
    }

    await _loadIndirectoDetail(selectedIndirectoId);
  }

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
