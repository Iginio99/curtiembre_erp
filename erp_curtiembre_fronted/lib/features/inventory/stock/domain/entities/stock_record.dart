import 'package:equatable/equatable.dart';

class StockRecord extends Equatable {
  const StockRecord({
    required this.insumoId,
    required this.codigo,
    required this.nombre,
    required this.tipoBien,
    required this.unidadMedidaCodigo,
    required this.unidadMedidaNombre,
    required this.stockMinimo,
    required this.cantidadActual,
    required this.costoPromedioActual,
    required this.activo,
    required this.stockBajo,
    required this.actualizadoEn,
  });

  final int insumoId;
  final String codigo;
  final String nombre;
  final String tipoBien;
  final String unidadMedidaCodigo;
  final String unidadMedidaNombre;
  final double stockMinimo;
  final double cantidadActual;
  final double costoPromedioActual;
  final bool activo;
  final bool stockBajo;
  final DateTime actualizadoEn;

  @override
  List<Object?> get props => [
        insumoId,
        codigo,
        nombre,
        tipoBien,
        unidadMedidaCodigo,
        unidadMedidaNombre,
        stockMinimo,
        cantidadActual,
        costoPromedioActual,
        activo,
        stockBajo,
        actualizadoEn,
      ];
}
