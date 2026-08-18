import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/features/finance/indirectos/data/datasources/indirectos_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/finance/indirectos/domain/entities/costo_indirecto_record.dart';
import 'package:erp_curtiembre_fronted/features/finance/indirectos/domain/repositories/indirectos_repository.dart';
import 'package:talker_flutter/talker_flutter.dart';

class IndirectosRepositoryImpl implements IndirectosRepository {
  IndirectosRepositoryImpl(this._remoteDataSource, this._talker);

  final IndirectosRemoteDataSource _remoteDataSource;
  final Talker _talker;

  @override
  Future<List<CostoIndirectoRecord>> listIndirectos({
    int? periodoCostoId,
    String? tipoCosto,
    String? texto,
  }) async {
    _talker.repository(
      'Consultando costos indirectos con filtros periodoCostoId=$periodoCostoId, tipoCosto=${_describeType(tipoCosto)}, texto=${_describeText(texto)}.',
    );
    final items = await _remoteDataSource.listIndirectos(
      periodoCostoId: periodoCostoId,
      tipoCosto: tipoCosto,
      texto: texto,
    );
    _talker.repository(
      'Se obtuvieron ${items.length} costos indirectos para la consulta.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<CostoIndirectoRecord> getIndirecto(int id) async {
    _talker.repository('Consultando detalle del costo indirecto $id.');
    final item = await _remoteDataSource.getIndirecto(id);
    _talker.repository(
      'Detalle del costo indirecto $id obtenido correctamente.',
    );
    return item.toEntity();
  }

  @override
  Future<CostoIndirectoRecord> createIndirecto({
    required int periodoCostoId,
    required String tipoCosto,
    String? descripcion,
    required double monto,
  }) async {
    _talker.repository(
      'Creando costo indirecto con periodoCostoId=$periodoCostoId, tipoCosto=${_describeType(tipoCosto)}, descripcion=${_describeText(descripcion)}, monto=$monto.',
      logLevel: LogLevel.warning,
    );
    final item = await _remoteDataSource.createIndirecto(
      periodoCostoId: periodoCostoId,
      tipoCosto: tipoCosto,
      descripcion: descripcion,
      monto: monto,
    );
    _talker.repository(
      'Costo indirecto creado correctamente con id=${item.id}.',
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

  String _describeType(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return normalized;
  }
}
