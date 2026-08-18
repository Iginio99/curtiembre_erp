import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/features/finance/periodos/data/datasources/periodos_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/finance/periodos/domain/entities/periodo_costo_record.dart';
import 'package:erp_curtiembre_fronted/features/finance/periodos/domain/repositories/periodos_repository.dart';
import 'package:talker_flutter/talker_flutter.dart';

class PeriodosRepositoryImpl implements PeriodosRepository {
  PeriodosRepositoryImpl(this._remoteDataSource, this._talker);

  final PeriodosRemoteDataSource _remoteDataSource;
  final Talker _talker;

  @override
  Future<List<PeriodoCostoRecord>> listPeriodos({
    int? anio,
    int? mes,
    String? estado,
  }) async {
    _talker.repository(
      'Consultando periodos de costo con filtros anio=$anio, mes=$mes, estado=${_describeText(estado)}.',
    );
    final items = await _remoteDataSource.listPeriodos(
      anio: anio,
      mes: mes,
      estado: estado,
    );
    _talker.repository(
      'Se obtuvieron ${items.length} periodos de costo para la consulta.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<PeriodoCostoRecord> getPeriodo(int id) async {
    _talker.repository('Consultando detalle del periodo de costo $id.');
    final item = await _remoteDataSource.getPeriodo(id);
    _talker.repository(
      'Detalle del periodo de costo $id obtenido correctamente.',
    );
    return item.toEntity();
  }

  @override
  Future<PeriodoCostoRecord> createPeriodo({
    required int anio,
    required int mes,
    String? observacion,
  }) async {
    _talker.repository(
      'Creando periodo de costo con anio=$anio, mes=$mes, observacion=${_describeText(observacion)}.',
      logLevel: LogLevel.warning,
    );
    final item = await _remoteDataSource.createPeriodo(
      anio: anio,
      mes: mes,
      observacion: observacion,
    );
    _talker.repository(
      'Periodo de costo creado correctamente con id=${item.id}.',
      logLevel: LogLevel.warning,
    );
    return item.toEntity();
  }

  @override
  Future<PeriodoCostoRecord> closePeriodo({
    required int id,
    String? observacion,
  }) async {
    _talker.repository(
      'Cerrando periodo de costo $id con observacion=${_describeText(observacion)}.',
      logLevel: LogLevel.warning,
    );
    final item = await _remoteDataSource.closePeriodo(
      id: id,
      observacion: observacion,
    );
    _talker.repository(
      'Periodo de costo $id cerrado correctamente.',
      logLevel: LogLevel.warning,
    );
    return item.toEntity();
  }

  String _describeText(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return '${normalized.length} caracteres';
  }
}
