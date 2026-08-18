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
    required this.estado,
    this.observacion,
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
  final String estado;
  final String? observacion;

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
        estado,
        observacion,
      ];
}
