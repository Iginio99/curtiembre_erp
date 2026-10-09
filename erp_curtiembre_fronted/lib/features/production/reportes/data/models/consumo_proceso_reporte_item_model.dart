import 'package:erp_curtiembre_fronted/features/production/reportes/domain/entities/consumo_proceso_reporte_item.dart';

class ConsumoProcesoReporteItemModel {
  const ConsumoProcesoReporteItemModel({
    required this.ordenProduccionId,
    required this.codigoOrden,
    required this.ordenCantidadPieles,
    required this.ordenProcesoId,
    required this.procesoCodigo,
    required this.procesoNombre,
    this.ordenProductoId,
    this.productoNombre,
    this.productoColor,
    this.productoEstado,
    this.productoCantidadPieles,
    this.productoCantidadLados,
    this.productoCantidadPielesTerminadas,
    this.productoPesoBaseKg,
    this.productoInicio,
    this.productoFin,
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
  final double ordenCantidadPieles;
  final int ordenProcesoId;
  final String procesoCodigo;
  final String procesoNombre;
  final int? ordenProductoId;
  final String? productoNombre;
  final String? productoColor;
  final String? productoEstado;
  final double? productoCantidadPieles;
  final double? productoCantidadLados;
  final double? productoCantidadPielesTerminadas;
  final double? productoPesoBaseKg;
  final DateTime? productoInicio;
  final DateTime? productoFin;
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
      ordenCantidadPieles: (json['ordenCantidadPieles'] as num).toDouble(),
      ordenProcesoId: (json['ordenProcesoId'] as num).toInt(),
      procesoCodigo: json['procesoCodigo'] as String,
      procesoNombre: json['procesoNombre'] as String,
      ordenProductoId: (json['ordenProductoId'] as num?)?.toInt(),
      productoNombre: json['productoNombre'] as String?,
      productoColor: json['productoColor'] as String?,
      productoEstado: json['productoEstado'] as String?,
      productoCantidadPieles: _parseOptionalDouble(
        json['productoCantidadPieles'],
      ),
      productoCantidadLados: _parseOptionalDouble(
        json['productoCantidadLados'],
      ),
      productoCantidadPielesTerminadas: _parseOptionalDouble(
        json['productoCantidadPielesTerminadas'],
      ),
      productoPesoBaseKg: _parseOptionalDouble(json['productoPesoBaseKg']),
      productoInicio: DateTime.tryParse(
        json['productoInicio'] as String? ?? '',
      ),
      productoFin: DateTime.tryParse(json['productoFin'] as String? ?? ''),
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
      ordenCantidadPieles: ordenCantidadPieles,
      ordenProcesoId: ordenProcesoId,
      procesoCodigo: procesoCodigo,
      procesoNombre: procesoNombre,
      ordenProductoId: ordenProductoId,
      productoNombre: productoNombre,
      productoColor: productoColor,
      productoEstado: productoEstado,
      productoCantidadPieles: productoCantidadPieles,
      productoCantidadLados: productoCantidadLados,
      productoCantidadPielesTerminadas: productoCantidadPielesTerminadas,
      productoPesoBaseKg: productoPesoBaseKg,
      productoInicio: productoInicio,
      productoFin: productoFin,
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
