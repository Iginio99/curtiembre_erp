import 'package:equatable/equatable.dart';
import 'package:erp_curtiembre_fronted/features/alerts/domain/entities/alert_record.dart';

enum AlertsStatus { loading, success, error }

class AlertsState extends Equatable {
  static const Object _sentinel = Object();

  const AlertsState({
    required this.status,
    this.summary,
    this.alerts = const [],
    this.selectedAlert,
    this.history = const [],
    this.errorMessage,
    this.loadingList = false,
    this.loadingDetail = false,
    this.loadingAction = false,
    this.estadoFilter,
    this.severidadFilter,
    this.tipoAlertaFilter,
    this.moduloOrigenFilter,
  });

  const AlertsState.loading() : this(status: AlertsStatus.loading);

  final AlertsStatus status;
  final AlertsSummary? summary;
  final List<AlertRecord> alerts;
  final AlertDetail? selectedAlert;
  final List<AlertHistoryItem> history;
  final String? errorMessage;
  final bool loadingList;
  final bool loadingDetail;
  final bool loadingAction;
  final String? estadoFilter;
  final String? severidadFilter;
  final String? tipoAlertaFilter;
  final String? moduloOrigenFilter;

  AlertsState copyWith({
    AlertsStatus? status,
    AlertsSummary? summary,
    List<AlertRecord>? alerts,
    Object? selectedAlert = _sentinel,
    List<AlertHistoryItem>? history,
    Object? errorMessage = _sentinel,
    bool? loadingList,
    bool? loadingDetail,
    bool? loadingAction,
    Object? estadoFilter = _sentinel,
    Object? severidadFilter = _sentinel,
    Object? tipoAlertaFilter = _sentinel,
    Object? moduloOrigenFilter = _sentinel,
  }) {
    return AlertsState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      alerts: alerts ?? this.alerts,
      selectedAlert: identical(selectedAlert, _sentinel)
          ? this.selectedAlert
          : selectedAlert as AlertDetail?,
      history: history ?? this.history,
      errorMessage:
          identical(errorMessage, _sentinel) ? this.errorMessage : errorMessage as String?,
      loadingList: loadingList ?? this.loadingList,
      loadingDetail: loadingDetail ?? this.loadingDetail,
      loadingAction: loadingAction ?? this.loadingAction,
      estadoFilter: identical(estadoFilter, _sentinel)
          ? this.estadoFilter
          : estadoFilter as String?,
      severidadFilter: identical(severidadFilter, _sentinel)
          ? this.severidadFilter
          : severidadFilter as String?,
      tipoAlertaFilter: identical(tipoAlertaFilter, _sentinel)
          ? this.tipoAlertaFilter
          : tipoAlertaFilter as String?,
      moduloOrigenFilter: identical(moduloOrigenFilter, _sentinel)
          ? this.moduloOrigenFilter
          : moduloOrigenFilter as String?,
    );
  }

  @override
  List<Object?> get props => [
        status,
        summary,
        alerts,
        selectedAlert,
        history,
        errorMessage,
        loadingList,
        loadingDetail,
        loadingAction,
        estadoFilter,
        severidadFilter,
        tipoAlertaFilter,
        moduloOrigenFilter,
      ];
}
