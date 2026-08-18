import 'package:erp_curtiembre_fronted/features/finance/indirectos/domain/entities/costo_indirecto_record.dart';

class CostoIndirectoRecordModel {
  const CostoIndirectoRecordModel({
    required this.id,
    required this.periodoCostoId,
    required this.periodoAnio,
    required this.periodoMes,
    required this.periodoEstado,
    required this.tipoCosto,
    required this.monto,
    required this.registradoEn,
    this.descripcion,
    this.registradoPorUsuarioId,
  });

  final int id;
  final int periodoCostoId;
  final int periodoAnio;
  final int periodoMes;
  final String periodoEstado;
  final String tipoCosto;
  final String? descripcion;
  final double monto;
  final DateTime registradoEn;
  final int? registradoPorUsuarioId;

  factory CostoIndirectoRecordModel.fromJson(Map<String, dynamic> json) {
    return CostoIndirectoRecordModel(
      id: (json['id'] as num).toInt(),
      periodoCostoId: (json['periodoCostoId'] as num).toInt(),
      periodoAnio: (json['periodoAnio'] as num).toInt(),
      periodoMes: (json['periodoMes'] as num).toInt(),
      periodoEstado: json['periodoEstado'] as String,
      tipoCosto: json['tipoCosto'] as String,
      descripcion: json['descripcion'] as String?,
      monto: (json['monto'] as num).toDouble(),
      registradoEn: DateTime.parse(json['registradoEn'] as String),
      registradoPorUsuarioId: _parseOptionalInt(json['registradoPorUsuarioId']),
    );
  }

  CostoIndirectoRecord toEntity() {
    return CostoIndirectoRecord(
      id: id,
      periodoCostoId: periodoCostoId,
      periodoAnio: periodoAnio,
      periodoMes: periodoMes,
      periodoEstado: periodoEstado,
      tipoCosto: tipoCosto,
      descripcion: descripcion,
      monto: monto,
      registradoEn: registradoEn,
      registradoPorUsuarioId: registradoPorUsuarioId,
    );
  }

  static int? _parseOptionalInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return null;
  }
}
