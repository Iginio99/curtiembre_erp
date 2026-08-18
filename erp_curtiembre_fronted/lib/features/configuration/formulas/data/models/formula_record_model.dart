import 'package:erp_curtiembre_fronted/features/configuration/formulas/domain/entities/formula_record.dart';

class FormulaVersionSummaryModel {
  const FormulaVersionSummaryModel({
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

  factory FormulaVersionSummaryModel.fromJson(Map<String, dynamic> json) {
    return FormulaVersionSummaryModel(
      id: (json['id'] as num).toInt(),
      numeroVersion: (json['numeroVersion'] as num).toInt(),
      fechaInicioVigencia: DateTime.parse(json['fechaInicioVigencia'] as String),
      fechaFinVigencia: json['fechaFinVigencia'] == null
          ? null
          : DateTime.parse(json['fechaFinVigencia'] as String),
      vigente: json['vigente'] as bool,
    );
  }

  FormulaVersionSummary toEntity() {
    return FormulaVersionSummary(
      id: id,
      numeroVersion: numeroVersion,
      fechaInicioVigencia: fechaInicioVigencia,
      fechaFinVigencia: fechaFinVigencia,
      vigente: vigente,
    );
  }
}

class FormulaDetailRecordModel {
  const FormulaDetailRecordModel({
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

  factory FormulaDetailRecordModel.fromJson(Map<String, dynamic> json) {
    return FormulaDetailRecordModel(
      id: (json['id'] as num).toInt(),
      formulaVersionId: (json['formulaVersionId'] as num).toInt(),
      insumoId: (json['insumoId'] as num).toInt(),
      insumoCodigo: json['insumoCodigo'] as String,
      insumoNombre: json['insumoNombre'] as String,
      porcentaje: (json['porcentaje'] as num).toDouble(),
      observacion: json['observacion'] as String?,
      activo: json['activo'] as bool,
    );
  }

  FormulaDetailRecord toEntity() {
    return FormulaDetailRecord(
      id: id,
      formulaVersionId: formulaVersionId,
      insumoId: insumoId,
      insumoCodigo: insumoCodigo,
      insumoNombre: insumoNombre,
      porcentaje: porcentaje,
      observacion: observacion,
      activo: activo,
    );
  }
}

class FormulaVersionRecordModel {
  const FormulaVersionRecordModel({
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
  final List<FormulaDetailRecordModel> detalles;

  factory FormulaVersionRecordModel.fromJson(Map<String, dynamic> json) {
    return FormulaVersionRecordModel(
      id: (json['id'] as num).toInt(),
      formulaId: (json['formulaId'] as num).toInt(),
      formulaCodigo: json['formulaCodigo'] as String,
      formulaNombre: json['formulaNombre'] as String,
      numeroVersion: (json['numeroVersion'] as num).toInt(),
      fechaInicioVigencia: DateTime.parse(json['fechaInicioVigencia'] as String),
      fechaFinVigencia: json['fechaFinVigencia'] == null
          ? null
          : DateTime.parse(json['fechaFinVigencia'] as String),
      vigente: json['vigente'] as bool,
      observacion: json['observacion'] as String?,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      creadoPorUsuarioId: (json['creadoPorUsuarioId'] as num?)?.toInt(),
      detallesActivos: (json['detallesActivos'] as num?)?.toInt() ?? 0,
      detalles: (json['detalles'] as List<dynamic>? ?? const [])
          .map((item) => FormulaDetailRecordModel.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  FormulaVersionRecord toEntity() {
    return FormulaVersionRecord(
      id: id,
      formulaId: formulaId,
      formulaCodigo: formulaCodigo,
      formulaNombre: formulaNombre,
      numeroVersion: numeroVersion,
      fechaInicioVigencia: fechaInicioVigencia,
      fechaFinVigencia: fechaFinVigencia,
      vigente: vigente,
      observacion: observacion,
      creadoEn: creadoEn,
      creadoPorUsuarioId: creadoPorUsuarioId,
      detallesActivos: detallesActivos,
      detalles: detalles.map((item) => item.toEntity()).toList(growable: false),
    );
  }
}

class FormulaRecordModel {
  const FormulaRecordModel({
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
  final FormulaVersionSummaryModel? versionVigente;

  factory FormulaRecordModel.fromJson(Map<String, dynamic> json) {
    return FormulaRecordModel(
      id: (json['id'] as num).toInt(),
      codigo: json['codigo'] as String,
      nombre: json['nombre'] as String,
      procesoProductivoId: (json['procesoProductivoId'] as num).toInt(),
      procesoProductivoCodigo: json['procesoProductivoCodigo'] as String,
      procesoProductivoNombre: json['procesoProductivoNombre'] as String,
      descripcion: json['descripcion'] as String?,
      activo: json['activo'] as bool,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      creadoPorUsuarioId: (json['creadoPorUsuarioId'] as num?)?.toInt(),
      versionVigente: json['versionVigente'] == null
          ? null
          : FormulaVersionSummaryModel.fromJson(
              json['versionVigente'] as Map<String, dynamic>,
            ),
    );
  }

  FormulaRecord toEntity() {
    return FormulaRecord(
      id: id,
      codigo: codigo,
      nombre: nombre,
      procesoProductivoId: procesoProductivoId,
      procesoProductivoCodigo: procesoProductivoCodigo,
      procesoProductivoNombre: procesoProductivoNombre,
      descripcion: descripcion,
      activo: activo,
      creadoEn: creadoEn,
      creadoPorUsuarioId: creadoPorUsuarioId,
      versionVigente: versionVigente?.toEntity(),
    );
  }
}

class ProcesoProductivoOptionModel {
  const ProcesoProductivoOptionModel({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.ordenSecuencia,
  });

  final int id;
  final String codigo;
  final String nombre;
  final int ordenSecuencia;

  factory ProcesoProductivoOptionModel.fromJson(Map<String, dynamic> json) {
    return ProcesoProductivoOptionModel(
      id: (json['id'] as num).toInt(),
      codigo: json['codigo'] as String,
      nombre: json['nombre'] as String,
      ordenSecuencia: (json['ordenSecuencia'] as num).toInt(),
    );
  }

  ProcesoProductivoOption toEntity() {
    return ProcesoProductivoOption(
      id: id,
      codigo: codigo,
      nombre: nombre,
      ordenSecuencia: ordenSecuencia,
    );
  }
}
