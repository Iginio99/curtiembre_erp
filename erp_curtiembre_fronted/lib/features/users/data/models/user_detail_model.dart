import 'package:erp_curtiembre_fronted/features/users/domain/entities/user_detail.dart';

class UserDetailModel {
  const UserDetailModel({
    required this.usuarioId,
    required this.dni,
    required this.nombres,
    required this.apellidos,
    required this.userName,
    required this.rolId,
    required this.rolCodigo,
    required this.rolNombre,
    required this.activo,
    required this.debeCambiarPassword,
    required this.intentosFallidos,
    required this.creadoEn,
    this.areaId,
    this.areaNombre,
    this.bloqueadoHasta,
    this.ultimoLoginEn,
  });

  final int usuarioId;
  final String dni;
  final String nombres;
  final String apellidos;
  final String userName;
  final int rolId;
  final String rolCodigo;
  final String rolNombre;
  final int? areaId;
  final String? areaNombre;
  final bool activo;
  final bool debeCambiarPassword;
  final int intentosFallidos;
  final DateTime? bloqueadoHasta;
  final DateTime? ultimoLoginEn;
  final DateTime creadoEn;

  factory UserDetailModel.fromJson(Map<String, dynamic> json) {
    return UserDetailModel(
      usuarioId: json['usuarioId'] as int,
      dni: json['dni'] as String,
      nombres: json['nombres'] as String,
      apellidos: json['apellidos'] as String,
      userName: json['userName'] as String,
      rolId: json['rolId'] as int,
      rolCodigo: json['rolCodigo'] as String,
      rolNombre: json['rolNombre'] as String,
      areaId: json['areaId'] as int?,
      areaNombre: json['areaNombre'] as String?,
      activo: json['activo'] as bool,
      debeCambiarPassword: json['debeCambiarPassword'] as bool,
      intentosFallidos: json['intentosFallidos'] as int,
      bloqueadoHasta: _parseOptionalDate(json['bloqueadoHasta']),
      ultimoLoginEn: _parseOptionalDate(json['ultimoLoginEn']),
      creadoEn: DateTime.parse(json['creadoEn'] as String),
    );
  }

  UserDetail toEntity() {
    return UserDetail(
      usuarioId: usuarioId,
      dni: dni,
      nombres: nombres,
      apellidos: apellidos,
      userName: userName,
      rolId: rolId,
      rolCodigo: rolCodigo,
      rolNombre: rolNombre,
      areaId: areaId,
      areaNombre: areaNombre,
      activo: activo,
      debeCambiarPassword: debeCambiarPassword,
      intentosFallidos: intentosFallidos,
      bloqueadoHasta: bloqueadoHasta,
      ultimoLoginEn: ultimoLoginEn,
      creadoEn: creadoEn,
    );
  }

  static DateTime? _parseOptionalDate(dynamic value) {
    if (value is! String || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }
}
