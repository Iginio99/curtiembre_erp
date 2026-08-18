import 'package:erp_curtiembre_fronted/features/configuration/units/domain/entities/unit_record.dart';

class UnitRecordModel {
  const UnitRecordModel({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.permiteDecimales,
    required this.activo,
    required this.creadoEn,
  });

  final int id;
  final String codigo;
  final String nombre;
  final bool permiteDecimales;
  final bool activo;
  final DateTime creadoEn;

  factory UnitRecordModel.fromJson(Map<String, dynamic> json) {
    return UnitRecordModel(
      id: json['id'] as int,
      codigo: json['codigo'] as String,
      nombre: json['nombre'] as String,
      permiteDecimales: json['permiteDecimales'] as bool,
      activo: json['activo'] as bool,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
    );
  }

  UnitRecord toEntity() {
    return UnitRecord(
      id: id,
      codigo: codigo,
      nombre: nombre,
      permiteDecimales: permiteDecimales,
      activo: activo,
      creadoEn: creadoEn,
    );
  }
}
