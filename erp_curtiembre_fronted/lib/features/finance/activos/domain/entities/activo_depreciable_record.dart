import 'package:equatable/equatable.dart';

class ActivoDepreciableRecord extends Equatable {
  const ActivoDepreciableRecord({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.valorCompra,
    required this.cantidad,
    required this.costoTotal,
    required this.fechaCompra,
    required this.vidaUtilMeses,
    required this.valorResidual,
    required this.activo,
    required this.creadoEn,
    this.depreciacionMensual,
    this.depreciacionAnual,
  });

  final int id;
  final String codigo;
  final String nombre;
  final double valorCompra;
  final int cantidad;
  final double costoTotal;
  final DateTime fechaCompra;
  final int vidaUtilMeses;
  final double valorResidual;
  final bool activo;
  final DateTime creadoEn;
  final double? depreciacionMensual;
  final double? depreciacionAnual;

  @override
  List<Object?> get props => [
    id,
    codigo,
    nombre,
    valorCompra,
    cantidad,
    costoTotal,
    fechaCompra,
    vidaUtilMeses,
    valorResidual,
    activo,
    creadoEn,
    depreciacionMensual,
    depreciacionAnual,
  ];
}
