import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/producto_terminado_record.dart';

class ProductoTerminadoRecordModel {
  const ProductoTerminadoRecordModel({
    required this.id,
    required this.codigo,
    required this.ordenProduccionId,
    required this.ordenCodigo,
    required this.calidadProductoId,
    required this.calidadCodigo,
    required this.calidadNombre,
    required this.fechaIngreso,
    required this.cantidadPielesBuenas,
    required this.cantidadLadosCalculada,
    required this.cantidadLadosA,
    required this.cantidadLadosB,
    required this.cantidadLadosC,
    required this.cantidadLadosMerma,
    required this.estado,
    this.observacion,
    this.ordenProductoId,
    this.productoNombre,
    this.productoColor,
    this.esProductoIndividual = false,
    this.clienteNombre,
    this.cantidadLadosProgramados = 0,
    this.cantidadLadosEntregados = 0,
    this.cantidadLadosPendientes = 0,
    this.fechaOrden,
    this.fechaTerminacionOrden,
  });

  final int id;
  final String codigo;
  final int ordenProduccionId;
  final String ordenCodigo;
  final int calidadProductoId;
  final String calidadCodigo;
  final String calidadNombre;
  final DateTime fechaIngreso;
  final double cantidadPielesBuenas;
  final double cantidadLadosCalculada;
  final double cantidadLadosA;
  final double cantidadLadosB;
  final double cantidadLadosC;
  final double cantidadLadosMerma;
  final String estado;
  final String? observacion;
  final int? ordenProductoId;
  final String? productoNombre, productoColor;
  final bool esProductoIndividual;
  final String? clienteNombre;
  final double cantidadLadosProgramados;
  final double cantidadLadosEntregados;
  final double cantidadLadosPendientes;
  final DateTime? fechaOrden;
  final DateTime? fechaTerminacionOrden;

  factory ProductoTerminadoRecordModel.fromJson(Map<String, dynamic> json) {
    return ProductoTerminadoRecordModel(
      id: (json['id'] as num).toInt(),
      codigo: json['codigo'] as String,
      ordenProduccionId: (json['ordenProduccionId'] as num).toInt(),
      ordenCodigo: json['ordenCodigo'] as String,
      calidadProductoId: (json['calidadProductoId'] as num).toInt(),
      calidadCodigo: json['calidadCodigo'] as String,
      calidadNombre: json['calidadNombre'] as String,
      fechaIngreso: DateTime.parse(json['fechaIngreso'] as String),
      cantidadPielesBuenas: (json['cantidadPielesBuenas'] as num).toDouble(),
      cantidadLadosCalculada: (json['cantidadLadosCalculada'] as num)
          .toDouble(),
      cantidadLadosA: (json['cantidadLadosA'] as num).toDouble(),
      cantidadLadosB: (json['cantidadLadosB'] as num).toDouble(),
      cantidadLadosC: (json['cantidadLadosC'] as num).toDouble(),
      cantidadLadosMerma: (json['cantidadLadosMerma'] as num).toDouble(),
      estado: json['estado'] as String,
      observacion: json['observacion'] as String?,
      ordenProductoId: _parseOptionalInt(json['ordenProductoId']),
      productoNombre: json['productoNombre'] as String?,
      productoColor: json['productoColor'] as String?,
      esProductoIndividual: json['esProductoIndividual'] as bool? ?? false,
      clienteNombre: json['clienteNombre'] as String?,
      cantidadLadosProgramados:
          (json['cantidadLadosProgramados'] as num?)?.toDouble() ?? 0,
      cantidadLadosEntregados:
          (json['cantidadLadosEntregados'] as num?)?.toDouble() ?? 0,
      cantidadLadosPendientes:
          (json['cantidadLadosPendientes'] as num?)?.toDouble() ?? 0,
      fechaOrden: _parseOptionalDate(json['fechaOrden']),
      fechaTerminacionOrden: _parseOptionalDate(json['fechaTerminacionOrden']),
    );
  }

  ProductoTerminadoRecord toEntity() {
    return ProductoTerminadoRecord(
      id: id,
      codigo: codigo,
      ordenProduccionId: ordenProduccionId,
      ordenCodigo: ordenCodigo,
      calidadProductoId: calidadProductoId,
      calidadCodigo: calidadCodigo,
      calidadNombre: calidadNombre,
      fechaIngreso: fechaIngreso,
      cantidadPielesBuenas: cantidadPielesBuenas,
      cantidadLadosCalculada: cantidadLadosCalculada,
      cantidadLadosA: cantidadLadosA,
      cantidadLadosB: cantidadLadosB,
      cantidadLadosC: cantidadLadosC,
      cantidadLadosMerma: cantidadLadosMerma,
      estado: estado,
      observacion: observacion,
      ordenProductoId: ordenProductoId,
      productoNombre: productoNombre,
      productoColor: productoColor,
      esProductoIndividual: esProductoIndividual,
      clienteNombre: clienteNombre,
      cantidadLadosProgramados: cantidadLadosProgramados,
      cantidadLadosEntregados: cantidadLadosEntregados,
      cantidadLadosPendientes: cantidadLadosPendientes,
      fechaOrden: fechaOrden,
      fechaTerminacionOrden: fechaTerminacionOrden,
    );
  }

  static int? _parseOptionalInt(dynamic value) {
    if (value is num) return value.toInt();
    return null;
  }

  static DateTime? _parseOptionalDate(dynamic value) =>
      value is String ? DateTime.tryParse(value) : null;
}
