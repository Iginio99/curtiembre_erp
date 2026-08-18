import 'package:erp_curtiembre_fronted/features/finance/pricing/domain/entities/finanzas_report_records.dart';

class ReporteCostoOrdenRecordModel {
  const ReporteCostoOrdenRecordModel({
    required this.ordenProduccionId,
    required this.ordenProduccionCodigo,
    required this.clienteRazonSocial,
    required this.estadoCosto,
    required this.costoTotal,
    required this.calculadoEn,
    this.costoPorPiel,
  });

  final int ordenProduccionId;
  final String ordenProduccionCodigo;
  final String clienteRazonSocial;
  final String estadoCosto;
  final double costoTotal;
  final double? costoPorPiel;
  final DateTime calculadoEn;

  factory ReporteCostoOrdenRecordModel.fromJson(Map<String, dynamic> json) {
    return ReporteCostoOrdenRecordModel(
      ordenProduccionId: (json['ordenProduccionId'] as num).toInt(),
      ordenProduccionCodigo: json['ordenProduccionCodigo'] as String,
      clienteRazonSocial: json['clienteRazonSocial'] as String,
      estadoCosto: json['estadoCosto'] as String,
      costoTotal: (json['costoTotal'] as num).toDouble(),
      costoPorPiel:
          json['costoPorPiel'] == null ? null : (json['costoPorPiel'] as num).toDouble(),
      calculadoEn: DateTime.parse(json['calculadoEn'] as String),
    );
  }

  ReporteCostoOrdenRecord toEntity() {
    return ReporteCostoOrdenRecord(
      ordenProduccionId: ordenProduccionId,
      ordenProduccionCodigo: ordenProduccionCodigo,
      clienteRazonSocial: clienteRazonSocial,
      estadoCosto: estadoCosto,
      costoTotal: costoTotal,
      costoPorPiel: costoPorPiel,
      calculadoEn: calculadoEn,
    );
  }
}

class ReporteCostoProcesoRecordModel {
  const ReporteCostoProcesoRecordModel({
    required this.ordenProduccionId,
    required this.ordenProduccionCodigo,
    required this.procesoCodigo,
    required this.procesoNombre,
    required this.costoInsumos,
    required this.costoManoObra,
    required this.costoTotal,
    required this.calculadoEn,
  });

  final int ordenProduccionId;
  final String ordenProduccionCodigo;
  final String procesoCodigo;
  final String procesoNombre;
  final double costoInsumos;
  final double costoManoObra;
  final double costoTotal;
  final DateTime calculadoEn;

  factory ReporteCostoProcesoRecordModel.fromJson(Map<String, dynamic> json) {
    return ReporteCostoProcesoRecordModel(
      ordenProduccionId: (json['ordenProduccionId'] as num).toInt(),
      ordenProduccionCodigo: json['ordenProduccionCodigo'] as String,
      procesoCodigo: json['procesoCodigo'] as String,
      procesoNombre: json['procesoNombre'] as String,
      costoInsumos: (json['costoInsumos'] as num).toDouble(),
      costoManoObra: (json['costoManoObra'] as num).toDouble(),
      costoTotal: (json['costoTotal'] as num).toDouble(),
      calculadoEn: DateTime.parse(json['calculadoEn'] as String),
    );
  }

  ReporteCostoProcesoRecord toEntity() {
    return ReporteCostoProcesoRecord(
      ordenProduccionId: ordenProduccionId,
      ordenProduccionCodigo: ordenProduccionCodigo,
      procesoCodigo: procesoCodigo,
      procesoNombre: procesoNombre,
      costoInsumos: costoInsumos,
      costoManoObra: costoManoObra,
      costoTotal: costoTotal,
      calculadoEn: calculadoEn,
    );
  }
}

class ReporteCostoClienteRecordModel {
  const ReporteCostoClienteRecordModel({
    required this.clienteId,
    required this.clienteRazonSocial,
    required this.ordenesCosteadas,
    required this.costoTotal,
    required this.costoPromedioOrden,
  });

  final int clienteId;
  final String clienteRazonSocial;
  final int ordenesCosteadas;
  final double costoTotal;
  final double costoPromedioOrden;

  factory ReporteCostoClienteRecordModel.fromJson(Map<String, dynamic> json) {
    return ReporteCostoClienteRecordModel(
      clienteId: (json['clienteId'] as num).toInt(),
      clienteRazonSocial: json['clienteRazonSocial'] as String,
      ordenesCosteadas: (json['ordenesCosteadas'] as num).toInt(),
      costoTotal: (json['costoTotal'] as num).toDouble(),
      costoPromedioOrden: (json['costoPromedioOrden'] as num).toDouble(),
    );
  }

  ReporteCostoClienteRecord toEntity() {
    return ReporteCostoClienteRecord(
      clienteId: clienteId,
      clienteRazonSocial: clienteRazonSocial,
      ordenesCosteadas: ordenesCosteadas,
      costoTotal: costoTotal,
      costoPromedioOrden: costoPromedioOrden,
    );
  }
}

class ReporteIndirectoPeriodoRecordModel {
  const ReporteIndirectoPeriodoRecordModel({
    required this.periodoCostoId,
    required this.anio,
    required this.mes,
    required this.estado,
    required this.totalIndirectos,
    required this.totalRegistros,
  });

