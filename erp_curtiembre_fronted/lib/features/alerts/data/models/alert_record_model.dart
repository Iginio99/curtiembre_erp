import 'package:erp_curtiembre_fronted/features/alerts/domain/entities/alert_record.dart';

class AlertRecordModel extends AlertRecord {
  const AlertRecordModel({
    required super.id,
    required super.tipoAlerta,
    required super.titulo,
    required super.mensaje,
    required super.severidad,
    required super.estado,
    required super.moduloOrigen,
    required super.entidadOrigen,
    required super.entidadOrigenId,
    required super.generadaEn,
  });

  factory AlertRecordModel.fromJson(Map<String, dynamic> json) {
    return AlertRecordModel(
      id: (json['id'] as num).toInt(),
      tipoAlerta: json['tipoAlerta'] as String,
      titulo: json['titulo'] as String,
      mensaje: json['mensaje'] as String,
      severidad: json['severidad'] as String,
      estado: json['estado'] as String,
      moduloOrigen: json['moduloOrigen'] as String,
      entidadOrigen: json['entidadOrigen'] as String?,
      entidadOrigenId: (json['entidadOrigenId'] as num?)?.toInt(),
      generadaEn: DateTime.parse(json['generadaEn'] as String),
    );
  }
}

class AlertDetailModel extends AlertDetail {
  const AlertDetailModel({
    required super.id,
    required super.tipoAlerta,
    required super.titulo,
    required super.mensaje,
    required super.severidad,
    required super.estado,
    required super.moduloOrigen,
    required super.entidadOrigen,
    required super.entidadOrigenId,
    required super.generadaEn,
    required super.leidaEn,
    required super.cerradaEn,
  });

  factory AlertDetailModel.fromJson(Map<String, dynamic> json) {
    return AlertDetailModel(
      id: (json['id'] as num).toInt(),
      tipoAlerta: json['tipoAlerta'] as String,
      titulo: json['titulo'] as String,
      mensaje: json['mensaje'] as String,
      severidad: json['severidad'] as String,
      estado: json['estado'] as String,
      moduloOrigen: json['moduloOrigen'] as String,
      entidadOrigen: json['entidadOrigen'] as String?,
      entidadOrigenId: (json['entidadOrigenId'] as num?)?.toInt(),
      generadaEn: DateTime.parse(json['generadaEn'] as String),
      leidaEn: json['leidaEn'] == null ? null : DateTime.parse(json['leidaEn'] as String),
      cerradaEn: json['cerradaEn'] == null ? null : DateTime.parse(json['cerradaEn'] as String),
    );
  }
}

class AlertHistoryItemModel extends AlertHistoryItem {
  const AlertHistoryItemModel({
    required super.id,
    required super.estadoAnterior,
    required super.estadoNuevo,
    required super.comentario,
    required super.cambiadoPorUsuarioId,
    required super.cambiadoPorNombre,
    required super.cambiadoEn,
  });

  factory AlertHistoryItemModel.fromJson(Map<String, dynamic> json) {
    return AlertHistoryItemModel(
      id: (json['id'] as num).toInt(),
      estadoAnterior: json['estadoAnterior'] as String?,
      estadoNuevo: json['estadoNuevo'] as String,
      comentario: json['comentario'] as String?,
      cambiadoPorUsuarioId: (json['cambiadoPorUsuarioId'] as num?)?.toInt(),
      cambiadoPorNombre: json['cambiadoPorNombre'] as String?,
      cambiadoEn: DateTime.parse(json['cambiadoEn'] as String),
    );
  }
}

class AlertsSummaryModel extends AlertsSummary {
  const AlertsSummaryModel({
    required super.totalPendientes,
    required super.totalLeidas,
    required super.totalAlta,
    required super.totalMedia,
    required super.totalBaja,
    required super.recientes,
  });

  factory AlertsSummaryModel.fromJson(Map<String, dynamic> json) {
    final recientes = (json['recientes'] as List<dynamic>? ?? const [])
        .map((item) => AlertRecordModel.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);

    return AlertsSummaryModel(
      totalPendientes: (json['totalPendientes'] as num?)?.toInt() ?? 0,
      totalLeidas: (json['totalLeidas'] as num?)?.toInt() ?? 0,
      totalAlta: (json['totalAlta'] as num?)?.toInt() ?? 0,
      totalMedia: (json['totalMedia'] as num?)?.toInt() ?? 0,
      totalBaja: (json['totalBaja'] as num?)?.toInt() ?? 0,
      recientes: recientes,
    );
  }
}
