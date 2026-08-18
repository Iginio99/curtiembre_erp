import 'package:equatable/equatable.dart';

class ConsumoPlanificadoRecord extends Equatable {
  const ConsumoPlanificadoRecord({
    required this.id,
    required this.ordenProduccionId,
    required this.ordenProcesoId,
    required this.procesoProductivoId,
    required this.procesoCodigo,
    required this.procesoNombre,
    required this.formulaVersionId,
    required this.insumoId,
    required this.insumoCodigo,
    required this.insumoNombre,
    required this.porcentaje,
    required this.cantidadPlanificada,
    required this.creadoEn,
  });

  final int id;
  final int ordenProduccionId;
  final int ordenProcesoId;
  final int procesoProductivoId;
  final String procesoCodigo;
  final String procesoNombre;
  final int formulaVersionId;
  final int insumoId;
  final String insumoCodigo;
  final String insumoNombre;
  final double porcentaje;
  final double cantidadPlanificada;
  final DateTime creadoEn;

  @override
  List<Object?> get props => [
        id,
        ordenProduccionId,
        ordenProcesoId,
        procesoProductivoId,
        procesoCodigo,
        procesoNombre,
        formulaVersionId,
        insumoId,
        insumoCodigo,
        insumoNombre,
        porcentaje,
        cantidadPlanificada,
        creadoEn,
      ];
}
