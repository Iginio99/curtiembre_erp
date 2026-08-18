import 'package:equatable/equatable.dart';

class ProveedorRecord extends Equatable {
  const ProveedorRecord({
    required this.id,
    required this.rucDocumento,
    required this.razonSocial,
    required this.activo,
    required this.creadoEn,
    this.direccion,
    this.telefono,
    this.correo,
    this.contacto,
    this.actualizadoEn,
  });

  final int id;
  final String rucDocumento;
  final String razonSocial;
  final String? direccion;
  final String? telefono;
  final String? correo;
  final String? contacto;
  final bool activo;
  final DateTime creadoEn;
  final DateTime? actualizadoEn;

  @override
  List<Object?> get props => [
        id,
        rucDocumento,
        razonSocial,
        direccion,
        telefono,
        correo,
        contacto,
        activo,
        creadoEn,
        actualizadoEn,
      ];
}
