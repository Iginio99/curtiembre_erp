import 'package:equatable/equatable.dart';

class PrecioSugeridoRecord extends Equatable {
  const PrecioSugeridoRecord({
    required this.id,
    required this.ordenProduccionId,
    required this.ordenProduccionCodigo,
    required this.costoBaseSinIgv,
    required this.margenPorcentaje,
    required this.precioSugeridoSinIgv,
    required this.igvPorcentaje,
    required this.precioSugeridoConIgv,
    required this.calculadoEn,
  });

  final int id;
  final int ordenProduccionId;
  final String ordenProduccionCodigo;
  final double costoBaseSinIgv;
  final double margenPorcentaje;
  final double precioSugeridoSinIgv;
  final double igvPorcentaje;
  final double precioSugeridoConIgv;
  final DateTime calculadoEn;

  @override
  List<Object?> get props => [
        id,
        ordenProduccionId,
        ordenProduccionCodigo,
        costoBaseSinIgv,
        margenPorcentaje,
        precioSugeridoSinIgv,
        igvPorcentaje,
        precioSugeridoConIgv,
        calculadoEn,
      ];
}

