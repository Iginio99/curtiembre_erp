import 'package:equatable/equatable.dart';

class ClienteRecord extends Equatable {
  const ClienteRecord({
    required this.id,
    required this.rucDocumento,
    required this.razonSocial,
    required this.activo,
    required this.creadoEn,
    this.direccion,
    this.celular,
    this.correo,
    this.contacto,
    this.actualizadoEn,
  });

  final int id;
  final String rucDocumento;
  final String razonSocial;
  final String? direccion;
  final String? celular;
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
        celular,
        correo,
        contacto,
        activo,
        creadoEn,
        actualizadoEn,
      ];
}
