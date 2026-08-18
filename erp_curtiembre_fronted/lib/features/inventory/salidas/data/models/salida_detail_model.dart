import 'package:erp_curtiembre_fronted/features/inventory/salidas/domain/entities/salida_detail.dart';

class SalidaDetalleLineModel {
  const SalidaDetalleLineModel({
    required this.id,
    required this.insumoId,
    required this.insumoCodigo,
    required this.insumoNombre,
    required this.cantidad,
    required this.costoUnitario,
    required this.costoTotal,
    required this.stockActual,
    required this.unidadMedidaCodigo,
    required this.unidadMedidaNombre,
    this.observacion,
  });

  final int id;
  final int insumoId;
  final String insumoCodigo;
  final String insumoNombre;
  final double cantidad;
  final double costoUnitario;
  final double costoTotal;
  final double stockActual;
  final String unidadMedidaCodigo;
  final String unidadMedidaNombre;
  final String? observacion;

  factory SalidaDetalleLineModel.fromJson(Map<String, dynamic> json) {
    return SalidaDetalleLineModel(
      id: (json['id'] as num).toInt(),
      insumoId: (json['insumoId'] as num).toInt(),
      insumoCodigo: json['insumoCodigo'] as String,
      insumoNombre: json['insumoNombre'] as String,
      cantidad: (json['cantidad'] as num).toDouble(),
      costoUnitario: (json['costoUnitario'] as num).toDouble(),
      costoTotal: (json['costoTotal'] as num).toDouble(),
      stockActual: (json['stockActual'] as num).toDouble(),
      unidadMedidaCodigo: json['unidadMedidaCodigo'] as String,
      unidadMedidaNombre: json['unidadMedidaNombre'] as String,
      observacion: json['observacion'] as String?,
    );
  }

  SalidaDetalleLine toEntity() {
    return SalidaDetalleLine(
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
      observacion: observacion,
    );
  }
}

class SalidaDetailModel {
  const SalidaDetailModel({
    required this.id,
    required this.codigo,
    required this.tipoSalida,
    required this.fechaSalida,
    required this.estado,
    required this.creadoEn,
    required this.detalles,
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
  final List<SalidaDetalleLineModel> detalles;

  factory SalidaDetailModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['detalles'] as List<dynamic>? ?? const [];
    return SalidaDetailModel(
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
      detalles: rawItems
          .map((item) => SalidaDetalleLineModel.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  SalidaDetail toEntity() {
    return SalidaDetail(
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
      detalles: detalles.map((item) => item.toEntity()).toList(growable: false),
    );
  }
}
