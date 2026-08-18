import 'package:equatable/equatable.dart';

class TipoPielOption extends Equatable {
  const TipoPielOption({
    required this.id,
    required this.codigo,
    required this.nombre,
  });

  final int id;
  final String codigo;
  final String nombre;

  String get label => '$nombre ($codigo)';

  @override
  List<Object?> get props => [id, codigo, nombre];
}
