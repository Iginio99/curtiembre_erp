import 'package:equatable/equatable.dart';

class SalidaDetalleLine extends Equatable {
  const SalidaDetalleLine({
    required this.id,
    required this.insumoId,
    required this.insumoCodigo,
    required this.insumoNombre,
    required this.cantidad,
    required this.costoUnitario,
    required this.costoTotal,
    required this.stockActual,
    required this.unidadMedidaCodigo,
    required this.unidadMedidaNombre,
    this.observacion,
  });

  final int id;
  final int insumoId;
  final String insumoCodigo;
  final String insumoNombre;
  final double cantidad;
  final double costoUnitario;
  final double costoTotal;
  final double stockActual;
  final String unidadMedidaCodigo;
  final String unidadMedidaNombre;
  final String? observacion;

  @override
  List<Object?> get props => [
        id,
        insumoId,
        insumoCodigo,
        insumoNombre,
        cantidad,
        costoUnitario,
        costoTotal,
        stockActual,
        unidadMedidaCodigo,
        unidadMedidaNombre,
        observacion,
      ];
}

class SalidaDetail extends Equatable {
  const SalidaDetail({
    required this.id,
    required this.codigo,
    required this.tipoSalida,
    required this.fechaSalida,
    required this.estado,
    required this.creadoEn,
    required this.detalles,
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
  final List<SalidaDetalleLine> detalles;

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
        detalles,
      ];
}
