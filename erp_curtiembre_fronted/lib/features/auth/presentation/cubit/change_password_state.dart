import 'package:equatable/equatable.dart';
import 'package:erp_curtiembre_fronted/features/auth/domain/entities/password_change_result.dart';

enum ChangePasswordStatus {
  idle,
  submitting,
  success,
  error,
}

class ChangePasswordState extends Equatable {
  const ChangePasswordState({
    required this.status,
    this.result,
    this.errorMessage,
  });

  const ChangePasswordState.idle() : this(status: ChangePasswordStatus.idle);

  final ChangePasswordStatus status;
  final PasswordChangeResult? result;
  final String? errorMessage;

  ChangePasswordState copyWith({
    ChangePasswordStatus? status,
    PasswordChangeResult? result,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChangePasswordState(
      status: status ?? this.status,
      result: result ?? this.result,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, result, errorMessage];
}
