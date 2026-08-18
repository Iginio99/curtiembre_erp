import 'package:erp_curtiembre_fronted/features/security/domain/entities/security_role.dart';
import 'package:erp_curtiembre_fronted/features/users/domain/entities/user_area_option.dart';
import 'package:erp_curtiembre_fronted/features/users/domain/entities/user_detail.dart';
import 'package:erp_curtiembre_fronted/features/users/domain/entities/user_list_item.dart';
import 'package:erp_curtiembre_fronted/features/users/domain/entities/user_mutation_result.dart';

abstract interface class UsersRepository {
  Future<List<SecurityRole>> listRoles();

  Future<List<UserAreaOption>> listActiveAreas();

  Future<List<UserListItem>> listUsers({
    String? texto,
    bool? activo,
  });

  Future<UserDetail> getUserDetail(int usuarioId);

  Future<UserMutationResult> createUser({
    required String dni,
    required String nombres,
    required String apellidos,
    required String userName,
    required int rolId,
    required int areaId,
    String? passwordTemporal,
  });

  Future<UserMutationResult> updateUser({
    required int usuarioId,
    required String dni,
    required String nombres,
    required String apellidos,
    required String userName,
    required int rolId,
    required int areaId,
  });

  Future<String> resetPassword({
    required int usuarioId,
    String? passwordTemporal,
  });

  Future<String> deactivateUser({
    required int usuarioId,
    String? motivo,
  });

  Future<String> reactivateUser({
    required int usuarioId,
    String? motivo,
  });
}
