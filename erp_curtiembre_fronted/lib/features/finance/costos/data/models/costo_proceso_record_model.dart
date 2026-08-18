import 'package:erp_curtiembre_fronted/features/finance/costos/domain/entities/costo_proceso_record.dart';

class CostoProcesoRecordModel {
  const CostoProcesoRecordModel({
    required this.id,
    required this.ordenProduccionId,
    required this.ordenProduccionCodigo,
    required this.ordenProcesoId,
    required this.procesoCodigo,
    required this.procesoNombre,
    required this.costoInsumos,
    required this.costoManoObra,
    required this.costoTotal,
    required this.calculadoEn,
  });

  final int id;
  final int ordenProduccionId;
  final String ordenProduccionCodigo;
  final int ordenProcesoId;
  final String procesoCodigo;
  final String procesoNombre;
  final double costoInsumos;
  final double costoManoObra;
  final double costoTotal;
  final DateTime calculadoEn;

  factory CostoProcesoRecordModel.fromJson(Map<String, dynamic> json) {
    return CostoProcesoRecordModel(
      id: (json['id'] as num).toInt(),
      ordenProduccionId: (json['ordenProduccionId'] as num).toInt(),
      ordenProduccionCodigo: json['ordenProduccionCodigo'] as String,
      ordenProcesoId: (json['ordenProcesoId'] as num).toInt(),
      procesoCodigo: json['procesoCodigo'] as String,
      procesoNombre: json['procesoNombre'] as String,
      costoInsumos: (json['costoInsumos'] as num).toDouble(),
      costoManoObra: (json['costoManoObra'] as num).toDouble(),
      costoTotal: (json['costoTotal'] as num).toDouble(),
      calculadoEn: DateTime.parse(json['calculadoEn'] as String),
    );
  }

  CostoProcesoRecord toEntity() {
    return CostoProcesoRecord(
      id: id,
      ordenProduccionId: ordenProduccionId,
      ordenProduccionCodigo: ordenProduccionCodigo,
      ordenProcesoId: ordenProcesoId,
      procesoCodigo: procesoCodigo,
      procesoNombre: procesoNombre,
      costoInsumos: costoInsumos,
      costoManoObra: costoManoObra,
      costoTotal: costoTotal,
      calculadoEn: calculadoEn,
    );
  }
}

