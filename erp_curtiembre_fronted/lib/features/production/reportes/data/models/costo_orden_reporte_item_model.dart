import 'package:erp_curtiembre_fronted/features/production/reportes/domain/entities/costo_orden_reporte_item.dart';

class CostoOrdenReporteItemModel {
  const CostoOrdenReporteItemModel({
    required this.ordenProduccionId,
    required this.codigoOrden,
    required this.cliente,
    required this.codigoLote,
    required this.cantidadPieles,
    required this.cantidadLados,
    required this.costoMaterialesReal,
    required this.costoMaterialesPorPiel,
    required this.costoMaterialesPorLado,
  });

  final int ordenProduccionId;
  final String codigoOrden;
  final String cliente;
  final String codigoLote;
  final double cantidadPieles;
  final double cantidadLados;
  final double costoMaterialesReal;
  final double costoMaterialesPorPiel;
  final double costoMaterialesPorLado;

  factory CostoOrdenReporteItemModel.fromJson(
    Map<String, dynamic> json,
  ) => CostoOrdenReporteItemModel(
    ordenProduccionId: (json['ordenProduccionId'] as num).toInt(),
    codigoOrden: json['codigoOrden'] as String,
    cliente: json['cliente'] as String,
    codigoLote: json['codigoLote'] as String,
    cantidadPieles: (json['cantidadPieles'] as num).toDouble(),
    cantidadLados: (json['cantidadLados'] as num).toDouble(),
    costoMaterialesReal: (json['costoMaterialesReal'] as num).toDouble(),
    costoMaterialesPorPiel: (json['costoMaterialesPorPiel'] as num).toDouble(),
    costoMaterialesPorLado: (json['costoMaterialesPorLado'] as num).toDouble(),
  );

  CostoOrdenReporteItem toEntity() => CostoOrdenReporteItem(
    ordenProduccionId: ordenProduccionId,
    codigoOrden: codigoOrden,
    cliente: cliente,
    codigoLote: codigoLote,
    cantidadPieles: cantidadPieles,
    cantidadLados: cantidadLados,
    costoMaterialesReal: costoMaterialesReal,
    costoMaterialesPorPiel: costoMaterialesPorPiel,
    costoMaterialesPorLado: costoMaterialesPorLado,
  );
}
