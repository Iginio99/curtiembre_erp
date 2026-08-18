import 'package:equatable/equatable.dart';

class KardexRecord extends Equatable {
  const KardexRecord({
    required this.id,
    required this.fechaMovimiento,
    required this.insumoId,
    required this.insumoCodigo,
    required this.insumoNombre,
    required this.tipoMovimiento,
    required this.entrada,
    required this.salida,
    required this.stockActual,
    required this.costoUnitario,
    required this.costoTotal,
    this.documentoTipo,
    this.documentoId,
    this.estadoStock,
    this.usuarioResponsableId,
    this.usuarioResponsable,
    this.observacion,
  });

  final int id;
  final DateTime fechaMovimiento;
  final int insumoId;
  final String insumoCodigo;
  final String insumoNombre;
  final String tipoMovimiento;
  final String? documentoTipo;
  final int? documentoId;
  final double entrada;
  final double salida;
  final double stockActual;
  final String? estadoStock;
  final double costoUnitario;
  final double costoTotal;
  final int? usuarioResponsableId;
  final String? usuarioResponsable;
  final String? observacion;

  bool get isEntrada => entrada > 0;

  @override
  List<Object?> get props => [
        id,
        fechaMovimiento,
        insumoId,
        insumoCodigo,
        insumoNombre,
        tipoMovimiento,
        documentoTipo,
        documentoId,
        entrada,
        salida,
        stockActual,
        estadoStock,
        costoUnitario,
        costoTotal,
        usuarioResponsableId,
        usuarioResponsable,
        observacion,
      ];
}
