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
    );
  }
}
