import 'package:erp_curtiembre_fronted/features/production/lotes/domain/entities/lote_disponibilidad.dart';

class LoteDisponibilidadModel {
  const LoteDisponibilidadModel({
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

  factory LoteDisponibilidadModel.fromJson(Map<String, dynamic> json) {
    return LoteDisponibilidadModel(
      id: (json['id'] as num).toInt(),
      codigo: json['codigo'] as String,
      clienteId: (json['clienteId'] as num).toInt(),
      clienteRazonSocial: json['clienteRazonSocial'] as String,
      cantidadPielesInicial: (json['cantidadPielesInicial'] as num).toDouble(),
      cantidadPielesUtilizada: (json['cantidadPielesUtilizada'] as num).toDouble(),
      cantidadPielesDisponible: (json['cantidadPielesDisponible'] as num).toDouble(),
      cantidadLadosCalculada: (json['cantidadLadosCalculada'] as num).toDouble(),
      estado: json['estado'] as String,
    );
  }

  LoteDisponibilidad toEntity() {
    return LoteDisponibilidad(
      id: id,
      codigo: codigo,
      clienteId: clienteId,
      clienteRazonSocial: clienteRazonSocial,
      cantidadPielesInicial: cantidadPielesInicial,
      cantidadPielesUtilizada: cantidadPielesUtilizada,
      cantidadPielesDisponible: cantidadPielesDisponible,
      cantidadLadosCalculada: cantidadLadosCalculada,
      estado: estado,
    );
  }
}
