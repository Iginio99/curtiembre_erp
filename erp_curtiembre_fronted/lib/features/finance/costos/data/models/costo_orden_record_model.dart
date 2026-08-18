import 'package:erp_curtiembre_fronted/features/finance/costos/domain/entities/costo_orden_record.dart';

class CostoOrdenRecordModel {
  const CostoOrdenRecordModel({
    required this.id,
    required this.ordenProduccionId,
    required this.ordenProduccionCodigo,
    required this.costoPieles,
    required this.costoInsumos,
    required this.costoManoObra,
    required this.costoIndirectoAsignado,
    required this.costoDepreciacionAsignado,
    required this.costoTotal,
    required this.estado,
    required this.calculadoEn,
    this.periodoCostoId,
    this.periodoAnio,
    this.periodoMes,
    this.pielesBuenasFinales,
    this.costoPorPiel,
    this.costoEstimado,
    this.costoReal,
    this.calculadoPorUsuarioId,
  });

  final int id;
  final int ordenProduccionId;
  final String ordenProduccionCodigo;
  final int? periodoCostoId;
  final int? periodoAnio;
  final int? periodoMes;
  final double costoPieles;
  final double costoInsumos;
  final double costoManoObra;
  final double costoIndirectoAsignado;
  final double costoDepreciacionAsignado;
  final double costoTotal;
  final double? pielesBuenasFinales;
  final double? costoPorPiel;
  final double? costoEstimado;
  final double? costoReal;
  final String estado;
  final DateTime calculadoEn;
  final int? calculadoPorUsuarioId;

  factory CostoOrdenRecordModel.fromJson(Map<String, dynamic> json) {
    return CostoOrdenRecordModel(
      id: (json['id'] as num).toInt(),
      ordenProduccionId: (json['ordenProduccionId'] as num).toInt(),
      ordenProduccionCodigo: json['ordenProduccionCodigo'] as String,
      periodoCostoId: _parseOptionalInt(json['periodoCostoId']),
      periodoAnio: _parseOptionalInt(json['periodoAnio']),
      periodoMes: _parseOptionalInt(json['periodoMes']),
      costoPieles: (json['costoPieles'] as num).toDouble(),
      costoInsumos: (json['costoInsumos'] as num).toDouble(),
      costoManoObra: (json['costoManoObra'] as num).toDouble(),
      costoIndirectoAsignado: (json['costoIndirectoAsignado'] as num).toDouble(),
      costoDepreciacionAsignado: (json['costoDepreciacionAsignado'] as num).toDouble(),
      costoTotal: (json['costoTotal'] as num).toDouble(),
      pielesBuenasFinales: _parseOptionalDouble(json['pielesBuenasFinales']),
      costoPorPiel: _parseOptionalDouble(json['costoPorPiel']),
      costoEstimado: _parseOptionalDouble(json['costoEstimado']),
      costoReal: _parseOptionalDouble(json['costoReal']),
      estado: json['estado'] as String,
      calculadoEn: DateTime.parse(json['calculadoEn'] as String),
      calculadoPorUsuarioId: _parseOptionalInt(json['calculadoPorUsuarioId']),
    );
  }

  CostoOrdenRecord toEntity() {
    return CostoOrdenRecord(
      id: id,
      ordenProduccionId: ordenProduccionId,
      ordenProduccionCodigo: ordenProduccionCodigo,
      periodoCostoId: periodoCostoId,
      periodoAnio: periodoAnio,
      periodoMes: periodoMes,
      costoPieles: costoPieles,
      costoInsumos: costoInsumos,
      costoManoObra: costoManoObra,
      costoIndirectoAsignado: costoIndirectoAsignado,
      costoDepreciacionAsignado: costoDepreciacionAsignado,
      costoTotal: costoTotal,
      pielesBuenasFinales: pielesBuenasFinales,
      costoPorPiel: costoPorPiel,
      costoEstimado: costoEstimado,
      costoReal: costoReal,
      estado: estado,
      calculadoEn: calculadoEn,
      calculadoPorUsuarioId: calculadoPorUsuarioId,
    );
  }

  static int? _parseOptionalInt(dynamic value) {
    if (value is num) return value.toInt();
    return null;
  }

  static double? _parseOptionalDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return null;
  }
}

