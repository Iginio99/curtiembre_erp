import 'package:erp_curtiembre_fronted/features/security/domain/entities/permission_check_result.dart';

class PermissionCheckResultModel {
  const PermissionCheckResultModel({
    required this.usuarioId,
    required this.permissionCode,
    required this.allowed,
  });

  final int usuarioId;
  final String permissionCode;
  final bool allowed;

  factory PermissionCheckResultModel.fromJson(Map<String, dynamic> json) {
    return PermissionCheckResultModel(
      usuarioId: json['usuarioId'] as int,
      permissionCode: json['permissionCode'] as String,
      allowed: json['allowed'] as bool,
    );
  }

  PermissionCheckResult toEntity() {
    return PermissionCheckResult(
      usuarioId: usuarioId,
      permissionCode: permissionCode,
      allowed: allowed,
    );
  }
}
