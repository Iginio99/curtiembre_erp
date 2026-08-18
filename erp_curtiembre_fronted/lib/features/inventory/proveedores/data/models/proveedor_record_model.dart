import 'package:erp_curtiembre_fronted/features/inventory/proveedores/domain/entities/proveedor_record.dart';

class ProveedorRecordModel {
  const ProveedorRecordModel({
    required this.id,
    required this.rucDocumento,
    required this.razonSocial,
    required this.activo,
    required this.creadoEn,
    this.direccion,
    this.telefono,
    this.correo,
    this.contacto,
    this.actualizadoEn,
  });

  final int id;
  final String rucDocumento;
  final String razonSocial;
  final String? direccion;
  final String? telefono;
  final String? correo;
  final String? contacto;
  final bool activo;
  final DateTime creadoEn;
  final DateTime? actualizadoEn;

  factory ProveedorRecordModel.fromJson(Map<String, dynamic> json) {
    return ProveedorRecordModel(
      id: (json['id'] as num).toInt(),
      rucDocumento: json['rucDocumento'] as String,
      razonSocial: json['razonSocial'] as String,
      direccion: json['direccion'] as String?,
      telefono: json['telefono'] as String?,
      correo: json['correo'] as String?,
      contacto: json['contacto'] as String?,
      activo: json['activo'] as bool,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      actualizadoEn: _parseOptionalDate(json['actualizadoEn']),
    );
  }

  ProveedorRecord toEntity() {
    return ProveedorRecord(
      id: id,
      rucDocumento: rucDocumento,
      razonSocial: razonSocial,
      direccion: direccion,
      telefono: telefono,
      correo: correo,
      contacto: contacto,
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
