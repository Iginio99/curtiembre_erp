import 'package:equatable/equatable.dart';

class OrdenClienteReporteItem extends Equatable {
  const OrdenClienteReporteItem({
    required this.ordenProduccionId,
    required this.codigoOrden,
    required this.clienteId,
    required this.cliente,
    required this.codigoLote,
    required this.cantidadPieles,
    required this.fechaFinEstimada,
    required this.estado,
    this.fechaInicioReal,
    this.fechaFinReal,
  });

  final int ordenProduccionId;
  final String codigoOrden;
  final int clienteId;
  final String cliente;
  final String codigoLote;
  final double cantidadPieles;
  final DateTime? fechaInicioReal;
  final DateTime fechaFinEstimada;
  final DateTime? fechaFinReal;
  final String estado;

  @override
  List<Object?> get props => [
    ordenProduccionId,
    codigoOrden,
    clienteId,
    cliente,
    codigoLote,
    cantidadPieles,
    fechaInicioReal,
    fechaFinEstimada,
    fechaFinReal,
    estado,
  ];
}
