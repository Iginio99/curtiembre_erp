import 'package:erp_curtiembre_fronted/features/inventory/insumos/domain/entities/insumo_record.dart';
import 'package:erp_curtiembre_fronted/features/inventory/insumos/domain/entities/unidad_medida_option.dart';

abstract class InsumosRepository {
  Future<List<InsumoRecord>> listInsumos({
    String? texto,
    String? tipoBien,
    int? unidadMedidaId,
    bool? activo,
    bool? stockBajo,
  });

  Future<InsumoRecord> getInsumo(int id);

  Future<InsumoRecord> createInsumo({
    required String codigo,
    required String nombre,
    required String tipoBien,
    String? presentacion,
    required int unidadMedidaId,
    required double stockMinimo,
    required bool requiereLote,
  });

  Future<InsumoRecord> updateInsumo({
    required int id,
    required String codigo,
    required String nombre,
    required String tipoBien,
    String? presentacion,
    required int unidadMedidaId,
    required double stockMinimo,
    required bool requiereLote,
  });

  Future<InsumoRecord> setInsumoActive({
    required int id,
    required bool active,
  });

  Future<List<UnidadMedidaOption>> listActiveUnits();
}
