import 'package:equatable/equatable.dart';

class CostoProcesoReporteItem extends Equatable {
  const CostoProcesoReporteItem({
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

  @override
  List<Object?> get props => [
    ordenProduccionId,
    codigoOrden,
    ordenProcesoId,
    procesoCodigo,
    procesoNombre,
    costoMaterialesReal,
  ];
}
