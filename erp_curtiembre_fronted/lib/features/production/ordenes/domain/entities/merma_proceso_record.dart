import 'package:equatable/equatable.dart';

class MermaProcesoRecord extends Equatable {
  const MermaProcesoRecord({
    required this.id,
    required this.ordenProduccionId,
    required this.ordenProcesoId,
    required this.procesoProductivoId,
    required this.procesoCodigo,
    required this.procesoNombre,
    required this.cantidadPerdida,
    required this.registradoEn,
    this.motivo,
    this.observacion,
    this.registradoPorUsuarioId,
    this.registradoPorNombre,
  });

  final int id;
  final int ordenProduccionId;
  final int ordenProcesoId;
  final int procesoProductivoId;
  final String procesoCodigo;
  final String procesoNombre;
  final double cantidadPerdida;
  final String? motivo;
  final String? observacion;
  final DateTime registradoEn;
  final int? registradoPorUsuarioId;
  final String? registradoPorNombre;

  @override
  List<Object?> get props => [
    id,
    ordenProduccionId,
    ordenProcesoId,
    procesoProductivoId,
    procesoCodigo,
    procesoNombre,
    cantidadPerdida,
    motivo,
    observacion,
    registradoEn,
    registradoPorUsuarioId,
    registradoPorNombre,
  ];
}
