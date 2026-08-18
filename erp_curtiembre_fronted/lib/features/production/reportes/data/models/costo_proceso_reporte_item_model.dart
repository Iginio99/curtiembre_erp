import 'package:erp_curtiembre_fronted/features/production/reportes/domain/entities/costo_proceso_reporte_item.dart';

class CostoProcesoReporteItemModel {
  const CostoProcesoReporteItemModel({
    required this.ordenProduccionId,
    required this.codigoOrden,
    required this.ordenProcesoId,
    required this.procesoCodigo,
    required this.procesoNombre,
    required this.costoMaterialesReal,
  });

  final int ordenProduccionId;
  final String codigoOrden;
  final int ordenProcesoId;
  final String procesoCodigo;
  final String procesoNombre;
  final double costoMaterialesReal;

  factory CostoProcesoReporteItemModel.fromJson(Map<String, dynamic> json) =>
      CostoProcesoReporteItemModel(
        ordenProduccionId: (json['ordenProduccionId'] as num).toInt(),
        codigoOrden: json['codigoOrden'] as String,
        ordenProcesoId: (json['ordenProcesoId'] as num).toInt(),
        procesoCodigo: json['procesoCodigo'] as String,
        procesoNombre: json['procesoNombre'] as String,
        costoMaterialesReal: (json['costoMaterialesReal'] as num).toDouble(),
      );

  CostoProcesoReporteItem toEntity() => CostoProcesoReporteItem(
    ordenProduccionId: ordenProduccionId,
    codigoOrden: codigoOrden,
    ordenProcesoId: ordenProcesoId,
    procesoCodigo: procesoCodigo,
    procesoNombre: procesoNombre,
    costoMaterialesReal: costoMaterialesReal,
  );
}
