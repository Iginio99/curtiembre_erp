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
    this.solicitudInsumosEstado,
    this.insumosSolicitados = const [],
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
  final String? solicitudInsumosEstado;
  final List<OrdenProcesoInsumoSolicitado> insumosSolicitados;

  bool get canStart => estado == 'PENDIENTE' && fechaInicio == null;
  bool get canFinish =>
      estado == 'EN_PROCESO' ||
      (estado == 'LISTA_PARA_INICIAR' && fechaInicio != null);
  bool get hasApprovedSupplies => solicitudInsumosEstado == 'APROBADA';
  bool get hasPendingSupplyRequest =>
      solicitudInsumosEstado == 'SOLICITADA' ||
      solicitudInsumosEstado == 'PARCIAL' ||
      solicitudInsumosEstado == 'ENTREGANDO';

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
    solicitudInsumosEstado,
    insumosSolicitados,
  ];
}

class OrdenProcesoInsumoSolicitado extends Equatable {
  const OrdenProcesoInsumoSolicitado({
    required this.insumoCodigo,
    required this.insumoNombre,
    required this.unidadMedidaCodigo,
    required this.cantidadSolicitada,
  });

  final String insumoCodigo;
  final String insumoNombre;
  final String unidadMedidaCodigo;
  final double cantidadSolicitada;

  @override
  List<Object?> get props => [
    insumoCodigo,
    insumoNombre,
    unidadMedidaCodigo,
    cantidadSolicitada,
  ];
}
