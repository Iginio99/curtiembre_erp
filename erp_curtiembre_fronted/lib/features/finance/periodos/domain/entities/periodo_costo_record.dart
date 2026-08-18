import 'package:equatable/equatable.dart';

class PeriodoCostoRecord extends Equatable {
  const PeriodoCostoRecord({
    required this.id,
    required this.anio,
    required this.mes,
    required this.fechaInicio,
    required this.fechaFin,
    required this.estado,
    required this.totalIndirectos,
    this.cerradoEn,
    this.cerradoPorUsuarioId,
    this.observacion,
  });

  final int id;
  final int anio;
  final int mes;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String estado;
  final DateTime? cerradoEn;
  final int? cerradoPorUsuarioId;
  final String? observacion;
  final double totalIndirectos;

  String get codigo => '$anio-${mes.toString().padLeft(2, '0')}';
  bool get isOpen => estado == 'ABIERTO';

  @override
  List<Object?> get props => [
        id,
        anio,
        mes,
        fechaInicio,
        fechaFin,
        estado,
        cerradoEn,
        cerradoPorUsuarioId,
        observacion,
        totalIndirectos,
      ];
}
