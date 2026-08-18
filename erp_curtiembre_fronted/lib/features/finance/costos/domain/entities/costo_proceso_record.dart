import 'package:equatable/equatable.dart';

class CostoProcesoRecord extends Equatable {
  const CostoProcesoRecord({
    required this.id,
    required this.ordenProduccionId,
    required this.ordenProduccionCodigo,
    required this.ordenProcesoId,
    required this.procesoCodigo,
    required this.procesoNombre,
    required this.costoInsumos,
    required this.costoManoObra,
    required this.costoTotal,
    required this.calculadoEn,
  });

  final int id;
  final int ordenProduccionId;
  final String ordenProduccionCodigo;
  final int ordenProcesoId;
  final String procesoCodigo;
  final String procesoNombre;
  final double costoInsumos;
  final double costoManoObra;
  final double costoTotal;
  final DateTime calculadoEn;

  @override
  List<Object?> get props => [
        id,
        ordenProduccionId,
        ordenProduccionCodigo,
        ordenProcesoId,
        procesoCodigo,
        procesoNombre,
        costoInsumos,
        costoManoObra,
        costoTotal,
        calculadoEn,
      ];
}

