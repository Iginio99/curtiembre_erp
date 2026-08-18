import 'package:dio/dio.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/configuration/system_parameters/data/models/system_parameter_record_model.dart';

class SystemParametersRemoteDataSource {
  SystemParametersRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<SystemParameterRecordModel>> listSystemParameters() async {
    try {
      final response = await _dio.get<List<dynamic>>('/api/configuracion/parametros');
      final items = response.data ?? const [];

      return items
          .map(
            (item) =>
                SystemParameterRecordModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }
}
