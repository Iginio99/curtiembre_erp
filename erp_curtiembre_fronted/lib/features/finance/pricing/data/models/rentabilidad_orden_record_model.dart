import 'package:erp_curtiembre_fronted/features/finance/pricing/domain/entities/rentabilidad_orden_record.dart';

class RentabilidadOrdenRecordModel {
  const RentabilidadOrdenRecordModel({
    required this.id,
    required this.ordenProduccionId,
    required this.ordenProduccionCodigo,
    required this.precioVenta,
    required this.costoTotal,
    required this.utilidad,
    required this.calculadoEn,
    this.margenPorcentaje,
  });

  final int id;
  final int ordenProduccionId;
  final String ordenProduccionCodigo;
  final double precioVenta;
  final double costoTotal;
  final double utilidad;
  final double? margenPorcentaje;
  final DateTime calculadoEn;

  factory RentabilidadOrdenRecordModel.fromJson(Map<String, dynamic> json) {
    return RentabilidadOrdenRecordModel(
      id: (json['id'] as num).toInt(),
      ordenProduccionId: (json['ordenProduccionId'] as num).toInt(),
      ordenProduccionCodigo: json['ordenProduccionCodigo'] as String,
      precioVenta: (json['precioVenta'] as num).toDouble(),
      costoTotal: (json['costoTotal'] as num).toDouble(),
      utilidad: (json['utilidad'] as num).toDouble(),
      margenPorcentaje: json['margenPorcentaje'] == null
          ? null
          : (json['margenPorcentaje'] as num).toDouble(),
      calculadoEn: DateTime.parse(json['calculadoEn'] as String),
    );
  }

  RentabilidadOrdenRecord toEntity() {
    return RentabilidadOrdenRecord(
      id: id,
      ordenProduccionId: ordenProduccionId,
      ordenProduccionCodigo: ordenProduccionCodigo,
      precioVenta: precioVenta,
      costoTotal: costoTotal,
      utilidad: utilidad,
      margenPorcentaje: margenPorcentaje,
      calculadoEn: calculadoEn,
    );
  }
}

