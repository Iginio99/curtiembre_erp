import 'package:equatable/equatable.dart';

class ControlCalidadRecord extends Equatable {
  const ControlCalidadRecord({
    required this.id,
    required this.ordenProduccionId,
    required this.calidadProductoId,
    required this.calidadCodigo,
    required this.calidadNombre,
    required this.cantidadLadosA,
    required this.cantidadLadosB,
    required this.cantidadLadosC,
    required this.cantidadLadosMerma,
    required this.resultado,
    required this.evaluadoEn,
    this.productoTerminadoId,
    this.observacion,
    this.evaluadoPorUsuarioId,
    this.evaluadoPorNombre,
  });

  final int id;
  final int ordenProduccionId;
  final int? productoTerminadoId;
  final int calidadProductoId;
  final String calidadCodigo;
  final String calidadNombre;
  final double cantidadLadosA;
  final double cantidadLadosB;
  final double cantidadLadosC;
  final double cantidadLadosMerma;
  final String resultado;
  final String? observacion;
  final DateTime evaluadoEn;
  final int? evaluadoPorUsuarioId;
  final String? evaluadoPorNombre;

  @override
  List<Object?> get props => [
    id,
    ordenProduccionId,
    productoTerminadoId,
    calidadProductoId,
    calidadCodigo,
    calidadNombre,
    cantidadLadosA,
    cantidadLadosB,
    cantidadLadosC,
    cantidadLadosMerma,
    resultado,
    observacion,
    evaluadoEn,
    evaluadoPorUsuarioId,
    evaluadoPorNombre,
  ];
}
