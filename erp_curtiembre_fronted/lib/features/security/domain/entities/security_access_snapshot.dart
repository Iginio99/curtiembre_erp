import 'package:equatable/equatable.dart';
import 'package:erp_curtiembre_fronted/features/security/domain/entities/security_permission.dart';
import 'package:erp_curtiembre_fronted/features/security/domain/entities/security_role.dart';

class SecurityAccessSnapshot extends Equatable {
  const SecurityAccessSnapshot({
    required this.roles,
    required this.permissions,
    required this.userPermissionCodes,
  });

  final List<SecurityRole> roles;
  final List<SecurityPermission> permissions;
  final List<String> userPermissionCodes;

  @override
  List<Object?> get props => [roles, permissions, userPermissionCodes];
}
