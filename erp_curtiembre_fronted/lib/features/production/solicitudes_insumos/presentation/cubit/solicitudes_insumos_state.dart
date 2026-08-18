import 'package:equatable/equatable.dart';
import 'package:erp_curtiembre_fronted/features/production/solicitudes_insumos/domain/entities/solicitud_insumo_record.dart';

enum SolicitudesInsumosStatus { loading, success, error }

class SolicitudesInsumosState extends Equatable {
  const SolicitudesInsumosState({
    required this.status,
    this.items = const [],
    this.estado = 'SOLICITADA',
    this.isDelivering = false,
    this.errorMessage,
  });

  const SolicitudesInsumosState.loading()
    : this(status: SolicitudesInsumosStatus.loading);

  final SolicitudesInsumosStatus status;
  final List<SolicitudInsumoRecord> items;
  final String? estado;
  final bool isDelivering;
  final String? errorMessage;

  SolicitudesInsumosState copyWith({
    SolicitudesInsumosStatus? status,
    List<SolicitudInsumoRecord>? items,
    String? estado,
    bool? isDelivering,
    String? errorMessage,
    bool clearError = false,
  }) => SolicitudesInsumosState(
    status: status ?? this.status,
    items: items ?? this.items,
    estado: estado ?? this.estado,
    isDelivering: isDelivering ?? this.isDelivering,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );

  @override
  List<Object?> get props => [
    status,
    items,
    estado,
    isDelivering,
    errorMessage,
  ];
}
