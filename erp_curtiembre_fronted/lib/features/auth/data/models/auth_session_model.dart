import 'package:erp_curtiembre_fronted/features/auth/domain/entities/auth_session.dart';

class AuthSessionModel {
  const AuthSessionModel({
    required this.usuarioId,
    required this.userName,
    required this.nombreCompleto,
    required this.rolCodigo,
    required this.rolNombre,
    required this.debeCambiarPassword,
    required this.sessionToken,
    required this.expiraEn,
    this.sesionId,
    this.rolId,
  });

  final int usuarioId;
  final String userName;
  final String nombreCompleto;
  final String rolCodigo;
  final String rolNombre;
  final bool debeCambiarPassword;
  final String sessionToken;
  final DateTime expiraEn;
  final int? sesionId;
  final int? rolId;

  factory AuthSessionModel.fromLoginJson(Map<String, dynamic> json) {
    return AuthSessionModel(
      usuarioId: json['usuarioId'] as int,
      userName: json['userName'] as String,
      nombreCompleto: json['nombreCompleto'] as String,
      rolCodigo: json['rolCodigo'] as String,
      rolNombre: json['rolNombre'] as String,
      debeCambiarPassword: json['debeCambiarPassword'] as bool,
      sessionToken: json['sessionToken'] as String,
      expiraEn: DateTime.parse(json['expiraEn'] as String),
    );
  }

  factory AuthSessionModel.fromSessionJson(
    Map<String, dynamic> json, {
    required String sessionToken,
  }) {
    return AuthSessionModel(
      sesionId: json['sesionId'] as int?,
      usuarioId: json['usuarioId'] as int,
      rolId: json['rolId'] as int?,
      userName: json['userName'] as String,
      nombreCompleto: json['nombreCompleto'] as String,
      rolCodigo: json['rolCodigo'] as String,
      rolNombre: json['rolNombre'] as String,
      debeCambiarPassword: json['debeCambiarPassword'] as bool,
      sessionToken: sessionToken,
      expiraEn: DateTime.parse(json['expiraEn'] as String),
    );
  }

  AuthSession toEntity() {
    return AuthSession(
      sesionId: sesionId,
      usuarioId: usuarioId,
      rolId: rolId,
      userName: userName,
      nombreCompleto: nombreCompleto,
      rolCodigo: rolCodigo,
      rolNombre: rolNombre,
      debeCambiarPassword: debeCambiarPassword,
      sessionToken: sessionToken,
      expiraEn: expiraEn,
    );
  }
}
