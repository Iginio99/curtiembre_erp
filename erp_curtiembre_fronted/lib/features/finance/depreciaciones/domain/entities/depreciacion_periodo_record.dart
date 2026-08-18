import 'package:equatable/equatable.dart';

class DepreciacionPeriodoRecord extends Equatable {
  const DepreciacionPeriodoRecord({
    required this.id,
    required this.periodoCostoId,
    required this.periodoAnio,
    required this.periodoMes,
    required this.activoDepreciableId,
    required this.activoCodigo,
    required this.activoNombre,
    required this.montoDepreciacion,
    required this.calculadoEn,
  });

  final int id;
  final int periodoCostoId;
  final int periodoAnio;
  final int periodoMes;
  final int activoDepreciableId;
  final String activoCodigo;
  final String activoNombre;
  final double montoDepreciacion;
  final DateTime calculadoEn;

  String get periodoCodigo => '$periodoAnio-${periodoMes.toString().padLeft(2, '0')}';

  @override
  List<Object?> get props => [
        id,
        periodoCostoId,
        periodoAnio,
        periodoMes,
        activoDepreciableId,
        activoCodigo,
        activoNombre,
        montoDepreciacion,
        calculadoEn,
      ];
}
