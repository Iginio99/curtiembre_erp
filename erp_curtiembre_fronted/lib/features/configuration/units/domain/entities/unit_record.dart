import 'package:equatable/equatable.dart';

class UnitRecord extends Equatable {
  const UnitRecord({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.permiteDecimales,
    required this.activo,
    required this.creadoEn,
  });

  final int id;
  final String codigo;
  final String nombre;
  final bool permiteDecimales;
  final bool activo;
  final DateTime creadoEn;

  @override
  List<Object?> get props => [
        id,
        codigo,
        nombre,
        permiteDecimales,
        activo,
        creadoEn,
      ];
}
