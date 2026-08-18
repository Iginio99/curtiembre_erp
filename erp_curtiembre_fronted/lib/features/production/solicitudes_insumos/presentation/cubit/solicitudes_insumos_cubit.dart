import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/production/solicitudes_insumos/domain/repositories/solicitudes_insumos_repository.dart';
import 'package:erp_curtiembre_fronted/features/production/solicitudes_insumos/domain/entities/solicitud_insumo_detail.dart';
import 'package:erp_curtiembre_fronted/features/production/solicitudes_insumos/presentation/cubit/solicitudes_insumos_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SolicitudesInsumosCubit extends Cubit<SolicitudesInsumosState> {
  SolicitudesInsumosCubit(this._repository)
    : super(const SolicitudesInsumosState.loading());

  final SolicitudesInsumosRepository _repository;

  Future<void> load({String? estado = 'SOLICITADA'}) async {
    emit(
      state.copyWith(
        status: SolicitudesInsumosStatus.loading,
        estado: estado,
        clearError: true,
      ),
    );
    try {
      final items = await _repository.list(estado: estado);
      emit(
        state.copyWith(status: SolicitudesInsumosStatus.success, items: items),
      );
    } on ApiException catch (exception) {
      emit(
        state.copyWith(
          status: SolicitudesInsumosStatus.error,
          errorMessage: exception.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: SolicitudesInsumosStatus.error,
          errorMessage: 'No pudimos cargar las solicitudes de insumos.',
        ),
      );
    }
  }

  Future<String?> deliver({
    required int id,
    String? motivo,
    String? observacion,
  }) async {
    emit(state.copyWith(isDelivering: true, clearError: true));
    try {
      await _repository.deliver(
        id: id,
        motivo: motivo,
        observacion: observacion,
      );
      await load(estado: state.estado);
      return null;
    } on ApiException catch (exception) {
      emit(
        state.copyWith(isDelivering: false, errorMessage: exception.message),
      );
      return exception.message;
    } catch (_) {
      const message = 'No pudimos entregar la solicitud de insumos.';
      emit(state.copyWith(isDelivering: false, errorMessage: message));
      return message;
    }
  }

  Future<SolicitudInsumoDetail> getDetail(int id) => _repository.getDetail(id);
}
