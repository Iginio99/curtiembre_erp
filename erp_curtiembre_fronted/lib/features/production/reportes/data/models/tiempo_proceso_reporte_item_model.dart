import 'package:erp_curtiembre_fronted/features/production/reportes/domain/entities/tiempo_proceso_reporte_item.dart';

class TiempoProcesoReporteItemModel {
  const TiempoProcesoReporteItemModel({
    required this.ordenProduccionId,
    required this.codigoOrden,
    required this.ordenProcesoId,
    required this.procesoCodigo,
    required this.procesoNombre,
    required this.estado,
    this.fechaInicio,
    this.fechaFin,
    this.diasReales,
    this.responsable,
  });

  final int ordenProduccionId;
  final String codigoOrden;
  final int ordenProcesoId;
  final String procesoCodigo;
  final String procesoNombre;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final int? diasReales;
  final String estado;
  final String? responsable;

  factory TiempoProcesoReporteItemModel.fromJson(Map<String, dynamic> json) {
    return TiempoProcesoReporteItemModel(
      ordenProduccionId: (json['ordenProduccionId'] as num).toInt(),
      codigoOrden: json['codigoOrden'] as String,
      ordenProcesoId: (json['ordenProcesoId'] as num).toInt(),
      procesoCodigo: json['procesoCodigo'] as String,
      procesoNombre: json['procesoNombre'] as String,
      fechaInicio: _parseOptionalDate(json['fechaInicio']),
      fechaFin: _parseOptionalDate(json['fechaFin']),
      diasReales: _parseOptionalInt(json['diasReales']),
      estado: json['estado'] as String,
      responsable: json['responsable'] as String?,
    );
  }

  TiempoProcesoReporteItem toEntity() {
    return TiempoProcesoReporteItem(
      ordenProduccionId: ordenProduccionId,
      codigoOrden: codigoOrden,
      ordenProcesoId: ordenProcesoId,
      procesoCodigo: procesoCodigo,
      procesoNombre: procesoNombre,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      diasReales: diasReales,
      estado: estado,
      responsable: responsable,
    );
  }

  static DateTime? _parseOptionalDate(dynamic value) {
    if (value is! String || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  static int? _parseOptionalInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return null;
  }
}
