import 'package:erp_curtiembre_fronted/features/inventory/ajustes/domain/entities/ajuste_record.dart';

class AjusteRecordModel {
  const AjusteRecordModel({
    required this.id,
    required this.codigo,
    required this.tipoAjuste,
    required this.fechaAjuste,
    required this.motivo,
    required this.usuarioResponsableId,
    required this.totalItems,
    required this.cantidadTotal,
    required this.montoTotal,
    this.observacion,
  });

  final int id;
  final String codigo;
  final String tipoAjuste;
  final DateTime fechaAjuste;
  final String motivo;
  final String? observacion;
  final int usuarioResponsableId;
  final int totalItems;
  final double cantidadTotal;
  final double montoTotal;

  factory AjusteRecordModel.fromJson(Map<String, dynamic> json) {
    return AjusteRecordModel(
      id: (json['id'] as num).toInt(),
      codigo: json['codigo'] as String,
      tipoAjuste: json['tipoAjuste'] as String,
      fechaAjuste: DateTime.parse(json['fechaAjuste'] as String),
      motivo: json['motivo'] as String,
      observacion: json['observacion'] as String?,
      usuarioResponsableId: (json['usuarioResponsableId'] as num).toInt(),
      totalItems: (json['totalItems'] as num).toInt(),
      cantidadTotal: (json['cantidadTotal'] as num).toDouble(),
      montoTotal: (json['montoTotal'] as num).toDouble(),
    );
  }

  AjusteRecord toEntity() {
    return AjusteRecord(
      id: id,
      codigo: codigo,
      tipoAjuste: tipoAjuste,
      fechaAjuste: fechaAjuste,
      motivo: motivo,
      observacion: observacion,
      usuarioResponsableId: usuarioResponsableId,
      totalItems: totalItems,
      cantidadTotal: cantidadTotal,
      montoTotal: montoTotal,
    );
  }
}
