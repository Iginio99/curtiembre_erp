import 'package:erp_curtiembre_fronted/features/production/clientes/domain/entities/cliente_option.dart';

class ClienteOptionModel {
  const ClienteOptionModel({
    required this.id,
    required this.rucDocumento,
    required this.razonSocial,
  });

  final int id;
  final String rucDocumento;
  final String razonSocial;

  factory ClienteOptionModel.fromJson(Map<String, dynamic> json) {
    return ClienteOptionModel(
      id: (json['id'] as num).toInt(),
      rucDocumento: json['rucDocumento'] as String,
      razonSocial: json['razonSocial'] as String,
    );
  }

  ClienteOption toEntity() {
    return ClienteOption(
      id: id,
      rucDocumento: rucDocumento,
      razonSocial: razonSocial,
    );
  }
}
