import 'package:equatable/equatable.dart';

class SystemParameterRecord extends Equatable {
  const SystemParameterRecord({
    required this.id,
    required this.clave,
    required this.valor,
    required this.descripcion,
    required this.tipoDato,
    required this.editable,
    required this.actualizadoEn,
  });

  final int id;
  final String clave;
  final String valor;
  final String? descripcion;
  final String tipoDato;
  final bool editable;
  final DateTime? actualizadoEn;

  @override
  List<Object?> get props => [
        id,
        clave,
        valor,
        descripcion,
        tipoDato,
        editable,
        actualizadoEn,
      ];
}
