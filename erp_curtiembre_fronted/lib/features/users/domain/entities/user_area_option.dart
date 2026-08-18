import 'package:equatable/equatable.dart';

class UserAreaOption extends Equatable {
  const UserAreaOption({
    required this.id,
    required this.codigo,
    required this.nombre,
  });

  final int id;
  final String codigo;
  final String nombre;

  String get displayName => '$nombre ($codigo)';

  @override
  List<Object?> get props => [id, codigo, nombre];
}
