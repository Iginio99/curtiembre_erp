import 'package:equatable/equatable.dart';

class OrdenActivaReporteItem extends Equatable {
  const OrdenActivaReporteItem({
    required this.ordenProduccionId,
    required this.codigoOrden,
    required this.cliente,
    required this.codigoLote,
    required this.fechaFinEstimada,
    required this.estado,
    this.responsable,
    this.fechaInicioReal,
  });

  final int ordenProduccionId;
  final String codigoOrden;
  final String cliente;
  final String codigoLote;
  final String? responsable;
  final DateTime? fechaInicioReal;
  final DateTime fechaFinEstimada;
  final String estado;

  @override
  List<Object?> get props => [
    ordenProduccionId,
    codigoOrden,
    cliente,
    codigoLote,
    responsable,
    fechaInicioReal,
    fechaFinEstimada,
    estado,
  ];
}
