import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/features/finance/pricing/data/datasources/finanzas_pricing_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/finance/pricing/domain/entities/finanzas_report_records.dart';
import 'package:erp_curtiembre_fronted/features/finance/pricing/domain/entities/precio_sugerido_record.dart';
import 'package:erp_curtiembre_fronted/features/finance/pricing/domain/entities/rentabilidad_orden_record.dart';
import 'package:erp_curtiembre_fronted/features/finance/pricing/domain/repositories/finanzas_pricing_repository.dart';
import 'package:talker_flutter/talker_flutter.dart';

class FinanzasPricingRepositoryImpl implements FinanzasPricingRepository {
  FinanzasPricingRepositoryImpl(this._remoteDataSource, this._talker);

  final FinanzasPricingRemoteDataSource _remoteDataSource;
  final Talker _talker;

  @override
  Future<PrecioSugeridoRecord> getPrecioSugerido(int ordenProduccionId) async {
    _talker.repository(
      'Consultando precio sugerido para la orden $ordenProduccionId.',
    );
    final item = await _remoteDataSource.getPrecioSugerido(ordenProduccionId);
    _talker.repository(
      'Precio sugerido de la orden $ordenProduccionId obtenido correctamente.',
    );
    return item.toEntity();
  }

  @override
  Future<PrecioSugeridoRecord> calculatePrecioSugerido({
    required int ordenProduccionId,
    required double margenPorcentaje,
  }) async {
    _talker.repository(
      'Calculando precio sugerido para la orden $ordenProduccionId con margenPorcentaje=$margenPorcentaje.',
      logLevel: LogLevel.warning,
    );
    final item = await _remoteDataSource.calculatePrecioSugerido(
      ordenProduccionId: ordenProduccionId,
      margenPorcentaje: margenPorcentaje,
    );
    _talker.repository(
      'Precio sugerido calculado correctamente para la orden $ordenProduccionId.',
      logLevel: LogLevel.warning,
    );
    return item.toEntity();
  }

  @override
  Future<RentabilidadOrdenRecord> getRentabilidad(int ordenProduccionId) async {
    _talker.repository(
      'Consultando rentabilidad para la orden $ordenProduccionId.',
    );
    final item = await _remoteDataSource.getRentabilidad(ordenProduccionId);
    _talker.repository(
      'Rentabilidad de la orden $ordenProduccionId obtenida correctamente.',
    );
    return item.toEntity();
  }

  @override
  Future<RentabilidadOrdenRecord> calculateRentabilidad({
    required int ordenProduccionId,
    required double precioVenta,
  }) async {
    _talker.repository(
      'Calculando rentabilidad para la orden $ordenProduccionId con precioVenta=$precioVenta.',
      logLevel: LogLevel.warning,
    );
    final item = await _remoteDataSource.calculateRentabilidad(
      ordenProduccionId: ordenProduccionId,
      precioVenta: precioVenta,
    );
    _talker.repository(
      'Rentabilidad calculada correctamente para la orden $ordenProduccionId.',
      logLevel: LogLevel.warning,
    );
    return item.toEntity();
  }

  @override
  Future<List<ReporteCostoOrdenRecord>> listReporteCostoOrden() async {
    _talker.repository('Consultando reporte de costo por orden.');
    final items = await _remoteDataSource.listReporteCostoOrden();
    _talker.repository(
      'Se obtuvieron ${items.length} registros del reporte de costo por orden.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<List<ReporteCostoProcesoRecord>> listReporteCostoProceso() async {
    _talker.repository('Consultando reporte de costo por proceso.');
    final items = await _remoteDataSource.listReporteCostoProceso();
    _talker.repository(
      'Se obtuvieron ${items.length} registros del reporte de costo por proceso.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<List<ReporteCostoClienteRecord>> listReporteCostoCliente() async {
    _talker.repository('Consultando reporte de costo por cliente.');
    final items = await _remoteDataSource.listReporteCostoCliente();
    _talker.repository(
      'Se obtuvieron ${items.length} registros del reporte de costo por cliente.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<List<ReporteIndirectoPeriodoRecord>>
  listReporteIndirectosPeriodo() async {
    _talker.repository('Consultando reporte de indirectos por periodo.');
    final items = await _remoteDataSource.listReporteIndirectosPeriodo();
    _talker.repository(
      'Se obtuvieron ${items.length} registros del reporte de indirectos por periodo.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<List<ReporteRentabilidadRecord>> listReporteRentabilidad() async {
    _talker.repository('Consultando reporte de rentabilidad.');
    final items = await _remoteDataSource.listReporteRentabilidad();
    _talker.repository(
      'Se obtuvieron ${items.length} registros del reporte de rentabilidad.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<List<ReportePrecioSugeridoRecord>> listReportePrecioSugerido() async {
    _talker.repository('Consultando reporte de precio sugerido.');
    final items = await _remoteDataSource.listReportePrecioSugerido();
    _talker.repository(
      'Se obtuvieron ${items.length} registros del reporte de precio sugerido.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }
}
