import 'package:equatable/equatable.dart';

class ProveedorLookup extends Equatable {
  const ProveedorLookup({
    required this.id,
    required this.rucDocumento,
    required this.razonSocial,
  });

  final int id;
  final String rucDocumento;
  final String razonSocial;

  String get displayName => '$razonSocial · $rucDocumento';

  @override
  List<Object?> get props => [
        id,
        rucDocumento,
        razonSocial,
      ];
}
