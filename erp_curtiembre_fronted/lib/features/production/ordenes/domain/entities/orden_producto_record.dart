import 'package:equatable/equatable.dart';

class FormulaProduccionOption extends Equatable {
  const FormulaProduccionOption({
    required this.formulaId,
    required this.formulaCodigo,
    required this.formulaNombre,
    this.tipoProducto,
    this.color,
    required this.procesoProductivoId,
    required this.procesoCodigo,
    required this.procesoNombre,
    required this.formulaVersionId,
    required this.numeroVersion,
    this.insumos = const [],
  });
  final int formulaId, procesoProductivoId, formulaVersionId, numeroVersion;
  final String formulaCodigo, formulaNombre, procesoCodigo, procesoNombre;
  final String? tipoProducto, color;
  final List<FormulaInsumo> insumos;
  factory FormulaProduccionOption.fromJson(Map<String, dynamic> j) =>
      FormulaProduccionOption(
        formulaId: (j['formulaId'] as num).toInt(),
        formulaCodigo: j['formulaCodigo'] as String,
        formulaNombre: j['formulaNombre'] as String,
        tipoProducto: j['tipoProducto'] as String?,
        color: j['color'] as String?,
        procesoProductivoId: (j['procesoProductivoId'] as num).toInt(),
        procesoCodigo: j['procesoCodigo'] as String,
        procesoNombre: j['procesoNombre'] as String,
        formulaVersionId: (j['formulaVersionId'] as num).toInt(),
        numeroVersion: (j['numeroVersion'] as num).toInt(),
        insumos: ((j['insumos'] as List?) ?? const [])
            .map((x) => FormulaInsumo.fromJson(x as Map<String, dynamic>))
            .toList(),
      );
  @override
  List<Object?> get props => [formulaVersionId, insumos];
}

class FormulaInsumo extends Equatable {
  const FormulaInsumo({
    required this.insumoId,
    required this.insumoCodigo,
    required this.insumoNombre,
    required this.porcentaje,
    this.observacion,
  });
  final int insumoId;
  final String insumoCodigo, insumoNombre;
  final double porcentaje;
  final String? observacion;
  factory FormulaInsumo.fromJson(Map<String, dynamic> j) => FormulaInsumo(
    insumoId: (j['insumoId'] as num).toInt(),
    insumoCodigo: j['insumoCodigo'] as String,
    insumoNombre: j['insumoNombre'] as String,
    porcentaje: (j['porcentaje'] as num).toDouble(),
    observacion: j['observacion'] as String?,
  );
  @override
  List<Object?> get props => [insumoId, porcentaje, observacion];
}

class OrdenProductoFormulaRecord extends Equatable {
  const OrdenProductoFormulaRecord({
    required this.id,
    required this.procesoProductivoId,
    required this.procesoCodigo,
    required this.procesoNombre,
    required this.formulaVersionId,
    required this.formulaCodigo,
    required this.formulaNombre,
    required this.numeroVersion,
    required this.kilosBase,
    required this.costoEstimado,
  });
  final int id, procesoProductivoId, formulaVersionId, numeroVersion;
  final String procesoCodigo, procesoNombre, formulaCodigo, formulaNombre;
  final double kilosBase, costoEstimado;
  factory OrdenProductoFormulaRecord.fromJson(Map<String, dynamic> j) =>
      OrdenProductoFormulaRecord(
        id: (j['id'] as num).toInt(),
        procesoProductivoId: (j['procesoProductivoId'] as num).toInt(),
        procesoCodigo: j['procesoCodigo'] as String,
        procesoNombre: j['procesoNombre'] as String,
        formulaVersionId: (j['formulaVersionId'] as num).toInt(),
        formulaCodigo: j['formulaCodigo'] as String,
        formulaNombre: j['formulaNombre'] as String,
        numeroVersion: (j['numeroVersion'] as num).toInt(),
        kilosBase: (j['kilosBase'] as num).toDouble(),
        costoEstimado: (j['costoEstimado'] as num).toDouble(),
      );
  @override
  List<Object?> get props => [id, formulaVersionId, kilosBase, costoEstimado];
}

class OrdenProductoRecord extends Equatable {
  const OrdenProductoRecord({
    required this.id,
    required this.ordenProduccionId,
    required this.codigo,
    required this.nombre,
    this.color,
    required this.cantidadPieles,
    required this.cantidadLados,
    required this.kilosRecurtido,
    required this.kilosAcabado,
    this.observacion,
    required this.costoEstimado,
    required this.costoPorLado,
    required this.formulas,
  });
  final int id, ordenProduccionId;
  final String codigo, nombre;
  final String? color, observacion;
  final double cantidadPieles,
      cantidadLados,
      kilosRecurtido,
      kilosAcabado,
      costoEstimado,
      costoPorLado;
  final List<OrdenProductoFormulaRecord> formulas;
  factory OrdenProductoRecord.fromJson(Map<String, dynamic> j) =>
      OrdenProductoRecord(
        id: (j['id'] as num).toInt(),
        ordenProduccionId: (j['ordenProduccionId'] as num).toInt(),
        codigo: j['codigo'] as String,
        nombre: j['nombre'] as String,
        color: j['color'] as String?,
        cantidadPieles: (j['cantidadPieles'] as num).toDouble(),
        cantidadLados: (j['cantidadLados'] as num).toDouble(),
        kilosRecurtido: (j['kilosRecurtido'] as num).toDouble(),
        kilosAcabado: (j['kilosAcabado'] as num).toDouble(),
        observacion: j['observacion'] as String?,
        costoEstimado: (j['costoEstimado'] as num).toDouble(),
        costoPorLado: (j['costoPorLado'] as num).toDouble(),
        formulas: ((j['formulas'] as List?) ?? const [])
            .map(
              (x) => OrdenProductoFormulaRecord.fromJson(
                x as Map<String, dynamic>,
              ),
            )
            .toList(),
      );
  @override
  List<Object?> get props => [
    id,
    codigo,
    nombre,
    color,
    cantidadPieles,
    cantidadLados,
    kilosRecurtido,
    kilosAcabado,
    costoEstimado,
    costoPorLado,
    formulas,
  ];
}

class OrdenProductoInput {
  const OrdenProductoInput({
    required this.codigo,
    required this.nombre,
    this.color,
    required this.cantidadPieles,
    required this.cantidadLados,
    required this.kilosRecurtido,
    required this.kilosAcabado,
    this.observacion,
    required this.formulas,
  });
  final String codigo, nombre;
  final String? color, observacion;
  final double cantidadPieles, cantidadLados, kilosRecurtido, kilosAcabado;
  final List<Map<String, dynamic>> formulas;
  Map<String, dynamic> toJson() => {
    'codigo': codigo,
    'nombre': nombre,
    'color': color,
    'cantidadPieles': cantidadPieles,
    'cantidadLados': cantidadLados,
    'kilosRecurtido': kilosRecurtido,
    'kilosAcabado': kilosAcabado,
    'observacion': observacion,
    'formulas': formulas,
  };
}
