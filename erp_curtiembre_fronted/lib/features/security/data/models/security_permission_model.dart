import 'package:erp_curtiembre_fronted/features/security/domain/entities/security_permission.dart';

class SecurityPermissionModel {
  const SecurityPermissionModel({
    required this.id,
    required this.codigo,
    required this.modulo,
    required this.accion,
    required this.descripcion,
    required this.activo,
  });

  final int id;
  final String codigo;
  final String modulo;
  final String accion;
  final String? descripcion;
  final bool activo;

  factory SecurityPermissionModel.fromJson(Map<String, dynamic> json) {
    return SecurityPermissionModel(
      id: json['id'] as int,
      codigo: json['codigo'] as String,
      modulo: json['modulo'] as String,
      accion: json['accion'] as String,
      descripcion: json['descripcion'] as String?,
      activo: json['activo'] as bool,
    );
  }

  SecurityPermission toEntity() {
    return SecurityPermission(
      id: id,
      codigo: codigo,
      modulo: modulo,
      accion: accion,
      descripcion: descripcion,
      activo: activo,
    );
  }
}
