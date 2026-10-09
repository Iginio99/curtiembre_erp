import 'package:equatable/equatable.dart';

class CostoProcesoReporteItem extends Equatable {
  const CostoProcesoReporteItem({
    required this.ordenProduccionId,
    required this.codigoOrden,
    required this.ordenProcesoId,
    required this.procesoCodigo,
    required this.procesoNombre,
    this.ordenProductoId,
    this.productoNombre,
    this.productoColor,
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
  final int? ordenProductoId;
  final String? productoNombre;
  final String? productoColor;
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

  @override
  List<Object?> get props => [
    ordenProduccionId,
    codigoOrden,
    ordenProcesoId,
    procesoCodigo,
    procesoNombre,
    ordenProductoId,
    productoNombre,
    productoColor,
    fechaInicio,
    fechaFin,
    cantidadPieles,
    pesoBaseKg,
    insumoId,
    insumoCodigo,
    insumoNombre,
    porcentaje,
    cantidadConsumida,
    costoUnitario,
    costoMaterialesReal,
  ];
}
