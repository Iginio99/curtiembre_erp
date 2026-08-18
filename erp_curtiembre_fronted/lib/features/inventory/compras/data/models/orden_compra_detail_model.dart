import 'package:erp_curtiembre_fronted/features/inventory/compras/domain/entities/orden_compra_detail.dart';

class OrdenCompraDetalleLineModel {
  const OrdenCompraDetalleLineModel({
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

  factory OrdenCompraDetalleLineModel.fromJson(Map<String, dynamic> json) {
    return OrdenCompraDetalleLineModel(
      id: (json['id'] as num).toInt(),
      insumoId: (json['insumoId'] as num).toInt(),
      insumoCodigo: json['insumoCodigo'] as String,
      insumoNombre: json['insumoNombre'] as String,
      unidadMedidaCodigo: json['unidadMedidaCodigo'] as String,
      unidadMedidaNombre: json['unidadMedidaNombre'] as String,
      cantidadSolicitada: (json['cantidadSolicitada'] as num).toDouble(),
      cantidadRecibida: (json['cantidadRecibida'] as num).toDouble(),
      saldoPendiente: (json['saldoPendiente'] as num).toDouble(),
      costoUnitarioEstimado: (json['costoUnitarioEstimado'] as num?)?.toDouble(),
      montoEstimado: (json['montoEstimado'] as num).toDouble(),
      observacion: json['observacion'] as String?,
    );
  }

  OrdenCompraDetalleLine toEntity() {
    return OrdenCompraDetalleLine(
      id: id,
      insumoId: insumoId,
      insumoCodigo: insumoCodigo,
      insumoNombre: insumoNombre,
      unidadMedidaCodigo: unidadMedidaCodigo,
      unidadMedidaNombre: unidadMedidaNombre,
      cantidadSolicitada: cantidadSolicitada,
      cantidadRecibida: cantidadRecibida,
      saldoPendiente: saldoPendiente,
      costoUnitarioEstimado: costoUnitarioEstimado,
      montoEstimado: montoEstimado,
      observacion: observacion,
    );
  }
}

class OrdenCompraDetailModel {
  const OrdenCompraDetailModel({
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
  final List<OrdenCompraDetalleLineModel> detalles;

  factory OrdenCompraDetailModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['detalles'] as List<dynamic>? ?? const [];
    return OrdenCompraDetailModel(
      id: (json['id'] as num).toInt(),
      codigo: json['codigo'] as String,
      proveedorId: (json['proveedorId'] as num).toInt(),
      proveedorRazonSocial: json['proveedorRazonSocial'] as String,
      fechaEmision: DateTime.parse(json['fechaEmision'] as String),
      fechaAprobacion: _parseOptionalDate(json['fechaAprobacion']),
      aprobadoPorUsuarioId: _parseOptionalInt(json['aprobadoPorUsuarioId']),
      estado: json['estado'] as String,
      observacion: json['observacion'] as String?,
      motivo: json['motivo'] as String?,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      creadoPorUsuarioId: _parseOptionalInt(json['creadoPorUsuarioId']),
      actualizadoEn: _parseOptionalDate(json['actualizadoEn']),
      actualizadoPorUsuarioId: _parseOptionalInt(json['actualizadoPorUsuarioId']),
      detalles: rawItems
          .map((item) => OrdenCompraDetalleLineModel.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  OrdenCompraDetail toEntity() {
    return OrdenCompraDetail(
      id: id,
      codigo: codigo,
      proveedorId: proveedorId,
      proveedorRazonSocial: proveedorRazonSocial,
      fechaEmision: fechaEmision,
      fechaAprobacion: fechaAprobacion,
      aprobadoPorUsuarioId: aprobadoPorUsuarioId,
      estado: estado,
      observacion: observacion,
      motivo: motivo,
      creadoEn: creadoEn,
      creadoPorUsuarioId: creadoPorUsuarioId,
      actualizadoEn: actualizadoEn,
      actualizadoPorUsuarioId: actualizadoPorUsuarioId,
      detalles: detalles.map((item) => item.toEntity()).toList(growable: false),
    );
  }

  static DateTime? _parseOptionalDate(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  static int? _parseOptionalInt(dynamic value) {
    if (value is num) return value.toInt();
    return null;
  }
}
