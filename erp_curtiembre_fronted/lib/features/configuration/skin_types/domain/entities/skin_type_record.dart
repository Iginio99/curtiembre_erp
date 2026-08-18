import 'package:equatable/equatable.dart';

class SkinTypeRecord extends Equatable {
  const SkinTypeRecord({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.activo,
    required this.creadoEn,
    this.descripcion,
  });

  final int id;
  final String codigo;
  final String nombre;
  final String? descripcion;
  final bool activo;
  final DateTime creadoEn;

  @override
  List<Object?> get props => [
        id,
        codigo,
        nombre,
        descripcion,
        activo,
        creadoEn,
      ];
}
