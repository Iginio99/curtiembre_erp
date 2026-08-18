import 'package:erp_curtiembre_fronted/features/production/solicitudes_insumos/domain/entities/solicitud_insumo_record.dart';

class SolicitudInsumoRecordModel {
  const SolicitudInsumoRecordModel({
    required this.id,
    required this.codigo,
    required this.ordenCodigo,
    required this.procesoCodigo,
    required this.procesoNombre,
    required this.estado,
    required this.solicitadoEn,
    required this.solicitadoPorNombre,
    required this.totalItems,
    required this.cantidadTotal,
    this.observacion,
  });

  final int id;
  final String codigo;
  final String ordenCodigo;
  final String procesoCodigo;
  final String procesoNombre;
  final String estado;
  final DateTime solicitadoEn;
  final String solicitadoPorNombre;
  final int totalItems;
  final double cantidadTotal;
  final String? observacion;

  factory SolicitudInsumoRecordModel.fromJson(Map<String, dynamic> json) =>
      SolicitudInsumoRecordModel(
        id: (json['id'] as num).toInt(),
        codigo: json['codigo'] as String,
        ordenCodigo: json['ordenCodigo'] as String,
        procesoCodigo: json['procesoCodigo'] as String,
        procesoNombre: json['procesoNombre'] as String,
        estado: json['estado'] as String,
        solicitadoEn: DateTime.parse(json['solicitadoEn'] as String),
        solicitadoPorNombre: json['solicitadoPorNombre'] as String,
        totalItems: (json['totalItems'] as num).toInt(),
        cantidadTotal: (json['cantidadTotal'] as num).toDouble(),
        observacion: json['observacion'] as String?,
      );

  SolicitudInsumoRecord toEntity() => SolicitudInsumoRecord(
    id: id,
    codigo: codigo,
    ordenCodigo: ordenCodigo,
    procesoCodigo: procesoCodigo,
    procesoNombre: procesoNombre,
    estado: estado,
    solicitadoEn: solicitadoEn,
    solicitadoPorNombre: solicitadoPorNombre,
    totalItems: totalItems,
    cantidadTotal: cantidadTotal,
    observacion: observacion,
  );
}
