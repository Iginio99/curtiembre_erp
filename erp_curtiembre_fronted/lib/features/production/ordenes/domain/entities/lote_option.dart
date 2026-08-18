import 'package:equatable/equatable.dart';

class LoteOption extends Equatable {
  const LoteOption({
    required this.id,
    required this.codigo,
    required this.clienteId,
    required this.clienteRazonSocial,
    required this.cantidadPielesDisponible,
    required this.estado,
  });

  final int id;
  final String codigo;
  final int clienteId;
  final String clienteRazonSocial;
  final double cantidadPielesDisponible;
  final String estado;

  String get label =>
      '$codigo · $clienteRazonSocial · disp. ${cantidadPielesDisponible.toStringAsFixed(cantidadPielesDisponible == cantidadPielesDisponible.roundToDouble() ? 0 : 2)}';

  @override
  List<Object?> get props => [
        id,
        codigo,
        clienteId,
        clienteRazonSocial,
        cantidadPielesDisponible,
        estado,
      ];
}
