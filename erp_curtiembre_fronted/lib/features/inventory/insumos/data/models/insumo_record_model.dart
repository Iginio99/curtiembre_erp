import 'package:erp_curtiembre_fronted/features/inventory/insumos/domain/entities/insumo_record.dart';

class InsumoRecordModel {
  const InsumoRecordModel({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.tipoBien,
    required this.unidadMedidaId,
    required this.unidadMedidaCodigo,
    required this.unidadMedidaNombre,
    required this.stockMinimo,
    required this.costoPromedioActual,
    required this.stockActual,
    required this.requiereLote,
    required this.activo,
    required this.creadoEn,
    this.presentacion,
    this.actualizadoEn,
    this.creadoPorUsuarioId,
    this.actualizadoPorUsuarioId,
  });

  final int id;
  final String codigo;
  final String nombre;
  final String tipoBien;
  final String? presentacion;
  final int unidadMedidaId;
  final String unidadMedidaCodigo;
  final String unidadMedidaNombre;
  final double stockMinimo;
  final double costoPromedioActual;
  final double stockActual;
  final bool requiereLote;
  final bool activo;
  final DateTime creadoEn;
  final DateTime? actualizadoEn;
  final int? creadoPorUsuarioId;
  final int? actualizadoPorUsuarioId;

  factory InsumoRecordModel.fromJson(Map<String, dynamic> json) {
    return InsumoRecordModel(
      id: (json['id'] as num).toInt(),
      codigo: json['codigo'] as String,
      nombre: json['nombre'] as String,
      tipoBien: json['tipoBien'] as String,
      presentacion: json['presentacion'] as String?,
      unidadMedidaId: (json['unidadMedidaId'] as num).toInt(),
      unidadMedidaCodigo: json['unidadMedidaCodigo'] as String,
      unidadMedidaNombre: json['unidadMedidaNombre'] as String,
      stockMinimo: (json['stockMinimo'] as num).toDouble(),
      costoPromedioActual: (json['costoPromedioActual'] as num).toDouble(),
      stockActual: (json['stockActual'] as num).toDouble(),
      requiereLote: json['requiereLote'] as bool,
      activo: json['activo'] as bool,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      creadoPorUsuarioId: _parseOptionalInt(json['creadoPorUsuarioId']),
      actualizadoEn: _parseOptionalDate(json['actualizadoEn']),
      actualizadoPorUsuarioId: _parseOptionalInt(json['actualizadoPorUsuarioId']),
    );
  }

  InsumoRecord toEntity() {
    return InsumoRecord(
      id: id,
      codigo: codigo,
      nombre: nombre,
      tipoBien: tipoBien,
      presentacion: presentacion,
      unidadMedidaId: unidadMedidaId,
      unidadMedidaCodigo: unidadMedidaCodigo,
      unidadMedidaNombre: unidadMedidaNombre,
      stockMinimo: stockMinimo,
      costoPromedioActual: costoPromedioActual,
      stockActual: stockActual,
      requiereLote: requiereLote,
      activo: activo,
      creadoEn: creadoEn,
      actualizadoEn: actualizadoEn,
      creadoPorUsuarioId: creadoPorUsuarioId,
      actualizadoPorUsuarioId: actualizadoPorUsuarioId,
    );
  }

  static DateTime? _parseOptionalDate(dynamic value) {
    if (value is! String || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }

  static int? _parseOptionalInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return null;
  }
}
