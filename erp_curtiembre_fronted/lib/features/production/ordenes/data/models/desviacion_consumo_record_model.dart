import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/desviacion_consumo_record.dart';

class DesviacionConsumoRecordModel {
  const DesviacionConsumoRecordModel({
    required this.id,
    required this.ordenConsumoRealId,
    required this.ordenProduccionId,
    required this.ordenProcesoId,
    required this.procesoProductivoId,
    required this.procesoCodigo,
    required this.procesoNombre,
    required this.insumoId,
    required this.insumoCodigo,
    required this.insumoNombre,
    required this.cantidadPlanificada,
    required this.cantidadReal,
    required this.cantidadDesviacion,
    required this.registradoEn,
    this.ordenConsumoPlanificadoId,
    this.motivo,
  });

  final int id;
  final int? ordenConsumoPlanificadoId;
  final int ordenConsumoRealId;
  final int ordenProduccionId;
  final int ordenProcesoId;
  final int procesoProductivoId;
  final String procesoCodigo;
  final String procesoNombre;
  final int insumoId;
  final String insumoCodigo;
  final String insumoNombre;
  final double cantidadPlanificada;
  final double cantidadReal;
  final double cantidadDesviacion;
  final String? motivo;
  final DateTime registradoEn;

  factory DesviacionConsumoRecordModel.fromJson(Map<String, dynamic> json) {
    return DesviacionConsumoRecordModel(
      id: (json['id'] as num).toInt(),
      ordenConsumoPlanificadoId: _parseOptionalInt(
        json['ordenConsumoPlanificadoId'],
      ),
      ordenConsumoRealId: (json['ordenConsumoRealId'] as num).toInt(),
      ordenProduccionId: (json['ordenProduccionId'] as num).toInt(),
      ordenProcesoId: (json['ordenProcesoId'] as num).toInt(),
      procesoProductivoId: (json['procesoProductivoId'] as num).toInt(),
      procesoCodigo: json['procesoCodigo'] as String,
      procesoNombre: json['procesoNombre'] as String,
      insumoId: (json['insumoId'] as num).toInt(),
      insumoCodigo: json['insumoCodigo'] as String,
      insumoNombre: json['insumoNombre'] as String,
      cantidadPlanificada: (json['cantidadPlanificada'] as num).toDouble(),
      cantidadReal: (json['cantidadReal'] as num).toDouble(),
      cantidadDesviacion: (json['cantidadDesviacion'] as num).toDouble(),
      motivo: json['motivo'] as String?,
      registradoEn: DateTime.parse(json['registradoEn'] as String),
    );
  }

  DesviacionConsumoRecord toEntity() {
    return DesviacionConsumoRecord(
      id: id,
      ordenConsumoPlanificadoId: ordenConsumoPlanificadoId,
      ordenConsumoRealId: ordenConsumoRealId,
      ordenProduccionId: ordenProduccionId,
      ordenProcesoId: ordenProcesoId,
      procesoProductivoId: procesoProductivoId,
      procesoCodigo: procesoCodigo,
      procesoNombre: procesoNombre,
      insumoId: insumoId,
      insumoCodigo: insumoCodigo,
      insumoNombre: insumoNombre,
      cantidadPlanificada: cantidadPlanificada,
      cantidadReal: cantidadReal,
      cantidadDesviacion: cantidadDesviacion,
      motivo: motivo,
      registradoEn: registradoEn,
    );
  }

  static int? _parseOptionalInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return null;
  }
}
