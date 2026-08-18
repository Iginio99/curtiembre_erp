import 'package:equatable/equatable.dart';
import 'package:erp_curtiembre_fronted/features/auth/domain/entities/auth_session.dart';

enum AuthStatus {
  checking,
  unauthenticated,
  authenticating,
  signingOut,
  authenticated,
}

class AuthState extends Equatable {
  const AuthState({
    required this.status,
    this.session,
    this.errorMessage,
    this.noticeMessage,
  });

  const AuthState.checking() : this(status: AuthStatus.checking);

  const AuthState.unauthenticated({
    String? errorMessage,
    String? noticeMessage,
  }) : this(
          status: AuthStatus.unauthenticated,
          errorMessage: errorMessage,
          noticeMessage: noticeMessage,
        );

  const AuthState.authenticating()
      : this(
          status: AuthStatus.authenticating,
        );

  const AuthState.signingOut(AuthSession session)
      : this(
          status: AuthStatus.signingOut,
          session: session,
        );

  const AuthState.authenticated(AuthSession session)
      : this(
          status: AuthStatus.authenticated,
          session: session,
        );

  final AuthStatus status;
  final AuthSession? session;
  final String? errorMessage;
  final String? noticeMessage;

  AuthState copyWith({
    AuthStatus? status,
    AuthSession? session,
    String? errorMessage,
    String? noticeMessage,
    bool clearError = false,
    bool clearNotice = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      session: session ?? this.session,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      noticeMessage: clearNotice ? null : noticeMessage ?? this.noticeMessage,
    );
  }

  @override
  List<Object?> get props => [status, session, errorMessage, noticeMessage];
}
