import 'package:erp_curtiembre_fronted/features/alerts/data/datasources/alerts_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/alerts/domain/entities/alert_record.dart';
import 'package:erp_curtiembre_fronted/features/alerts/domain/repositories/alerts_repository.dart';

class AlertsRepositoryImpl implements AlertsRepository {
  AlertsRepositoryImpl(this._remoteDataSource);

  final AlertsRemoteDataSource _remoteDataSource;

  @override
  Future<AlertDetail> closeAlert(int id, {String? comentario}) {
    return _remoteDataSource.closeAlert(id, comentario: comentario);
  }

  @override
  Future<AlertDetail> getAlert(int id) {
    return _remoteDataSource.getAlert(id);
  }

  @override
  Future<List<AlertHistoryItem>> getHistory(int id) {
    return _remoteDataSource.getHistory(id);
  }

  @override
  Future<AlertsSummary> getSummary() {
    return _remoteDataSource.getSummary();
  }

  @override
  Future<List<AlertRecord>> listActivas() {
    return _remoteDataSource.listActivas();
  }

  @override
  Future<List<AlertRecord>> listAlerts({
    String? estado,
    String? severidad,
    String? tipoAlerta,
    String? moduloOrigen,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) {
    return _remoteDataSource.listAlerts(
      estado: estado,
      severidad: severidad,
      tipoAlerta: tipoAlerta,
      moduloOrigen: moduloOrigen,
      fechaDesde: fechaDesde,
      fechaHasta: fechaHasta,
    );
  }

  @override
  Future<AlertDetail> markAsRead(int id) {
    return _remoteDataSource.markAsRead(id);
  }
}
