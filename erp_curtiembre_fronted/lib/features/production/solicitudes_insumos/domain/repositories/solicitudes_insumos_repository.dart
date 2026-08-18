import 'package:erp_curtiembre_fronted/features/production/solicitudes_insumos/domain/entities/solicitud_insumo_detail.dart';
import 'package:erp_curtiembre_fronted/features/production/solicitudes_insumos/domain/entities/solicitud_insumo_record.dart';

abstract class SolicitudesInsumosRepository {
  Future<List<SolicitudInsumoRecord>> list({String? estado});

  Future<SolicitudInsumoDetail> getDetail(int id);

  Future<void> deliver({required int id, String? motivo, String? observacion});
}
