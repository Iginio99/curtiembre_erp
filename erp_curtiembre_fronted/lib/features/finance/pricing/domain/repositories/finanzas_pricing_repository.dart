import 'package:erp_curtiembre_fronted/features/finance/pricing/domain/entities/finanzas_report_records.dart';
import 'package:erp_curtiembre_fronted/features/finance/pricing/domain/entities/precio_sugerido_record.dart';
import 'package:erp_curtiembre_fronted/features/finance/pricing/domain/entities/rentabilidad_orden_record.dart';

abstract class FinanzasPricingRepository {
  Future<PrecioSugeridoRecord> getPrecioSugerido(int ordenProduccionId);

  Future<PrecioSugeridoRecord> calculatePrecioSugerido({
    required int ordenProduccionId,
    required double margenPorcentaje,
  });

  Future<RentabilidadOrdenRecord> getRentabilidad(int ordenProduccionId);

  Future<RentabilidadOrdenRecord> calculateRentabilidad({
    required int ordenProduccionId,
    required double precioVenta,
  });

  Future<List<ReporteCostoOrdenRecord>> listReporteCostoOrden();

  Future<List<ReporteCostoProcesoRecord>> listReporteCostoProceso();

  Future<List<ReporteCostoClienteRecord>> listReporteCostoCliente();

  Future<List<ReporteIndirectoPeriodoRecord>> listReporteIndirectosPeriodo();

  Future<List<ReporteRentabilidadRecord>> listReporteRentabilidad();

  Future<List<ReportePrecioSugeridoRecord>> listReportePrecioSugerido();
}

