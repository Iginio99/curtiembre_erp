import 'package:equatable/equatable.dart';

class InventarioFisicoResumen extends Equatable {
  const InventarioFisicoResumen({
    required this.totalItems,
    required this.itemsConDiferencia,
    required this.itemsConAjustePositivo,
    required this.itemsConAjusteNegativo,
    required this.totalDiferenciaAbsoluta,
  });

  final int totalItems;
  final int itemsConDiferencia;
  final int itemsConAjustePositivo;
  final int itemsConAjusteNegativo;
  final double totalDiferenciaAbsoluta;

  @override
  List<Object?> get props => [
        totalItems,
        itemsConDiferencia,
        itemsConAjustePositivo,
        itemsConAjusteNegativo,
        totalDiferenciaAbsoluta,
      ];
}

class InventarioFisicoConteoLine extends Equatable {
  const InventarioFisicoConteoLine({
    required this.id,
    required this.insumoId,
    required this.insumoCodigo,
    required this.insumoNombre,
    required this.stockSistema,
    required this.stockContado,
    required this.diferencia,
    required this.unidadMedidaCodigo,
    required this.unidadMedidaNombre,
    this.observacion,
  });

  final int id;
  final int insumoId;
  final String insumoCodigo;
  final String insumoNombre;
  final double stockSistema;
  final double stockContado;
  final double diferencia;
  final String unidadMedidaCodigo;
  final String unidadMedidaNombre;
  final String? observacion;

  @override
  List<Object?> get props => [
        id,
        insumoId,
        insumoCodigo,
        insumoNombre,
        stockSistema,
        stockContado,
        diferencia,
        unidadMedidaCodigo,
        unidadMedidaNombre,
        observacion,
      ];
}

class InventarioFisicoDetail extends Equatable {
  const InventarioFisicoDetail({
    required this.id,
    required this.codigo,
    required this.fechaInicio,
    required this.periodoAnio,
    required this.periodoMes,
    required this.estado,
    required this.ejecutadoPorUsuarioId,
    required this.resumen,
    required this.detalles,
    this.fechaCierre,
    this.observacion,
  });

  final int id;
  final String codigo;
  final DateTime fechaInicio;
  final DateTime? fechaCierre;
  final int periodoAnio;
  final int periodoMes;
  final String estado;
  final int ejecutadoPorUsuarioId;
  final String? observacion;
  final InventarioFisicoResumen resumen;
  final List<InventarioFisicoConteoLine> detalles;

  bool get isOpen => estado.toUpperCase() == 'ABIERTO';

  @override
  List<Object?> get props => [
        id,
        codigo,
        fechaInicio,
        fechaCierre,
        periodoAnio,
        periodoMes,
        estado,
        ejecutadoPorUsuarioId,
        observacion,
        resumen,
        detalles,
      ];
}
