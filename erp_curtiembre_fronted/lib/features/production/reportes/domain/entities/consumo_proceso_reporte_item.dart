import 'package:equatable/equatable.dart';

class ConsumoProcesoReporteItem extends Equatable {
  const ConsumoProcesoReporteItem({
    required this.ordenProduccionId,
    required this.codigoOrden,
    required this.ordenCantidadPieles,
    required this.ordenProcesoId,
    required this.procesoCodigo,
    required this.procesoNombre,
    this.ordenProductoId,
    this.productoNombre,
    this.productoColor,
    this.productoEstado,
    this.productoCantidadPieles,
    this.productoCantidadLados,
    this.productoCantidadPielesTerminadas,
    this.productoPesoBaseKg,
    this.productoInicio,
    this.productoFin,
    required this.insumoId,
    required this.insumoCodigo,
    required this.insumoNombre,
    required this.cantidadPlanificada,
    required this.cantidadReal,
    required this.cantidadDesviacion,
    required this.costoTotal,
    this.costoUnitario,
  });

  final int ordenProduccionId;
  final String codigoOrden;
  final double ordenCantidadPieles;
  final int ordenProcesoId;
  final String procesoCodigo;
  final String procesoNombre;
  final int? ordenProductoId;
  final String? productoNombre;
  final String? productoColor;
  final String? productoEstado;
  final double? productoCantidadPieles;
  final double? productoCantidadLados;
  final double? productoCantidadPielesTerminadas;
  final double? productoPesoBaseKg;
  final DateTime? productoInicio;
  final DateTime? productoFin;
  final int insumoId;
  final String insumoCodigo;
  final String insumoNombre;
  final double cantidadPlanificada;
  final double cantidadReal;
  final double cantidadDesviacion;
  final double? costoUnitario;
  final double costoTotal;

  @override
  List<Object?> get props => [
    ordenProduccionId,
    codigoOrden,
    ordenCantidadPieles,
    ordenProcesoId,
    procesoCodigo,
    procesoNombre,
    ordenProductoId,
    productoNombre,
    productoColor,
    productoEstado,
    productoCantidadPieles,
    productoCantidadLados,
    productoCantidadPielesTerminadas,
    productoPesoBaseKg,
    productoInicio,
    productoFin,
    insumoId,
    insumoCodigo,
    insumoNombre,
    cantidadPlanificada,
    cantidadReal,
    cantidadDesviacion,
    costoUnitario,
    costoTotal,
  ];
}
