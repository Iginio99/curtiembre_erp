import 'package:erp_curtiembre_fronted/features/inventory/insumos/domain/entities/unidad_medida_option.dart';

class UnidadMedidaOptionModel {
  const UnidadMedidaOptionModel({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.permiteDecimales,
  });

  final int id;
  final String codigo;
  final String nombre;
  final bool permiteDecimales;

  factory UnidadMedidaOptionModel.fromJson(Map<String, dynamic> json) {
    return UnidadMedidaOptionModel(
      id: (json['id'] as num).toInt(),
      codigo: json['codigo'] as String,
      nombre: json['nombre'] as String,
      permiteDecimales: json['permiteDecimales'] as bool,
    );
  }

  UnidadMedidaOption toEntity() {
    return UnidadMedidaOption(
      id: id,
      codigo: codigo,
      nombre: nombre,
      permiteDecimales: permiteDecimales,
    );
  }
}
