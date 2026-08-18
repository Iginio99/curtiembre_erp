import 'package:erp_curtiembre_fronted/features/inventory/fisico/domain/entities/inventario_fisico_record.dart';

class InventarioFisicoRecordModel {
  const InventarioFisicoRecordModel({
    required this.id,
    required this.codigo,
    required this.fechaInicio,
    required this.fechaCierre,
    required this.periodoAnio,
    required this.periodoMes,
    required this.estado,
    required this.ejecutadoPorUsuarioId,
    required this.observacion,
    required this.totalItems,
    required this.itemsConDiferencia,
    required this.totalDiferenciaAbsoluta,
  });

  factory InventarioFisicoRecordModel.fromJson(Map<String, dynamic> json) {
    return InventarioFisicoRecordModel(
      id: (json['id'] as num).toInt(),
      codigo: json['codigo'] as String,
      fechaInicio: DateTime.parse(json['fechaInicio'] as String),
      fechaCierre: json['fechaCierre'] == null
          ? null
          : DateTime.parse(json['fechaCierre'] as String),
      periodoAnio: (json['periodoAnio'] as num).toInt(),
      periodoMes: (json['periodoMes'] as num).toInt(),
      estado: json['estado'] as String,
      ejecutadoPorUsuarioId: (json['ejecutadoPorUsuarioId'] as num).toInt(),
      observacion: json['observacion'] as String?,
      totalItems: (json['totalItems'] as num).toInt(),
      itemsConDiferencia: (json['itemsConDiferencia'] as num).toInt(),
      totalDiferenciaAbsoluta:
          (json['totalDiferenciaAbsoluta'] as num).toDouble(),
    );
  }

  final int id;
  final String codigo;
  final DateTime fechaInicio;
  final DateTime? fechaCierre;
  final int periodoAnio;
  final int periodoMes;
  final String estado;
  final int ejecutadoPorUsuarioId;
  final String? observacion;
  final int totalItems;
  final int itemsConDiferencia;
  final double totalDiferenciaAbsoluta;

  InventarioFisicoRecord toEntity() {
    return InventarioFisicoRecord(
      id: id,
      codigo: codigo,
      fechaInicio: fechaInicio,
      fechaCierre: fechaCierre,
      periodoAnio: periodoAnio,
      periodoMes: periodoMes,
      estado: estado,
      ejecutadoPorUsuarioId: ejecutadoPorUsuarioId,
      observacion: observacion,
      totalItems: totalItems,
      itemsConDiferencia: itemsConDiferencia,
      totalDiferenciaAbsoluta: totalDiferenciaAbsoluta,
    );
  }
}
