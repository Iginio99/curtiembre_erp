import 'package:erp_curtiembre_fronted/features/configuration/areas/domain/entities/area_record.dart';

class AreaRecordModel {
  const AreaRecordModel({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.activo,
    required this.creadoEn,
    this.descripcion,
    this.actualizadoEn,
  });

  final int id;
  final String codigo;
  final String nombre;
  final String? descripcion;
  final bool activo;
  final DateTime creadoEn;
  final DateTime? actualizadoEn;

  factory AreaRecordModel.fromJson(Map<String, dynamic> json) {
    return AreaRecordModel(
      id: json['id'] as int,
      codigo: json['codigo'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      activo: json['activo'] as bool,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      actualizadoEn: _parseOptionalDate(json['actualizadoEn']),
    );
  }

  AreaRecord toEntity() {
    return AreaRecord(
      id: id,
      codigo: codigo,
      nombre: nombre,
      descripcion: descripcion,
      activo: activo,
      creadoEn: creadoEn,
      actualizadoEn: actualizadoEn,
    );
  }

  static DateTime? _parseOptionalDate(dynamic value) {
    if (value is! String || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }
}
