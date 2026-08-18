import 'package:equatable/equatable.dart';

class TiempoProcesoReporteItem extends Equatable {
  const TiempoProcesoReporteItem({
    required this.ordenProduccionId,
    required this.codigoOrden,
    required this.ordenProcesoId,
    required this.procesoCodigo,
    required this.procesoNombre,
    required this.estado,
    this.fechaInicio,
    this.fechaFin,
    this.diasReales,
    this.responsable,
  });

  final int ordenProduccionId;
  final String codigoOrden;
  final int ordenProcesoId;
  final String procesoCodigo;
  final String procesoNombre;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final int? diasReales;
  final String estado;
  final String? responsable;

  @override
  List<Object?> get props => [
    ordenProduccionId,
    codigoOrden,
    ordenProcesoId,
    procesoCodigo,
    procesoNombre,
    fechaInicio,
    fechaFin,
    diasReales,
    estado,
    responsable,
  ];
}
