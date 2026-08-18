import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/auth/domain/repositories/auth_repository.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/change_password_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChangePasswordCubit extends Cubit<ChangePasswordState> {
  ChangePasswordCubit(this._authRepository) : super(const ChangePasswordState.idle());

  final AuthRepository _authRepository;

  Future<void> submit({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    emit(state.copyWith(status: ChangePasswordStatus.submitting, clearError: true));

    try {
      final result = await _authRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      emit(
        state.copyWith(
          status: ChangePasswordStatus.success,
          result: result,
          clearError: true,
        ),
      );
    } on ApiException catch (exception) {
      emit(
        state.copyWith(
          status: ChangePasswordStatus.error,
          errorMessage: exception.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ChangePasswordStatus.error,
          errorMessage: 'No pudimos actualizar la contrasena. Intenta nuevamente.',
        ),
      );
    }
  }

  void clearError() {
    if (state.errorMessage == null) {
      return;
    }

    emit(state.copyWith(clearError: true));
  }
}
