import 'package:erp_curtiembre_fronted/features/users/data/models/user_detail_model.dart';
import 'package:erp_curtiembre_fronted/features/users/domain/entities/user_mutation_result.dart';

class UserMutationResultModel {
  const UserMutationResultModel({
    required this.usuario,
    this.passwordTemporal,
  });

  final UserDetailModel usuario;
  final String? passwordTemporal;

  factory UserMutationResultModel.fromJson(Map<String, dynamic> json) {
    return UserMutationResultModel(
      usuario: UserDetailModel.fromJson(json['usuario'] as Map<String, dynamic>),
      passwordTemporal: json['passwordTemporal'] as String?,
    );
  }

  UserMutationResult toEntity() {
    return UserMutationResult(
      usuario: usuario.toEntity(),
      passwordTemporal: passwordTemporal,
    );
  }
}
