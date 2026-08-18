import 'package:erp_curtiembre_fronted/features/inventory/proveedores/domain/entities/proveedor_record.dart';

abstract class ProveedoresRepository {
  Future<List<ProveedorRecord>> listProveedores({
    String? texto,
    bool? activo,
  });

  Future<ProveedorRecord> getProveedor(int id);

  Future<ProveedorRecord> createProveedor({
    required String rucDocumento,
    required String razonSocial,
    String? direccion,
    String? telefono,
    String? correo,
    String? contacto,
  });

  Future<ProveedorRecord> updateProveedor({
    required int id,
    required String rucDocumento,
    required String razonSocial,
    String? direccion,
    String? telefono,
    String? correo,
    String? contacto,
  });

  Future<ProveedorRecord> setProveedorActive({
    required int id,
    required bool active,
  });
}
