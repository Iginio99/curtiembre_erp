import 'package:erp_curtiembre_fronted/features/inventory/entradas/domain/entities/entrada_inventario_detail.dart';

class EntradaInventarioDetalleLineModel {
  const EntradaInventarioDetalleLineModel({
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

  factory EntradaInventarioDetalleLineModel.fromJson(Map<String, dynamic> json) {
    return EntradaInventarioDetalleLineModel(
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

  EntradaInventarioDetalleLine toEntity() {
    return EntradaInventarioDetalleLine(
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

class EntradaInventarioDetailModel {
  const EntradaInventarioDetailModel({
    required this.id,
    required this.codigo,
    required this.tipoEntrada,
    required this.fechaEntrada,
    required this.estado,
    required this.creadoEn,
    required this.detalles,
    this.documentoSoporte,
    this.observacion,
    this.creadoPorUsuarioId,
  });

  final int id;
  final String codigo;
  final String tipoEntrada;
  final DateTime fechaEntrada;
  final String? documentoSoporte;
  final String? observacion;
  final String estado;
  final int? creadoPorUsuarioId;
  final DateTime creadoEn;
  final List<EntradaInventarioDetalleLineModel> detalles;

  factory EntradaInventarioDetailModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['detalles'] as List<dynamic>? ?? const [];
    return EntradaInventarioDetailModel(
      id: (json['id'] as num).toInt(),
      codigo: json['codigo'] as String,
      tipoEntrada: json['tipoEntrada'] as String,
      fechaEntrada: DateTime.parse(json['fechaEntrada'] as String),
      documentoSoporte: json['documentoSoporte'] as String?,
      observacion: json['observacion'] as String?,
      estado: json['estado'] as String,
      creadoPorUsuarioId: _parseOptionalInt(json['creadoPorUsuarioId']),
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      detalles: rawItems
          .map(
            (item) => EntradaInventarioDetalleLineModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
    );
  }

  EntradaInventarioDetail toEntity() {
    return EntradaInventarioDetail(
      id: id,
      codigo: codigo,
      tipoEntrada: tipoEntrada,
      fechaEntrada: fechaEntrada,
      documentoSoporte: documentoSoporte,
      observacion: observacion,
      estado: estado,
      creadoPorUsuarioId: creadoPorUsuarioId,
      creadoEn: creadoEn,
      detalles: detalles.map((item) => item.toEntity()).toList(growable: false),
    );
  }

  static int? _parseOptionalInt(dynamic value) {
    if (value is num) return value.toInt();
    return null;
  }
}
