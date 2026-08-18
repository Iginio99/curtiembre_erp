import 'package:erp_curtiembre_fronted/features/configuration/skin_types/domain/entities/skin_type_record.dart';

class SkinTypeRecordModel {
  const SkinTypeRecordModel({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.activo,
    required this.creadoEn,
    this.descripcion,
  });

  final int id;
  final String codigo;
  final String nombre;
  final String? descripcion;
  final bool activo;
  final DateTime creadoEn;

  factory SkinTypeRecordModel.fromJson(Map<String, dynamic> json) {
    return SkinTypeRecordModel(
      id: json['id'] as int,
      codigo: json['codigo'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      activo: json['activo'] as bool,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
    );
  }

  SkinTypeRecord toEntity() {
    return SkinTypeRecord(
      id: id,
      codigo: codigo,
      nombre: nombre,
      descripcion: descripcion,
      activo: activo,
      creadoEn: creadoEn,
    );
  }
}
