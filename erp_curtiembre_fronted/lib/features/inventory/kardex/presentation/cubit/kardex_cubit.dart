import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/inventory/kardex/domain/repositories/kardex_repository.dart';
import 'package:erp_curtiembre_fronted/features/inventory/kardex/presentation/cubit/kardex_state.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/domain/entities/insumo_lookup.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';

class KardexCubit extends Cubit<KardexState> {
  static const Object _sentinel = Object();

  KardexCubit(this._repository, this._talker)
    : super(const KardexState.loading());

  final KardexRepository _repository;
  final Talker _talker;

  Future<void> initialize() async {
    _talker.cubit('Inicializando modulo de kardex.');
    emit(const KardexState.loading());

    try {
      final insumos = await _repository.listActiveInsumos();
      _talker.cubit(
        'Catalogo base de kardex cargado con ${insumos.length} insumos activos.',
        logLevel: LogLevel.debug,
      );
      emit(state.copyWith(insumos: insumos));
      await load();
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar la base de kardex: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(
        state.copyWith(
          status: KardexStatus.error,
          errorMessage: exception.message,
        ),
      );
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al cargar la base de kardex.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          status: KardexStatus.error,
          errorMessage: 'No pudimos cargar la base de kardex.',
        ),
      );
    }
  }

  Future<void> load({
    Object? selectedInsumoId = _sentinel,
    Object? tipoMovimientoFilter = _sentinel,
    Object? documentoTipoFilter = _sentinel,
    Object? usuarioResponsableIdFilter = _sentinel,
    Object? fechaDesde = _sentinel,
    Object? fechaHasta = _sentinel,
  }) async {
    final nextInsumoId = identical(selectedInsumoId, _sentinel)
        ? state.selectedInsumoId
        : selectedInsumoId as int?;
    final nextTipoMovimiento = identical(tipoMovimientoFilter, _sentinel)
        ? state.tipoMovimientoFilter
        : tipoMovimientoFilter as String?;
    final nextDocumentoTipo = identical(documentoTipoFilter, _sentinel)
        ? state.documentoTipoFilter
        : documentoTipoFilter as String?;
    final nextUsuarioResponsableId =
        identical(usuarioResponsableIdFilter, _sentinel)
        ? state.usuarioResponsableIdFilter
        : usuarioResponsableIdFilter as int?;
    final nextFechaDesde = identical(fechaDesde, _sentinel)
        ? state.fechaDesde
        : fechaDesde as DateTime?;
    final nextFechaHasta = identical(fechaHasta, _sentinel)
        ? state.fechaHasta
        : fechaHasta as DateTime?;
    _talker.cubit(
      'Cargando kardex con insumoId=$nextInsumoId, tipoMovimiento=${_describeState(nextTipoMovimiento)}, documentoTipo=${_describeState(nextDocumentoTipo)}, usuarioResponsableId=$nextUsuarioResponsableId, fechaDesde=${_describeDate(nextFechaDesde)}, fechaHasta=${_describeDate(nextFechaHasta)}.',
    );

    emit(
      state.copyWith(
        status: KardexStatus.loading,
        selectedInsumoId: nextInsumoId,
        tipoMovimientoFilter: nextTipoMovimiento,
        documentoTipoFilter: nextDocumentoTipo,
        usuarioResponsableIdFilter: nextUsuarioResponsableId,
        fechaDesde: nextFechaDesde,
        fechaHasta: nextFechaHasta,
        clearError: true,
      ),
    );

    try {
      final items = nextInsumoId == null
          ? await _repository.listKardex(
              tipoMovimiento: nextTipoMovimiento,
              documentoTipo: nextDocumentoTipo,
              usuarioResponsableId: nextUsuarioResponsableId,
              fechaDesde: nextFechaDesde,
              fechaHasta: nextFechaHasta,
            )
          : await _repository.listKardexByInsumo(
              nextInsumoId,
              tipoMovimiento: nextTipoMovimiento,
              documentoTipo: nextDocumentoTipo,
              usuarioResponsableId: nextUsuarioResponsableId,
              fechaDesde: nextFechaDesde,
              fechaHasta: nextFechaHasta,
            );

      emit(state.copyWith(status: KardexStatus.success, items: items));
      _talker.cubit(
        'Kardex cargado correctamente con ${items.length} movimientos.',
        logLevel: LogLevel.debug,
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar el kardex: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(
        state.copyWith(
          status: KardexStatus.error,
          errorMessage: exception.message,
        ),
      );
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al cargar el kardex.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          status: KardexStatus.error,
          errorMessage: 'No pudimos cargar el kardex. Intenta nuevamente.',
        ),
      );
    }
  }

  List<InsumoLookup> get insumos => state.insumos;

  String _describeState(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return normalized;
  }

  String _describeDate(DateTime? value) {
    if (value == null) {
      return 'sin-filtro';
    }

    return value.toIso8601String();
  }
}
