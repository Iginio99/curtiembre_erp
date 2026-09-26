import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/control_calidad_record.dart';

class ControlCalidadRecordModel {
  const ControlCalidadRecordModel({
    required this.id,
    required this.ordenProduccionId,
    required this.calidadProductoId,
    required this.calidadCodigo,
    required this.calidadNombre,
    required this.cantidadLadosA,
    required this.cantidadLadosB,
    required this.cantidadLadosC,
    required this.cantidadLadosMerma,
    required this.resultado,
    required this.evaluadoEn,
    this.productoTerminadoId,
    this.observacion,
    this.evaluadoPorUsuarioId,
    this.evaluadoPorNombre,
  });

  final int id;
  final int ordenProduccionId;
  final int? productoTerminadoId;
  final int calidadProductoId;
  final String calidadCodigo;
  final String calidadNombre;
  final double cantidadLadosA;
  final double cantidadLadosB;
  final double cantidadLadosC;
  final double cantidadLadosMerma;
  final String resultado;
  final String? observacion;
  final DateTime evaluadoEn;
  final int? evaluadoPorUsuarioId;
  final String? evaluadoPorNombre;

  factory ControlCalidadRecordModel.fromJson(Map<String, dynamic> json) {
    return ControlCalidadRecordModel(
      id: (json['id'] as num).toInt(),
      ordenProduccionId: (json['ordenProduccionId'] as num).toInt(),
      productoTerminadoId: _parseOptionalInt(json['productoTerminadoId']),
      calidadProductoId: (json['calidadProductoId'] as num).toInt(),
      calidadCodigo: json['calidadCodigo'] as String,
      calidadNombre: json['calidadNombre'] as String,
      cantidadLadosA: (json['cantidadLadosA'] as num).toDouble(),
      cantidadLadosB: (json['cantidadLadosB'] as num).toDouble(),
      cantidadLadosC: (json['cantidadLadosC'] as num).toDouble(),
      cantidadLadosMerma: (json['cantidadLadosMerma'] as num).toDouble(),
      resultado: json['resultado'] as String,
      observacion: json['observacion'] as String?,
      evaluadoEn: DateTime.parse(json['evaluadoEn'] as String),
      evaluadoPorUsuarioId: _parseOptionalInt(json['evaluadoPorUsuarioId']),
      evaluadoPorNombre: json['evaluadoPorNombre'] as String?,
    );
  }

  ControlCalidadRecord toEntity() {
    return ControlCalidadRecord(
      id: id,
      ordenProduccionId: ordenProduccionId,
      productoTerminadoId: productoTerminadoId,
      calidadProductoId: calidadProductoId,
      calidadCodigo: calidadCodigo,
      calidadNombre: calidadNombre,
      cantidadLadosA: cantidadLadosA,
      cantidadLadosB: cantidadLadosB,
      cantidadLadosC: cantidadLadosC,
      cantidadLadosMerma: cantidadLadosMerma,
      resultado: resultado,
      observacion: observacion,
      evaluadoEn: evaluadoEn,
      evaluadoPorUsuarioId: evaluadoPorUsuarioId,
      evaluadoPorNombre: evaluadoPorNombre,
    );
  }

  static int? _parseOptionalInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return null;
  }
}
