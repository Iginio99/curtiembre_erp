import 'package:erp_curtiembre_fronted/features/inventory/kardex/domain/entities/kardex_record.dart';

class KardexRecordModel {
  const KardexRecordModel({
    required this.id,
    required this.fechaMovimiento,
    required this.insumoId,
    required this.insumoCodigo,
    required this.insumoNombre,
    required this.tipoMovimiento,
    required this.entrada,
    required this.salida,
    required this.stockActual,
    required this.costoUnitario,
    required this.costoTotal,
    this.documentoTipo,
    this.documentoId,
    this.estadoStock,
    this.usuarioResponsableId,
    this.usuarioResponsable,
    this.observacion,
  });

  final int id;
  final DateTime fechaMovimiento;
  final int insumoId;
  final String insumoCodigo;
  final String insumoNombre;
  final String tipoMovimiento;
  final String? documentoTipo;
  final int? documentoId;
  final double entrada;
  final double salida;
  final double stockActual;
  final String? estadoStock;
  final double costoUnitario;
  final double costoTotal;
  final int? usuarioResponsableId;
  final String? usuarioResponsable;
  final String? observacion;

  factory KardexRecordModel.fromJson(Map<String, dynamic> json) {
    return KardexRecordModel(
      id: (json['id'] as num).toInt(),
      fechaMovimiento: DateTime.parse(json['fechaMovimiento'] as String),
      insumoId: (json['insumoId'] as num).toInt(),
      insumoCodigo: json['insumoCodigo'] as String,
      insumoNombre: json['insumoNombre'] as String,
      tipoMovimiento: json['tipoMovimiento'] as String,
      documentoTipo: json['documentoTipo'] as String?,
      documentoId: (json['documentoId'] as num?)?.toInt(),
      entrada: (json['entrada'] as num).toDouble(),
      salida: (json['salida'] as num).toDouble(),
      stockActual: (json['stockActual'] as num).toDouble(),
      estadoStock: json['estadoStock'] as String?,
      costoUnitario: (json['costoUnitario'] as num).toDouble(),
      costoTotal: (json['costoTotal'] as num).toDouble(),
      usuarioResponsableId: (json['usuarioResponsableId'] as num?)?.toInt(),
      usuarioResponsable: json['usuarioResponsable'] as String?,
      observacion: json['observacion'] as String?,
    );
  }

  KardexRecord toEntity() {
    return KardexRecord(
      id: id,
      fechaMovimiento: fechaMovimiento,
      insumoId: insumoId,
      insumoCodigo: insumoCodigo,
      insumoNombre: insumoNombre,
      tipoMovimiento: tipoMovimiento,
      documentoTipo: documentoTipo,
      documentoId: documentoId,
      entrada: entrada,
      salida: salida,
      stockActual: stockActual,
      estadoStock: estadoStock,
      costoUnitario: costoUnitario,
      costoTotal: costoTotal,
      usuarioResponsableId: usuarioResponsableId,
      usuarioResponsable: usuarioResponsable,
      observacion: observacion,
    );
  }
}
