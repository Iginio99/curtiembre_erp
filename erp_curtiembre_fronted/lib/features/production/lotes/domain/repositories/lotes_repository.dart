import 'package:erp_curtiembre_fronted/features/production/clientes/domain/entities/cliente_option.dart';
import 'package:erp_curtiembre_fronted/features/production/lotes/domain/entities/lote_disponibilidad.dart';
import 'package:erp_curtiembre_fronted/features/production/lotes/domain/entities/lote_record.dart';
import 'package:erp_curtiembre_fronted/features/production/lotes/domain/entities/tipo_piel_option.dart';

abstract class LotesRepository {
  Future<List<LoteRecord>> listLotes({
    String? texto,
    int? clienteId,
    int? tipoPielId,
    String? estado,
  });

  Future<LoteRecord> getLote(int id);

  Future<LoteDisponibilidad> getDisponibilidad(int id);

  Future<List<ClienteOption>> listActiveClientes();

  Future<List<TipoPielOption>> listActiveTiposPiel();

  Future<LoteRecord> createLote({
    required int clienteId,
    required int tipoPielId,
    required DateTime fechaIngreso,
    required double cantidadPielesInicial,
    required bool clienteTraeLote,
    required double costoPielesTotal,
    String? observacion,
  });

  Future<LoteRecord> updateLote({
    required int id,
    required int clienteId,
    required int tipoPielId,
    required DateTime fechaIngreso,
    required double cantidadPielesInicial,
    required bool clienteTraeLote,
    required double costoPielesTotal,
    String? observacion,
  });
}
