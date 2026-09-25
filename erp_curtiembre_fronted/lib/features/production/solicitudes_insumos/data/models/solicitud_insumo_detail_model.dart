import 'package:erp_curtiembre_fronted/features/production/solicitudes_insumos/domain/entities/solicitud_insumo_detail.dart';

class SolicitudInsumoDetailModel {
  const SolicitudInsumoDetailModel({
    required this.codigo,
    required this.detalles,
  });

  final String codigo;
  final List<SolicitudInsumoDetailLineModel> detalles;

  factory SolicitudInsumoDetailModel.fromJson(Map<String, dynamic> json) =>
      SolicitudInsumoDetailModel(
        codigo: json['codigo'] as String,
        detalles: (json['detalles'] as List<dynamic>)
            .map(
              (item) => SolicitudInsumoDetailLineModel.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList(growable: false),
      );

  SolicitudInsumoDetail toEntity() => SolicitudInsumoDetail(
    codigo: codigo,
    detalles: detalles.map((item) => item.toEntity()).toList(growable: false),
  );
}

class SolicitudInsumoDetailLineModel {
  const SolicitudInsumoDetailLineModel({
    required this.insumoCodigo,
    required this.insumoNombre,
    required this.unidadMedidaCodigo,
    required this.cantidadSolicitada,
    this.observacion,
  });

  final String insumoCodigo;
  final String insumoNombre;
  final String unidadMedidaCodigo;
  final double cantidadSolicitada;
  final String? observacion;

  factory SolicitudInsumoDetailLineModel.fromJson(Map<String, dynamic> json) =>
      SolicitudInsumoDetailLineModel(
        insumoCodigo: json['insumoCodigo'] as String,
        insumoNombre: json['insumoNombre'] as String,
        unidadMedidaCodigo: json['unidadMedidaCodigo'] as String,
        cantidadSolicitada: (json['cantidadSolicitada'] as num).toDouble(),
        observacion: json['observacion'] as String?,
      );

  SolicitudInsumoDetailLine toEntity() => SolicitudInsumoDetailLine(
    insumoCodigo: insumoCodigo,
    insumoNombre: insumoNombre,
    unidadMedidaCodigo: unidadMedidaCodigo,
    cantidadSolicitada: cantidadSolicitada,
    observacion: observacion,
  );
}
