import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/features/finance/mano_obra/data/datasources/mano_obra_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/finance/mano_obra/domain/entities/mano_obra_directa_record.dart';
import 'package:erp_curtiembre_fronted/features/finance/mano_obra/domain/repositories/mano_obra_repository.dart';
import 'package:talker_flutter/talker_flutter.dart';

class ManoObraRepositoryImpl implements ManoObraRepository {
  ManoObraRepositoryImpl(this._remoteDataSource, this._talker);

  final ManoObraRemoteDataSource _remoteDataSource;
  final Talker _talker;

  @override
  Future<List<ManoObraDirectaRecord>> listManoObra({
    int? ordenProduccionId,
    int? ordenProcesoId,
  }) async {
    _talker.repository(
      'Consultando mano de obra directa con filtros ordenProduccionId=$ordenProduccionId, ordenProcesoId=$ordenProcesoId.',
    );
    final items = await _remoteDataSource.listManoObra(
      ordenProduccionId: ordenProduccionId,
      ordenProcesoId: ordenProcesoId,
    );
    _talker.repository(
      'Se obtuvieron ${items.length} registros de mano de obra directa.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<ManoObraDirectaRecord> getManoObra(int id) async {
    _talker.repository('Consultando detalle de mano de obra directa $id.');
    final item = await _remoteDataSource.getManoObra(id);
    _talker.repository(
      'Detalle de mano de obra directa $id obtenido correctamente.',
    );
    return item.toEntity();
  }

  @override
  Future<ManoObraDirectaRecord> createManoObra({
    required int ordenProduccionId,
    required int ordenProcesoId,
    required double monto,
    String? descripcion,
  }) async {
    _talker.repository(
      'Creando mano de obra directa con ordenProduccionId=$ordenProduccionId, ordenProcesoId=$ordenProcesoId, monto=$monto, descripcion=${_describeText(descripcion)}.',
      logLevel: LogLevel.warning,
    );
    final item = await _remoteDataSource.createManoObra(
      ordenProduccionId: ordenProduccionId,
      ordenProcesoId: ordenProcesoId,
      monto: monto,
      descripcion: descripcion,
    );
    _talker.repository(
      'Mano de obra directa creada correctamente con id=${item.id}.',
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
