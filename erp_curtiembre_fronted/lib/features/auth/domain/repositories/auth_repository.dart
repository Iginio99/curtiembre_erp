import 'package:erp_curtiembre_fronted/features/auth/domain/entities/auth_session.dart';
import 'package:erp_curtiembre_fronted/features/auth/domain/entities/password_change_result.dart';

abstract class AuthRepository {
  Future<AuthSession?> restoreSession();

  Future<AuthSession> login({
    required String userName,
    required String password,
  });

  Future<PasswordChangeResult> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  });

  Future<String?> logout();
}
