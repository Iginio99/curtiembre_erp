import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/features/finance/depreciaciones/data/datasources/depreciaciones_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/finance/depreciaciones/domain/entities/depreciacion_periodo_record.dart';
import 'package:erp_curtiembre_fronted/features/finance/depreciaciones/domain/repositories/depreciaciones_repository.dart';
import 'package:talker_flutter/talker_flutter.dart';

class DepreciacionesRepositoryImpl implements DepreciacionesRepository {
  DepreciacionesRepositoryImpl(this._remoteDataSource, this._talker);

  final DepreciacionesRemoteDataSource _remoteDataSource;
  final Talker _talker;

  @override
  Future<List<DepreciacionPeriodoRecord>> listDepreciaciones({
    int? periodoCostoId,
    int? activoDepreciableId,
  }) async {
    _talker.repository(
      'Consultando depreciaciones con filtros periodoCostoId=$periodoCostoId, activoDepreciableId=$activoDepreciableId.',
    );
    final items = await _remoteDataSource.listDepreciaciones(
      periodoCostoId: periodoCostoId,
      activoDepreciableId: activoDepreciableId,
    );
    _talker.repository(
      'Se obtuvieron ${items.length} depreciaciones para la consulta.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<DepreciacionPeriodoRecord> getDepreciacion(int id) async {
    _talker.repository('Consultando detalle de la depreciacion $id.');
    final item = await _remoteDataSource.getDepreciacion(id);
    _talker.repository(
      'Detalle de la depreciacion $id obtenido correctamente.',
    );
    return item.toEntity();
  }

  @override
  Future<void> calculateForPeriod(int periodoId) {
    _talker.repository(
      'Calculando depreciaciones para el periodo $periodoId.',
      logLevel: LogLevel.warning,
    );
    return _remoteDataSource.calculateForPeriod(periodoId);
  }
}
