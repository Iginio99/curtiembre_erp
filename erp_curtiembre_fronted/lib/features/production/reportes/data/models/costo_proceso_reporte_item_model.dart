import 'package:erp_curtiembre_fronted/features/production/reportes/domain/entities/costo_proceso_reporte_item.dart';

class CostoProcesoReporteItemModel {
  const CostoProcesoReporteItemModel({
    required this.ordenProduccionId,
    required this.codigoOrden,
    required this.ordenProcesoId,
    required this.procesoCodigo,
    required this.procesoNombre,
    required this.cantidadPieles,
    required this.cantidadConsumida,
    required this.costoMaterialesReal,
    this.fechaInicio,
    this.fechaFin,
    this.pesoBaseKg,
    this.insumoId,
    this.insumoCodigo,
    this.insumoNombre,
    this.porcentaje,
    this.costoUnitario,
  });

  final int ordenProduccionId;
  final String codigoOrden;
  final int ordenProcesoId;
  final String procesoCodigo;
  final String procesoNombre;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final double cantidadPieles;
  final double? pesoBaseKg;
  final int? insumoId;
  final String? insumoCodigo;
  final String? insumoNombre;
  final double? porcentaje;
  final double cantidadConsumida;
  final double? costoUnitario;
  final double costoMaterialesReal;

  factory CostoProcesoReporteItemModel.fromJson(Map<String, dynamic> json) =>
      CostoProcesoReporteItemModel(
        ordenProduccionId: (json['ordenProduccionId'] as num).toInt(),
        codigoOrden: json['codigoOrden'] as String,
        ordenProcesoId: (json['ordenProcesoId'] as num).toInt(),
        procesoCodigo: json['procesoCodigo'] as String,
        procesoNombre: json['procesoNombre'] as String,
        fechaInicio: json['fechaInicio'] == null
            ? null
            : DateTime.parse(json['fechaInicio'] as String),
        fechaFin: json['fechaFin'] == null
            ? null
            : DateTime.parse(json['fechaFin'] as String),
        cantidadPieles: (json['cantidadPieles'] as num).toDouble(),
        pesoBaseKg: (json['pesoBaseKg'] as num?)?.toDouble(),
        insumoId: (json['insumoId'] as num?)?.toInt(),
        insumoCodigo: json['insumoCodigo'] as String?,
        insumoNombre: json['insumoNombre'] as String?,
        porcentaje: (json['porcentaje'] as num?)?.toDouble(),
        cantidadConsumida: (json['cantidadConsumida'] as num).toDouble(),
        costoUnitario: (json['costoUnitario'] as num?)?.toDouble(),
        costoMaterialesReal: (json['costoMaterialesReal'] as num).toDouble(),
      );

  CostoProcesoReporteItem toEntity() => CostoProcesoReporteItem(
    ordenProduccionId: ordenProduccionId,
    codigoOrden: codigoOrden,
    ordenProcesoId: ordenProcesoId,
    procesoCodigo: procesoCodigo,
    procesoNombre: procesoNombre,
    fechaInicio: fechaInicio,
    fechaFin: fechaFin,
    cantidadPieles: cantidadPieles,
    pesoBaseKg: pesoBaseKg,
    insumoId: insumoId,
    insumoCodigo: insumoCodigo,
    insumoNombre: insumoNombre,
    porcentaje: porcentaje,
    cantidadConsumida: cantidadConsumida,
    costoUnitario: costoUnitario,
    costoMaterialesReal: costoMaterialesReal,
  );
}
