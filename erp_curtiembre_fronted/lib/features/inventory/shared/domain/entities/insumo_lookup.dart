import 'package:equatable/equatable.dart';

class InsumoLookup extends Equatable {
  const InsumoLookup({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.tipoBien,
    required this.unidadMedidaCodigo,
    required this.unidadMedidaNombre,
    required this.stockActual,
  });

  final int id;
  final String codigo;
  final String nombre;
  final String tipoBien;
  final String unidadMedidaCodigo;
  final String unidadMedidaNombre;
  final double stockActual;

  String get displayName => '$codigo · $nombre';
  String get unitLabel => '$unidadMedidaCodigo · $unidadMedidaNombre';

  @override
  List<Object?> get props => [
        id,
        codigo,
        nombre,
        tipoBien,
        unidadMedidaCodigo,
        unidadMedidaNombre,
        stockActual,
      ];
}
