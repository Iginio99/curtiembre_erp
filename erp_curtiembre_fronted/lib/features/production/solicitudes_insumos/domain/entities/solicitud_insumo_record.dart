import 'package:equatable/equatable.dart';

class SolicitudInsumoRecord extends Equatable {
  const SolicitudInsumoRecord({
    required this.id,
    required this.codigo,
    required this.ordenCodigo,
    required this.procesoCodigo,
    required this.procesoNombre,
    required this.estado,
    required this.solicitadoEn,
    required this.solicitadoPorNombre,
    required this.totalItems,
    required this.cantidadTotal,
    this.observacion,
  });

  final int id;
  final String codigo;
  final String ordenCodigo;
  final String procesoCodigo;
  final String procesoNombre;
  final String estado;
  final DateTime solicitadoEn;
  final String solicitadoPorNombre;
  final int totalItems;
  final double cantidadTotal;
  final String? observacion;

  bool get canDeliver => estado == 'SOLICITADA';

  @override
  List<Object?> get props => [
    id,
    codigo,
    ordenCodigo,
    procesoCodigo,
    procesoNombre,
    estado,
    solicitadoEn,
    solicitadoPorNombre,
    totalItems,
    cantidadTotal,
    observacion,
  ];
}
