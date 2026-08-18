import 'package:equatable/equatable.dart';

class LoteRecord extends Equatable {
  const LoteRecord({
    required this.id,
    required this.codigo,
    required this.clienteId,
    required this.clienteRazonSocial,
    required this.tipoPielId,
    required this.tipoPielCodigo,
    required this.tipoPielNombre,
    required this.fechaIngreso,
    required this.cantidadPielesInicial,
    required this.cantidadPielesUtilizada,
    required this.cantidadPielesDisponible,
    required this.cantidadLadosCalculada,
    required this.clienteTraeLote,
    required this.costoPielesTotal,
    required this.estado,
    required this.creadoEn,
    this.observacion,
    this.creadoPorUsuarioId,
  });

  final int id;
  final String codigo;
  final int clienteId;
  final String clienteRazonSocial;
  final int tipoPielId;
  final String tipoPielCodigo;
  final String tipoPielNombre;
  final DateTime fechaIngreso;
  final double cantidadPielesInicial;
  final double cantidadPielesUtilizada;
  final double cantidadPielesDisponible;
  final double cantidadLadosCalculada;
  final bool clienteTraeLote;
  final double costoPielesTotal;
  final String estado;
  final String? observacion;
  final DateTime creadoEn;
  final int? creadoPorUsuarioId;

  @override
  List<Object?> get props => [
        id,
        codigo,
        clienteId,
        clienteRazonSocial,
        tipoPielId,
        tipoPielCodigo,
        tipoPielNombre,
        fechaIngreso,
        cantidadPielesInicial,
        cantidadPielesUtilizada,
        cantidadPielesDisponible,
        cantidadLadosCalculada,
        clienteTraeLote,
        costoPielesTotal,
        estado,
        observacion,
        creadoEn,
        creadoPorUsuarioId,
      ];
}
