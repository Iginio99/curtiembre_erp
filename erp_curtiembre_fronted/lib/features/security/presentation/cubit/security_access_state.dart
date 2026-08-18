import 'package:equatable/equatable.dart';
import 'package:erp_curtiembre_fronted/features/security/domain/entities/security_access_snapshot.dart';

enum SecurityAccessStatus {
  loading,
  success,
  error,
}

class SecurityAccessState extends Equatable {
  const SecurityAccessState({
    required this.status,
    this.snapshot,
    this.errorMessage,
    this.checkedPermissions = const {},
  });

  const SecurityAccessState.loading() : this(status: SecurityAccessStatus.loading);

  final SecurityAccessStatus status;
  final SecurityAccessSnapshot? snapshot;
  final String? errorMessage;
  final Map<String, bool> checkedPermissions;

  SecurityAccessState copyWith({
    SecurityAccessStatus? status,
    SecurityAccessSnapshot? snapshot,
    String? errorMessage,
    Map<String, bool>? checkedPermissions,
    bool clearError = false,
  }) {
    return SecurityAccessState(
      status: status ?? this.status,
      snapshot: snapshot ?? this.snapshot,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      checkedPermissions: checkedPermissions ?? this.checkedPermissions,
    );
  }

  @override
  List<Object?> get props => [status, snapshot, errorMessage, checkedPermissions];
}
