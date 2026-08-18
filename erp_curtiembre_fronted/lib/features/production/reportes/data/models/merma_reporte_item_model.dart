import 'package:erp_curtiembre_fronted/features/production/reportes/domain/entities/merma_reporte_item.dart';

class MermaReporteItemModel {
  const MermaReporteItemModel({
    required this.id,
    required this.ordenProduccionId,
    required this.codigoOrden,
    required this.ordenProcesoId,
    required this.procesoCodigo,
    required this.procesoNombre,
    required this.cantidadPerdida,
    required this.registradoEn,
    this.motivo,
    this.responsable,
  });

  final int id;
  final int ordenProduccionId;
  final String codigoOrden;
  final int ordenProcesoId;
  final String procesoCodigo;
  final String procesoNombre;
  final double cantidadPerdida;
  final String? motivo;
  final DateTime registradoEn;
  final String? responsable;

  factory MermaReporteItemModel.fromJson(Map<String, dynamic> json) {
    return MermaReporteItemModel(
      id: (json['id'] as num).toInt(),
      ordenProduccionId: (json['ordenProduccionId'] as num).toInt(),
      codigoOrden: json['codigoOrden'] as String,
      ordenProcesoId: (json['ordenProcesoId'] as num).toInt(),
      procesoCodigo: json['procesoCodigo'] as String,
      procesoNombre: json['procesoNombre'] as String,
      cantidadPerdida: (json['cantidadPerdida'] as num).toDouble(),
      motivo: json['motivo'] as String?,
      registradoEn: DateTime.parse(json['registradoEn'] as String),
      responsable: json['responsable'] as String?,
    );
  }

  MermaReporteItem toEntity() {
    return MermaReporteItem(
      id: id,
      ordenProduccionId: ordenProduccionId,
      codigoOrden: codigoOrden,
      ordenProcesoId: ordenProcesoId,
      procesoCodigo: procesoCodigo,
      procesoNombre: procesoNombre,
      cantidadPerdida: cantidadPerdida,
      motivo: motivo,
      registradoEn: registradoEn,
      responsable: responsable,
    );
  }
}
