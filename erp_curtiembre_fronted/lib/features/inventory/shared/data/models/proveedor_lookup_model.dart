import 'package:erp_curtiembre_fronted/features/inventory/shared/domain/entities/proveedor_lookup.dart';

class ProveedorLookupModel {
  const ProveedorLookupModel({
    required this.id,
    required this.rucDocumento,
    required this.razonSocial,
  });

  final int id;
  final String rucDocumento;
  final String razonSocial;

  factory ProveedorLookupModel.fromJson(Map<String, dynamic> json) {
    return ProveedorLookupModel(
      id: (json['id'] as num).toInt(),
      rucDocumento: json['rucDocumento'] as String,
      razonSocial: json['razonSocial'] as String,
    );
  }

  ProveedorLookup toEntity() {
    return ProveedorLookup(
      id: id,
      rucDocumento: rucDocumento,
      razonSocial: razonSocial,
    );
  }
}
