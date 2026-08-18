import 'package:equatable/equatable.dart';

class AjusteRecord extends Equatable {
  const AjusteRecord({
    required this.id,
    required this.codigo,
    required this.tipoAjuste,
    required this.fechaAjuste,
    required this.motivo,
    required this.usuarioResponsableId,
    required this.totalItems,
    required this.cantidadTotal,
    required this.montoTotal,
    this.observacion,
  });

  final int id;
  final String codigo;
  final String tipoAjuste;
  final DateTime fechaAjuste;
  final String motivo;
  final String? observacion;
  final int usuarioResponsableId;
  final int totalItems;
  final double cantidadTotal;
  final double montoTotal;

  @override
  List<Object?> get props => [
        id,
        codigo,
        tipoAjuste,
        fechaAjuste,
        motivo,
        observacion,
        usuarioResponsableId,
        totalItems,
        cantidadTotal,
        montoTotal,
      ];
}