  final int periodoCostoId;
  final int anio;
  final int mes;
  final String estado;
  final double totalIndirectos;
  final int totalRegistros;

  factory ReporteIndirectoPeriodoRecordModel.fromJson(Map<String, dynamic> json) {
    return ReporteIndirectoPeriodoRecordModel(
      periodoCostoId: (json['periodoCostoId'] as num).toInt(),
      anio: (json['anio'] as num).toInt(),
      mes: (json['mes'] as num).toInt(),
      estado: json['estado'] as String,
      totalIndirectos: (json['totalIndirectos'] as num).toDouble(),
      totalRegistros: (json['totalRegistros'] as num).toInt(),
    );
  }

  ReporteIndirectoPeriodoRecord toEntity() {
    return ReporteIndirectoPeriodoRecord(
      periodoCostoId: periodoCostoId,
      anio: anio,
      mes: mes,
      estado: estado,
      totalIndirectos: totalIndirectos,
      totalRegistros: totalRegistros,
    );
  }
}

class ReporteRentabilidadRecordModel {
  const ReporteRentabilidadRecordModel({
    required this.ordenProduccionId,
    required this.ordenProduccionCodigo,
    required this.clienteRazonSocial,
    required this.precioVenta,
    required this.costoTotal,
    required this.utilidad,
    required this.calculadoEn,
    this.margenPorcentaje,
  });

  final int ordenProduccionId;
  final String ordenProduccionCodigo;
  final String clienteRazonSocial;
  final double precioVenta;
  final double costoTotal;
  final double utilidad;
  final double? margenPorcentaje;
  final DateTime calculadoEn;

  factory ReporteRentabilidadRecordModel.fromJson(Map<String, dynamic> json) {
    return ReporteRentabilidadRecordModel(
      ordenProduccionId: (json['ordenProduccionId'] as num).toInt(),
      ordenProduccionCodigo: json['ordenProduccionCodigo'] as String,
      clienteRazonSocial: json['clienteRazonSocial'] as String,
      precioVenta: (json['precioVenta'] as num).toDouble(),
      costoTotal: (json['costoTotal'] as num).toDouble(),
      utilidad: (json['utilidad'] as num).toDouble(),
      margenPorcentaje: json['margenPorcentaje'] == null
          ? null
          : (json['margenPorcentaje'] as num).toDouble(),
      calculadoEn: DateTime.parse(json['calculadoEn'] as String),
    );
  }

  ReporteRentabilidadRecord toEntity() {
    return ReporteRentabilidadRecord(
      ordenProduccionId: ordenProduccionId,
      ordenProduccionCodigo: ordenProduccionCodigo,
      clienteRazonSocial: clienteRazonSocial,
      precioVenta: precioVenta,
      costoTotal: costoTotal,
      utilidad: utilidad,
      margenPorcentaje: margenPorcentaje,
      calculadoEn: calculadoEn,
    );
  }
}

class ReportePrecioSugeridoRecordModel {
  const ReportePrecioSugeridoRecordModel({
    required this.ordenProduccionId,
    required this.ordenProduccionCodigo,
    required this.clienteRazonSocial,
    required this.costoBaseSinIgv,
    required this.margenPorcentaje,
    required this.precioSugeridoSinIgv,
    required this.igvPorcentaje,
    required this.precioSugeridoConIgv,
    required this.calculadoEn,
  });

  final int ordenProduccionId;
  final String ordenProduccionCodigo;
  final String clienteRazonSocial;
  final double costoBaseSinIgv;
  final double margenPorcentaje;
  final double precioSugeridoSinIgv;
  final double igvPorcentaje;
  final double precioSugeridoConIgv;
  final DateTime calculadoEn;

  factory ReportePrecioSugeridoRecordModel.fromJson(Map<String, dynamic> json) {
    return ReportePrecioSugeridoRecordModel(
      ordenProduccionId: (json['ordenProduccionId'] as num).toInt(),
      ordenProduccionCodigo: json['ordenProduccionCodigo'] as String,
      clienteRazonSocial: json['clienteRazonSocial'] as String,
      costoBaseSinIgv: (json['costoBaseSinIgv'] as num).toDouble(),
      margenPorcentaje: (json['margenPorcentaje'] as num).toDouble(),
      precioSugeridoSinIgv: (json['precioSugeridoSinIgv'] as num).toDouble(),
      igvPorcentaje: (json['igvPorcentaje'] as num).toDouble(),
      precioSugeridoConIgv: (json['precioSugeridoConIgv'] as num).toDouble(),
      calculadoEn: DateTime.parse(json['calculadoEn'] as String),
    );
  }

  ReportePrecioSugeridoRecord toEntity() {
    return ReportePrecioSugeridoRecord(
      ordenProduccionId: ordenProduccionId,
      ordenProduccionCodigo: ordenProduccionCodigo,
      clienteRazonSocial: clienteRazonSocial,
      costoBaseSinIgv: costoBaseSinIgv,
      margenPorcentaje: margenPorcentaje,
      precioSugeridoSinIgv: precioSugeridoSinIgv,
      igvPorcentaje: igvPorcentaje,
      precioSugeridoConIgv: precioSugeridoConIgv,
      calculadoEn: calculadoEn,
    );
  }
}

