import 'package:erp_curtiembre_fronted/features/production/lotes/domain/entities/tipo_piel_option.dart';

class TipoPielOptionModel {
  const TipoPielOptionModel({
    required this.id,
    required this.codigo,
    required this.nombre,
  });

  final int id;
  final String codigo;
  final String nombre;

  factory TipoPielOptionModel.fromJson(Map<String, dynamic> json) {
    return TipoPielOptionModel(
      id: (json['id'] as num).toInt(),
      codigo: json['codigo'] as String,
      nombre: json['nombre'] as String,
    );
  }

  TipoPielOption toEntity() {
    return TipoPielOption(
      id: id,
      codigo: codigo,
      nombre: nombre,
    );
  }
}
