import 'package:equatable/equatable.dart';
import 'package:erp_curtiembre_fronted/features/auth/domain/entities/auth_session.dart';

class PasswordChangeResult extends Equatable {
  const PasswordChangeResult({
    required this.session,
    required this.message,
  });

  final AuthSession session;
  final String message;

  @override
  List<Object?> get props => [session, message];
}
