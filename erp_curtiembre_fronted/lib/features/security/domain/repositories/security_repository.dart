import 'package:erp_curtiembre_fronted/features/security/domain/entities/security_access_snapshot.dart';
import 'package:erp_curtiembre_fronted/features/security/domain/entities/permission_check_result.dart';

abstract class SecurityRepository {
  Future<SecurityAccessSnapshot> loadAccessSnapshot({
    required int usuarioId,
  });

  Future<PermissionCheckResult> checkPermission({
    required int usuarioId,
    required String permissionCode,
  });
}
