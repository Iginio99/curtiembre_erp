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
  final double? pesoBaseKg;
  final DateTime? fechaFinEstimada;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final int? diasReales;
  final String estado;
  final String? observacion;

  bool get canStart => estado == 'PENDIENTE' || estado == 'LISTA_PARA_INICIAR';
  bool get canFinish => estado == 'EN_PROCESO';

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
    pesoBaseKg,
    fechaFinEstimada,
    fechaInicio,
    fechaFin,
    diasReales,
    estado,
    observacion,
  ];
}
