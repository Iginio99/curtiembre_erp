import 'package:equatable/equatable.dart';

class UserListItem extends Equatable {
  const UserListItem({
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

  String get nombreCompleto => '$nombres $apellidos';

  @override
  List<Object?> get props => [
        usuarioId,
        dni,
        nombres,
        apellidos,
        userName,
        rolId,
        rolNombre,
        areaId,
        areaNombre,
        activo,
        debeCambiarPassword,
        intentosFallidos,
        bloqueadoHasta,
        ultimoLoginEn,
      ];
}
