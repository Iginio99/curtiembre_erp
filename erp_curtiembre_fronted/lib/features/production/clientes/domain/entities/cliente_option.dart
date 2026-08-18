import 'package:equatable/equatable.dart';

class ClienteOption extends Equatable {
  const ClienteOption({
    required this.id,
    required this.rucDocumento,
    required this.razonSocial,
  });

  final int id;
  final String rucDocumento;
  final String razonSocial;

  String get label => '$razonSocial ($rucDocumento)';

  @override
  List<Object?> get props => [id, rucDocumento, razonSocial];
}
