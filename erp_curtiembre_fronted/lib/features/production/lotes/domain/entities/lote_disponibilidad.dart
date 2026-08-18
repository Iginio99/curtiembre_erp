import 'package:equatable/equatable.dart';

class LoteDisponibilidad extends Equatable {
  const LoteDisponibilidad({
    required this.id,
    required this.codigo,
    required this.clienteId,
    required this.clienteRazonSocial,
    required this.cantidadPielesInicial,
    required this.cantidadPielesUtilizada,
    required this.cantidadPielesDisponible,
    required this.cantidadLadosCalculada,
    required this.estado,
  });

  final int id;
  final String codigo;
  final int clienteId;
  final String clienteRazonSocial;
  final double cantidadPielesInicial;
  final double cantidadPielesUtilizada;
  final double cantidadPielesDisponible;
  final double cantidadLadosCalculada;
  final String estado;

  @override
  List<Object?> get props => [
        id,
        codigo,
        clienteId,
        clienteRazonSocial,
        cantidadPielesInicial,
        cantidadPielesUtilizada,
        cantidadPielesDisponible,
        cantidadLadosCalculada,
        estado,
      ];
}
