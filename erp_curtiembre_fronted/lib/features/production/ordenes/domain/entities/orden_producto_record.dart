import 'package:equatable/equatable.dart';

class ProductoProduccionOption extends Equatable {
  const ProductoProduccionOption({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.tipo,
    this.color,
  });
  final int id;
  final String codigo, nombre, tipo;
  final String? color;
  factory ProductoProduccionOption.fromJson(Map<String, dynamic> j) =>
      ProductoProduccionOption(
        id: (j['id'] as num).toInt(),
        codigo: j['codigo'] as String,
        nombre: j['nombre'] as String,
        tipo: j['tipo'] as String,
        color: j['color'] as String?,
      );
  @override
  List<Object?> get props => [id, codigo, nombre, tipo, color];
}

class FormulaProduccionOption extends Equatable {
  const FormulaProduccionOption({
    required this.formulaId,
    required this.formulaCodigo,
    required this.formulaNombre,
    required this.procesoProductivoId,
    required this.procesoCodigo,
    required this.procesoNombre,
    required this.formulaVersionId,
    required this.numeroVersion,
    this.insumos = const [],
  });
  final int formulaId, procesoProductivoId, formulaVersionId, numeroVersion;
  final String formulaCodigo, formulaNombre, procesoCodigo, procesoNombre;
  final List<FormulaInsumo> insumos;
  factory FormulaProduccionOption.fromJson(Map<String, dynamic> j) =>
      FormulaProduccionOption(
        formulaId: (j['formulaId'] as num).toInt(),
        formulaCodigo: j['formulaCodigo'] as String,
        formulaNombre: j['formulaNombre'] as String,
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
    required this.estadoRecurtido,
    this.inicioRecurtido,
    this.finRecurtido,
    this.responsableRecurtidoId,
    this.responsableRecurtidoNombre,
    required this.estadoAcabado,
    this.inicioAcabado,
    this.finAcabado,
    this.responsableAcabadoId,
    this.responsableAcabadoNombre,
    this.cantidadPielesTerminadas,
    this.productoTerminadoId,
    this.solicitudRecurtidoEstado,
    this.solicitudAcabadoEstado,
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
  final String estadoRecurtido, estadoAcabado;
  final DateTime? inicioRecurtido, finRecurtido, inicioAcabado, finAcabado;
  final int? responsableRecurtidoId, responsableAcabadoId;
  final String? responsableRecurtidoNombre, responsableAcabadoNombre;
  final double? cantidadPielesTerminadas;
  final int? productoTerminadoId;
  final String? solicitudRecurtidoEstado, solicitudAcabadoEstado;
  final List<OrdenProductoFormulaRecord> formulas;
  String? supplyRequestStatus(String processCode) => processCode == 'ACABADO'
      ? solicitudAcabadoEstado
      : solicitudRecurtidoEstado;
  bool hasApprovedSupplies(String processCode) =>
      supplyRequestStatus(processCode) == 'APROBADA';
  bool hasPendingSupplyRequest(String processCode) {
    final status = supplyRequestStatus(processCode);
    return status == 'SOLICITADA' ||
        status == 'PARCIAL' ||
        status == 'ENTREGANDO';
  }

  factory OrdenProductoRecord.fromJson(
    Map<String, dynamic> j,
  ) => OrdenProductoRecord(
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
    estadoRecurtido: j['estadoRecurtido'] as String? ?? 'PENDIENTE',
    inicioRecurtido: DateTime.tryParse(j['inicioRecurtido'] as String? ?? ''),
    finRecurtido: DateTime.tryParse(j['finRecurtido'] as String? ?? ''),
    responsableRecurtidoId: (j['responsableRecurtidoId'] as num?)?.toInt(),
    responsableRecurtidoNombre: j['responsableRecurtidoNombre'] as String?,
    estadoAcabado: j['estadoAcabado'] as String? ?? 'PENDIENTE',
    inicioAcabado: DateTime.tryParse(j['inicioAcabado'] as String? ?? ''),
    finAcabado: DateTime.tryParse(j['finAcabado'] as String? ?? ''),
    responsableAcabadoId: (j['responsableAcabadoId'] as num?)?.toInt(),
    responsableAcabadoNombre: j['responsableAcabadoNombre'] as String?,
    cantidadPielesTerminadas: (j['cantidadPielesTerminadas'] as num?)
        ?.toDouble(),
    productoTerminadoId: (j['productoTerminadoId'] as num?)?.toInt(),
    solicitudRecurtidoEstado: j['solicitudRecurtidoEstado'] as String?,
    solicitudAcabadoEstado: j['solicitudAcabadoEstado'] as String?,
    formulas: ((j['formulas'] as List?) ?? const [])
        .map(
          (x) => OrdenProductoFormulaRecord.fromJson(x as Map<String, dynamic>),
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
    estadoRecurtido,
    inicioRecurtido,
    finRecurtido,
    responsableRecurtidoId,
    responsableRecurtidoNombre,
    estadoAcabado,
    inicioAcabado,
    finAcabado,
    responsableAcabadoId,
    responsableAcabadoNombre,
    cantidadPielesTerminadas,
    productoTerminadoId,
    solicitudRecurtidoEstado,
    solicitudAcabadoEstado,
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
