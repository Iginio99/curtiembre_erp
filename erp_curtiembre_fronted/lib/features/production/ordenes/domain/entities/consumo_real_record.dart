import 'package:equatable/equatable.dart';

class ConsumoRealRecord extends Equatable {
  const ConsumoRealRecord({
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

  @override
  List<Object?> get props => [
    id,
    ordenProduccionId,
    ordenProcesoId,
    procesoProductivoId,
    procesoCodigo,
    procesoNombre,
    salidaInventarioDetalleId,
    insumoId,
    insumoCodigo,
    insumoNombre,
    cantidadConsumida,
    costoUnitario,
    costoTotal,
    esExtra,
    creadoEn,
  ];
}
