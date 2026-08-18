import 'package:equatable/equatable.dart';

class ConsumoProcesoReporteItem extends Equatable {
  const ConsumoProcesoReporteItem({
    required this.ordenProduccionId,
    required this.codigoOrden,
    required this.ordenProcesoId,
    required this.procesoCodigo,
    required this.procesoNombre,
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
  final int ordenProcesoId;
  final String procesoCodigo;
  final String procesoNombre;
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
    ordenProcesoId,
    procesoCodigo,
    procesoNombre,
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
