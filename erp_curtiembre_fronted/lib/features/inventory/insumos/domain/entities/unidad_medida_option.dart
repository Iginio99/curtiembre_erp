import 'package:equatable/equatable.dart';

class UnidadMedidaOption extends Equatable {
  const UnidadMedidaOption({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.permiteDecimales,
  });

  final int id;
  final String codigo;
  final String nombre;
  final bool permiteDecimales;

  String get displayName => '$codigo · $nombre';

  @override
  List<Object?> get props => [
        id,
        codigo,
        nombre,
        permiteDecimales,
      ];
}
