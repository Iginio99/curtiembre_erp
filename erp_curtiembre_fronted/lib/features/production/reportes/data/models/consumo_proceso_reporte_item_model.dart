import 'package:erp_curtiembre_fronted/features/production/reportes/domain/entities/consumo_proceso_reporte_item.dart';

class ConsumoProcesoReporteItemModel {
  const ConsumoProcesoReporteItemModel({
    required this.ordenProduccionId,
    required this.codigoOrden,
    required this.ordenProcesoId,
    required this.procesoCodigo,
    required this.procesoNombre,
    required this.insumoId,
    required this.insumoCodigo,
    required this.insumoNombre,
    required this.cantidadPlanificada,
    required this.cantidadReal,
    required this.cantidadDesviacion,
    required this.costoTotal,
    this.costoUnitario,
  });

  final int ordenProduccionId;
  final String codigoOrden;
  final int ordenProcesoId;
  final String procesoCodigo;
  final String procesoNombre;
  final int insumoId;
  final String insumoCodigo;
  final String insumoNombre;
  final double cantidadPlanificada;
  final double cantidadReal;
  final double cantidadDesviacion;
  final double? costoUnitario;
  final double costoTotal;

  factory ConsumoProcesoReporteItemModel.fromJson(Map<String, dynamic> json) {
    return ConsumoProcesoReporteItemModel(
      ordenProduccionId: (json['ordenProduccionId'] as num).toInt(),
      codigoOrden: json['codigoOrden'] as String,
      ordenProcesoId: (json['ordenProcesoId'] as num).toInt(),
      procesoCodigo: json['procesoCodigo'] as String,
      procesoNombre: json['procesoNombre'] as String,
      insumoId: (json['insumoId'] as num).toInt(),
      insumoCodigo: json['insumoCodigo'] as String,
      insumoNombre: json['insumoNombre'] as String,
      cantidadPlanificada: (json['cantidadPlanificada'] as num).toDouble(),
      cantidadReal: (json['cantidadReal'] as num).toDouble(),
      cantidadDesviacion: (json['cantidadDesviacion'] as num).toDouble(),
      costoUnitario: _parseOptionalDouble(json['costoUnitario']),
      costoTotal: (json['costoTotal'] as num).toDouble(),
    );
  }

  ConsumoProcesoReporteItem toEntity() {
    return ConsumoProcesoReporteItem(
      ordenProduccionId: ordenProduccionId,
      codigoOrden: codigoOrden,
      ordenProcesoId: ordenProcesoId,
      procesoCodigo: procesoCodigo,
      procesoNombre: procesoNombre,
      insumoId: insumoId,
      insumoCodigo: insumoCodigo,
      insumoNombre: insumoNombre,
      cantidadPlanificada: cantidadPlanificada,
      cantidadReal: cantidadReal,
      cantidadDesviacion: cantidadDesviacion,
      costoUnitario: costoUnitario,
      costoTotal: costoTotal,
    );
  }

  static double? _parseOptionalDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return null;
  }
}
