import 'package:equatable/equatable.dart';

class AlertRecord extends Equatable {
  const AlertRecord({
    required this.id,
    required this.tipoAlerta,
    required this.titulo,
    required this.mensaje,
    required this.severidad,
    required this.estado,
    required this.moduloOrigen,
    required this.entidadOrigen,
    required this.entidadOrigenId,
    required this.generadaEn,
  });

  final int id;
  final String tipoAlerta;
  final String titulo;
  final String mensaje;
  final String severidad;
  final String estado;
  final String moduloOrigen;
  final String? entidadOrigen;
  final int? entidadOrigenId;
  final DateTime generadaEn;

  @override
  List<Object?> get props => [
        id,
        tipoAlerta,
        titulo,
        mensaje,
        severidad,
        estado,
        moduloOrigen,
        entidadOrigen,
        entidadOrigenId,
        generadaEn,
      ];
}

class AlertDetail extends AlertRecord {
  const AlertDetail({
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
    required this.leidaEn,
    required this.cerradaEn,
  });

  final DateTime? leidaEn;
  final DateTime? cerradaEn;

  @override
  List<Object?> get props => [...super.props, leidaEn, cerradaEn];
}

class AlertHistoryItem extends Equatable {
  const AlertHistoryItem({
    required this.id,
    required this.estadoAnterior,
    required this.estadoNuevo,
    required this.comentario,
    required this.cambiadoPorUsuarioId,
    required this.cambiadoPorNombre,
    required this.cambiadoEn,
  });

  final int id;
  final String? estadoAnterior;
  final String estadoNuevo;
  final String? comentario;
  final int? cambiadoPorUsuarioId;
  final String? cambiadoPorNombre;
  final DateTime cambiadoEn;

  @override
  List<Object?> get props => [
        id,
        estadoAnterior,
        estadoNuevo,
        comentario,
        cambiadoPorUsuarioId,
        cambiadoPorNombre,
        cambiadoEn,
      ];
}

class AlertsSummary extends Equatable {
  const AlertsSummary({
    required this.totalPendientes,
    required this.totalLeidas,
    required this.totalAlta,
    required this.totalMedia,
    required this.totalBaja,
    required this.recientes,
  });

  final int totalPendientes;
  final int totalLeidas;
  final int totalAlta;
  final int totalMedia;
  final int totalBaja;
  final List<AlertRecord> recientes;

  @override
  List<Object?> get props => [
        totalPendientes,
        totalLeidas,
        totalAlta,
        totalMedia,
        totalBaja,
        recientes,
      ];
}
