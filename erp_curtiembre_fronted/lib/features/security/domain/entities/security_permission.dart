import 'package:equatable/equatable.dart';

class SecurityPermission extends Equatable {
  const SecurityPermission({
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

  @override
  List<Object?> get props => [id, codigo, modulo, accion, descripcion, activo];
}
