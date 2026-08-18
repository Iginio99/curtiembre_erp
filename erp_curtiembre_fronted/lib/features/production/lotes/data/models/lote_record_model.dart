import 'package:erp_curtiembre_fronted/features/production/lotes/domain/entities/lote_record.dart';

class LoteRecordModel {
  const LoteRecordModel({
    required this.id,
    required this.codigo,
    required this.clienteId,
    required this.clienteRazonSocial,
    required this.tipoPielId,
    required this.tipoPielCodigo,
    required this.tipoPielNombre,
    required this.fechaIngreso,
    required this.cantidadPielesInicial,
    required this.cantidadPielesUtilizada,
    required this.cantidadPielesDisponible,
    required this.cantidadLadosCalculada,
    required this.clienteTraeLote,
    required this.costoPielesTotal,
    required this.estado,
    required this.creadoEn,
    this.observacion,
    this.creadoPorUsuarioId,
  });

  final int id;
  final String codigo;
  final int clienteId;
  final String clienteRazonSocial;
  final int tipoPielId;
  final String tipoPielCodigo;
  final String tipoPielNombre;
  final DateTime fechaIngreso;
  final double cantidadPielesInicial;
  final double cantidadPielesUtilizada;
  final double cantidadPielesDisponible;
  final double cantidadLadosCalculada;
  final bool clienteTraeLote;
  final double costoPielesTotal;
  final String estado;
  final String? observacion;
  final DateTime creadoEn;
  final int? creadoPorUsuarioId;

  factory LoteRecordModel.fromJson(Map<String, dynamic> json) {
    return LoteRecordModel(
      id: (json['id'] as num).toInt(),
      codigo: json['codigo'] as String,
      clienteId: (json['clienteId'] as num).toInt(),
      clienteRazonSocial: json['clienteRazonSocial'] as String,
      tipoPielId: (json['tipoPielId'] as num).toInt(),
      tipoPielCodigo: json['tipoPielCodigo'] as String,
      tipoPielNombre: json['tipoPielNombre'] as String,
      fechaIngreso: DateTime.parse(json['fechaIngreso'] as String),
      cantidadPielesInicial: (json['cantidadPielesInicial'] as num).toDouble(),
      cantidadPielesUtilizada: (json['cantidadPielesUtilizada'] as num).toDouble(),
      cantidadPielesDisponible: (json['cantidadPielesDisponible'] as num).toDouble(),
      cantidadLadosCalculada: (json['cantidadLadosCalculada'] as num).toDouble(),
      clienteTraeLote: json['clienteTraeLote'] as bool,
      costoPielesTotal: (json['costoPielesTotal'] as num).toDouble(),
      estado: json['estado'] as String,
      observacion: json['observacion'] as String?,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      creadoPorUsuarioId: _parseOptionalInt(json['creadoPorUsuarioId']),
    );
  }

  LoteRecord toEntity() {
    return LoteRecord(
      id: id,
      codigo: codigo,
      clienteId: clienteId,
      clienteRazonSocial: clienteRazonSocial,
      tipoPielId: tipoPielId,
      tipoPielCodigo: tipoPielCodigo,
      tipoPielNombre: tipoPielNombre,
      fechaIngreso: fechaIngreso,
      cantidadPielesInicial: cantidadPielesInicial,
      cantidadPielesUtilizada: cantidadPielesUtilizada,
      cantidadPielesDisponible: cantidadPielesDisponible,
      cantidadLadosCalculada: cantidadLadosCalculada,
      clienteTraeLote: clienteTraeLote,
      costoPielesTotal: costoPielesTotal,
      estado: estado,
      observacion: observacion,
      creadoEn: creadoEn,
      creadoPorUsuarioId: creadoPorUsuarioId,
    );
  }

  static int? _parseOptionalInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return null;
  }
}
