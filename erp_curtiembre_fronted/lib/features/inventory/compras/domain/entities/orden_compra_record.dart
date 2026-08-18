import 'package:equatable/equatable.dart';

class OrdenCompraRecord extends Equatable {
  const OrdenCompraRecord({
    required this.id,
    required this.codigo,
    required this.proveedorId,
    required this.proveedorRazonSocial,
    required this.fechaEmision,
    required this.estado,
    required this.creadoEn,
    required this.totalItems,
    required this.cantidadTotalSolicitada,
    required this.cantidadTotalRecibida,
    required this.montoTotalEstimado,
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
  final int totalItems;
  final double cantidadTotalSolicitada;
  final double cantidadTotalRecibida;
  final double montoTotalEstimado;

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
        totalItems,
        cantidadTotalSolicitada,
        cantidadTotalRecibida,
        montoTotalEstimado,
      ];
}
