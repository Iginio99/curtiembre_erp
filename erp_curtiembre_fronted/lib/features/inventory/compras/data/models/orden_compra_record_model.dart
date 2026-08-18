import 'package:erp_curtiembre_fronted/features/inventory/compras/domain/entities/orden_compra_record.dart';

class OrdenCompraRecordModel {
  const OrdenCompraRecordModel({
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

  factory OrdenCompraRecordModel.fromJson(Map<String, dynamic> json) {
    return OrdenCompraRecordModel(
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
      totalItems: (json['totalItems'] as num).toInt(),
      cantidadTotalSolicitada: (json['cantidadTotalSolicitada'] as num).toDouble(),
      cantidadTotalRecibida: (json['cantidadTotalRecibida'] as num).toDouble(),
      montoTotalEstimado: (json['montoTotalEstimado'] as num).toDouble(),
    );
  }

  OrdenCompraRecord toEntity() {
    return OrdenCompraRecord(
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
      totalItems: totalItems,
      cantidadTotalSolicitada: cantidadTotalSolicitada,
      cantidadTotalRecibida: cantidadTotalRecibida,
      montoTotalEstimado: montoTotalEstimado,
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
