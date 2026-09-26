import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/orden_proceso_record.dart';

class OrdenProcesoRecordModel {
  const OrdenProcesoRecordModel({
    required this.id,
    required this.ordenProduccionId,
    required this.procesoProductivoId,
    required this.procesoCodigo,
    required this.procesoNombre,
    required this.secuencia,
    required this.estado,
    this.responsableUsuarioId,
    this.responsableNombre,
    this.responsableCargo,
    this.pesoBaseKg,
    this.fechaFinEstimada,
    this.fechaInicio,
    this.fechaFin,
    this.diasReales,
    this.observacion,
  });

  final int id;
  final int ordenProduccionId;
  final int procesoProductivoId;
  final String procesoCodigo;
  final String procesoNombre;
  final int secuencia;
  final int? responsableUsuarioId;
  final String? responsableNombre;
  final String? responsableCargo;
  final double? pesoBaseKg;
  final DateTime? fechaFinEstimada;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final int? diasReales;
  final String estado;
  final String? observacion;

  factory OrdenProcesoRecordModel.fromJson(Map<String, dynamic> json) {
    return OrdenProcesoRecordModel(
      id: (json['id'] as num).toInt(),
      ordenProduccionId: (json['ordenProduccionId'] as num).toInt(),
      procesoProductivoId: (json['procesoProductivoId'] as num).toInt(),
      procesoCodigo: json['procesoCodigo'] as String,
      procesoNombre: json['procesoNombre'] as String,
      secuencia: (json['secuencia'] as num).toInt(),
      responsableUsuarioId: _parseOptionalInt(json['responsableUsuarioId']),
      responsableNombre: json['responsableNombre'] as String?,
      responsableCargo: json['responsableCargo'] as String?,
      pesoBaseKg: _parseOptionalDouble(json['pesoBaseKg']),
      fechaFinEstimada: _parseOptionalDate(json['fechaFinEstimada']),
      fechaInicio: _parseOptionalDate(json['fechaInicio']),
      fechaFin: _parseOptionalDate(json['fechaFin']),
      diasReales: _parseOptionalInt(json['diasReales']),
      estado: json['estado'] as String,
      observacion: json['observacion'] as String?,
    );
  }

  OrdenProcesoRecord toEntity() {
    return OrdenProcesoRecord(
      id: id,
      ordenProduccionId: ordenProduccionId,
      procesoProductivoId: procesoProductivoId,
      procesoCodigo: procesoCodigo,
      procesoNombre: procesoNombre,
      secuencia: secuencia,
      responsableUsuarioId: responsableUsuarioId,
      responsableNombre: responsableNombre,
      responsableCargo: responsableCargo,
      pesoBaseKg: pesoBaseKg,
      fechaFinEstimada: fechaFinEstimada,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      diasReales: diasReales,
      estado: estado,
      observacion: observacion,
    );
  }

  static int? _parseOptionalInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return null;
  }

  static double? _parseOptionalDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return null;
  }

  static DateTime? _parseOptionalDate(dynamic value) {
    if (value is! String || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }
}
