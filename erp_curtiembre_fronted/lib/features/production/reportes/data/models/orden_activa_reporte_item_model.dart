import 'package:erp_curtiembre_fronted/features/production/reportes/domain/entities/orden_activa_reporte_item.dart';

class OrdenActivaReporteItemModel {
  const OrdenActivaReporteItemModel({
    required this.ordenProduccionId,
    required this.codigoOrden,
    required this.cliente,
    required this.codigoLote,
    required this.fechaFinEstimada,
    required this.estado,
    this.responsable,
    this.fechaInicioReal,
  });

  final int ordenProduccionId;
  final String codigoOrden;
  final String cliente;
  final String codigoLote;
  final String? responsable;
  final DateTime? fechaInicioReal;
  final DateTime fechaFinEstimada;
  final String estado;

  factory OrdenActivaReporteItemModel.fromJson(Map<String, dynamic> json) {
    return OrdenActivaReporteItemModel(
      ordenProduccionId: (json['ordenProduccionId'] as num).toInt(),
      codigoOrden: json['codigoOrden'] as String,
      cliente: json['cliente'] as String,
      codigoLote: json['codigoLote'] as String,
      responsable: json['responsable'] as String?,
      fechaInicioReal: _parseOptionalDate(json['fechaInicioReal']),
      fechaFinEstimada: DateTime.parse(json['fechaFinEstimada'] as String),
      estado: json['estado'] as String,
    );
  }

  OrdenActivaReporteItem toEntity() {
    return OrdenActivaReporteItem(
      ordenProduccionId: ordenProduccionId,
      codigoOrden: codigoOrden,
      cliente: cliente,
      codigoLote: codigoLote,
      responsable: responsable,
      fechaInicioReal: fechaInicioReal,
      fechaFinEstimada: fechaFinEstimada,
      estado: estado,
    );
  }

  static DateTime? _parseOptionalDate(dynamic value) {
    if (value is! String || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }
}
