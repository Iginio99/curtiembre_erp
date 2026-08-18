import 'package:erp_curtiembre_fronted/features/production/clientes/domain/entities/cliente_record.dart';

class ClienteRecordModel {
  const ClienteRecordModel({
    required this.id,
    required this.rucDocumento,
    required this.razonSocial,
    required this.activo,
    required this.creadoEn,
    this.direccion,
    this.celular,
    this.correo,
    this.contacto,
    this.actualizadoEn,
  });

  final int id;
  final String rucDocumento;
  final String razonSocial;
  final String? direccion;
  final String? celular;
  final String? correo;
  final String? contacto;
  final bool activo;
  final DateTime creadoEn;
  final DateTime? actualizadoEn;

  factory ClienteRecordModel.fromJson(Map<String, dynamic> json) {
    return ClienteRecordModel(
      id: (json['id'] as num).toInt(),
      rucDocumento: json['rucDocumento'] as String,
      razonSocial: json['razonSocial'] as String,
      direccion: json['direccion'] as String?,
      celular: json['celular'] as String?,
      correo: json['correo'] as String?,
      contacto: json['contacto'] as String?,
      activo: json['activo'] as bool,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      actualizadoEn: _parseOptionalDate(json['actualizadoEn']),
    );
  }

  ClienteRecord toEntity() {
    return ClienteRecord(
      id: id,
      rucDocumento: rucDocumento,
      razonSocial: razonSocial,
      direccion: direccion,
      celular: celular,
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
