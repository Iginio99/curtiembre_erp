import 'package:equatable/equatable.dart';

class PermissionCheckResult extends Equatable {
  const PermissionCheckResult({
    required this.usuarioId,
    required this.permissionCode,
    required this.allowed,
  });

  final int usuarioId;
  final String permissionCode;
  final bool allowed;

  @override
  List<Object?> get props => [usuarioId, permissionCode, allowed];
}
