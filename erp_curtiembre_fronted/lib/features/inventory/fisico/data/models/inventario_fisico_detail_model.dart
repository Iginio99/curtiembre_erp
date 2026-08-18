import 'package:erp_curtiembre_fronted/features/inventory/fisico/domain/entities/inventario_fisico_detail.dart';

class InventarioFisicoResumenModel {
  const InventarioFisicoResumenModel({
    required this.totalItems,
    required this.itemsConDiferencia,
    required this.itemsConAjustePositivo,
    required this.itemsConAjusteNegativo,
    required this.totalDiferenciaAbsoluta,
  });

  factory InventarioFisicoResumenModel.fromJson(Map<String, dynamic> json) {
    return InventarioFisicoResumenModel(
      totalItems: (json['totalItems'] as num).toInt(),
      itemsConDiferencia: (json['itemsConDiferencia'] as num).toInt(),
      itemsConAjustePositivo: (json['itemsConAjustePositivo'] as num).toInt(),
      itemsConAjusteNegativo: (json['itemsConAjusteNegativo'] as num).toInt(),
      totalDiferenciaAbsoluta:
          (json['totalDiferenciaAbsoluta'] as num).toDouble(),
    );
  }

  final int totalItems;
  final int itemsConDiferencia;
  final int itemsConAjustePositivo;
  final int itemsConAjusteNegativo;
  final double totalDiferenciaAbsoluta;

  InventarioFisicoResumen toEntity() {
    return InventarioFisicoResumen(
      totalItems: totalItems,
      itemsConDiferencia: itemsConDiferencia,
      itemsConAjustePositivo: itemsConAjustePositivo,
      itemsConAjusteNegativo: itemsConAjusteNegativo,
      totalDiferenciaAbsoluta: totalDiferenciaAbsoluta,
    );
  }
}

class InventarioFisicoConteoLineModel {
  const InventarioFisicoConteoLineModel({
    required this.id,
    required this.insumoId,
    required this.insumoCodigo,
    required this.insumoNombre,
    required this.stockSistema,
    required this.stockContado,
    required this.diferencia,
    required this.unidadMedidaCodigo,
    required this.unidadMedidaNombre,
    required this.observacion,
  });

  factory InventarioFisicoConteoLineModel.fromJson(Map<String, dynamic> json) {
    return InventarioFisicoConteoLineModel(
      id: (json['id'] as num).toInt(),
      insumoId: (json['insumoId'] as num).toInt(),
      insumoCodigo: json['insumoCodigo'] as String,
      insumoNombre: json['insumoNombre'] as String,
      stockSistema: (json['stockSistema'] as num).toDouble(),
      stockContado: (json['stockContado'] as num).toDouble(),
      diferencia: (json['diferencia'] as num).toDouble(),
      unidadMedidaCodigo: json['unidadMedidaCodigo'] as String,
      unidadMedidaNombre: json['unidadMedidaNombre'] as String,
      observacion: json['observacion'] as String?,
    );
  }

  final int id;
  final int insumoId;
  final String insumoCodigo;
  final String insumoNombre;
  final double stockSistema;
  final double stockContado;
  final double diferencia;
  final String unidadMedidaCodigo;
  final String unidadMedidaNombre;
  final String? observacion;

  InventarioFisicoConteoLine toEntity() {
    return InventarioFisicoConteoLine(
      id: id,
      insumoId: insumoId,
      insumoCodigo: insumoCodigo,
      insumoNombre: insumoNombre,
      stockSistema: stockSistema,
      stockContado: stockContado,
      diferencia: diferencia,
      unidadMedidaCodigo: unidadMedidaCodigo,
      unidadMedidaNombre: unidadMedidaNombre,
      observacion: observacion,
    );
  }
}

class InventarioFisicoDetailModel {
  const InventarioFisicoDetailModel({
    required this.id,
    required this.codigo,
    required this.fechaInicio,
    required this.fechaCierre,
    required this.periodoAnio,
    required this.periodoMes,
    required this.estado,
    required this.ejecutadoPorUsuarioId,
    required this.observacion,
    required this.resumen,
    required this.detalles,
  });

  factory InventarioFisicoDetailModel.fromJson(Map<String, dynamic> json) {
    return InventarioFisicoDetailModel(
      id: (json['id'] as num).toInt(),
      codigo: json['codigo'] as String,
      fechaInicio: DateTime.parse(json['fechaInicio'] as String),
      fechaCierre: json['fechaCierre'] == null
          ? null
          : DateTime.parse(json['fechaCierre'] as String),
      periodoAnio: (json['periodoAnio'] as num).toInt(),
      periodoMes: (json['periodoMes'] as num).toInt(),
      estado: json['estado'] as String,
      ejecutadoPorUsuarioId: (json['ejecutadoPorUsuarioId'] as num).toInt(),
      observacion: json['observacion'] as String?,
      resumen: InventarioFisicoResumenModel.fromJson(
        json['resumen'] as Map<String, dynamic>,
      ),
      detalles: (json['detalles'] as List<dynamic>? ?? const [])
          .map(
            (item) => InventarioFisicoConteoLineModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
    );
  }

  final int id;
  final String codigo;
  final DateTime fechaInicio;
  final DateTime? fechaCierre;
  final int periodoAnio;
  final int periodoMes;
  final String estado;
  final int ejecutadoPorUsuarioId;
  final String? observacion;
  final InventarioFisicoResumenModel resumen;
  final List<InventarioFisicoConteoLineModel> detalles;

  InventarioFisicoDetail toEntity() {
    return InventarioFisicoDetail(
      id: id,
      codigo: codigo,
      fechaInicio: fechaInicio,
      fechaCierre: fechaCierre,
      periodoAnio: periodoAnio,
      periodoMes: periodoMes,
      estado: estado,
      ejecutadoPorUsuarioId: ejecutadoPorUsuarioId,
      observacion: observacion,
      resumen: resumen.toEntity(),
      detalles: detalles.map((item) => item.toEntity()).toList(growable: false),
    );
  }
}
