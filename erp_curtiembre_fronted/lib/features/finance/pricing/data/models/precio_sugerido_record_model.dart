import 'package:erp_curtiembre_fronted/features/finance/pricing/domain/entities/precio_sugerido_record.dart';

class PrecioSugeridoRecordModel {
  const PrecioSugeridoRecordModel({
    required this.id,
    required this.ordenProduccionId,
    required this.ordenProduccionCodigo,
    required this.costoBaseSinIgv,
    required this.margenPorcentaje,
    required this.precioSugeridoSinIgv,
    required this.igvPorcentaje,
    required this.precioSugeridoConIgv,
    required this.calculadoEn,
  });

  final int id;
  final int ordenProduccionId;
  final String ordenProduccionCodigo;
  final double costoBaseSinIgv;
  final double margenPorcentaje;
  final double precioSugeridoSinIgv;
  final double igvPorcentaje;
  final double precioSugeridoConIgv;
  final DateTime calculadoEn;

  factory PrecioSugeridoRecordModel.fromJson(Map<String, dynamic> json) {
    return PrecioSugeridoRecordModel(
      id: (json['id'] as num).toInt(),
      ordenProduccionId: (json['ordenProduccionId'] as num).toInt(),
      ordenProduccionCodigo: json['ordenProduccionCodigo'] as String,
      costoBaseSinIgv: (json['costoBaseSinIgv'] as num).toDouble(),
      margenPorcentaje: (json['margenPorcentaje'] as num).toDouble(),
      precioSugeridoSinIgv: (json['precioSugeridoSinIgv'] as num).toDouble(),
      igvPorcentaje: (json['igvPorcentaje'] as num).toDouble(),
      precioSugeridoConIgv: (json['precioSugeridoConIgv'] as num).toDouble(),
      calculadoEn: DateTime.parse(json['calculadoEn'] as String),
    );
  }

  PrecioSugeridoRecord toEntity() {
    return PrecioSugeridoRecord(
      id: id,
      ordenProduccionId: ordenProduccionId,
      ordenProduccionCodigo: ordenProduccionCodigo,
      costoBaseSinIgv: costoBaseSinIgv,
      margenPorcentaje: margenPorcentaje,
      precioSugeridoSinIgv: precioSugeridoSinIgv,
      igvPorcentaje: igvPorcentaje,
      precioSugeridoConIgv: precioSugeridoConIgv,
      calculadoEn: calculadoEn,
    );
  }
}

