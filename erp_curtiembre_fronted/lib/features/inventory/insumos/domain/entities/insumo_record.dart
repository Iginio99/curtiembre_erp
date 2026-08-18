import 'package:equatable/equatable.dart';

class InsumoRecord extends Equatable {
  const InsumoRecord({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.tipoBien,
    required this.unidadMedidaId,
    required this.unidadMedidaCodigo,
    required this.unidadMedidaNombre,
    required this.stockMinimo,
    required this.costoPromedioActual,
    required this.stockActual,
    required this.requiereLote,
    required this.activo,
    required this.creadoEn,
    this.presentacion,
    this.actualizadoEn,
    this.creadoPorUsuarioId,
    this.actualizadoPorUsuarioId,
  });

  final int id;
  final String codigo;
  final String nombre;
  final String tipoBien;
  final String? presentacion;
  final int unidadMedidaId;
  final String unidadMedidaCodigo;
  final String unidadMedidaNombre;
  final double stockMinimo;
  final double costoPromedioActual;
  final double stockActual;
  final bool requiereLote;
  final bool activo;
  final DateTime creadoEn;
  final DateTime? actualizadoEn;
  final int? creadoPorUsuarioId;
  final int? actualizadoPorUsuarioId;

  bool get stockBajo => stockActual <= stockMinimo;

  @override
  List<Object?> get props => [
        id,
        codigo,
        nombre,
        tipoBien,
        presentacion,
        unidadMedidaId,
        unidadMedidaCodigo,
        unidadMedidaNombre,
        stockMinimo,
        costoPromedioActual,
        stockActual,
        requiereLote,
        activo,
        creadoEn,
        actualizadoEn,
        creadoPorUsuarioId,
        actualizadoPorUsuarioId,
      ];
}
