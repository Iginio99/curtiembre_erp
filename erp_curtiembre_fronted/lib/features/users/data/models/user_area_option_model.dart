import 'package:erp_curtiembre_fronted/features/users/domain/entities/user_area_option.dart';

class UserAreaOptionModel {
  const UserAreaOptionModel({
    required this.id,
    required this.codigo,
    required this.nombre,
  });

  final int id;
  final String codigo;
  final String nombre;

  factory UserAreaOptionModel.fromJson(Map<String, dynamic> json) {
    return UserAreaOptionModel(
      id: json['id'] as int,
      codigo: json['codigo'] as String,
      nombre: json['nombre'] as String,
    );
  }

  UserAreaOption toEntity() {
    return UserAreaOption(
      id: id,
      codigo: codigo,
      nombre: nombre,
    );
  }
}
