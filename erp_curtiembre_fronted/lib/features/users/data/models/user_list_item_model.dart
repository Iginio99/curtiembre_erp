import 'package:erp_curtiembre_fronted/features/users/domain/entities/user_list_item.dart';

class UserListItemModel {
  const UserListItemModel({
    required this.usuarioId,
    required this.dni,
    required this.nombres,
    required this.apellidos,
    required this.userName,
    required this.rolId,
    required this.rolNombre,
    required this.activo,
    required this.debeCambiarPassword,
    required this.intentosFallidos,
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
  final String rolNombre;
  final int? areaId;
  final String? areaNombre;
  final bool activo;
  final bool debeCambiarPassword;
  final int intentosFallidos;
  final DateTime? bloqueadoHasta;
  final DateTime? ultimoLoginEn;

  factory UserListItemModel.fromJson(Map<String, dynamic> json) {
    return UserListItemModel(
      usuarioId: json['usuarioId'] as int,
      dni: json['dni'] as String,
      nombres: json['nombres'] as String,
      apellidos: json['apellidos'] as String,
      userName: json['userName'] as String,
      rolId: json['rolId'] as int,
      rolNombre: json['rolNombre'] as String,
      areaId: json['areaId'] as int?,
      areaNombre: json['areaNombre'] as String?,
      activo: json['activo'] as bool,
      debeCambiarPassword: json['debeCambiarPassword'] as bool,
      intentosFallidos: json['intentosFallidos'] as int,
      bloqueadoHasta: _parseDate(json['bloqueadoHasta']),
      ultimoLoginEn: _parseDate(json['ultimoLoginEn']),
    );
  }

  UserListItem toEntity() {
    return UserListItem(
      usuarioId: usuarioId,
      dni: dni,
      nombres: nombres,
      apellidos: apellidos,
      userName: userName,
      rolId: rolId,
      rolNombre: rolNombre,
      areaId: areaId,
      areaNombre: areaNombre,
      activo: activo,
      debeCambiarPassword: debeCambiarPassword,
      intentosFallidos: intentosFallidos,
      bloqueadoHasta: bloqueadoHasta,
      ultimoLoginEn: ultimoLoginEn,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is! String || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }
}
