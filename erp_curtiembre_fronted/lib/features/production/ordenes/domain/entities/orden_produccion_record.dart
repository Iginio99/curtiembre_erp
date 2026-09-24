import 'package:equatable/equatable.dart';

class OrdenProduccionRecord extends Equatable {
  const OrdenProduccionRecord({
    required this.id,
    required this.codigo,
    required this.loteId,
    required this.loteCodigo,
    required this.clienteId,
    required this.clienteRazonSocial,
    required this.cantidadPieles,
    required this.fechaFinEstimada,
    required this.estado,
    required this.procesosTotales,
    required this.procesosFinalizados,
    required this.creadoEn,
    this.fechaInicioPlanificada,
    this.fechaInicioReal,
    this.fechaFinReal,
    this.responsableUsuarioId,
    this.responsableNombre,
    this.observacion,
    this.motivoAnulacion,
    this.creadoPorUsuarioId,
    this.actualizadoEn,
    this.actualizadoPorUsuarioId,
  });

  final int id;
  final String codigo;
  final int loteId;
  final String loteCodigo;
  final int clienteId;
  final String clienteRazonSocial;
  final double cantidadPieles;
  final DateTime? fechaInicioPlanificada;
  final DateTime? fechaInicioReal;
  final DateTime fechaFinEstimada;
  final DateTime? fechaFinReal;
  final int? responsableUsuarioId;
  final String? responsableNombre;
  final String estado;
  final String? observacion;
  final String? motivoAnulacion;
  final int procesosTotales;
  final int procesosFinalizados;
  final DateTime creadoEn;
  final int? creadoPorUsuarioId;
  final DateTime? actualizadoEn;
  final int? actualizadoPorUsuarioId;

  double get progresoProcesos {
    if (procesosTotales <= 0) {
      return 0;
    }

    return procesosFinalizados / procesosTotales;
  }

  bool get canStart => estado == 'PROGRAMADA';
  bool get canCancel =>
      estado == 'PROGRAMADA' || estado == 'LISTA_PARA_INICIAR';

  @override
  List<Object?> get props => [
    id,
    codigo,
    loteId,
    loteCodigo,
    clienteId,
    clienteRazonSocial,
    cantidadPieles,
    fechaInicioPlanificada,
    fechaInicioReal,
    fechaFinEstimada,
    fechaFinReal,
    responsableUsuarioId,
    responsableNombre,
    estado,
    observacion,
    motivoAnulacion,
    procesosTotales,
    procesosFinalizados,
    creadoEn,
    creadoPorUsuarioId,
    actualizadoEn,
    actualizadoPorUsuarioId,
  ];
}
