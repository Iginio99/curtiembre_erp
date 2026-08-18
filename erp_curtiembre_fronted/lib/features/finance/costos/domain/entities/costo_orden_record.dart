import 'package:equatable/equatable.dart';

class CostoOrdenRecord extends Equatable {
  const CostoOrdenRecord({
    required this.id,
    required this.ordenProduccionId,
    required this.ordenProduccionCodigo,
    required this.costoPieles,
    required this.costoInsumos,
    required this.costoManoObra,
    required this.costoIndirectoAsignado,
    required this.costoDepreciacionAsignado,
    required this.costoTotal,
    required this.estado,
    required this.calculadoEn,
    this.periodoCostoId,
    this.periodoAnio,
    this.periodoMes,
    this.pielesBuenasFinales,
    this.costoPorPiel,
    this.costoEstimado,
    this.costoReal,
    this.calculadoPorUsuarioId,
  });

  final int id;
  final int ordenProduccionId;
  final String ordenProduccionCodigo;
  final int? periodoCostoId;
  final int? periodoAnio;
  final int? periodoMes;
  final double costoPieles;
  final double costoInsumos;
  final double costoManoObra;
  final double costoIndirectoAsignado;
  final double costoDepreciacionAsignado;
  final double costoTotal;
  final double? pielesBuenasFinales;
  final double? costoPorPiel;
  final double? costoEstimado;
  final double? costoReal;
  final String estado;
  final DateTime calculadoEn;
  final int? calculadoPorUsuarioId;

  String? get periodoCodigo {
    if (periodoAnio == null || periodoMes == null) return null;
    return '$periodoAnio-${periodoMes!.toString().padLeft(2, '0')}';
  }

  bool get canClose => estado == 'REAL';

  @override
  List<Object?> get props => [
        id,
        ordenProduccionId,
        ordenProduccionCodigo,
        periodoCostoId,
        periodoAnio,
        periodoMes,
        costoPieles,
        costoInsumos,
        costoManoObra,
        costoIndirectoAsignado,
        costoDepreciacionAsignado,
        costoTotal,
        pielesBuenasFinales,
        costoPorPiel,
        costoEstimado,
        costoReal,
        estado,
        calculadoEn,
        calculadoPorUsuarioId,
      ];
}

