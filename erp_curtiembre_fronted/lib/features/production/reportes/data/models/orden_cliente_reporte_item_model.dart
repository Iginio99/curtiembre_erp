import 'package:erp_curtiembre_fronted/features/production/reportes/domain/entities/orden_cliente_reporte_item.dart';

class OrdenClienteReporteItemModel {
  const OrdenClienteReporteItemModel({
    required this.ordenProduccionId,
    required this.codigoOrden,
    required this.clienteId,
    required this.cliente,
    required this.codigoLote,
    required this.cantidadPieles,
    required this.fechaFinEstimada,
    required this.estado,
    this.fechaInicioReal,
    this.fechaFinReal,
  });

  final int ordenProduccionId;
  final String codigoOrden;
  final int clienteId;
  final String cliente;
  final String codigoLote;
  final double cantidadPieles;
  final DateTime? fechaInicioReal;
  final DateTime fechaFinEstimada;
  final DateTime? fechaFinReal;
  final String estado;

  factory OrdenClienteReporteItemModel.fromJson(Map<String, dynamic> json) {
    return OrdenClienteReporteItemModel(
      ordenProduccionId: (json['ordenProduccionId'] as num).toInt(),
      codigoOrden: json['codigoOrden'] as String,
      clienteId: (json['clienteId'] as num).toInt(),
      cliente: json['cliente'] as String,
      codigoLote: json['codigoLote'] as String,
      cantidadPieles: (json['cantidadPieles'] as num).toDouble(),
      fechaInicioReal: _parseOptionalDate(json['fechaInicioReal']),
      fechaFinEstimada: DateTime.parse(json['fechaFinEstimada'] as String),
      fechaFinReal: _parseOptionalDate(json['fechaFinReal']),
      estado: json['estado'] as String,
    );
  }

  OrdenClienteReporteItem toEntity() {
    return OrdenClienteReporteItem(
      ordenProduccionId: ordenProduccionId,
      codigoOrden: codigoOrden,
      clienteId: clienteId,
      cliente: cliente,
      codigoLote: codigoLote,
      cantidadPieles: cantidadPieles,
      fechaInicioReal: fechaInicioReal,
      fechaFinEstimada: fechaFinEstimada,
      fechaFinReal: fechaFinReal,
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
