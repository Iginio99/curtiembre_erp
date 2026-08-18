import 'package:erp_curtiembre_fronted/features/finance/mano_obra/domain/entities/mano_obra_directa_record.dart';

abstract class ManoObraRepository {
  Future<List<ManoObraDirectaRecord>> listManoObra({
    int? ordenProduccionId,
    int? ordenProcesoId,
  });

  Future<ManoObraDirectaRecord> getManoObra(int id);

  Future<ManoObraDirectaRecord> createManoObra({
    required int ordenProduccionId,
    required int ordenProcesoId,
    required double monto,
    String? descripcion,
  });
}
