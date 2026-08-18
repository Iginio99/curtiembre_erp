import 'package:erp_curtiembre_fronted/features/inventory/shared/domain/entities/insumo_lookup.dart';

class InsumoLookupModel {
  const InsumoLookupModel({
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

  factory InsumoLookupModel.fromJson(Map<String, dynamic> json) {
    return InsumoLookupModel(
      id: (json['id'] as num).toInt(),
      codigo: json['codigo'] as String,
      nombre: json['nombre'] as String,
      tipoBien: json['tipoBien'] as String,
      unidadMedidaCodigo: json['unidadMedidaCodigo'] as String,
      unidadMedidaNombre: json['unidadMedidaNombre'] as String,
      stockActual: (json['stockActual'] as num).toDouble(),
    );
  }

  InsumoLookup toEntity() {
    return InsumoLookup(
      id: id,
      codigo: codigo,
      nombre: nombre,
      tipoBien: tipoBien,
      unidadMedidaCodigo: unidadMedidaCodigo,
      unidadMedidaNombre: unidadMedidaNombre,
      stockActual: stockActual,
    );
  }
}
