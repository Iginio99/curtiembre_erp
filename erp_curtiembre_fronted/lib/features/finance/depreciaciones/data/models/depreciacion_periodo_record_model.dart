import 'package:erp_curtiembre_fronted/features/finance/depreciaciones/domain/entities/depreciacion_periodo_record.dart';

class DepreciacionPeriodoRecordModel {
  const DepreciacionPeriodoRecordModel({
    required this.id,
    required this.periodoCostoId,
    required this.periodoAnio,
    required this.periodoMes,
    required this.activoDepreciableId,
    required this.activoCodigo,
    required this.activoNombre,
    required this.montoDepreciacion,
    required this.calculadoEn,
  });

  final int id;
  final int periodoCostoId;
  final int periodoAnio;
  final int periodoMes;
  final int activoDepreciableId;
  final String activoCodigo;
  final String activoNombre;
  final double montoDepreciacion;
  final DateTime calculadoEn;

  factory DepreciacionPeriodoRecordModel.fromJson(Map<String, dynamic> json) {
    return DepreciacionPeriodoRecordModel(
      id: (json['id'] as num).toInt(),
      periodoCostoId: (json['periodoCostoId'] as num).toInt(),
      periodoAnio: (json['periodoAnio'] as num).toInt(),
      periodoMes: (json['periodoMes'] as num).toInt(),
      activoDepreciableId: (json['activoDepreciableId'] as num).toInt(),
      activoCodigo: json['activoCodigo'] as String,
      activoNombre: json['activoNombre'] as String,
      montoDepreciacion: (json['montoDepreciacion'] as num).toDouble(),
      calculadoEn: DateTime.parse(json['calculadoEn'] as String),
    );
  }

  DepreciacionPeriodoRecord toEntity() {
    return DepreciacionPeriodoRecord(
      id: id,
      periodoCostoId: periodoCostoId,
      periodoAnio: periodoAnio,
      periodoMes: periodoMes,
      activoDepreciableId: activoDepreciableId,
      activoCodigo: activoCodigo,
      activoNombre: activoNombre,
      montoDepreciacion: montoDepreciacion,
      calculadoEn: calculadoEn,
    );
  }
}
