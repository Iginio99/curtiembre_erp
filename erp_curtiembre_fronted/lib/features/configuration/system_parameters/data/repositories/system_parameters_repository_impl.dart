import 'package:erp_curtiembre_fronted/features/configuration/system_parameters/data/datasources/system_parameters_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/configuration/system_parameters/domain/entities/system_parameter_record.dart';
import 'package:erp_curtiembre_fronted/features/configuration/system_parameters/domain/repositories/system_parameters_repository.dart';

class SystemParametersRepositoryImpl implements SystemParametersRepository {
  SystemParametersRepositoryImpl(this._remoteDataSource);

  final SystemParametersRemoteDataSource _remoteDataSource;

  @override
  Future<List<SystemParameterRecord>> listSystemParameters() {
    return _remoteDataSource.listSystemParameters();
  }
}
