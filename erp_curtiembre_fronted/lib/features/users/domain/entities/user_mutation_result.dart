import 'package:equatable/equatable.dart';
import 'package:erp_curtiembre_fronted/features/users/domain/entities/user_detail.dart';

class UserMutationResult extends Equatable {
  const UserMutationResult({
    required this.usuario,
    this.passwordTemporal,
  });

  final UserDetail usuario;
  final String? passwordTemporal;

  @override
  List<Object?> get props => [usuario, passwordTemporal];
}
