import 'package:equatable/equatable.dart';

class CostoIndirectoRecord extends Equatable {
  const CostoIndirectoRecord({
    required this.id,
    required this.periodoCostoId,
    required this.periodoAnio,
    required this.periodoMes,
    required this.periodoEstado,
    required this.tipoCosto,
    required this.monto,
    required this.registradoEn,
    this.descripcion,
    this.registradoPorUsuarioId,
  });

  final int id;
  final int periodoCostoId;
  final int periodoAnio;
  final int periodoMes;
  final String periodoEstado;
  final String tipoCosto;
  final String? descripcion;
  final double monto;
  final DateTime registradoEn;
  final int? registradoPorUsuarioId;

  String get periodoCodigo => '$periodoAnio-${periodoMes.toString().padLeft(2, '0')}';

  @override
  List<Object?> get props => [
        id,
        periodoCostoId,
        periodoAnio,
        periodoMes,
        periodoEstado,
        tipoCosto,
        descripcion,
        monto,
        registradoEn,
        registradoPorUsuarioId,
      ];
}
