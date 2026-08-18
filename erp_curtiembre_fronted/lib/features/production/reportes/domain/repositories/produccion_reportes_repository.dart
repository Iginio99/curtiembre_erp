import 'package:erp_curtiembre_fronted/features/production/reportes/domain/entities/consumo_proceso_reporte_item.dart';
import 'package:erp_curtiembre_fronted/features/production/reportes/domain/entities/costo_orden_reporte_item.dart';
import 'package:erp_curtiembre_fronted/features/production/reportes/domain/entities/costo_proceso_reporte_item.dart';
import 'package:erp_curtiembre_fronted/features/production/reportes/domain/entities/merma_reporte_item.dart';
import 'package:erp_curtiembre_fronted/features/production/reportes/domain/entities/orden_activa_reporte_item.dart';
import 'package:erp_curtiembre_fronted/features/production/reportes/domain/entities/orden_cliente_reporte_item.dart';
import 'package:erp_curtiembre_fronted/features/production/reportes/domain/entities/tiempo_proceso_reporte_item.dart';

abstract class ProduccionReportesRepository {
  Future<List<OrdenActivaReporteItem>> listOrdenesActivas();

  Future<List<OrdenClienteReporteItem>> listOrdenesPorCliente({
    int? clienteId,
    String? estado,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  });

  Future<List<ConsumoProcesoReporteItem>> listConsumoPorProceso({
    int? ordenProduccionId,
    int? ordenProcesoId,
  });

  Future<List<MermaReporteItem>> listMerma({
    int? ordenProduccionId,
    int? ordenProcesoId,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  });

  Future<List<TiempoProcesoReporteItem>> listTiemposProceso({
    int? ordenProduccionId,
    int? ordenProcesoId,
    String? estado,
  });

  Future<List<CostoOrdenReporteItem>> listCostosPorOrden({
    int? ordenProduccionId,
  });

  Future<List<CostoProcesoReporteItem>> listCostosPorProceso({
    int? ordenProduccionId,
  });
}
