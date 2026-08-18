import 'package:erp_curtiembre_fronted/features/production/clientes/domain/entities/cliente_option.dart';
import 'package:erp_curtiembre_fronted/features/production/clientes/domain/entities/cliente_record.dart';

abstract class ClientesRepository {
  Future<List<ClienteRecord>> listClientes({
    String? texto,
    bool? activo,
  });

  Future<ClienteRecord> getCliente(int id);

  Future<List<ClienteOption>> listActiveClientes();

  Future<ClienteRecord> createCliente({
    required String rucDocumento,
    required String razonSocial,
    String? direccion,
    String? celular,
    String? correo,
    String? contacto,
  });

  Future<ClienteRecord> updateCliente({
    required int id,
    required String rucDocumento,
    required String razonSocial,
    String? direccion,
    String? celular,
    String? correo,
    String? contacto,
  });

  Future<ClienteRecord> setClienteActive({
    required int id,
    required bool active,
  });
}
