import 'package:erp_curtiembre_fronted/features/finance/indirectos/domain/entities/costo_indirecto_record.dart';

abstract class IndirectosRepository {
  Future<List<CostoIndirectoRecord>> listIndirectos({
    int? periodoCostoId,
    String? tipoCosto,
    String? texto,
  });

  Future<CostoIndirectoRecord> getIndirecto(int id);

  Future<CostoIndirectoRecord> createIndirecto({
    required int periodoCostoId,
    required String tipoCosto,
    String? descripcion,
    required double monto,
  });
}
