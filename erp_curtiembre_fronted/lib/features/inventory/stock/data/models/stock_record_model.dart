import 'package:erp_curtiembre_fronted/features/inventory/stock/domain/entities/stock_record.dart';

class StockRecordModel {
  const StockRecordModel({
    required this.insumoId,
    required this.codigo,
    required this.nombre,
    required this.tipoBien,
    required this.unidadMedidaCodigo,
    required this.unidadMedidaNombre,
    required this.stockMinimo,
    required this.cantidadActual,
    required this.costoPromedioActual,
    required this.activo,
    required this.stockBajo,
    required this.actualizadoEn,
  });

  final int insumoId;
  final String codigo;
  final String nombre;
  final String tipoBien;
  final String unidadMedidaCodigo;
  final String unidadMedidaNombre;
  final double stockMinimo;
  final double cantidadActual;
  final double costoPromedioActual;
  final bool activo;
  final bool stockBajo;
  final DateTime actualizadoEn;

  factory StockRecordModel.fromJson(Map<String, dynamic> json) {
    return StockRecordModel(
      insumoId: (json['insumoId'] as num).toInt(),
      codigo: json['codigo'] as String,
      nombre: json['nombre'] as String,
      tipoBien: json['tipoBien'] as String,
      unidadMedidaCodigo: json['unidadMedidaCodigo'] as String,
      unidadMedidaNombre: json['unidadMedidaNombre'] as String,
      stockMinimo: (json['stockMinimo'] as num).toDouble(),
      cantidadActual: (json['cantidadActual'] as num).toDouble(),
      costoPromedioActual: (json['costoPromedioActual'] as num).toDouble(),
      activo: json['activo'] as bool,
      stockBajo: json['stockBajo'] as bool,
      actualizadoEn: DateTime.parse(json['actualizadoEn'] as String),
    );
  }

  StockRecord toEntity() {
    return StockRecord(
      insumoId: insumoId,
      codigo: codigo,
      nombre: nombre,
      tipoBien: tipoBien,
      unidadMedidaCodigo: unidadMedidaCodigo,
      unidadMedidaNombre: unidadMedidaNombre,
      stockMinimo: stockMinimo,
      cantidadActual: cantidadActual,
      costoPromedioActual: costoPromedioActual,
      activo: activo,
      stockBajo: stockBajo,
      actualizadoEn: actualizadoEn,
    );
  }
}
