import 'package:equatable/equatable.dart';

class MermaReporteItem extends Equatable {
  const MermaReporteItem({
    required this.id,
    required this.ordenProduccionId,
    required this.codigoOrden,
    required this.ordenProcesoId,
    required this.procesoCodigo,
    required this.procesoNombre,
    required this.cantidadPerdida,
    required this.registradoEn,
    this.motivo,
    this.responsable,
  });

  final int id;
  final int ordenProduccionId;
  final String codigoOrden;
  final int ordenProcesoId;
  final String procesoCodigo;
  final String procesoNombre;
  final double cantidadPerdida;
  final String? motivo;
  final DateTime registradoEn;
  final String? responsable;

  @override
  List<Object?> get props => [
    id,
    ordenProduccionId,
    codigoOrden,
    ordenProcesoId,
    procesoCodigo,
    procesoNombre,
    cantidadPerdida,
    motivo,
    registradoEn,
    responsable,
  ];
}
