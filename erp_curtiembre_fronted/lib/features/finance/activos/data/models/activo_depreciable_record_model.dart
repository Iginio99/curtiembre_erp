import 'package:erp_curtiembre_fronted/features/finance/activos/domain/entities/activo_depreciable_record.dart';

class ActivoDepreciableRecordModel {
  const ActivoDepreciableRecordModel({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.valorCompra,
    required this.cantidad,
    required this.costoTotal,
    required this.fechaCompra,
    required this.vidaUtilMeses,
    required this.valorResidual,
    required this.activo,
    required this.creadoEn,
    this.depreciacionMensual,
    this.depreciacionAnual,
  });

  final int id;
  final String codigo;
  final String nombre;
  final double valorCompra;
  final int cantidad;
  final double costoTotal;
  final DateTime fechaCompra;
  final int vidaUtilMeses;
  final double valorResidual;
  final bool activo;
  final DateTime creadoEn;
  final double? depreciacionMensual;
  final double? depreciacionAnual;

  factory ActivoDepreciableRecordModel.fromJson(Map<String, dynamic> json) {
    return ActivoDepreciableRecordModel(
      id: (json['id'] as num).toInt(),
      codigo: json['codigo'] as String,
      nombre: json['nombre'] as String,
      valorCompra: (json['valorCompra'] as num).toDouble(),
      cantidad: (json['cantidad'] as num).toInt(),
      costoTotal: (json['costoTotal'] as num).toDouble(),
      fechaCompra: DateTime.parse(json['fechaCompra'] as String),
      vidaUtilMeses: (json['vidaUtilMeses'] as num).toInt(),
      valorResidual: (json['valorResidual'] as num).toDouble(),
      activo: json['activo'] as bool,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      depreciacionMensual: _parseOptionalDouble(json['depreciacionMensual']),
      depreciacionAnual: _parseOptionalDouble(json['depreciacionAnual']),
    );
  }

  ActivoDepreciableRecord toEntity() {
    return ActivoDepreciableRecord(
      id: id,
      codigo: codigo,
      nombre: nombre,
      valorCompra: valorCompra,
      cantidad: cantidad,
      costoTotal: costoTotal,
      fechaCompra: fechaCompra,
      vidaUtilMeses: vidaUtilMeses,
      valorResidual: valorResidual,
      activo: activo,
      creadoEn: creadoEn,
      depreciacionMensual: depreciacionMensual,
      depreciacionAnual: depreciacionAnual,
    );
  }

  static double? _parseOptionalDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return null;
  }
}
