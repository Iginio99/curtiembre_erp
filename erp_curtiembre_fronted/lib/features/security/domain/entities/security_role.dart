import 'package:equatable/equatable.dart';

class SecurityRole extends Equatable {
  const SecurityRole({
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

  @override
  List<Object?> get props => [id, codigo, nombre, descripcion, activo];
}
