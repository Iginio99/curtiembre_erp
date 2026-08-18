import 'package:equatable/equatable.dart';

class ManoObraDirectaRecord extends Equatable {
  const ManoObraDirectaRecord({
    required this.id,
    required this.ordenProduccionId,
    required this.ordenProduccionCodigo,
    required this.ordenProcesoId,
    required this.procesoCodigo,
    required this.procesoNombre,
    required this.monto,
    required this.registradoEn,
    this.descripcion,
    this.registradoPorUsuarioId,
  });

  final int id;
  final int ordenProduccionId;
  final String ordenProduccionCodigo;
  final int ordenProcesoId;
  final String procesoCodigo;
  final String procesoNombre;
  final double monto;
  final String? descripcion;
  final DateTime registradoEn;
  final int? registradoPorUsuarioId;

  @override
  List<Object?> get props => [
        id,
        ordenProduccionId,
        ordenProduccionCodigo,
        ordenProcesoId,
        procesoCodigo,
        procesoNombre,
        monto,
        descripcion,
        registradoEn,
        registradoPorUsuarioId,
      ];
}
