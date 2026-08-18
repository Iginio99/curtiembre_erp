import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/auth/domain/entities/auth_session.dart';
import 'package:erp_curtiembre_fronted/features/auth/domain/repositories/auth_repository.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._authRepository) : super(const AuthState.checking());

  final AuthRepository _authRepository;

  Future<void> bootstrap() async {
    emit(const AuthState.checking());

    try {
      final session = await _authRepository.restoreSession();

      if (session == null) {
        emit(const AuthState.unauthenticated());
        return;
      }

      emit(AuthState.authenticated(session));
    } catch (_) {
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> signIn({
    required String userName,
    required String password,
  }) async {
    emit(const AuthState.authenticating());

    try {
      final session = await _authRepository.login(
        userName: userName,
        password: password,
      );
      emit(AuthState.authenticated(session));
    } on ApiException catch (exception) {
      emit(AuthState.unauthenticated(errorMessage: exception.message));
    } catch (_) {
      emit(
        const AuthState.unauthenticated(
          errorMessage: 'No pudimos completar el inicio de sesion. Intenta nuevamente.',
        ),
      );
    }
  }

  Future<void> signOut() async {
    final currentSession = state.session;

    if (currentSession == null) {
      emit(const AuthState.unauthenticated());
      return;
    }

    emit(AuthState.signingOut(currentSession));

    try {
      final message = await _authRepository.logout();

      emit(
        AuthState.unauthenticated(
          noticeMessage: message ?? 'Sesion cerrada correctamente.',
        ),
      );
    } catch (_) {
      emit(
        const AuthState.unauthenticated(
          noticeMessage: 'Sesion cerrada localmente.',
        ),
      );
    }
  }

  void replaceSession(AuthSession session) {
    emit(AuthState.authenticated(session));
  }

  void clearError() {
    if (state.errorMessage == null) {
      return;
    }

    emit(state.copyWith(clearError: true));
  }

  void clearNotice() {
    if (state.noticeMessage == null) {
      return;
    }

    emit(state.copyWith(clearNotice: true));
  }
}
