import 'package:erp_curtiembre_fronted/features/alerts/domain/entities/alert_record.dart';

abstract class AlertsRepository {
  Future<List<AlertRecord>> listActivas();

  Future<List<AlertRecord>> listAlerts({
    String? estado,
    String? severidad,
    String? tipoAlerta,
    String? moduloOrigen,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  });

  Future<AlertDetail> getAlert(int id);

  Future<AlertsSummary> getSummary();

  Future<List<AlertHistoryItem>> getHistory(int id);

  Future<AlertDetail> markAsRead(int id);

  Future<AlertDetail> closeAlert(int id, {String? comentario});
}
