import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/alerts/domain/repositories/alerts_repository.dart';
import 'package:erp_curtiembre_fronted/features/alerts/presentation/cubit/alerts_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AlertsCubit extends Cubit<AlertsState> {
  static const Object _sentinel = Object();

  AlertsCubit(this._repository) : super(const AlertsState.loading());

  final AlertsRepository _repository;

  Future<void> initialize() async {
    emit(const AlertsState.loading());

    try {
      final summaryFuture = _repository.getSummary();
      final alertsFuture = _repository.listAlerts();

      final summary = await summaryFuture;
      final alerts = await alertsFuture;

      emit(
        state.copyWith(
          status: AlertsStatus.success,
          summary: summary,
          alerts: alerts,
          errorMessage: null,
        ),
      );

      if (alerts.isNotEmpty) {
        await selectAlert(alerts.first.id);
      }
    } on ApiException catch (exception) {
      emit(state.copyWith(status: AlertsStatus.error, errorMessage: exception.message));
    } catch (_) {
      emit(
        state.copyWith(
          status: AlertsStatus.error,
          errorMessage: 'No pudimos cargar la bandeja de alertas.',
        ),
      );
    }
  }

  Future<void> loadHomeSummary() async {
    emit(const AlertsState.loading());

    try {
      final summary = await _repository.getSummary();
      emit(
        state.copyWith(
          status: AlertsStatus.success,
          summary: summary,
          alerts: summary.recientes,
          errorMessage: null,
        ),
      );
    } on ApiException catch (exception) {
      emit(state.copyWith(status: AlertsStatus.error, errorMessage: exception.message));
    } catch (_) {
      emit(
        state.copyWith(
          status: AlertsStatus.error,
          errorMessage: 'No pudimos cargar el resumen de alertas.',
        ),
      );
    }
  }

  Future<void> applyFilters({
    Object? estado = _sentinel,
    Object? severidad = _sentinel,
    Object? tipoAlerta = _sentinel,
    Object? moduloOrigen = _sentinel,
  }) async {
    final nextEstado =
        identical(estado, _sentinel) ? state.estadoFilter : estado as String?;
    final nextSeveridad = identical(severidad, _sentinel)
        ? state.severidadFilter
        : severidad as String?;
    final nextTipo = identical(tipoAlerta, _sentinel)
        ? state.tipoAlertaFilter
        : tipoAlerta as String?;
    final nextModulo = identical(moduloOrigen, _sentinel)
        ? state.moduloOrigenFilter
        : moduloOrigen as String?;

    emit(
      state.copyWith(
        loadingList: true,
        errorMessage: null,
        estadoFilter: nextEstado,
        severidadFilter: nextSeveridad,
        tipoAlertaFilter: nextTipo,
        moduloOrigenFilter: nextModulo,
      ),
    );

    try {
      final alerts = await _repository.listAlerts(
        estado: nextEstado,
        severidad: nextSeveridad,
        tipoAlerta: nextTipo,
        moduloOrigen: nextModulo,
      );
      emit(state.copyWith(loadingList: false, alerts: alerts));

      if (alerts.isEmpty) {
        emit(state.copyWith(selectedAlert: null, history: const []));
      } else if (state.selectedAlert == null ||
          alerts.every((item) => item.id != state.selectedAlert!.id)) {
        await selectAlert(alerts.first.id);
      }
    } on ApiException catch (exception) {
      emit(state.copyWith(loadingList: false, errorMessage: exception.message));
    } catch (_) {
      emit(
        state.copyWith(
          loadingList: false,
          errorMessage: 'No pudimos actualizar la bandeja de alertas.',
        ),
      );
    }
  }

  Future<void> clearFilters() async {
    await applyFilters(
      estado: null,
      severidad: null,
      tipoAlerta: null,
      moduloOrigen: null,
    );
  }

  Future<void> selectAlert(int id) async {
    emit(state.copyWith(loadingDetail: true, errorMessage: null));

    try {
      final detailFuture = _repository.getAlert(id);
      final historyFuture = _repository.getHistory(id);
      final detail = await detailFuture;
      final history = await historyFuture;
      emit(
        state.copyWith(
          loadingDetail: false,
          selectedAlert: detail,
          history: history,
        ),
      );
    } on ApiException catch (exception) {
      emit(state.copyWith(loadingDetail: false, errorMessage: exception.message));
    } catch (_) {
      emit(
        state.copyWith(
          loadingDetail: false,
          errorMessage: 'No pudimos cargar el detalle de la alerta.',
        ),
      );
    }
  }

  Future<void> markSelectedAsRead() async {
    final selected = state.selectedAlert;
    if (selected == null) {
      return;
    }

    emit(state.copyWith(loadingAction: true, errorMessage: null));

    try {
      final updated = await _repository.markAsRead(selected.id);
      final history = await _repository.getHistory(selected.id);
      final updatedAlerts = state.alerts
          .map(
            (item) => item.id == updated.id
                ? updated
                : item,
          )
          .toList(growable: false);
      final summary = await _repository.getSummary();
      emit(
        state.copyWith(
          loadingAction: false,
          selectedAlert: updated,
          history: history,
          alerts: updatedAlerts,
          summary: summary,
        ),
      );
    } on ApiException catch (exception) {
      emit(state.copyWith(loadingAction: false, errorMessage: exception.message));
    } catch (_) {
      emit(
        state.copyWith(
          loadingAction: false,
          errorMessage: 'No pudimos marcar la alerta como leida.',
        ),
      );
    }
  }

  Future<void> closeSelected({String? comentario}) async {
    final selected = state.selectedAlert;
    if (selected == null) {
      return;
    }

    emit(state.copyWith(loadingAction: true, errorMessage: null));

    try {
      final updated = await _repository.closeAlert(selected.id, comentario: comentario);
      final history = await _repository.getHistory(selected.id);
      final updatedAlerts = state.alerts
          .map((item) => item.id == updated.id ? updated : item)
          .where((item) => item.estado.toUpperCase() != 'CERRADA')
          .toList(growable: false);
      final summary = await _repository.getSummary();

      emit(
        state.copyWith(
          loadingAction: false,
          selectedAlert: updated,
          history: history,
          alerts: updatedAlerts,
          summary: summary,
        ),
      );
    } on ApiException catch (exception) {
      emit(state.copyWith(loadingAction: false, errorMessage: exception.message));
    } catch (_) {
      emit(
        state.copyWith(
          loadingAction: false,
          errorMessage: 'No pudimos cerrar la alerta.',
        ),
      );
    }
  }
}
