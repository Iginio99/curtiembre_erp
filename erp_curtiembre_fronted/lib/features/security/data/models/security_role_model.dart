import 'package:erp_curtiembre_fronted/features/security/domain/entities/security_role.dart';

class SecurityRoleModel {
  const SecurityRoleModel({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.descripcion,
    required this.activo,
  });

  final int id;
  final String codigo;
  final String nombre;
  final String? descripcion;
  final bool activo;

  factory SecurityRoleModel.fromJson(Map<String, dynamic> json) {
    return SecurityRoleModel(
      id: json['id'] as int,
      codigo: json['codigo'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      activo: json['activo'] as bool,
    );
  }

  SecurityRole toEntity() {
    return SecurityRole(
      id: id,
      codigo: codigo,
      nombre: nombre,
      descripcion: descripcion,
      activo: activo,
    );
  }
}
