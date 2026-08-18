import 'package:equatable/equatable.dart';

class DesviacionConsumoRecord extends Equatable {
  const DesviacionConsumoRecord({
    required this.id,
    required this.ordenConsumoRealId,
    required this.ordenProduccionId,
    required this.ordenProcesoId,
    required this.procesoProductivoId,
    required this.procesoCodigo,
    required this.procesoNombre,
    required this.insumoId,
    required this.insumoCodigo,
    required this.insumoNombre,
    required this.cantidadPlanificada,
    required this.cantidadReal,
    required this.cantidadDesviacion,
    required this.registradoEn,
    this.ordenConsumoPlanificadoId,
    this.motivo,
  });

  final int id;
  final int? ordenConsumoPlanificadoId;
  final int ordenConsumoRealId;
  final int ordenProduccionId;
  final int ordenProcesoId;
  final int procesoProductivoId;
  final String procesoCodigo;
  final String procesoNombre;
  final int insumoId;
  final String insumoCodigo;
  final String insumoNombre;
  final double cantidadPlanificada;
  final double cantidadReal;
  final double cantidadDesviacion;
  final String? motivo;
  final DateTime registradoEn;

  @override
  List<Object?> get props => [
        id,
        ordenConsumoPlanificadoId,
        ordenConsumoRealId,
        ordenProduccionId,
        ordenProcesoId,
        procesoProductivoId,
        procesoCodigo,
        procesoNombre,
        insumoId,
        insumoCodigo,
        insumoNombre,
        cantidadPlanificada,
        cantidadReal,
        cantidadDesviacion,
        motivo,
        registradoEn,
      ];
}
