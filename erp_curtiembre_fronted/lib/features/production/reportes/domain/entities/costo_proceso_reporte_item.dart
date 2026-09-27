import 'package:equatable/equatable.dart';

class CostoProcesoReporteItem extends Equatable {
  const CostoProcesoReporteItem({
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

  @override
  List<Object?> get props => [
    ordenProduccionId,
    codigoOrden,
    ordenProcesoId,
    procesoCodigo,
    procesoNombre,
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
