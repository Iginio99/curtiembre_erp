import 'package:equatable/equatable.dart';

class AjusteDetalleLine extends Equatable {
  const AjusteDetalleLine({
    required this.id,
    required this.insumoId,
    required this.insumoCodigo,
    required this.insumoNombre,
    required this.cantidad,
    required this.costoTotal,
    required this.stockActual,
    required this.unidadMedidaCodigo,
    required this.unidadMedidaNombre,
    this.costoUnitario,
  });

  final int id;
  final int insumoId;
  final String insumoCodigo;
  final String insumoNombre;
  final double cantidad;
  final double? costoUnitario;
  final double costoTotal;
  final double stockActual;
  final String unidadMedidaCodigo;
  final String unidadMedidaNombre;

  @override
  List<Object?> get props => [
        id,
        insumoId,
        insumoCodigo,
        insumoNombre,
        cantidad,
        costoUnitario,
        costoTotal,
        stockActual,
        unidadMedidaCodigo,
        unidadMedidaNombre,
      ];
}

class AjusteDetail extends Equatable {
  const AjusteDetail({
    required this.id,
    required this.codigo,
    required this.tipoAjuste,
    required this.fechaAjuste,
    required this.motivo,
    required this.usuarioResponsableId,
    required this.detalles,
    this.observacion,
  });

  final int id;
  final String codigo;
  final String tipoAjuste;
  final DateTime fechaAjuste;
  final String motivo;
  final String? observacion;
  final int usuarioResponsableId;
  final List<AjusteDetalleLine> detalles;

  @override
  List<Object?> get props => [
        id,
        codigo,
        tipoAjuste,
        fechaAjuste,
        motivo,
        observacion,
        usuarioResponsableId,
        detalles,
      ];
}
