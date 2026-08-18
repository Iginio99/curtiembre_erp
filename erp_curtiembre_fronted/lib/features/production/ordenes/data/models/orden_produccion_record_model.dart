import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/orden_produccion_record.dart';

class OrdenProduccionRecordModel {
  const OrdenProduccionRecordModel({
    required this.id,
    required this.codigo,
    required this.loteId,
    required this.loteCodigo,
    required this.clienteId,
    required this.clienteRazonSocial,
    required this.cantidadPieles,
    required this.fechaFinEstimada,
    required this.estado,
    required this.procesosTotales,
    required this.procesosFinalizados,
    required this.creadoEn,
    this.fechaInicioPlanificada,
    this.fechaInicioReal,
    this.fechaFinReal,
    this.responsableUsuarioId,
    this.responsableNombre,
    this.observacion,
    this.motivoAnulacion,
    this.creadoPorUsuarioId,
    this.actualizadoEn,
    this.actualizadoPorUsuarioId,
  });

  final int id;
  final String codigo;
  final int loteId;
  final String loteCodigo;
  final int clienteId;
  final String clienteRazonSocial;
  final double cantidadPieles;
  final DateTime? fechaInicioPlanificada;
  final DateTime? fechaInicioReal;
  final DateTime fechaFinEstimada;
  final DateTime? fechaFinReal;
  final int? responsableUsuarioId;
  final String? responsableNombre;
  final String estado;
  final String? observacion;
  final String? motivoAnulacion;
  final int procesosTotales;
  final int procesosFinalizados;
  final DateTime creadoEn;
  final int? creadoPorUsuarioId;
  final DateTime? actualizadoEn;
  final int? actualizadoPorUsuarioId;

  factory OrdenProduccionRecordModel.fromJson(Map<String, dynamic> json) {
    return OrdenProduccionRecordModel(
      id: (json['id'] as num).toInt(),
      codigo: json['codigo'] as String,
      loteId: (json['loteId'] as num).toInt(),
      loteCodigo: json['loteCodigo'] as String,
      clienteId: (json['clienteId'] as num).toInt(),
      clienteRazonSocial: json['clienteRazonSocial'] as String,
      cantidadPieles: (json['cantidadPieles'] as num).toDouble(),
      fechaInicioPlanificada: _parseOptionalDate(json['fechaInicioPlanificada']),
      fechaInicioReal: _parseOptionalDate(json['fechaInicioReal']),
      fechaFinEstimada: DateTime.parse(json['fechaFinEstimada'] as String),
      fechaFinReal: _parseOptionalDate(json['fechaFinReal']),
      responsableUsuarioId: _parseOptionalInt(json['responsableUsuarioId']),
      responsableNombre: json['responsableNombre'] as String?,
      estado: json['estado'] as String,
      observacion: json['observacion'] as String?,
      motivoAnulacion: json['motivoAnulacion'] as String?,
      procesosTotales: (json['procesosTotales'] as num).toInt(),
      procesosFinalizados: (json['procesosFinalizados'] as num).toInt(),
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      creadoPorUsuarioId: _parseOptionalInt(json['creadoPorUsuarioId']),
      actualizadoEn: _parseOptionalDate(json['actualizadoEn']),
      actualizadoPorUsuarioId: _parseOptionalInt(json['actualizadoPorUsuarioId']),
    );
  }

  OrdenProduccionRecord toEntity() {
    return OrdenProduccionRecord(
      id: id,
      codigo: codigo,
      loteId: loteId,
      loteCodigo: loteCodigo,
      clienteId: clienteId,
      clienteRazonSocial: clienteRazonSocial,
      cantidadPieles: cantidadPieles,
      fechaInicioPlanificada: fechaInicioPlanificada,
      fechaInicioReal: fechaInicioReal,
      fechaFinEstimada: fechaFinEstimada,
      fechaFinReal: fechaFinReal,
      responsableUsuarioId: responsableUsuarioId,
      responsableNombre: responsableNombre,
      estado: estado,
      observacion: observacion,
      motivoAnulacion: motivoAnulacion,
      procesosTotales: procesosTotales,
      procesosFinalizados: procesosFinalizados,
      creadoEn: creadoEn,
      creadoPorUsuarioId: creadoPorUsuarioId,
      actualizadoEn: actualizadoEn,
      actualizadoPorUsuarioId: actualizadoPorUsuarioId,
    );
  }

  static int? _parseOptionalInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return null;
  }

  static DateTime? _parseOptionalDate(dynamic value) {
    if (value is! String || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }
}
