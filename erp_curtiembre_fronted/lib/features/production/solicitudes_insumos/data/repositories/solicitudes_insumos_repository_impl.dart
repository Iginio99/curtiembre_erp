import 'package:erp_curtiembre_fronted/features/production/solicitudes_insumos/data/datasources/solicitudes_insumos_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/production/solicitudes_insumos/domain/entities/solicitud_insumo_record.dart';
import 'package:erp_curtiembre_fronted/features/production/solicitudes_insumos/domain/entities/solicitud_insumo_detail.dart';
import 'package:erp_curtiembre_fronted/features/production/solicitudes_insumos/domain/repositories/solicitudes_insumos_repository.dart';

class SolicitudesInsumosRepositoryImpl implements SolicitudesInsumosRepository {
  SolicitudesInsumosRepositoryImpl(this._remote);

  final SolicitudesInsumosRemoteDataSource _remote;

  @override
  Future<List<SolicitudInsumoRecord>> list({String? estado}) async =>
      (await _remote.list(
        estado: estado,
      )).map((item) => item.toEntity()).toList(growable: false);

  @override
  Future<SolicitudInsumoDetail> getDetail(int id) async =>
      (await _remote.getDetail(id)).toEntity();

  @override
  Future<void> deliver({
    required int id,
    String? motivo,
    String? observacion,
  }) => _remote.deliver(id: id, motivo: motivo, observacion: observacion);
}
