import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/lote_option.dart';

class LoteOptionModel {
  const LoteOptionModel({
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

  factory LoteOptionModel.fromJson(Map<String, dynamic> json) {
    return LoteOptionModel(
      id: (json['id'] as num).toInt(),
      codigo: json['codigo'] as String,
      clienteId: (json['clienteId'] as num).toInt(),
      clienteRazonSocial: json['clienteRazonSocial'] as String,
      cantidadPielesDisponible: (json['cantidadPielesDisponible'] as num)
          .toDouble(),
      estado: json['estado'] as String,
    );
  }

  LoteOption toEntity() {
    return LoteOption(
      id: id,
      codigo: codigo,
      clienteId: clienteId,
      clienteRazonSocial: clienteRazonSocial,
      cantidadPielesDisponible: cantidadPielesDisponible,
      estado: estado,
    );
  }
}
