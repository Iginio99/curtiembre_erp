import 'package:equatable/equatable.dart';

class FormulaVersionSummary extends Equatable {
  const FormulaVersionSummary({
    required this.id,
    required this.numeroVersion,
    required this.fechaInicioVigencia,
    this.fechaFinVigencia,
    required this.vigente,
  });

  final int id;
  final int numeroVersion;
  final DateTime fechaInicioVigencia;
  final DateTime? fechaFinVigencia;
  final bool vigente;

  @override
  List<Object?> get props => [
        id,
        numeroVersion,
        fechaInicioVigencia,
        fechaFinVigencia,
        vigente,
      ];
}

class FormulaDetailRecord extends Equatable {
  const FormulaDetailRecord({
    required this.id,
    required this.formulaVersionId,
    required this.insumoId,
    required this.insumoCodigo,
    required this.insumoNombre,
    required this.porcentaje,
    this.observacion,
    required this.activo,
  });

  final int id;
  final int formulaVersionId;
  final int insumoId;
  final String insumoCodigo;
  final String insumoNombre;
  final double porcentaje;
  final String? observacion;
  final bool activo;

  String get displayName => '$insumoCodigo · $insumoNombre';

  @override
  List<Object?> get props => [
        id,
        formulaVersionId,
        insumoId,
        insumoCodigo,
        insumoNombre,
        porcentaje,
        observacion,
        activo,
      ];
}

class FormulaVersionRecord extends Equatable {
  const FormulaVersionRecord({
    required this.id,
    required this.formulaId,
    required this.formulaCodigo,
    required this.formulaNombre,
    required this.numeroVersion,
    required this.fechaInicioVigencia,
    this.fechaFinVigencia,
    required this.vigente,
    this.observacion,
    required this.creadoEn,
    this.creadoPorUsuarioId,
    this.detallesActivos = 0,
    this.detalles = const [],
  });

  final int id;
  final int formulaId;
  final String formulaCodigo;
  final String formulaNombre;
  final int numeroVersion;
  final DateTime fechaInicioVigencia;
  final DateTime? fechaFinVigencia;
  final bool vigente;
  final String? observacion;
  final DateTime creadoEn;
  final int? creadoPorUsuarioId;
  final int detallesActivos;
  final List<FormulaDetailRecord> detalles;

  bool get hasDetails => detalles.isNotEmpty || detallesActivos > 0;

  @override
  List<Object?> get props => [
        id,
        formulaId,
        formulaCodigo,
        formulaNombre,
        numeroVersion,
        fechaInicioVigencia,
        fechaFinVigencia,
        vigente,
        observacion,
        creadoEn,
        creadoPorUsuarioId,
        detallesActivos,
        detalles,
      ];
}

class FormulaRecord extends Equatable {
  const FormulaRecord({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.procesoProductivoId,
    required this.procesoProductivoCodigo,
    required this.procesoProductivoNombre,
    this.descripcion,
    required this.activo,
    required this.creadoEn,
    this.creadoPorUsuarioId,
    this.versionVigente,
  });

  final int id;
  final String codigo;
  final String nombre;
  final int procesoProductivoId;
  final String procesoProductivoCodigo;
  final String procesoProductivoNombre;
  final String? descripcion;
  final bool activo;
  final DateTime creadoEn;
  final int? creadoPorUsuarioId;
  final FormulaVersionSummary? versionVigente;

  String get processLabel => '$procesoProductivoCodigo · $procesoProductivoNombre';

  @override
  List<Object?> get props => [
        id,
        codigo,
        nombre,
        procesoProductivoId,
        procesoProductivoCodigo,
        procesoProductivoNombre,
        descripcion,
        activo,
        creadoEn,
        creadoPorUsuarioId,
        versionVigente,
      ];
}

class ProcesoProductivoOption extends Equatable {
  const ProcesoProductivoOption({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.ordenSecuencia,
  });

  final int id;
  final String codigo;
  final String nombre;
  final int ordenSecuencia;

  String get displayName => '$codigo · $nombre';

  @override
  List<Object?> get props => [id, codigo, nombre, ordenSecuencia];
}
