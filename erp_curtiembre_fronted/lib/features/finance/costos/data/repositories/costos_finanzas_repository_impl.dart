import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/features/finance/costos/data/datasources/costos_finanzas_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/finance/costos/domain/entities/costo_orden_record.dart';
import 'package:erp_curtiembre_fronted/features/finance/costos/domain/entities/costo_proceso_record.dart';
import 'package:erp_curtiembre_fronted/features/finance/costos/domain/repositories/costos_finanzas_repository.dart';
import 'package:talker_flutter/talker_flutter.dart';

class CostosFinanzasRepositoryImpl implements CostosFinanzasRepository {
  CostosFinanzasRepositoryImpl(this._remoteDataSource, this._talker);

  final CostosFinanzasRemoteDataSource _remoteDataSource;
  final Talker _talker;

  @override
  Future<List<CostoProcesoRecord>> listCostosProceso({
    int? ordenProduccionId,
    int? ordenProcesoId,
  }) async {
    _talker.repository(
      'Consultando costos por proceso con filtros ordenProduccionId=$ordenProduccionId, ordenProcesoId=$ordenProcesoId.',
    );
    final items = await _remoteDataSource.listCostosProceso(
      ordenProduccionId: ordenProduccionId,
      ordenProcesoId: ordenProcesoId,
    );
    _talker.repository(
      'Se obtuvieron ${items.length} costos por proceso para la consulta.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<CostoProcesoRecord> getCostoProceso(int ordenProcesoId) async {
    _talker.repository(
      'Consultando detalle del costo de proceso $ordenProcesoId.',
    );
    final item = await _remoteDataSource.getCostoProceso(ordenProcesoId);
    _talker.repository(
      'Detalle del costo de proceso $ordenProcesoId obtenido correctamente.',
    );
    return item.toEntity();
  }

  @override
  Future<CostoProcesoRecord> calculateCostoProceso({
    required int ordenProduccionId,
    required int ordenProcesoId,
  }) async {
    _talker.repository(
      'Calculando costo de proceso para ordenProduccionId=$ordenProduccionId y ordenProcesoId=$ordenProcesoId.',
      logLevel: LogLevel.warning,
    );
    final item = await _remoteDataSource.calculateCostoProceso(
      ordenProduccionId: ordenProduccionId,
      ordenProcesoId: ordenProcesoId,
    );
    _talker.repository(
      'Costo de proceso calculado correctamente para ordenProcesoId=$ordenProcesoId.',
      logLevel: LogLevel.warning,
    );
    return item.toEntity();
  }

  @override
  Future<List<CostoOrdenRecord>> listCostosOrden({
    int? ordenProduccionId,
    int? periodoCostoId,
    String? estado,
  }) async {
    _talker.repository(
      'Consultando costos por orden con filtros ordenProduccionId=$ordenProduccionId, periodoCostoId=$periodoCostoId, estado=${_describeText(estado)}.',
    );
    final items = await _remoteDataSource.listCostosOrden(
      ordenProduccionId: ordenProduccionId,
      periodoCostoId: periodoCostoId,
      estado: estado,
    );
    _talker.repository(
      'Se obtuvieron ${items.length} costos por orden para la consulta.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<CostoOrdenRecord> getCostoOrden(int ordenProduccionId) async {
    _talker.repository(
      'Consultando detalle del costo de orden $ordenProduccionId.',
    );
    final item = await _remoteDataSource.getCostoOrden(ordenProduccionId);
    _talker.repository(
      'Detalle del costo de orden $ordenProduccionId obtenido correctamente.',
    );
    return item.toEntity();
  }

  @override
  Future<CostoOrdenRecord> calculateCostoOrdenEstimado(
    int ordenProduccionId,
  ) async {
    _talker.repository(
      'Calculando costo estimado para la orden $ordenProduccionId.',
      logLevel: LogLevel.warning,
    );
    final item = await _remoteDataSource.calculateCostoOrdenEstimado(
      ordenProduccionId,
    );
    _talker.repository(
      'Costo estimado calculado correctamente para la orden $ordenProduccionId.',
      logLevel: LogLevel.warning,
    );
    return item.toEntity();
  }

  @override
  Future<CostoOrdenRecord> calculateCostoOrdenReal(
    int ordenProduccionId,
  ) async {
    _talker.repository(
      'Calculando costo real para la orden $ordenProduccionId.',
      logLevel: LogLevel.warning,
    );
    final item = await _remoteDataSource.calculateCostoOrdenReal(
      ordenProduccionId,
    );
    _talker.repository(
      'Costo real calculado correctamente para la orden $ordenProduccionId.',
      logLevel: LogLevel.warning,
    );
    return item.toEntity();
  }

  @override
  Future<CostoOrdenRecord> closeCostoOrden(int ordenProduccionId) async {
    _talker.repository(
      'Cerrando costo de orden $ordenProduccionId.',
      logLevel: LogLevel.warning,
    );
    final item = await _remoteDataSource.closeCostoOrden(ordenProduccionId);
    _talker.repository(
      'Costo de orden $ordenProduccionId cerrado correctamente.',
      logLevel: LogLevel.warning,
    );
    return item.toEntity();
  }

  String _describeText(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return normalized;
  }
}
