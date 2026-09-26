import 'package:equatable/equatable.dart';

class OrdenProcesoRecord extends Equatable {
  const OrdenProcesoRecord({
    required this.id,
    required this.ordenProduccionId,
    required this.procesoProductivoId,
    required this.procesoCodigo,
    required this.procesoNombre,
    required this.secuencia,
    required this.estado,
    this.responsableUsuarioId,
    this.responsableNombre,
    this.responsableCargo,
    this.pesoBaseKg,
    this.fechaFinEstimada,
    this.fechaInicio,
    this.fechaFin,
    this.diasReales,
    this.observacion,
  });

  final int id;
  final int ordenProduccionId;
  final int procesoProductivoId;
  final String procesoCodigo;
  final String procesoNombre;
  final int secuencia;
  final int? responsableUsuarioId;
  final String? responsableNombre;
  final String? responsableCargo;
  final double? pesoBaseKg;
  final DateTime? fechaFinEstimada;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final int? diasReales;
  final String estado;
  final String? observacion;

  bool get canStart => estado == 'PENDIENTE' && fechaInicio == null;
  bool get canFinish =>
      estado == 'EN_PROCESO' ||
      (estado == 'LISTA_PARA_INICIAR' && fechaInicio != null);

  @override
  List<Object?> get props => [
    id,
    ordenProduccionId,
    procesoProductivoId,
    procesoCodigo,
    procesoNombre,
    secuencia,
    responsableUsuarioId,
    responsableNombre,
    responsableCargo,
    pesoBaseKg,
    fechaFinEstimada,
    fechaInicio,
    fechaFin,
    diasReales,
    estado,
    observacion,
  ];
}
