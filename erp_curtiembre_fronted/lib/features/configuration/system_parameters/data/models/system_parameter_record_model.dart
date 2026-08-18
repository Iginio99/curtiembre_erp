import 'package:erp_curtiembre_fronted/features/configuration/system_parameters/domain/entities/system_parameter_record.dart';

class SystemParameterRecordModel extends SystemParameterRecord {
  const SystemParameterRecordModel({
    required super.id,
    required super.clave,
    required super.valor,
    required super.descripcion,
    required super.tipoDato,
    required super.editable,
    required super.actualizadoEn,
  });

  factory SystemParameterRecordModel.fromJson(Map<String, dynamic> json) {
    return SystemParameterRecordModel(
      id: json['id'] as int,
      clave: json['clave'] as String,
      valor: json['valor'] as String? ?? '',
      descripcion: json['descripcion'] as String?,
      tipoDato: json['tipoDato'] as String? ?? 'texto',
      editable: json['editable'] as bool? ?? false,
      actualizadoEn: json['actualizadoEn'] == null
          ? null
          : DateTime.tryParse(json['actualizadoEn'] as String),
    );
  }
}
