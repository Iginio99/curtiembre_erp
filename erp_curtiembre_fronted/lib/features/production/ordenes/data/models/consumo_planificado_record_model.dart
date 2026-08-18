import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/consumo_planificado_record.dart';

class ConsumoPlanificadoRecordModel {
  const ConsumoPlanificadoRecordModel({
    required this.id,
    required this.ordenProduccionId,
    required this.ordenProcesoId,
    required this.procesoProductivoId,
    required this.procesoCodigo,
    required this.procesoNombre,
    required this.formulaVersionId,
    required this.insumoId,
    required this.insumoCodigo,
    required this.insumoNombre,
    required this.porcentaje,
    required this.cantidadPlanificada,
    required this.creadoEn,
  });

  final int id;
  final int ordenProduccionId;
  final int ordenProcesoId;
  final int procesoProductivoId;
  final String procesoCodigo;
  final String procesoNombre;
  final int formulaVersionId;
  final int insumoId;
  final String insumoCodigo;
  final String insumoNombre;
  final double porcentaje;
  final double cantidadPlanificada;
  final DateTime creadoEn;

  factory ConsumoPlanificadoRecordModel.fromJson(Map<String, dynamic> json) {
    return ConsumoPlanificadoRecordModel(
      id: (json['id'] as num).toInt(),
      ordenProduccionId: (json['ordenProduccionId'] as num).toInt(),
      ordenProcesoId: (json['ordenProcesoId'] as num).toInt(),
      procesoProductivoId: (json['procesoProductivoId'] as num).toInt(),
      procesoCodigo: json['procesoCodigo'] as String,
      procesoNombre: json['procesoNombre'] as String,
      formulaVersionId: (json['formulaVersionId'] as num).toInt(),
      insumoId: (json['insumoId'] as num).toInt(),
      insumoCodigo: json['insumoCodigo'] as String,
      insumoNombre: json['insumoNombre'] as String,
      porcentaje: (json['porcentaje'] as num).toDouble(),
      cantidadPlanificada: (json['cantidadPlanificada'] as num).toDouble(),
      creadoEn: DateTime.parse(json['creadoEn'] as String),
    );
  }

  ConsumoPlanificadoRecord toEntity() {
    return ConsumoPlanificadoRecord(
      id: id,
      ordenProduccionId: ordenProduccionId,
      ordenProcesoId: ordenProcesoId,
      procesoProductivoId: procesoProductivoId,
      procesoCodigo: procesoCodigo,
      procesoNombre: procesoNombre,
      formulaVersionId: formulaVersionId,
      insumoId: insumoId,
      insumoCodigo: insumoCodigo,
      insumoNombre: insumoNombre,
      porcentaje: porcentaje,
      cantidadPlanificada: cantidadPlanificada,
      creadoEn: creadoEn,
    );
  }
}
