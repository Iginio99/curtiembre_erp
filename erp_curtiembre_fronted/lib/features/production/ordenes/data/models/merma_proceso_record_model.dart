import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/merma_proceso_record.dart';

class MermaProcesoRecordModel {
  const MermaProcesoRecordModel({
    required this.id,
    required this.ordenProduccionId,
    required this.ordenProcesoId,
    required this.procesoProductivoId,
    required this.procesoCodigo,
    required this.procesoNombre,
    required this.cantidadPerdida,
    required this.registradoEn,
    this.motivo,
    this.observacion,
    this.registradoPorUsuarioId,
    this.registradoPorNombre,
  });

  final int id;
  final int ordenProduccionId;
  final int ordenProcesoId;
  final int procesoProductivoId;
  final String procesoCodigo;
  final String procesoNombre;
  final double cantidadPerdida;
  final String? motivo;
  final String? observacion;
  final DateTime registradoEn;
  final int? registradoPorUsuarioId;
  final String? registradoPorNombre;

  factory MermaProcesoRecordModel.fromJson(Map<String, dynamic> json) {
    return MermaProcesoRecordModel(
      id: (json['id'] as num).toInt(),
      ordenProduccionId: (json['ordenProduccionId'] as num).toInt(),
      ordenProcesoId: (json['ordenProcesoId'] as num).toInt(),
      procesoProductivoId: _parseOptionalInt(json['procesoProductivoId']) ?? 0,
      procesoCodigo: json['procesoCodigo'] as String,
      procesoNombre: json['procesoNombre'] as String,
      cantidadPerdida: (json['cantidadPerdida'] as num).toDouble(),
      motivo: json['motivo'] as String?,
      observacion: json['observacion'] as String?,
      registradoEn: DateTime.parse(json['registradoEn'] as String),
      registradoPorUsuarioId: _parseOptionalInt(json['registradoPorUsuarioId']),
      registradoPorNombre:
          json['registradoPorNombre'] as String? ?? json['responsable'] as String?,
    );
  }

  MermaProcesoRecord toEntity() {
    return MermaProcesoRecord(
      id: id,
      ordenProduccionId: ordenProduccionId,
      ordenProcesoId: ordenProcesoId,
      procesoProductivoId: procesoProductivoId,
      procesoCodigo: procesoCodigo,
      procesoNombre: procesoNombre,
      cantidadPerdida: cantidadPerdida,
      motivo: motivo,
      observacion: observacion,
      registradoEn: registradoEn,
      registradoPorUsuarioId: registradoPorUsuarioId,
      registradoPorNombre: registradoPorNombre,
    );
  }

  static int? _parseOptionalInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return null;
  }
}
