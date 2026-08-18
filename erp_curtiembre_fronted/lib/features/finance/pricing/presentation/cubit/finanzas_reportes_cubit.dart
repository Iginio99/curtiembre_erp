import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/finance/pricing/domain/repositories/finanzas_pricing_repository.dart';
import 'package:erp_curtiembre_fronted/features/finance/pricing/presentation/cubit/finanzas_reportes_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';

class FinanzasReportesCubit extends Cubit<FinanzasReportesState> {
  FinanzasReportesCubit(this._repository, this._talker)
    : super(const FinanzasReportesState.loading());

  final FinanzasPricingRepository _repository;
  final Talker _talker;

  Future<void> initialize() async {
    _talker.cubit('Inicializando modulo de reportes financieros.');
    emit(const FinanzasReportesState.loading());
    try {
      final costoOrdenFuture = _repository.listReporteCostoOrden();
      final costoProcesoFuture = _repository.listReporteCostoProceso();
      final costoClienteFuture = _repository.listReporteCostoCliente();
      final indirectosFuture = _repository.listReporteIndirectosPeriodo();
      final rentabilidadFuture = _repository.listReporteRentabilidad();
      final precioFuture = _repository.listReportePrecioSugerido();

      final costoOrden = await costoOrdenFuture;
      final costoProceso = await costoProcesoFuture;
      final costoCliente = await costoClienteFuture;
      final indirectos = await indirectosFuture;
      final rentabilidad = await rentabilidadFuture;
      final precio = await precioFuture;
      _talker.cubit(
        'Reportes financieros cargados: costoOrden=${costoOrden.length}, costoProceso=${costoProceso.length}, costoCliente=${costoCliente.length}, indirectos=${indirectos.length}, rentabilidad=${rentabilidad.length}, precioSugerido=${precio.length}.',
        logLevel: LogLevel.debug,
      );

      emit(
        state.copyWith(
          status: FinanzasReportesStatus.success,
          costoOrden: costoOrden,
          costoProceso: costoProceso,
          costoCliente: costoCliente,
          indirectosPeriodo: indirectos,
          rentabilidad: rentabilidad,
          precioSugerido: precio,
          clearError: true,
        ),
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudieron cargar los reportes financieros: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(
        state.copyWith(
          status: FinanzasReportesStatus.error,
          errorMessage: exception.message,
        ),
      );
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al cargar los reportes financieros.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          status: FinanzasReportesStatus.error,
          errorMessage: 'No pudimos cargar los reportes financieros.',
        ),
      );
    }
  }
}
