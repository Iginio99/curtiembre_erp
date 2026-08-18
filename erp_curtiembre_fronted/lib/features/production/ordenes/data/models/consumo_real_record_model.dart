import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/consumo_real_record.dart';

class ConsumoRealRecordModel {
  const ConsumoRealRecordModel({
    required this.id,
    required this.ordenProduccionId,
    required this.ordenProcesoId,
    required this.procesoProductivoId,
    required this.procesoCodigo,
    required this.procesoNombre,
    required this.insumoId,
    required this.insumoCodigo,
    required this.insumoNombre,
    required this.cantidadConsumida,
    required this.costoUnitario,
    required this.costoTotal,
    required this.esExtra,
    required this.creadoEn,
    this.salidaInventarioDetalleId,
  });

  final int id;
  final int ordenProduccionId;
  final int ordenProcesoId;
  final int procesoProductivoId;
  final String procesoCodigo;
  final String procesoNombre;
  final int? salidaInventarioDetalleId;
  final int insumoId;
  final String insumoCodigo;
  final String insumoNombre;
  final double cantidadConsumida;
  final double costoUnitario;
  final double costoTotal;
  final bool esExtra;
  final DateTime creadoEn;

  factory ConsumoRealRecordModel.fromJson(Map<String, dynamic> json) {
    return ConsumoRealRecordModel(
      id: (json['id'] as num).toInt(),
      ordenProduccionId: (json['ordenProduccionId'] as num).toInt(),
      ordenProcesoId: (json['ordenProcesoId'] as num).toInt(),
      procesoProductivoId: (json['procesoProductivoId'] as num).toInt(),
      procesoCodigo: json['procesoCodigo'] as String,
      procesoNombre: json['procesoNombre'] as String,
      salidaInventarioDetalleId: _parseOptionalInt(json['salidaInventarioDetalleId']),
      insumoId: (json['insumoId'] as num).toInt(),
      insumoCodigo: json['insumoCodigo'] as String,
      insumoNombre: json['insumoNombre'] as String,
      cantidadConsumida: (json['cantidadConsumida'] as num).toDouble(),
      costoUnitario: (json['costoUnitario'] as num).toDouble(),
      costoTotal: (json['costoTotal'] as num).toDouble(),
      esExtra: json['esExtra'] as bool,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
    );
  }

  ConsumoRealRecord toEntity() {
    return ConsumoRealRecord(
      id: id,
      ordenProduccionId: ordenProduccionId,
      ordenProcesoId: ordenProcesoId,
      procesoProductivoId: procesoProductivoId,
      procesoCodigo: procesoCodigo,
      procesoNombre: procesoNombre,
      salidaInventarioDetalleId: salidaInventarioDetalleId,
      insumoId: insumoId,
      insumoCodigo: insumoCodigo,
      insumoNombre: insumoNombre,
      cantidadConsumida: cantidadConsumida,
      costoUnitario: costoUnitario,
      costoTotal: costoTotal,
      esExtra: esExtra,
      creadoEn: creadoEn,
    );
  }

  static int? _parseOptionalInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return null;
  }
}
