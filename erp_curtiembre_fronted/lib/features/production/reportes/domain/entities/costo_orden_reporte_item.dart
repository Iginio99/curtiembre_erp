import 'package:equatable/equatable.dart';

class CostoOrdenReporteItem extends Equatable {
  const CostoOrdenReporteItem({
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

  @override
  List<Object?> get props => [
    ordenProduccionId,
    codigoOrden,
    cliente,
    codigoLote,
    cantidadPieles,
    cantidadLados,
    costoMaterialesReal,
    costoMaterialesPorPiel,
    costoMaterialesPorLado,
  ];
}
