import 'package:equatable/equatable.dart';

class InventarioFisicoRecord extends Equatable {
  const InventarioFisicoRecord({
    required this.id,
    required this.codigo,
    required this.fechaInicio,
    required this.periodoAnio,
    required this.periodoMes,
    required this.estado,
    required this.ejecutadoPorUsuarioId,
    required this.totalItems,
    required this.itemsConDiferencia,
    required this.totalDiferenciaAbsoluta,
    this.fechaCierre,
    this.observacion,
  });

  final int id;
  final String codigo;
  final DateTime fechaInicio;
  final DateTime? fechaCierre;
  final int periodoAnio;
  final int periodoMes;
  final String estado;
  final int ejecutadoPorUsuarioId;
  final String? observacion;
  final int totalItems;
  final int itemsConDiferencia;
  final double totalDiferenciaAbsoluta;

  @override
  List<Object?> get props => [
        id,
        codigo,
        fechaInicio,
        fechaCierre,
        periodoAnio,
        periodoMes,
        estado,
        ejecutadoPorUsuarioId,
        observacion,
        totalItems,
        itemsConDiferencia,
        totalDiferenciaAbsoluta,
      ];
}
