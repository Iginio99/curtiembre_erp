import 'package:erp_curtiembre_fronted/features/inventory/ajustes/domain/entities/ajuste_detail.dart';

class AjusteDetalleLineModel {
  const AjusteDetalleLineModel({
    required this.id,
    required this.insumoId,
    required this.insumoCodigo,
    required this.insumoNombre,
    required this.cantidad,
    required this.costoTotal,
    required this.stockActual,
    required this.unidadMedidaCodigo,
    required this.unidadMedidaNombre,
    this.costoUnitario,
  });

  final int id;
  final int insumoId;
  final String insumoCodigo;
  final String insumoNombre;
  final double cantidad;
  final double? costoUnitario;
  final double costoTotal;
  final double stockActual;
  final String unidadMedidaCodigo;
  final String unidadMedidaNombre;

  factory AjusteDetalleLineModel.fromJson(Map<String, dynamic> json) {
    return AjusteDetalleLineModel(
      id: (json['id'] as num).toInt(),
      insumoId: (json['insumoId'] as num).toInt(),
      insumoCodigo: json['insumoCodigo'] as String,
      insumoNombre: json['insumoNombre'] as String,
      cantidad: (json['cantidad'] as num).toDouble(),
      costoUnitario: (json['costoUnitario'] as num?)?.toDouble(),
      costoTotal: (json['costoTotal'] as num).toDouble(),
      stockActual: (json['stockActual'] as num).toDouble(),
      unidadMedidaCodigo: json['unidadMedidaCodigo'] as String,
      unidadMedidaNombre: json['unidadMedidaNombre'] as String,
    );
  }

  AjusteDetalleLine toEntity() {
    return AjusteDetalleLine(
      id: id,
      insumoId: insumoId,
      insumoCodigo: insumoCodigo,
      insumoNombre: insumoNombre,
      cantidad: cantidad,
      costoUnitario: costoUnitario,
      costoTotal: costoTotal,
      stockActual: stockActual,
      unidadMedidaCodigo: unidadMedidaCodigo,
      unidadMedidaNombre: unidadMedidaNombre,
    );
  }
}

class AjusteDetailModel {
  const AjusteDetailModel({
    required this.id,
    required this.codigo,
    required this.tipoAjuste,
    required this.fechaAjuste,
    required this.motivo,
    required this.usuarioResponsableId,
    required this.detalles,
    this.observacion,
  });

  final int id;
  final String codigo;
  final String tipoAjuste;
  final DateTime fechaAjuste;
  final String motivo;
  final String? observacion;
  final int usuarioResponsableId;
  final List<AjusteDetalleLineModel> detalles;

  factory AjusteDetailModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['detalles'] as List<dynamic>? ?? const [];
    return AjusteDetailModel(
      id: (json['id'] as num).toInt(),
      codigo: json['codigo'] as String,
      tipoAjuste: json['tipoAjuste'] as String,
      fechaAjuste: DateTime.parse(json['fechaAjuste'] as String),
      motivo: json['motivo'] as String,
      observacion: json['observacion'] as String?,
      usuarioResponsableId: (json['usuarioResponsableId'] as num).toInt(),
      detalles: rawItems
          .map((item) => AjusteDetalleLineModel.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  AjusteDetail toEntity() {
    return AjusteDetail(
      id: id,
      codigo: codigo,
      tipoAjuste: tipoAjuste,
      fechaAjuste: fechaAjuste,
      motivo: motivo,
      observacion: observacion,
      usuarioResponsableId: usuarioResponsableId,
      detalles: detalles.map((item) => item.toEntity()).toList(growable: false),
    );
  }
}
