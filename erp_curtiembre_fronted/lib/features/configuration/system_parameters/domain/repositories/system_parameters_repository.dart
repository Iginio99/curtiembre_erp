import 'package:erp_curtiembre_fronted/features/configuration/system_parameters/domain/entities/system_parameter_record.dart';

abstract interface class SystemParametersRepository {
  Future<List<SystemParameterRecord>> listSystemParameters();
}
