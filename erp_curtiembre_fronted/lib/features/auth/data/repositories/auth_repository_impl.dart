import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/core/storage/session_storage.dart';
import 'package:erp_curtiembre_fronted/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/auth/data/models/change_password_request_model.dart';
import 'package:erp_curtiembre_fronted/features/auth/data/models/login_request_model.dart';
import 'package:erp_curtiembre_fronted/features/auth/domain/entities/auth_session.dart';
import 'package:erp_curtiembre_fronted/features/auth/domain/entities/password_change_result.dart';
import 'package:erp_curtiembre_fronted/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(
    this._remoteDataSource,
    this._sessionStorage,
  );

  final AuthRemoteDataSource _remoteDataSource;
  final SessionStorage _sessionStorage;

  @override
  Future<AuthSession> login({
    required String userName,
    required String password,
  }) async {
    final model = await _remoteDataSource.login(
      LoginRequestModel(
        userName: userName,
        password: password,
      ),
    );

    final session = model.toEntity();
    await _sessionStorage.saveSession(session);
    return session;
  }

  @override
  Future<PasswordChangeResult> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final currentSession = await _sessionStorage.readSession();
    if (currentSession == null) {
      throw ApiException(
        message: 'Tu sesion expiro por seguridad. Inicia sesion nuevamente.',
        statusCode: 401,
      );
    }

    final message = await _remoteDataSource.changePassword(
      ChangePasswordRequestModel(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      ),
    );

    final updatedSession = currentSession.copyWith(debeCambiarPassword: false);
    await _sessionStorage.saveSession(updatedSession);

    return PasswordChangeResult(
      session: updatedSession,
      message: message,
    );
  }

  @override
  Future<String?> logout() async {
    try {
      return await _remoteDataSource.logout();
    } on ApiException {
      // Clear local session even if remote logout fails.
      return null;
    } finally {
      await _sessionStorage.clearSession();
    }
  }

  @override
  Future<AuthSession?> restoreSession() async {
    final localSession = await _sessionStorage.readSession();
    if (localSession == null) {
      return null;
    }

    try {
      final remoteSession = await _remoteDataSource.fetchCurrentSession(
        localSession.sessionToken,
      );
      final refreshedSession = remoteSession.toEntity();
      await _sessionStorage.saveSession(refreshedSession);
      return refreshedSession;
    } on ApiException catch (exception) {
      if (exception.statusCode == 401 || exception.statusCode == 403) {
        await _sessionStorage.clearSession();
        return null;
      }

      return localSession;
    }
  }
}
