import 'package:erp_curtiembre_fronted/features/finance/mano_obra/domain/entities/mano_obra_directa_record.dart';

class ManoObraDirectaRecordModel {
  const ManoObraDirectaRecordModel({
    required this.id,
    required this.ordenProduccionId,
    required this.ordenProduccionCodigo,
    required this.ordenProcesoId,
    required this.procesoCodigo,
    required this.procesoNombre,
    required this.monto,
    required this.registradoEn,
    this.descripcion,
    this.registradoPorUsuarioId,
  });

  final int id;
  final int ordenProduccionId;
  final String ordenProduccionCodigo;
  final int ordenProcesoId;
  final String procesoCodigo;
  final String procesoNombre;
  final double monto;
  final String? descripcion;
  final DateTime registradoEn;
  final int? registradoPorUsuarioId;

  factory ManoObraDirectaRecordModel.fromJson(Map<String, dynamic> json) {
    return ManoObraDirectaRecordModel(
      id: (json['id'] as num).toInt(),
      ordenProduccionId: (json['ordenProduccionId'] as num).toInt(),
      ordenProduccionCodigo: json['ordenProduccionCodigo'] as String,
      ordenProcesoId: (json['ordenProcesoId'] as num).toInt(),
      procesoCodigo: json['procesoCodigo'] as String,
      procesoNombre: json['procesoNombre'] as String,
      monto: (json['monto'] as num).toDouble(),
      descripcion: json['descripcion'] as String?,
      registradoEn: DateTime.parse(json['registradoEn'] as String),
      registradoPorUsuarioId: _parseOptionalInt(json['registradoPorUsuarioId']),
    );
  }

  ManoObraDirectaRecord toEntity() {
    return ManoObraDirectaRecord(
      id: id,
      ordenProduccionId: ordenProduccionId,
      ordenProduccionCodigo: ordenProduccionCodigo,
      ordenProcesoId: ordenProcesoId,
      procesoCodigo: procesoCodigo,
      procesoNombre: procesoNombre,
      monto: monto,
      descripcion: descripcion,
      registradoEn: registradoEn,
      registradoPorUsuarioId: registradoPorUsuarioId,
    );
  }

  static int? _parseOptionalInt(dynamic value) {
    if (value is num) return value.toInt();
    return null;
  }
}
