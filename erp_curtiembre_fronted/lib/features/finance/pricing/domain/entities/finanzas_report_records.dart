import 'package:equatable/equatable.dart';

class ReporteCostoOrdenRecord extends Equatable {
  const ReporteCostoOrdenRecord({
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

  @override
  List<Object?> get props => [
        ordenProduccionId,
        ordenProduccionCodigo,
        clienteRazonSocial,
        estadoCosto,
        costoTotal,
        costoPorPiel,
        calculadoEn,
      ];
}

class ReporteCostoProcesoRecord extends Equatable {
  const ReporteCostoProcesoRecord({
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

  @override
  List<Object?> get props => [
        ordenProduccionId,
        ordenProduccionCodigo,
        procesoCodigo,
        procesoNombre,
        costoInsumos,
        costoManoObra,
        costoTotal,
        calculadoEn,
      ];
}

class ReporteCostoClienteRecord extends Equatable {
  const ReporteCostoClienteRecord({
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

  @override
  List<Object?> get props => [
        clienteId,
        clienteRazonSocial,
        ordenesCosteadas,
        costoTotal,
        costoPromedioOrden,
      ];
}

class ReporteIndirectoPeriodoRecord extends Equatable {
  const ReporteIndirectoPeriodoRecord({
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

  String get periodoCodigo => '$anio-${mes.toString().padLeft(2, '0')}';

  @override
  List<Object?> get props => [
        periodoCostoId,
        anio,
        mes,
        estado,
        totalIndirectos,
        totalRegistros,
      ];
}

class ReporteRentabilidadRecord extends Equatable {
  const ReporteRentabilidadRecord({
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

  @override
  List<Object?> get props => [
        ordenProduccionId,
        ordenProduccionCodigo,
        clienteRazonSocial,
        precioVenta,
        costoTotal,
        utilidad,
        margenPorcentaje,
        calculadoEn,
      ];
}

class ReportePrecioSugeridoRecord extends Equatable {
  const ReportePrecioSugeridoRecord({
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

  @override
  List<Object?> get props => [
        ordenProduccionId,
        ordenProduccionCodigo,
        clienteRazonSocial,
        costoBaseSinIgv,
        margenPorcentaje,
        precioSugeridoSinIgv,
        igvPorcentaje,
        precioSugeridoConIgv,
        calculadoEn,
      ];
}

