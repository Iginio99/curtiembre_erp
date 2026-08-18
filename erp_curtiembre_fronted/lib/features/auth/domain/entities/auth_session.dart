import 'package:equatable/equatable.dart';

class AuthSession extends Equatable {
  const AuthSession({
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

  AuthSession copyWith({
    int? usuarioId,
    String? userName,
    String? nombreCompleto,
    String? rolCodigo,
    String? rolNombre,
    bool? debeCambiarPassword,
    String? sessionToken,
    DateTime? expiraEn,
    int? sesionId,
    int? rolId,
  }) {
    return AuthSession(
      usuarioId: usuarioId ?? this.usuarioId,
      userName: userName ?? this.userName,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      rolCodigo: rolCodigo ?? this.rolCodigo,
      rolNombre: rolNombre ?? this.rolNombre,
      debeCambiarPassword: debeCambiarPassword ?? this.debeCambiarPassword,
      sessionToken: sessionToken ?? this.sessionToken,
      expiraEn: expiraEn ?? this.expiraEn,
      sesionId: sesionId ?? this.sesionId,
      rolId: rolId ?? this.rolId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sesionId': sesionId,
      'usuarioId': usuarioId,
      'rolId': rolId,
      'userName': userName,
      'nombreCompleto': nombreCompleto,
      'rolCodigo': rolCodigo,
      'rolNombre': rolNombre,
      'debeCambiarPassword': debeCambiarPassword,
      'sessionToken': sessionToken,
      'expiraEn': expiraEn.toIso8601String(),
    };
  }

  factory AuthSession.fromMap(Map<String, dynamic> map) {
    return AuthSession(
      sesionId: map['sesionId'] as int?,
      usuarioId: map['usuarioId'] as int,
      rolId: map['rolId'] as int?,
      userName: map['userName'] as String,
      nombreCompleto: map['nombreCompleto'] as String,
      rolCodigo: map['rolCodigo'] as String,
      rolNombre: map['rolNombre'] as String,
      debeCambiarPassword: map['debeCambiarPassword'] as bool,
      sessionToken: map['sessionToken'] as String,
      expiraEn: DateTime.parse(map['expiraEn'] as String),
    );
  }

  @override
  List<Object?> get props => [
        sesionId,
        usuarioId,
        rolId,
        userName,
        nombreCompleto,
        rolCodigo,
        rolNombre,
        debeCambiarPassword,
        sessionToken,
        expiraEn,
      ];
}
