import 'package:erp_curtiembre_fronted/features/finance/periodos/domain/entities/periodo_costo_record.dart';

class PeriodoCostoRecordModel {
  const PeriodoCostoRecordModel({
    required this.id,
    required this.anio,
    required this.mes,
    required this.fechaInicio,
    required this.fechaFin,
    required this.estado,
    required this.totalIndirectos,
    this.cerradoEn,
    this.cerradoPorUsuarioId,
    this.observacion,
  });

  final int id;
  final int anio;
  final int mes;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String estado;
  final DateTime? cerradoEn;
  final int? cerradoPorUsuarioId;
  final String? observacion;
  final double totalIndirectos;

  factory PeriodoCostoRecordModel.fromJson(Map<String, dynamic> json) {
    return PeriodoCostoRecordModel(
      id: (json['id'] as num).toInt(),
      anio: (json['anio'] as num).toInt(),
      mes: (json['mes'] as num).toInt(),
      fechaInicio: DateTime.parse(json['fechaInicio'] as String),
      fechaFin: DateTime.parse(json['fechaFin'] as String),
      estado: json['estado'] as String,
      cerradoEn: _parseOptionalDate(json['cerradoEn']),
      cerradoPorUsuarioId: _parseOptionalInt(json['cerradoPorUsuarioId']),
      observacion: json['observacion'] as String?,
      totalIndirectos: (json['totalIndirectos'] as num).toDouble(),
    );
  }

  PeriodoCostoRecord toEntity() {
    return PeriodoCostoRecord(
      id: id,
      anio: anio,
      mes: mes,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      estado: estado,
      cerradoEn: cerradoEn,
      cerradoPorUsuarioId: cerradoPorUsuarioId,
      observacion: observacion,
      totalIndirectos: totalIndirectos,
    );
  }

  static DateTime? _parseOptionalDate(dynamic value) {
    if (value is! String || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  static int? _parseOptionalInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return null;
  }
}
