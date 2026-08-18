import 'package:erp_curtiembre_fronted/features/inventory/salidas/domain/entities/salida_record.dart';

class SalidaRecordModel {
  const SalidaRecordModel({
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

  factory SalidaRecordModel.fromJson(Map<String, dynamic> json) {
    return SalidaRecordModel(
      id: (json['id'] as num).toInt(),
      codigo: json['codigo'] as String,
      tipoSalida: json['tipoSalida'] as String,
      ordenProduccionId: (json['ordenProduccionId'] as num?)?.toInt(),
      ordenProcesoId: (json['ordenProcesoId'] as num?)?.toInt(),
      fechaSalida: DateTime.parse(json['fechaSalida'] as String),
      motivo: json['motivo'] as String?,
      observacion: json['observacion'] as String?,
      estado: json['estado'] as String,
      creadoPorUsuarioId: (json['creadoPorUsuarioId'] as num?)?.toInt(),
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      totalItems: (json['totalItems'] as num).toInt(),
      cantidadTotal: (json['cantidadTotal'] as num).toDouble(),
      montoTotal: (json['montoTotal'] as num).toDouble(),
    );
  }

  SalidaRecord toEntity() {
    return SalidaRecord(
      id: id,
      codigo: codigo,
      tipoSalida: tipoSalida,
      ordenProduccionId: ordenProduccionId,
      ordenProcesoId: ordenProcesoId,
      fechaSalida: fechaSalida,
      motivo: motivo,
      observacion: observacion,
      estado: estado,
      creadoPorUsuarioId: creadoPorUsuarioId,
      creadoEn: creadoEn,
      totalItems: totalItems,
      cantidadTotal: cantidadTotal,
      montoTotal: montoTotal,
    );
  }
}
