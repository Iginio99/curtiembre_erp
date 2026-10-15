import 'package:equatable/equatable.dart';

class ProductoTerminadoRecord extends Equatable {
  const ProductoTerminadoRecord({
    required this.id,
    required this.codigo,
    required this.ordenProduccionId,
    required this.ordenCodigo,
    required this.calidadProductoId,
    required this.calidadCodigo,
    required this.calidadNombre,
    required this.fechaIngreso,
    required this.cantidadPielesBuenas,
    required this.cantidadLadosCalculada,
    required this.cantidadLadosA,
    required this.cantidadLadosB,
    required this.cantidadLadosC,
    required this.cantidadLadosMerma,
    required this.estado,
    this.observacion,
    this.ordenProductoId,
    this.productoNombre,
    this.productoColor,
    this.esProductoIndividual = false,
    this.clienteNombre,
    this.cantidadLadosProgramados = 0,
    this.cantidadLadosEntregados = 0,
    this.cantidadLadosPendientes = 0,
    this.fechaOrden,
    this.fechaTerminacionOrden,
  });

  final int id;
  final String codigo;
  final int ordenProduccionId;
  final String ordenCodigo;
  final int calidadProductoId;
  final String calidadCodigo;
  final String calidadNombre;
  final DateTime fechaIngreso;
  final double cantidadPielesBuenas;
  final double cantidadLadosCalculada;
  final double cantidadLadosA;
  final double cantidadLadosB;
  final double cantidadLadosC;
  final double cantidadLadosMerma;
  final String estado;
  final String? observacion;
  final int? ordenProductoId;
  final String? productoNombre, productoColor;
  final bool esProductoIndividual;
  final String? clienteNombre;
  final double cantidadLadosProgramados;
  final double cantidadLadosEntregados;
  final double cantidadLadosPendientes;
  final DateTime? fechaOrden;
  final DateTime? fechaTerminacionOrden;

  @override
  List<Object?> get props => [
    id,
    codigo,
    ordenProduccionId,
    ordenCodigo,
    calidadProductoId,
    calidadCodigo,
    calidadNombre,
    fechaIngreso,
    cantidadPielesBuenas,
    cantidadLadosCalculada,
    cantidadLadosA,
    cantidadLadosB,
    cantidadLadosC,
    cantidadLadosMerma,
    estado,
    observacion,
    ordenProductoId,
    productoNombre,
    productoColor,
    esProductoIndividual,
    clienteNombre,
    cantidadLadosProgramados,
    cantidadLadosEntregados,
    cantidadLadosPendientes,
    fechaOrden,
    fechaTerminacionOrden,
  ];
}
