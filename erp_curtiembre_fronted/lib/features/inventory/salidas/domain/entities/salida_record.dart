import 'package:equatable/equatable.dart';

class SalidaRecord extends Equatable {
  const SalidaRecord({
    required this.id,
    required this.codigo,
    required this.tipoSalida,
    required this.fechaSalida,
    required this.estado,
    required this.creadoEn,
    required this.totalItems,
    required this.cantidadTotal,
    required this.montoTotal,
    this.ordenProduccionId,
    this.ordenProcesoId,
    this.motivo,
    this.observacion,
    this.creadoPorUsuarioId,
  });

  final int id;
  final String codigo;
  final String tipoSalida;
  final int? ordenProduccionId;
  final int? ordenProcesoId;
  final DateTime fechaSalida;
  final String? motivo;
  final String? observacion;
  final String estado;
  final int? creadoPorUsuarioId;
  final DateTime creadoEn;
  final int totalItems;
  final double cantidadTotal;
  final double montoTotal;

  @override
  List<Object?> get props => [
        id,
        codigo,
        tipoSalida,
        ordenProduccionId,
        ordenProcesoId,
        fechaSalida,
        motivo,
        observacion,
        estado,
        creadoPorUsuarioId,
        creadoEn,
        totalItems,
        cantidadTotal,
        montoTotal,
      ];
}
