import 'package:equatable/equatable.dart';

class AreaRecord extends Equatable {
  const AreaRecord({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.activo,
    required this.creadoEn,
    this.descripcion,
    this.actualizadoEn,
  });

  final int id;
  final String codigo;
  final String nombre;
  final String? descripcion;
  final bool activo;
  final DateTime creadoEn;
  final DateTime? actualizadoEn;

  @override
  List<Object?> get props => [
        id,
        codigo,
        nombre,
        descripcion,
        activo,
        creadoEn,
        actualizadoEn,
      ];
}
