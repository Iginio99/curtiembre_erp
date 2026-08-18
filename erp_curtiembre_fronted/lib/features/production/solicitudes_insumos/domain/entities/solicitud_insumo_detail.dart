import 'package:equatable/equatable.dart';

class SolicitudInsumoDetail extends Equatable {
  const SolicitudInsumoDetail({required this.codigo, required this.detalles});

  final String codigo;
  final List<SolicitudInsumoDetailLine> detalles;

  @override
  List<Object?> get props => [codigo, detalles];
}

class SolicitudInsumoDetailLine extends Equatable {
  const SolicitudInsumoDetailLine({
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
