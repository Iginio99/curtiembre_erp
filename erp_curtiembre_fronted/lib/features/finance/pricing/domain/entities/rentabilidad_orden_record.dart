import 'package:equatable/equatable.dart';

class RentabilidadOrdenRecord extends Equatable {
  const RentabilidadOrdenRecord({
    required this.id,
    required this.ordenProduccionId,
    required this.ordenProduccionCodigo,
    required this.precioVenta,
    required this.costoTotal,
    required this.utilidad,
    required this.calculadoEn,
    this.margenPorcentaje,
  });

  final int id;
  final int ordenProduccionId;
  final String ordenProduccionCodigo;
  final double precioVenta;
  final double costoTotal;
  final double utilidad;
  final double? margenPorcentaje;
  final DateTime calculadoEn;

  @override
  List<Object?> get props => [
        id,
        ordenProduccionId,
        ordenProduccionCodigo,
        precioVenta,
        costoTotal,
        utilidad,
        margenPorcentaje,
        calculadoEn,
      ];
}

