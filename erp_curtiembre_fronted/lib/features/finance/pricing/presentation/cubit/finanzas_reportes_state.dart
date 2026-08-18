import 'package:equatable/equatable.dart';
import 'package:erp_curtiembre_fronted/features/finance/pricing/domain/entities/finanzas_report_records.dart';

enum FinanzasReportesStatus { loading, success, error }

class FinanzasReportesState extends Equatable {
  const FinanzasReportesState({
    required this.status,
    this.costoOrden = const [],
    this.costoProceso = const [],
    this.costoCliente = const [],
    this.indirectosPeriodo = const [],
    this.rentabilidad = const [],
    this.precioSugerido = const [],
    this.errorMessage,
  });

  const FinanzasReportesState.loading() : this(status: FinanzasReportesStatus.loading);

  final FinanzasReportesStatus status;
  final List<ReporteCostoOrdenRecord> costoOrden;
  final List<ReporteCostoProcesoRecord> costoProceso;
  final List<ReporteCostoClienteRecord> costoCliente;
  final List<ReporteIndirectoPeriodoRecord> indirectosPeriodo;
  final List<ReporteRentabilidadRecord> rentabilidad;
  final List<ReportePrecioSugeridoRecord> precioSugerido;
  final String? errorMessage;

  FinanzasReportesState copyWith({
    FinanzasReportesStatus? status,
    List<ReporteCostoOrdenRecord>? costoOrden,
    List<ReporteCostoProcesoRecord>? costoProceso,
    List<ReporteCostoClienteRecord>? costoCliente,
    List<ReporteIndirectoPeriodoRecord>? indirectosPeriodo,
    List<ReporteRentabilidadRecord>? rentabilidad,
    List<ReportePrecioSugeridoRecord>? precioSugerido,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FinanzasReportesState(
      status: status ?? this.status,
      costoOrden: costoOrden ?? this.costoOrden,
      costoProceso: costoProceso ?? this.costoProceso,
      costoCliente: costoCliente ?? this.costoCliente,
      indirectosPeriodo: indirectosPeriodo ?? this.indirectosPeriodo,
      rentabilidad: rentabilidad ?? this.rentabilidad,
      precioSugerido: precioSugerido ?? this.precioSugerido,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        costoOrden,
        costoProceso,
        costoCliente,
        indirectosPeriodo,
        rentabilidad,
        precioSugerido,
        errorMessage,
      ];
}

