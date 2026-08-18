import 'package:equatable/equatable.dart';

class OrdenCompraDetalleLine extends Equatable {
  const OrdenCompraDetalleLine({
    required this.id,
    required this.insumoId,
    required this.insumoCodigo,
    required this.insumoNombre,
    required this.unidadMedidaCodigo,
    required this.unidadMedidaNombre,
    required this.cantidadSolicitada,
    required this.cantidadRecibida,
    required this.saldoPendiente,
    required this.montoEstimado,
    this.costoUnitarioEstimado,
    this.observacion,
  });

  final int id;
  final int insumoId;
  final String insumoCodigo;
  final String insumoNombre;
  final String unidadMedidaCodigo;
  final String unidadMedidaNombre;
  final double cantidadSolicitada;
  final double cantidadRecibida;
  final double saldoPendiente;
  final double? costoUnitarioEstimado;
  final double montoEstimado;
  final String? observacion;

  @override
  List<Object?> get props => [
        id,
        insumoId,
        insumoCodigo,
        insumoNombre,
        unidadMedidaCodigo,
        unidadMedidaNombre,
        cantidadSolicitada,
        cantidadRecibida,
        saldoPendiente,
        costoUnitarioEstimado,
        montoEstimado,
        observacion,
      ];
}

class OrdenCompraDetail extends Equatable {
  const OrdenCompraDetail({
    required this.id,
    required this.codigo,
    required this.proveedorId,
    required this.proveedorRazonSocial,
    required this.fechaEmision,
    required this.estado,
    required this.creadoEn,
    required this.detalles,
    this.fechaAprobacion,
    this.aprobadoPorUsuarioId,
    this.observacion,
    this.motivo,
    this.creadoPorUsuarioId,
    this.actualizadoEn,
    this.actualizadoPorUsuarioId,
  });

  final int id;
  final String codigo;
  final int proveedorId;
  final String proveedorRazonSocial;
  final DateTime fechaEmision;
  final DateTime? fechaAprobacion;
  final int? aprobadoPorUsuarioId;
  final String estado;
  final String? observacion;
  final String? motivo;
  final DateTime creadoEn;
  final int? creadoPorUsuarioId;
  final DateTime? actualizadoEn;
  final int? actualizadoPorUsuarioId;
  final List<OrdenCompraDetalleLine> detalles;

  bool get canApprove => estado == 'PENDIENTE';
  bool get canReject => estado == 'PENDIENTE';
  bool get canCancel =>
      estado == 'PENDIENTE' || estado == 'APROBADA' || estado == 'PARCIALMENTE_RECIBIDA';

  @override
  List<Object?> get props => [
        id,
        codigo,
        proveedorId,
        proveedorRazonSocial,
        fechaEmision,
        fechaAprobacion,
        aprobadoPorUsuarioId,
        estado,
        observacion,
        motivo,
        creadoEn,
        creadoPorUsuarioId,
        actualizadoEn,
        actualizadoPorUsuarioId,
        detalles,
      ];
}
